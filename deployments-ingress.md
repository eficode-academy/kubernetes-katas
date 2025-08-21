# Deployments and Loadbalancing

## Learning Goals

- Learn how to expose a deployment using Ingress
- Learn how to use `deployments`
- Learn how to scale deployments
- Learn how to use `services` to do load balancing between the pods of a scaled deployment

## Introduction

In this exercise, you'll learn how to deploy a pod using a deployment, how to
scale it, and how to expose it using an `Ingress` resource with URL routing.

## Deployments

Deployments are a higher-level abstraction than pods, and control the lifecycle
and configuration of a "deployment" of an application. They are used to manage a
set of pods, and to ensure that a specified number of pods are always running
with the desired configuration. `deployments` are a Kubernetes `kind` and
defined in a manifest file.

A `deployment` manifest file looks like this:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: # Deployment name
spec:
  replicas: # the number of pods to run
  selector: # How to select pods belonging to this deployment, must match the pod template's labels
    matchLabels: # List of labels to match pods
  template: # Pod template
    metadata:
    labels: # List of labels
    spec:
    containers: # List of containers belonging to the pod
      - name: # Name of the container
          image: # Container image
```

<details>
<summary>:bulb: An Example: Nginx deployment</summary>

An example of a deployment manifest file for nginx would look like this:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      run: nginx
  template:
    metadata:
    labels:
      run: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
```

</details>

### High Availability

To make our application stable, we want **high availability**. High availability means that
we replicate our applications, such that we have **redundant copies**, which means that _when_ an
application fails, our users are not impacted, as they will simply use one of the other copies,
while the failed instance recovers.

In Kubernetes, this is done in practice by `scaling` a deployment, e.g., by adding or removing
`replicas`. `replicas` are **identical** copies of the **same pod**.

To scale a deployment, we change the number of `replicas` in the manifest file, and then apply the
changes using `kubectl apply -f <manifest-file>`.

## Ingress

Ingress in Kubernetes that manages external access to the services in a cluster, typically HTTP and
HTTPS.

Ingress can provide load balancing, SSL termination, and name-based virtual routing.

Ingress builds on top of the `service` concept, and is implemented by an `ingress controller`.

An example Ingress manifest to be used in AWS looks like this:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    # Annotations are used to configure the ingress controller behavior.
    alb.ingress.kubernetes.io/scheme: internet-facing
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
  name: quotes-ingress
spec:
  # Rules are used to configure the routing behavior.
  rules:
    # Each rule has a host and a list of paths. The host is used to match the
    # host header of the request, normally the domain name.
    - host: quotes-1.prosa.eficode.academy
      http:
        paths:
          - pathType: Prefix
            path: "/"
            # Each path has a backend, which is used to route the request to a service.
            backend:
              service:
                # This is the name of the service to route to.
                name: quotes-frontend
                port:
                  number: 80
