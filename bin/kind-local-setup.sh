#!/bin/bash
set -o errexit

# create registry container unless it already exists 
CLUSTER_NAME='kind'                   # desired cluster name; default is "kind"
REGISTRY_CONTAINER_NAME='kind-registry'
REGISTRY_PORT='5000'
LOCAL_REGISTRY='localhost:5000'

startme(){

  # check if there is already a container for reg
  echo "starting local git repo"
  registry_container_id="$(docker container ls -a | grep kind-registry | awk '{ print $1}')" 

  if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_CONTAINER_NAME}")" != 'true' ]; then
    if [  -z ${registry_container_id}  ]; then
      docker run -d -p "${REGISTRY_PORT}:5000" --restart=always --name "${REGISTRY_CONTAINER_NAME}" registry:2
    else
      docker container start ${registry_container_id}
    fi
  fi

# TODO move this to use the kind.yaml in the config folder
# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches: 
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry:${REGISTRY_PORT}"]
    endpoint = ["http://registry:${REGISTRY_PORT}"]
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF

  # add the registry to /etc/hosts on each node
  for node in $(kind get nodes --name ${CLUSTER_NAME}); do
    docker exec ${node} sh -c "echo $(docker inspect --format '{{.NetworkSettings.IPAddress }}' "${REGISTRY_CONTAINER_NAME}") registry >> /etc/hosts"
  done

}

stopme(){
  kind delete cluster
  docker stop "${REGISTRY_CONTAINER_NAME}"
}

case "$1" in 
  start)      startme ;;
  stop)       stopme ;;
  getimages)   getimages ;;

  *) echo "usage: $0 start|stop" >&2
    exit 1
    ;;
esac
