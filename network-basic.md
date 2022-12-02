# Networking Basics

## Learning Goals

- Ability to reach a pod inside the cluster from your local machine.

## Introduction

Deploying a pod is not enough to make it accessible from outside the cluster. In this exercise you will learn how to make temporary connections to a pod inside the cluster via `kubectl port-forward`.

## port-forward

the kubectl port-forward command allows you to forward one or more local ports to a pod. This can be used to access a pod that is running on the cluster. The command takes two arguments: the pod name and the port to forward. The port can be specified as `local:remote` to forward a local port to a remote port inside the pod.



<details>
<summary>:bulb: How does this port-forward work?</summary>

TODO: Explain how this works
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
You can use the `kubectl apply` command to deploy the pod. The pod is defined in the `frontend-pod.yaml` file.
</details>

* Check that the pod is running with `kubectl get pods` command.

You should see something like this:

```
NAME       READY   STATUS    RESTARTS   AGE
frontend   1/1     Running   0          2m
```

* Expose the frontend with port-forward

Port forward can be achieved with:


`kubectl port-forward --address 0.0.0.0 frontend-7b45d74f95-b9zzg 8080:5000` 

And can then be accessed on inst<number>.<prefix>.eficode.academy:8080 (from the internet)

:bulb: VSCode will ask you if you wnat to see the open port. Unfortuneatly vscode proxy does not proxy requests correctly back to the pod)


<details>
<summary>More Details</summary>

**take the same bullet names as above and put them in to illustrate how far the student have gone**

- all actions that you believe the student should do, should be in a bullet

> :bulb: Help can be illustrated with bulbs in order to make it easy to distinguish.

</details>

### Clean up

Delete the pod with `kubectl delete pod frontend` command.