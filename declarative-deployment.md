# Declarative Deployment

In this exercise you will create the same nginx deployment as the `basic-deployment` exercise, but instead of creating the deployment `imperatively` you will do it `declaratively`.

## Learning Goals

- Reading Kubernetes manifest files.
- Applying Kubernetes manifests using `kubectl apply -f <file>`.
- Verifying Kubernetes promise of fullfilling your desried state.

## Introduction

Doing things `imperatively` is fine for _hacking_ on things, but most of the time we want to work with Kubernetes `declaratively`.

What we mean by imperatively, is that you are actively _creating, deleting and modifying_ resources. 
The potential problems with doing things imperatively is that we have no way of knowing what changes were made, by who, and why - which we might need to know at later point if something breaks.

Therefore we much prefer to do things `declaratively`. 
Declaratively means that we _declare what we want,_ and _not how_ Kubernetes should do it. 

This declaration is what we call our `desired state`. 

Kubernetes resources are declared in what is called `manifests` which use a markup language called `yaml` to express the desired state of resources.

## Exercise

### Overview

- Inspect existing Kubernetes manifest for a `deployment` object.
- Apply the manifest using the `kubectl apply` command.
- Delete a pod managed by the deployment controller.
- Observe that a new pod is created in it's place by the controller.

### Step by step instructions

<!-- <details> -->
<!-- <summary>More Details</summary> -->

## Inspect existing Kubernetes manifest for a `deployment` object.

We have prepared a Kubernetes manifest for you.

You can find the manifest in the file: `declarative-deployment/nginx-deployment.yaml`.

Below is the contents of the manifest:

```yaml
# a comment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx # arbitrary label on deployment
spec:
  replicas: 1
  selector:
    matchLabels: # labels the replica selector should match
      app: nginx
  template:
    metadata:
      labels:
        app: nginx # label for replica selector to match
        version: latest # arbitrary label we can match on elsewhere
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
```
## Apply the manifest using the `kubectl apply`.

Use the `kubectl apply -f <file>` command to send your manifest with your desired state to Kubernetes:

```
kubectl apply -f declartive-deployment/nginx-deployment.yaml
```

Verify that the deployment is created:

```
kubectl get deployments
```

Expected output:

```
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
nginx       1/1     1            1           36s
```

Check if the pods are running:

```
kubectl get pods
```

Expected output:

```
NAME                         READY     STATUS    RESTARTS   AGE
nginx-431080787-9r0lx        1/1       Running   0          40s
```

Kubernetes is now doing everything it can to satisfy our desired state of running our nginx webserver.

Let's test that Kubernetes actually keeps it's promise of fullfilling the desired state. 

## Test Kubernetes promise of desired state by deleting a pod

Since we have asked Kubernetes to run our nginx using a `deployment`, the deployment controller will keep monitoring our pods and make sure that a nginx pod keeps running.

Let's see this in action:

We will use the `kubectl delete <kind> <name>` command to delete our nginx pod.

We then expect a new pod to be created by the deployment controller in its place. 

First, find the name of your pod using `kubectl get pods`, like you did above.

The name will be something like `nginx-431080787-9r0lx`. __Yours will have a different, but similar name__.

```
kubectl delete pod nginx-431080787-9r0lx
```

Expected output:

```
pod "nginx-431080787-9r0lx" deleted
```

## Observe that a new pod is created in it's place by the deployment controller

As soon as we delete a pod, a new one is created, satisfying the desired state of the deployment.

So rightfully we see that a **new** nginx pod is created (with a new name):


```
kubectl get pods
```

Expected output:

```
NAME                         READY     STATUS              RESTARTS   AGE
nginx-431080787-tx5m7        0/1       ContainerCreating   0          5s
```

And after few more seconds:

```
kubectl get pods
```

Expected output:

```
NAME                         READY     STATUS    RESTARTS   AGE
nginx-431080787-tx5m7        1/1       Running   0          12s
```

<!-- </details> -->

### Clean up

Delete your desired state by using the `kubectl delete -f <file>` command.

```
kubectl delete -f declarative-deployment/nginx-depoyment.yaml
```