# Pods and Deployments

A **Pod** (*not container*) is the smallest building-block/worker-unit in Kubernetes,
  it has a specification of one or more containers and exists for the duration of the containers;
  if all the containers stop or terminate, the Pod is stopped.

  Usually a pod will be part of a **Deployment**; a more controlled or _robust_ way of running Pods.
  A deployment can be configured to automatically delete stopped or exited Pods and start new ones,
  as well as run a number of identical Pods e.g. to provide high-availability.

So let's try to use some of the Kubernetes objects, starting with a deployment.

## 1.1 Creating deployments using 'create' command

We start by creating our first deployment. Normally people will run a pod with an Nginx container as a first example.
  You can surely do that.
  But, we will start at little differently by creating a deployment with a pod that has a container with a different container image, as our first exercise.
  The reason is that this pod will work as a multitool for testing and debugging throughout this course; besides it too runs Nginx!

Here is the command to do it:

```shell
$ kubectl create deployment multitool --image=ghcr.io/eficode-academy/network-multitool
deployment.apps/multitool created
```

So what happened? The `create`-command is great for imperative testing, and getting something up and running fast.
  It creates a _[deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)_ named `multitool`, which creates a _[replicaset](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)_, which starts a _[pod](https://kubernetes.io/docs/concepts/workloads/pods/)_ using the docker image `ghcr.io/eficode-academy/network-multitool`. You don't need to concern yourself with all these details at this stage, this is just extra (however notable) information.

Just so you know what we're talking about,
  you can check the objects you've created with `get <object>`,
  either one at a time, or all-together like below:

```shell
$ kubectl get deployment,replicaset,pod    # NB: no whitespace in the comma-separated list
NAME                              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/multitool   1         1         1            1           1m

NAME                                         DESIRED   CURRENT   READY     AGE
replicaset.extensions/multitool-5c8676565d   1         1         1         1m

NAME                             READY     STATUS    RESTARTS   AGE
pod/multitool-5c8676565d-wnw2v   1/1       Running   0          1m
```

> A ReplicaSet is something which deals with the number of copies of this pod.
It will be covered in a later exercise, but it's mentioned and shown above for completeness.

## 1.1.1 Testing access to our Pod

 We are getting a little ahead of our exercises here, but to illustrate that we actually have
 a functioning web-server running in our pod, let's try exposing it to the internet and access it from a browser!

 First use the following command to create a `service` for your `deployment`:
 ```shell
 $ kubectl expose deployment multitool --port 80 --type NodePort
 service/multitool exposed
 ```

 Get the `service` called `multitool` and note down the NodePort:

```shell
 $ kubectl get service multitool
 NAME        TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
 multitool   NodePort   10.96.223.218   <none>        80:32458/TCP   12s
```

 In this example, Kubernetes has chosen port `32458`.

 Finally, look up the IP address of a node in the cluster with:

 ```shell
 $ kubectl get nodes -o wide           # The -o wide flag makes the output more verbose, i.e. to include the IPs
 NAME    STATUS   . . . INTERNAL-IP  EXTERNAL-IP     . . .
 node1   Ready    . . . 10.123.0.8   35.240.20.246   . . .
 node2   Ready    . . . 10.123.0.7   35.205.245.42   . . .
 ```

 Since your `service` is of type `NodePort` it will be exposed on _any_ of the nodes,
 on the port from before, so choose one of the `EXTERNAL-IP`'s,
 and point your web browser to the URL `<EXTERNAL-IP>:<PORT>`. Alternatively, if you
 use e.g. curl from within the training infrastructure, you should use the <INTERNAL-IP>
 address.

 The next exercise will cover what we did here in more detail.

## 1.2 Specifying the image version

Lets setup another pod, a traditional nginx deployment, with a specific version i.e. `1.7.9`.

```shell
$ kubectl create deployment nginx --image=nginx:1.7.9
deployment.apps/nginx created
```

You get another deployment and a replicaset as a result of above command; shown below, so you know what to expect:

```shell
$ kubectl get pods,deployments,replicasets
NAME                            READY     STATUS    RESTARTS   AGE
po/multitool-3148954972-k8q06   1/1       Running   0          25m
po/nginx-1480123054-xn5p8       1/1       Running   0          14s

NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/multitool   1         1         1            1           25m
deploy/nginx       1         1         1            1           14s

NAME                      DESIRED   CURRENT   READY     AGE
rs/multitool-3148954972   1         1         1         25m
rs/nginx-1480123054       1         1         1         14s
```

## 1.3 Deploying applications using declarative configuration files

Although the `kubectl create` command allows us to specify a number of flags
  to configure which kind of deployment should be created,
  it's a bit easier to work with if we instead specify it in a _deployment spec_-file
  and `create` that instead.

To create the `nginx` deployment above, you can use the provided `support-files/nginx-simple-deployment.yaml` file.

> NB: before you execute the command shown below, note that it will try to create a deployment with the name **nginx**. If you already have a deployment named **nginx** running from the previous step you will need to delete that first.
> You can delete an existing deployment called `nginx` with the following command:
> ```shell
> $ kubectl delete deployment nginx
> deployment "nginx" deleted
> ```
> Now you are ready to proceed with the example below.

To create one or more objects specified by a file, run:

```shell
$ kubectl create -f support-files/nginx-simple-deployment.yaml
deployment.extensions/nginx created
```

The contents of `support-files/nginx-simple-deployment.yaml` are as follows:

```yaml,k8s
# a comment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx          # arbitrary label on deployment
spec:
  replicas: 1
  selector:
    matchLabels:        # labels the replica selector should match
      app: nginx
  template:
    metadata:
      labels:
        app: nginx      # label for replica selector to match
        version: 1.7.9  # arbitrary label we can match on elsewhere
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

Verify that the deployment is created:

```shell
$ kubectl get deployments
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
multitool   1/1     1            1           59m
nginx       1/1     1            1           36s
```

Check if the pods are running:

```shell
$ kubectl get pods
NAME                         READY     STATUS    RESTARTS   AGE
multitool-3148954972-k8q06   1/1       Running   0          1h
nginx-431080787-9r0lx        1/1       Running   0          40s
```

## 1.4 Testing Kubernetes promise of resilience by deleting a pod

> A great first mistake that many newcomers make,
> is to create a _deployment_, and when they're done,
> delete the pod.. and what happens then? - A new pod is created in its place.

Let's see this in action:

```shell
$ kubectl delete pod nginx-431080787-9r0lx
pod "nginx-431080787-9r0lx" deleted
```

As soon as we delete a pod, a new one is created, satisfying the desired state by the deployment, which is - it needs at least one pod running nginx.

So rightfully we see that a **new** nginx pod is created (with a new name):

```shell
$ kubectl get pods
NAME                         READY     STATUS              RESTARTS   AGE
multitool-3148954972-k8q06   1/1       Running             0          1h
nginx-431080787-tx5m7        0/1       ContainerCreating   0          5s
```

.. and after few more seconds:

```shell
$ kubectl get pods
NAME                         READY     STATUS    RESTARTS   AGE
multitool-3148954972-k8q06   1/1       Running   0          1h
nginx-431080787-tx5m7        1/1       Running   0          12s
```

## Clean up

Delete the `nginx` and `multitool` deployments:

```shell
$ kubectl delete deployment nginx
$ kubectl delete deployment multitool
$ kubectl delete service multitool
```
