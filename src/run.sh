#!/usr/bin/env sh

# Set DRY_RUN to true to avoid applying any changes
: "${NAMESPACES:?A comma separated list of namespaces is required}"

MAX_DAYS="${MAX_DAYS:-3}"
DEPLOYMENT_LABEL_FILTER="${DEPLOYMENT_LABEL_FILTER:-version,version!=master}"

readonly NOW_IN_SECONDS=$(date +%s)
readonly DEPLOYMENT_SELECTOR_TEMPLATE="{{range .items}}{{.metadata.name}} app={{ .metadata.labels.app }},tier={{ .metadata.labels.tier }},version={{ .metadata.labels.version }}
{{end}}"
readonly REPLICASET_TEMPLATE="{{range .items}}{{.metadata.creationTimestamp}}
{{end}}"

function getDaysSinceLastChange()
{
    local namespace=$1
    local deploymentSelector=$2
    lastModifiedDate=$(kubectl get replicasets --namespace ${namespace} --selector "${deploymentSelector}" --template "${REPLICASET_TEMPLATE}" | sort | tail -1)
    lastModifiedDate=${lastModifiedDate/T/ }; lastModifiedDate=${lastModifiedDate/Z/} # Convert to readable date
    lastModifiedDateInSeconds=$(date -d "${lastModifiedDate}" +%s)
    durationInDays=$(((NOW_IN_SECONDS-lastModifiedDateInSeconds)/60/60/24))
    echo ${durationInDays}
}

function deleteDeployment()
{
    local namespace=$1
    local deploymentName=$2
    if [ -z ${DRY_RUN+x} ]; then
        kubectl delete deployment --namespace ${namespace} ${deploymentName}
    else
        echo "Dry run, no changes have been made."
    fi
}

function cleanUpNamespace()
{
    local namespace=$1
    echo "Cleanning up ${namespace}"

    matchingDeployments=$(kubectl get deployments --namespace ${namespace} --selector "${DEPLOYMENT_LABEL_FILTER}" --label-columns 'app,tier,version' --template="${DEPLOYMENT_SELECTOR_TEMPLATE}")

    if [ -n "$matchingDeployments" ]; then
        echo "${matchingDeployments}" | while read deploymentName deploymentSelector ; do
            durationInDays=$(getDaysSinceLastChange ${namespace} ${deploymentSelector})
            if [ "${durationInDays}" -gt "${MAX_DAYS}" ]; then
                echo "${deploymentName} has not been modified for ${durationInDays} days, cleaning up..."
                deleteDeployment ${namespace} ${deploymentName}
            fi
        done
    fi
}

for namespace in $(echo ${NAMESPACES} | sed "s/,/ /g")
do
    cleanUpNamespace ${namespace}
done


