
DOCKER_IMAGE=quay.io/wealthwizards/kube-housekeeper

image:
	docker build -t ${DOCKER_IMAGE} .
.PHONY: image

dry-run: image
	docker run -w /usr/src -v $(PWD)/src:/usr/src -v ~/.kube:/root/.kube -e DRY_RUN=true -it ${DOCKER_IMAGE} /usr/src/run.sh
.PHONY: dry-run

tinker: image
	docker run -w /usr/src -v $(PWD)/src:/usr/src -v ~/.kube:/root/.kube -it ${DOCKER_IMAGE} /bin/sh
.PHONY: tinker