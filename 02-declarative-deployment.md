# Declarative deployment

## Deploy an application using a declarative configuration file

Although the `kubectl create` command allows us to specify a number of flags to
configure which kind of deployment should be created, it's a bit easier to work
with if we instead specify it in a _deployment spec_-file and `create` that
instead.

To create the `nginx` from the[Pods and Deployments](01-pods-deployments.md)
exercise, you can use the provided `support-files/nginx-simple-deployment.yaml`
file.

> NB: before you execute the command shown below, note that it will try to
> create a deployment with the name **nginx**. If you already have a deployment
> named **nginx** running from a previous exercise you will need to delete that
> first. You can delete an existing deployment called `nginx` with the following
> command:
>
> ```
> kubectl delete deployment nginx
> ```
>
> Expected output:
>
> ```
> deployment "nginx" deleted
> ```
>
> Now you are ready to proceed with the example below.

To create one or more objects specified by a file, run:

```
kubectl apply -f support-files/nginx-simple-deployment.yaml
```

Expected output:

```
deployment.extensions/nginx created
```

The contents of `support-files/nginx-simple-deployment.yaml` are as follows:

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
        version: 1.7.9 # arbitrary label we can match on elsewhere
    spec:
      containers:
        - name: nginx
          image: nginx:1.7.9
          ports:
            - containerPort: 80
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

## Test Kubernetes promise of resilience by deleting a pod

> A great first mistake that many newcomers make, is to create a _deployment_,
> and when they're done, delete the pod.. and what happens then? - A new pod is
> created in its place.

Let's see this in action:

```
kubectl delete pod nginx-431080787-9r0lx
```

Expected output:

```
pod "nginx-431080787-9r0lx" deleted
```

As soon as we delete a pod, a new one is created, satisfying the desired state
by the deployment, which is - it needs at least one pod running nginx.

So rightfully we see that a **new** nginx pod is created (with a new name):

```
kubectl get pods
```

Expected output:

```
NAME                         READY     STATUS              RESTARTS   AGE
nginx-431080787-tx5m7        0/1       ContainerCreating   0          5s
```

.. and after few more seconds:

```
kubectl get pods
```

Expected output:

```
NAME                         READY     STATUS    RESTARTS   AGE
nginx-431080787-tx5m7        1/1       Running   0          12s
```

## Clean up

Delete the `nginx` deployment:

```
kubectl delete deployment nginx
```
