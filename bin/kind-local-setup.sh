#!/bin/sh
set -o errexit

# create registry container unless it already exists 
CLUSTER_NAME='my-cluster'                   # desired cluster name; default is "kind"
REGISTRY_CONTAINER_NAME='kind-registry'
REGISTRY_PORT='5000'

startme(){

    if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_CONTAINER_NAME}")" != 'true' ]; then
        docker run -d -p "${REGISTRY_PORT}:5000" --restart=always --name "${REGISTRY_CONTAINER_NAME}" registry:2
    fi

# TODO check if kind is already running with cluster name

    # create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches: 
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry:${REGISTRY_PORT}"]
    endpoint = ["http://registry:${REGISTRY_PORT}"]
EOF

    # add the registry to /etc/hosts on control-plan node
    docker exec kind-control-plane sh -c "echo $(docker inspect --format '{{.NetworkSettings.IPAddress }}' "${REGISTRY_CONTAINER_NAME}") registry >> /etc/hosts"
    
    # add the registry to /etc/hosts on each node
    for node in $(kind get nodes --name ${CLUSTER_NAME}); do
        docker exec ${node} sh -c "echo $(docker inspect --format '{{.NetworkSettings.IPAddress }}' "${REGISTRY_CONTAINER_NAME}") registry >> /etc/hosts"
    done

}

stopme(){
    kind delete cluster
    docker stop "${REGISTRY_CONTAINER_NAME}"
}

getimage(){
    #TODO make this read from a toml file a list of images to get from x location and push the local docker reg
    echo "getting images"
}

case "$1" in 
    start)      startme ;;
    stop)       stopme ;;
    getimage)   getimage ;;

    *) echo "usage: $0 start|stop" >&2
       exit 1
       ;;
esac
