# Overview

This is just a quick way to setup kind and a local docker regestry

```bash
$ bin/kind-local-setup.sh
usage: kind-local-setup.sh start|stop|getimages
```

### Confirmed working with:
* kind: `v0.8.1`
* tilt: `v0.13.4`

# Table of contents
<!--ts-->
  * [Overview](#Overview)
  * [Table of contents](#table-of-contents)
  * [Usage](#usage)
    * [Mac OS Only](#Mac-OS-only)
    * [Start](#Start)
    * [Get Images](#Get-images)
    * [Deploy with Helm](#Deploy-with-Helm)
    * [Stop](#Stop)
  * [Troubleshooting](#Troubleshooting)
  * [Reference Documentation](#Reference-Documentation)
  * [Dependency](#dependency)
<!--te-->

# Usage
## Mac OS only
1. Mac OS:
    * https://www.thehumblelab.com/kind-and-metallb-on-mac/
    * *note* if brew install of tuntap is not working you may have to update your settings:
        * https://github.com/Homebrew/homebrew-cask/issues/61236

## Start
1. In the bin dir of this repo you will find the start / stop script
  ```bash
  $ bin/kind-local-setup.sh start
  Creating cluster "kind" ...
  ✓ Ensuring node image (kindest/node:v1.16.3) 🖼
  ✓ Preparing nodes 📦
  ✓ Writing configuration 📜
  ✓ Starting control-plane 🕹️
  ✓ Installing CNI 🔌
  ✓ Installing StorageClass 💾
  ✓ Joining worker nodes 🚜
  Set kubectl context to "kind-kind"
  You can now use your cluster with:

  kubectl cluster-info --context kind-kind

  Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
  ```

## Get images
This has been moved into the tiltfie: [k8s-tilt](https://github.com/onzyone/k8s-tilt)
    
## Deploy with Helm
This has been moved into the tiltfie: [k8s-tilt](https://github.com/onzyone/k8s-tilt)

## Stop
1. Run the following to stop kind and the local registry.
    ```bash
    $ bin/kind-local-setup.sh stop
    Deleting cluster "kind" ...
    kind-registry
    ```

# Troubleshooting 

1. Note: you may update your local hosts file as well, for example by adding 127.0.0.1 registry in your laptop's /etc/hosts, so you can reference it in a consistent way by simply using registry:5000
1. check what images are in the local repo, if you do not see a list of images please run the commands in this section: [Get Images](#Get-images)
    ```bash
    $ curl localhost:5000/v2/_catalog -s | jq
    {
      "repositories": [
        "datawire/ambassador",
        "hello-app"
      ]
    }
    ```
1. Quick test (if this pod doesn't deploy, please have a look at the troubleshooting section)
    ```bash
    $ kubectl create deployment hello-server --image=registry:5000/hello-app:1.0
    $ kubectl get po -w
    NAME                            READY   STATUS    RESTARTS   AGE
    hello-server-7f9c5b8577-2n7x2   1/1     Running   0          10s
    ```
1. ingress test
    ``` bash
    $ kubectl run echo --image=registry:5000/inanimate/echo-server --port=8080
    $ kubectl expose deployment echo --type=LoadBalancer
    $ kubectl get service
    NAME                         TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)                      AGE
    echo                         LoadBalancer   10.107.67.130    172.17.255.2   8080:32105/TCP               17m
    $ curl 172.17.255.2:8080
    ```
    More reading (On Mac only)
    * [metallb + mac](https://www.thehumblelab.com/kind-and-metallb-on-mac/)
1. unknown hook
  The chart has not been updated to support helm 3 yet 
    ``` bash
    ...
    manifest_sorter.go:175: info: skipping unknown hook: "crd-install"
    ...
    ```
# Reference Documentation:

* [Helm Quickstart](https://helm.sh/docs/intro/quickstart/)
* [Kind Local-registry](https://kind.sigs.k8s.io/docs/user/local-registry/)
* [Kind With Registry](https://github.com/windmilleng/kind-local/blob/master/kind-with-registry.sh)
* [metallb](https://mauilion.dev/posts/kind-metallb/)

# Dependency

1. linux vm
1. docker installed, as well as the ability to pull images from the internet
1. [kind](https://kind.sigs.k8s.io/)
1. k8s tools (kubectl, helm 3 or greater)
