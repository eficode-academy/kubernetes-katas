# Desired State

Desired state is one of the core concepts of Kubernetes. It is the state that you want your cluster
to be in. It is the state that you define in your Kubernetes manifests. It means that the cluster
continuously will try to fulfill your desired state, even if that will never be possible.

In this exercise, you will apply Kubernetes manifests to your cluster and learn how Kubernetes
fulfills your desired state.

## Controllers

Kubernetes controllers are the components that fulfill your desired state. The example we will
use is a deployment controller, which will attempt to ensure that the number of pods that you have
defined in your manifest are always running in the cluster.

## Learning Goals

- Applying Kubernetes manifests using `kubectl apply -f <file>`.
- Verifying the Kubernetes promise of fulfilling your desired state.

## Exercise

### Overview

- Inspect existing Kubernetes manifest for a `deployment` object.
- Apply the manifest using the `kubectl apply` command.
- Delete a pod managed by the deployment controller.
- Observe that a new pod is created in its place by the controller.

### Step-by-step instructions

<details>
<summary>
Step by step:
</summary>

## Inspect existing Kubernetes manifest for a `deployment` object

We have prepared a Kubernetes manifest for you.

You can find the manifest in the file: `desired-state/nginx-deployment.yaml`.

Below is the contents of the manifest:

```yaml
# anything after a `#` are comments!
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx # deployment resource name, pods running as a part of the deployment will share the name.
  labels:
    app: nginx # deployment resource label
spec:
  replicas: 1 # number of pods to run
  selector:
    matchLabels: # selector labels the replicaset looks for
      app: nginx
  template:
    metadata:
      labels:
        app: nginx # pod labels that must match the selector
        version: latest # arbitrary label we can match on elsewhere
    spec:
      containers:
        - name: nginx # name of the container running inside a pod, different from the pod name
          image: nginx:latest
          ports:
            - containerPort: 80 # port the container is listening on
```

## Apply the manifest using the `kubectl apply`

Use the `kubectl apply -f <file>` command to send the manifest with your desired state to Kubernetes:

```shell
kubectl apply -f desired-state/nginx-deployment.yaml
```

Expected output:

```text
deployment.apps/nginx applied
```

Verify that the deployment is created:

```shell
kubectl get deployments
```

Expected output:

```text
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
nginx       1/1     1            1           36s
```

Check if the pods are running:

```shell
kubectl get pods
```

Expected output:

```text
NAME                         READY     STATUS    RESTARTS   AGE
nginx-431080787-9r0lx        1/1       Running   0          40s
```

Kubernetes is now doing everything it can to satisfy our desired state of running our nginx web server.

Let's test that Kubernetes keeps its promise of fulfilling the desired state.

## Test Kubernetes promise of desired state by deleting a pod

Since we have asked Kubernetes to run our nginx pod using a `deployment`, the deployment controller
will keep monitoring our pods and make sure that an nginx pod keeps running.

Let's see this in action:

We will use the `kubectl delete <kind> <name>` command to delete our nginx pod.

We then expect a new pod to be created by the deployment controller in its place.

First, find the name of your pod using `kubectl get pods`, like you did above.

The name will be something like `nginx-431080787-9r0lx`. **Yours will have a different, but similar name**.

```shell
kubectl delete pod nginx-431080787-9r0lx
```

Expected output:

```text
pod "nginx-431080787-9r0lx" deleted
```

The desired state we have defined specifies that exactly one nginx pod should exist, since we have
now deleted the nginx pod, we have forced our `deployment` to drift away from the desired state, because
now there are zero nginx pods.

Therefore, Kubernetes must make a change to the state of the cluster to once again fulfill our
desired state and create a new nginx pod to replace the one we have deleted.

## Observe that a new pod is created in its place by the deployment controller

We use `kubectl get` to verify that a **new** nginx pod is created (with a different name):

```shell
kubectl get pods
```

Expected output:

```text
NAME                         READY     STATUS              RESTARTS   AGE
nginx-431080787-tx5m7        0/1       ContainerCreating   0          5s
```

And after a few more seconds:

```shell
kubectl get pods
```

Expected output:

```text
NAME                         READY     STATUS    RESTARTS   AGE
nginx-431080787-tx5m7        1/1       Running   0          12s
```

Congratulations! You have now created a deployment using a Kubernetes manifest.

You have also seen that Kubernetes keeps its promise of fulfilling your desired state by creating
a new pod in the place of the deleted pod.

</details>

### Clean up

Delete your desired state by using the `kubectl delete -f <file>` command.

```text
kubectl delete -f desired-state/nginx-deployment.yaml
```
