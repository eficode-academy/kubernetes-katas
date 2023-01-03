# Networking Basics

## Learning Goals

- Ability to reach a pod inside the cluster from your local machine.

## Introduction

Deploying a pod is not enough to make it accessible from outside the cluster. 

In this exercise you will learn how to make temporary connections to a pod inside the cluster via `kubectl port-forward`.

## Port-forward

The `kubectl port-forward` command allows you to forward one or more local ports to a pod. This can be used to access a pod that is running in the cluster.

The command takes two arguments: the pod name and the port to forward. The port is specified as `local:remote` to forward a local port to a remote port inside the pod.

For example, if you want to forward port 8080 on your local machine to port 5000 in the pod, you can use the following command:

`kubectl port-forward frontend 8080:5000`

You can then access the pod on `localhost:8080`.

<details>
<summary>:bulb: How does this port-forward work?</summary>

Port forwarding is a network address translation that redirects internet packets form one IP address with specified port number to another IP:PORT set.

In Kubernetes `port-forwad` creates a tunnel between your local machine and Kubernetes cluster on the specified `IP:PORT` pairs in order to establish connection to the cluster. `kubectl port-forward` allows you to forward not only pods but also services, deployments and other.   

More informatin can be found from [here](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)

</details>

## Exercise


### Overview

- Deploy the frontend pod
- Expose the frontend with port-forward.
- Look at it in the browser.


### Step by step instructions

* Go into the `networking-basics` directory and the `start` folder.
* Deploy the frontend pod 

<details>
<summary>Hint on doing that</summary>

You can use the `kubectl apply -f` command to deploy the pod. The pod is defined in the `frontend-pod.yaml` file.

</details>

* Check that the pod is running with `kubectl get pods` command.

You should see something like this:

```
NAME       READY   STATUS    RESTARTS   AGE
frontend   1/1     Running   0          2m
```

* Expose the frontend with port-forward

Port forward can be achieved with:

`kubectl port-forward --address 0.0.0.0 frontend 8080:5000` 

And can then be accessed on inst<number>.<prefix>.eficode.academy:8080 (from the internet)

> :bulb: VSCode will ask you if you what to see the open port. Unfortuneatly vscode proxy does not proxy requests correctly back to the pod, so use the url of the instance instead.

* Look at it in the browser.
If you see the frontend, you have succeeded.

### Clean up

* Stop the port-forward with `Ctrl+C` command.

* Delete the pod with `kubectl delete pod frontend` command.

Congratulations! You have now learned how to make temporary connections to a pod inside the cluster via `kubectl port-forward`.