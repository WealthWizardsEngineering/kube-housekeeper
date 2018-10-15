# Kubernetes Housekeeper

The kubernetes housekeeper is designed to periodically run within a Kubernetes cluter to clean up deployments that are
no longer needed. An example is where multiple versions of a deployment are deployed for development and testing
purposes and are no longer needed after the work has been completed.

* NAMESPACES - a comma separated list of namespaces to housekeep
* DRY_RUN - set to avoid applying any changes
* MAX_DAYS - the number of days after the last change to clean up deployments
* DEPLOYMENT_LABEL_FILTER - a
[label selector](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors) for
identifying deployments to manage

## Access to the Kubernetes API

The project uses [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/) which connects to the Kubernetes API.
Kubectl access the API from within a running pod, the following Service Account and Role is required:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-housekeeper
subjects:
- kind: ServiceAccount
  name: kube-housekeeper
  namespace: platform
roleRef:
  kind: ClusterRole
  name: kube-housekeeper
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-housekeeper
rules:
- apiGroups: ["extensions", "apps"]
  resources:
  - deployments
  verbs:
  - delete
  - list
- apiGroups: ["extensions", "apps"]
  resources:
  - replicasets
  verbs:
  - list
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-housekeeper
  namespace: platform
```