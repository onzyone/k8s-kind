# Overview

This is just a quick way to setup kind and a local repo

```bash
    ➜  bin ./kind-local-setup.sh
    usage: ./kind-local-setup.sh start|stop|getimage
```

# Table of contents
=================
<!--ts-->
   * [Overview](#Overview)
   * [Table of contents](#table-of-contents)
   * [Usage](#usage)
      * [Start](#Start)
      * [Deploy with Helm](#Deploy-with-Helm)
      * [Stop](#Stop)
   * [Troubleshooting](#Troubleshooting)
   * [Reference Documentation](#Reference-Documentation)
   * [Dependency](#dependency)
<!--te-->
=================

# Usage
## Start
1. In the bin dir of this repo you will find the start / stop script
1. `./kind-local-setup.sh start`
    ```bash
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
1. Quick test (if this pod doesn't deploy, please have a look at the troubleshooting section)
    ```bash
    $ kubectl create deployment hello-server --image=registry:5000/hello-app:1.0

    $ k get po -w
    NAME                            READY   STATUS    RESTARTS   AGE
    hello-server-7f9c5b8577-2n7x2   1/1     Running   0          10s
    ```

## Deploy with Helm
1. If this is the first time that you have used helm, please have a look at the quick start below. TL/DR `helm repo add stable https://kubernetes-charts.storage.googleapis.com/`
1. In the k8s folder you will find some helm chart values-local.yaml files ... these have been modified to use the new local repo that you just created. (note: inside the cluster the localhost repo on your laptop is pointing to registry)
    ```bash
    $ ambassador pwd
    <root>/kind/k8s/ambassador
    ➜  ambassador ls -lrat
    total 12
    drwxrwxrwx 1 vagrant vagrant     0 Dec 13 15:50 ..
    drwxrwxrwx 1 vagrant vagrant     0 Dec 13 15:50 .
    -rwxrwxrwx 1 vagrant vagrant 10271 Dec 13 15:54 values-local.yaml
    ```
    ie:
    ```yaml
    image:
      repository: registry:5000/datawire/ambassador
      tag: 0.86.1
      pullPolicy: IfNotPresent
    ```
1. As this is a local k8s install, is no way of requesting a loadbalancer from the cloud vender. In comes metallb
    ```bash
    helm upgrade --install --wait kind-test-metallb -f k8s/metallb/values-local.yaml stable/metallb
    ```
1. Apply the melallb configMap (ensure that you docker subnet is default `"172.17.0.0/16"`. Run this:  `docker network inspect bridge | jq '.[].IPAM'`). If it is different you have to update the `km-config.yaml` file
    ```
    kubectl apply -f k8s/metallb/km-config.yaml
    ```
1. Install ambassador with helm
    ```bash
    helm upgrade --install --wait kind-test-ambassador -f k8s/ambassador/values-local.yaml stable/ambassador
    Release "kind-test-ambassador" does not exist. Installing it now.
    NAME: kind-test-ambassador
    LAST DEPLOYED: Mon Dec 16 17:26:16 2019
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    NOTES:
    Congratulations! You've successfully installed Ambassador.

    For help, visit our Slack at https://d6e.co/slack or view the documentation online at https://www.getambassador.io.

    To get the IP address of Ambassador, run the following commands:
    NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc -w  --namespace default kind-test-ambassador'

    On GKE/Azure:
    export SERVICE_IP=$(kubectl get svc --namespace default kind-test-ambassador -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

    On AWS:
    export SERVICE_IP=$(kubectl get svc --namespace default kind-test-ambassador -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

    echo http://$SERVICE_IP:
    ```
1. Check helm deployment
    ```bash
    $ helm ls
    NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
    kind-test-ambassador    default         1               2019-12-16 17:26:16.004571157 +0000 UTC deployed        ambassador-5.2.1        0.86.1
    ```
1.  Get the external IP for ambassador
    ```bash
    kubectl get service
    NAME                         TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)                      AGE
    kind-test-ambassador         LoadBalancer   10.97.146.231    172.17.255.1   80:32764/TCP,443:30260/TCP   89s
    ```
1. Deploy ambassador test
    ```bash
    $ kubectl apply -f k8s/ambassador/example/tour.yaml
    $ curl 172.17.255.1:80/tour
    <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="shortcut icon" href="/favicon.ico"/><link rel="manifest" href="/manifest.json"/><title>Ambassador Tour</title><link href="/static/css/2.81a10015.chunk.css" rel="stylesheet"><link href="/static/css/main.4f47a8aa.chunk.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div><script>!function(l){function e(e){for(var r,t,n=e[0],o=e[1],u=e[2],f=0,i=[];f<n.length;f++)t=n[f],p[t]&&i.push(p[t][0]),p[t]=0;for(r in o)Object.prototype.hasOwnProperty.call(o,r)&&(l[r]=o[r]);for(s&&s(e);i.length;)i.shift()();return c.push.apply(c,u||[]),a()}function a(){for(var e,r=0;r<c.length;r++){for(var t=c[r],n=!0,o=1;o<t.length;o++){var u=t[o];0!==p[u]&&(n=!1)}n&&(c.splice(r--,1),e=f(f.s=t[0]))}return e}var t={},p={1:0},c=[];function f(e){if(t[e])return t[e].exports;var r=t[e]={i:e,l:!1,exports:{}};return l[e].call(r.exports,r,r.exports,f),r.l=!0,r.exports}f.m=l,f.c=t,f.d=function(e,r,t){f.o(e,r)||Object.defineProperty(e,r,{enumerable:!0,get:t})},f.r=function(e){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},f.t=function(r,e){if(1&e&&(r=f(r)),8&e)return r;if(4&e&&"object"==typeof r&&r&&r.__esModule)return r;var t=Object.create(null);if(f.r(t),Object.defineProperty(t,"default",{enumerable:!0,value:r}),2&e&&"string"!=typeof r)for(var n in r)f.d(t,n,function(e){return r[e]}.bind(null,n));return t},f.n=function(e){var r=e&&e.__esModule?function(){return e.default}:function(){return e};return f.d(r,"a",r),r},f.o=function(e,r){return Object.prototype.hasOwnProperty.call(e,r)},f.p="/";var r=window.webpackJsonp=window.webpackJsonp||[],n=r.push.bind(r);r.push=e,r=r.slice();for(var o=0;o<r.length;o++)e(r[o]);var s=n;a()}([])</script><script src="/static/js/2.9d622537.chunk.js"></script><script src="/static/js/main.202b1a10.chunk.js"></script></body></html>
    ``` 

## Stop
1. `./kind-local-setup.sh stop`
    ```bash
    Deleting cluster "kind" ...
    kind-registry
    ```

# Troubleshooting 

1. Note: you may update your local hosts file as well, for example by adding 127.0.0.1 registry in your laptop's /etc/hosts, so you can reference it in a consistent way by simply using registry:5000
1. check what images are in the local repo
    ```bash
    ➜  bin curl localhost:5000/v2/_catalog -s | jq
    {
    "repositories": [
        "datawire/ambassador",
        "hello-app",
        "kuar-demo/kuard-amd64",
        "projectcontour/contour"
    ]
    }
    ```
1. unknown hook
    The chart has not been updated to support helm3 
    ``` bash
    manifest_sorter.go:175: info: skipping unknown hook: "crd-install"
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

# Reference Documentation:

* [Helm Quickstart](https://helm.sh/docs/intro/quickstart/)
* [Kind Local-registry](https://kind.sigs.k8s.io/docs/user/local-registry/)
* [metallb](https://mauilion.dev/posts/kind-metallb/)


# Dependency

1. linux vm
1. docker installed, as well as the ability to pull images from the internet
1. [kind](https://kind.sigs.k8s.io/)
1. k8s tools (kubectl, helm)