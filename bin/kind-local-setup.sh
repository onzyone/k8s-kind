#!/bin/bash
set -o errexit

#
# most of this script is taken from here: https://github.com/windmilleng/kind-local/blob/master/kind-with-registry.sh
#

# desired cluster name; default is "kind"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-kind}"
reg_name='kind-registry'

startme(){

  kind_version=$(kind version)
  kind_network='kind'
  reg_port='5000'

  echo ${kind_version}
  # get kind version and setup kind network
  case "${kind_version}" in
    "kind v0.7."* | "kind v0.6."* | "kind v0.5."*)
      kind_network='bridge'
      ;;
  esac

  # check if there is already a container for reg
  echo "starting local git repo"
  # create registry container unless it already exists
  if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}")" != 'true' ]; then
    registry_container_id="$(docker container ls -a | grep ${reg_name} | awk '{ print $1}')" 
    if [  -z ${registry_container_id}  ]; then
      docker run \
        -d -p --restart=always \
        "${reg_port}:5000" \
        --name "${reg_name}" \
        registry:2
    else
      docker container start ${registry_container_id}
    fi
  fi

  reg_host="${reg_name}"
  if [ "${kind_network}" = "bridge" ]; then
      reg_host="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "${reg_name}")"
  fi
  echo "Registry Host: ${reg_host}"

# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --name "${KIND_CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches: 
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_host}:${reg_port}"]
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF

  # add the registry to /etc/hosts on each node
  for node in $(kind get nodes --name ${KIND_CLUSTER_NAME}); do
#    docker exec ${node} sh -c "echo $(docker inspect --format '{{.NetworkSettings.IPAddress }}' "${REGISTRY_CONTAINER_NAME}") registry >> /etc/hosts"
    kubectl annotate node "${node}" tilt.dev/registry=localhost:${reg_port};
  done

  if [ "${kind_network}" != "bridge" ]; then
    containers=$(docker network inspect ${kind_network} -f "{{range .Containers}}{{.Name}} {{end}}")
    needs_connect="true"
    for c in $containers; do
      if [ "$c" = "${reg_name}" ]; then
        needs_connect="false"
      fi
    done
    if [ "${needs_connect}" = "true" ]; then               
      docker network connect "${kind_network}" "${reg_name}" || true
    fi
  fi
}

stopme(){
  kind delete cluster
  docker stop "${reg_name}"
}

installme(){
  # This is only tested to be working for github actions
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.8.0/kind-$(uname)-amd64
  chmod +x ./kind
}

case "$1" in 
  start)      startme ;;
  stop)       stopme ;;
  install)    installme ;;

  *) echo "usage: $0 start|stop|installme" >&2
    exit 1
    ;;
esac