```

When you apply this manifest, an A-record will be created in Route53, pointing to our
ingress-controller called ALB, and the ALB will route traffic to the service.

## Exercise

### Overview

- Add frontend Ingress and let it reconcile
- Turn the backend pod manifests into a deployment manifest
- Apply the backend deployment manifest
- Scale the deployment by adding a replicas key
- Turn frontend pod manifests into a deployment manifest
- Apply the frontend deployment manifest
- Test the service promise of high availability

> :bulb: If you get stuck somewhere along the way, you can check the solution in the **done** directory.

### Step-by-step instructions

<details>
<summary>
Step by step:
</summary>

- Go into the `deployments-ingress/start` directory.

In the directory, we have the pod manifests for the backend and frontend that were created in the
previous exercises. We also have two services, one for the backend (type ClusterIP) and one for the
frontend (type NodePort), as well as an ingress manifest for the frontend.

#### Add Ingress to frontend service

As it might take a while for the ingress to work, we will start by adding the ingress to the
frontend service, even though we have not applied the service yet.

- Open the `frontend-ingress.yaml` file in your editor.
- Change the hostname to `quotes-<yourname>.<prefix>.eficode.academy`. Just as long as it is unique.
  - the prefix normally is what is after your workstation-X.`<prefix>`.eficode.academy. If you are
    unsure, ask the trainer.
- Change the service name to match the name of the frontend service.
- Apply the ingress manifest.

```shell
kubectl apply -f frontend-ingress.yaml
```

Expected output:

```text
ingress.networking.k8s.io/frontend-ingress created
```

- Check that the ingress has been created.

```shell
kubectl get ingress
```

Expected output:

```text
NAME              HOSTS                                   ADDRESS   PORTS   AGE
frontend-ingress   quotes-<yourname>.<prefix>.eficode.academy             80      1m
```

Congratulations, you have now added an ingress to the frontend service.
It will take a while for the ingress to work, so we will continue with the backend deployment.

#### Deploy the quotes application

To show how Deployments take the place of Pod manifests, we will first deploy the quotes application,
and then slowly replace the Pods with Deployments.

- Deploy the following using the `kubectl apply -f` command
  - `frontend-pod.yaml`
  - `frontend-svc.yaml`
  - `backend-pod.yaml`
  - `backend-svc.yaml`

- Verify that the frontend is accessible from the browser.

<details>

<summary>
How do I connect to a pod through a NodePort service?
</summary>

> :bulb: In previous exercises, you learned how to connect to a pod exposed through a NodePort service,
> you need to find the nodePort using `kubectl get service` and the IP address of one of the nodes
> using `kubectl get nodes -o wide`
> Then combine the node IP address and nodePort with a colon between them, in a browser or using curl:

```text
http://<node-ip>:<nodePort>
```

</details>

#### Turn the backend pod manifests into a deployment manifest

Now we'll replace the Pod manifest with a Deployment manifest. In addition to the regular
manifest fields, we need to set a couple of extra things:

1. A Pod `template`. This is almost a copy of most of the Pod manifest. This defines the Pods
   that will be created by the deployment.
2. A `selectorLabel`. This is used to determine which pods will be managed by the ReplicaSet.
3. A number of `replicas`. This specifies how many simultaneous identical copies we want of the Pod

To do this, open both the `backend-deployment.yaml` and the `backend-pod.yaml` files in your editor,
and make the following changes to `backend-deployment.yaml`:

- Set `metadata.name` to `backend`
- Add the label `run: backend` under the `metadata.labels` key
- Set `spec.replicas` to `1`

Now we need to set the `selectorLabel`

- Add a `selector` key under the `spec` key
- Add a `matchLabels` key under the `selector` key
- Look up the `metadata.label` section in `backend-pod.yaml`
  and the labels defined there under `matchLabels`

<details>
<summary>
:bulb: Hint
</summary>

The `matchLabels` key should look like this:

```yaml
...
spec:
  replicas: 1
  selector:
    matchLabels:
      run: backend
  template:
  ...
```

</details>

Finally, we'll add the Pod `template`. We will take this information from the Pod manifest.

- Copy the `metadata.labels` and `spec` contents of the `backend-pod.yaml` file into the
  `backend-deployment.yaml` file under the `spec.template` key
- Make sure the copied section is properly indented by two spaces more than `spec.template`
- _Delete_ the `spec.template.metadata.name` key. The Pods will be named automatically by the `ReplicaSet`

<details>
<summary>
:bulb: Hint (solution)
</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    run: backend
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      run: backend
  template:
    metadata:
      labels:
        run: backend
    spec:
      containers:
        - image: ghcr.io/eficode-academy/quotes-flask-backend:release
          name: quotes-flask-backend
```

</details>

#### Apply the deployment manifest

