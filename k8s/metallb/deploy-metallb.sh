#!/bin/bash
set -ex

cd $(dirname $0)

docker pull metallb/controller:v0.9.3
docker tag metallb/controller:v0.9.3 localhost:5000/metallb/controller:v0.9.3
docker push localhost:5000/metallb/controller:v0.9.3

docker pull metallb/speaker:v0.9.3
docker tag metallb/speaker:v0.9.3 localhost:5000/metallb/speaker:v0.9.3
docker push localhost:5000/metallb/speaker:v0.9.3

curl localhost:5000/v2/_catalog -s | jq
curl localhost:5000/v2/metallb/controller/tags/list -s | jq
curl localhost:5000/v2/metallb/speaker/tags/list -s | jq

# delete if there
kubectl delete -f namespace.yaml --ignore-not-found
kubectl delete -f metallb.yaml --ignore-not-found
kubectl delete secret -n metallb-system memberlist --ignore-not-found
kubectl delete -f km-config.yaml --ignore-not-found

# create
kubectl create -f namespace.yaml
kubectl create -f metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl create -f km-config.yaml