Now, it is time to replace the `backend` Pod with the `backend
Deployment. We've already deployed the Pod, so let us remove it again before applying the Deployment

- Delete the `backend` pod
  
  ```shell
  kubectl delete -f backend-pod.yaml
  ```

- Apply the deployment manifest

  ```shell
  kubectl apply -f backend-deployment.yaml
  ```

  Expected output:

  ```text
  deployment.apps/backend-deployment created
  ```

- Check that the deployment has been created.

  ```shell
  kubectl get deployments
  ```

  Expected output:

  ```text
  NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
  backend   1         1         1            1           1m
  ```

- Check that the pod has been created.

  ```shell
  kubectl get pods
  ```

  Expected output:

  ```text
  NAME                      READY     STATUS    RESTARTS   AGE
  backend-5f4b8b7b4-5x7xg   1/1       Running   0          1m
  ```

- Access the frontend again from the browser.

  Now the Ingress should work, and you should be able to access the frontend from the browser using
  the hostname you specified in the ingress manifest.

  The URL should look something like this:

  ```text
  http://quotes-<yourname>.<prefix>.eficode.academy
  ```

- If it still does not work, you can check it through the NodePort service instead.

- You should now see the backend.

- If this works, please delete the `backend-pod.yaml` file, as we have now upgraded to a deployment
  and no longer need it!

#### Scale the deployment by adding a replicas key

- Scale the deployment by changing the replicas key in the deployment manifest.
  Set the replicas key to 3.

- Apply the deployment manifest again.

```shell
kubectl apply -f backend-deployment.yaml
```

Expected output:

```text
deployment.apps/backend-deployment configured
```

- Check that the deployment has been scaled.

```shell
kubectl get deployments
```

Expected output:

```text
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
backend   3/3     3            3           3m29s
```

- Check that the pods have been scaled.

```shell
kubectl get pods
```

Expected output:

```text
NAME                      READY     STATUS    RESTARTS   AGE
backend-5f4b8b7b4-5x7xg   1/1       Running   0          2m
backend-5f4b8b7b4-6j6xg   1/1       Running   0          1m
backend-5f4b8b7b4-7x7xg   1/1       Running   0          1m
```

- Access the frontend again from the browser. It should now periodically change the `hostname` part
  of the website.

<!-- <details> -->
<!-- <summary>Extra</summary> -->
<!-- TODO: explain relationship between pod name and deployment name -->
<!-- </details> -->

#### Turn frontend pod manifests into a deployment manifest

You will now do the same thing for the frontend. We will walk you through it again, but at a
higher level. If you get stuck, you can go back and double-check how you did it for the backend.

- Open both the `frontend-deployment.yaml` and the `frontend-pod.yaml` files in your editor.
- Add the api-version and kind keys to the `frontend-deployment.yaml` file.
- Give the deployment a name of `frontend` under the `metadata.name` key.
- Add a label of `run: frontend` under `metadata.labels` key.
- Set `spec.replicas` to `3`.
- Copy the `metadata` and `spec` contents of the `frontend-pod.yaml` file into the
  `frontend-deployment.yaml` file under the `spec.template` key.
- Add a selector key under the `spec` key.
  - The selector key should have a `matchLabels` key.
  - The `matchLabels` key should have a `run: frontend` key-value pair.

#### Apply the frontend deployment manifest

- First, delete the frontend pod.

```shell
kubectl delete pod frontend
```

Expected output:

```text
pod "frontend" deleted
```

- Apply the frontend deployment manifest.

```shell
kubectl apply -f frontend-deployment.yaml
```

Expected output:

```text
deployment.apps/frontend-deployment created
```

- Check that the deployment has been created.

```shell
kubectl get deployments
```

Expected output:

```text
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
backend    3/3     3            3           2m41s
frontend   3/3     3            3           2m41s
```

- Check that the pod has been created.

```shell
kubectl get pods
```

Expected output:

```text
NAME                       READY     STATUS    RESTARTS   AGE
backend-5f4b8b7b4-5x7xg    1/1       Running   0          3m
backend-5f4b8b7b4-6j6xg    1/1       Running   0          2m
backend-5f4b8b7b4-7x7xg    1/1       Running   0          2m
frontend-47b45fb8b-4x7xg   1/1       Running   0          1m
frontend-47b45fb8b-4j6xg   1/1       Running   0          1m
frontend-47b45fb8b-4x7xg   1/1       Running   0          1m
```

- Access the frontend again from the browser.
  Note that both the frontend and backend hostname parts of the website should change periodically.

- If this works, please delete the `frontend-pod.yaml` file, as we have now upgraded to a deployment
  and no longer need it!

</details>

### Clean up

- Delete the deployments.

```shell
kubectl delete -f frontend-deployment.yaml
kubectl delete -f backend-deployment.yaml
```

- Delete the services

```shell
kubectl delete -f frontend-svc.yaml
kubectl delete -f backend-svc.yaml
```

- Delete the ingress

```shell
kubectl delete -f frontend-ingress.yaml
```

> :bulb: If you ever want to delete all resources from a particular directory, you can use:
> `kubectl delete -f .` which will point at **all** files in that directory!

## Extra Exercise

Test the Kubernetes promise of resiliency and high availability

<details>
<summary>
An example of using a LoadBalancer service to route traffic to replicated pods
</summary>

We can use the `ghcr.io/eficode-academy/network-multitool` image to illustrate both high
availability and load balancing of `services`. The `network-multitool` pod will serve a tiny
webpage that dynamically contains the pod hostname and IP address of the pod. This enables us to see
which of a group of network-multitool pods served the request.

Create the network-multitool deployment:

```shell
kubectl create deployment customnginx --image ghcr.io/eficode-academy/network-multitool --port 80 --replicas 4
```

We create the network-multitool deployment with the name "customnginx" and with four replicas, so we
expect to have four pods.

We also create a service of type `LoadBalancer`:

```shell
kubectl expose deployment customnginx --port 80 --type LoadBalancer
```

> :bulb: It might take a minute to provision the LoadBalancer. If you are using AWS, then
> `kubectl get services` will show you the DNS name of the provisioned LoadBalancer immediately, but
> it will be a moment before it is ready.

When the LoadBalancer is ready, we set up a loop to keep sending requests to the pods:

```shell
while true; do  curl --connect-timeout 1 -m 1 -s <loadbalancerIP> ; sleep 0.5; done
```

Expected output:

```text
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.36 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.1.150 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.37 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.37 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.36 <BR></p>
```

We see that when we query the LoadBalancer IP, it is giving us results/content from all four pods.
None of the curl commands times out.
Now, if we kill three out of four pods, the service should still respond, without timing out.
We let the loop run in a separate terminal, and kill three pods of this deployment from another terminal.

```shell
kubectl delete pod customnginx-3557040084-1z489 customnginx-3557040084-3hhlt customnginx-3557040084-c6skw
```

Expected output:

```text
pod "customnginx-3557040084-1z489" deleted
pod "customnginx-3557040084-3hhlt" deleted
pod "customnginx-3557040084-c6skw" deleted
```

Immediately check the other terminal for any failed curl commands or timeouts.

```text
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-4w4gf - 10.244.0.19
```

Expected output:

```text
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-h2dbg - 10.244.0.21
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-5xbjc - 10.244.0.22
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-h2dbg - 10.244.0.21
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-4wn9c - 10.244.0.20
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-5xbjc - 10.244.0.22
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-h2dbg - 10.244.0.21
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-5xbjc - 10.244.0.22
```

We notice that no curl commands failed, and actually, we have started seeing new IPs.

Why is that? It is because, as soon as the pods are deleted, the deployment sees that its desired
state is four pods, and there is only one running, so it immediately starts three more to reach the
desired state of four pods. And, while the pods are in the process of starting, one surviving pod serves
all of the traffic, preventing our application from missing any requests.

```shell
kubectl get pods
```

Expected output:

```text
NAME                           READY     STATUS        RESTARTS   AGE
customnginx-3557040084-0s7l8   1/1       Running       0          15s
customnginx-3557040084-1z489   1/1       Terminating   0          16m
customnginx-3557040084-3hhlt   1/1       Terminating   0          16m
customnginx-3557040084-bvtnh   1/1       Running       0          15s
customnginx-3557040084-c6skw   1/1       Terminating   0          16m
customnginx-3557040084-fw1t3   1/1       Running       0          16m
customnginx-3557040084-xqk1n   1/1       Running       0          15s
```

This proves, Kubernetes enables high availability by using multiple replicas of a pod, and
load-balancing between them.

Remember to clean up the deployment afterwards with:

```shell
kubectl delete deployment customnginx
```

And delete the LoadBalancer service:

```shell
kubectl delete service customnginx
```

</details>
