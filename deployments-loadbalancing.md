# Deployments and load balancing

## Learning Goals

- Learn about manifest kind deployments
    - Learn about how to scale deployments
- Learn about load balancing
    - Learn about how to expose a deployment using a service type LoadBalancer

## Introduction

In this exercise you'll learn about how to deploy a pod using a deployment, and how to scale it. You'll also learn about how to expose a deployment using a service type LoadBalancer.

## Deployments

Deployments are a higher level concept than pods. They are used to manage a set of pods, and to ensure that a certain number of pods are always running. Deployments are defined in a manifest file.

A typical deployment manifest file looks like this:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: # Deployment name
spec:
    replicas: # the number of pods to run
    selector: # How to select pods belonging to this deployment. Must match the pod template's labels
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
        app: nginx
    template:
        metadata:
        labels:
            app: nginx
        spec:
        containers:
        - name: nginx
            image: nginx:latest
            ports:
            - containerPort: 80
``` 
</details>



### High Availability

Now we see how we can have **high availability** on Kubernetes. The easiest and preferred way to do this is by having multiple replicas for a deployment.

To scale a deployment, we can simply change the number of replicas in the manifest file, and then apply the changes using `kubectl apply -f <manifest-file>`.

### Service type: LoadBalancer
Similar to pods, deployments can also be exposed using services. For all practical purposes, deployments are used along with services.
We have seen how to expose a pod using a service type ClusterIP. This service type is only accessible from within the cluster. 
We have also seen how to expose a pod using a service type NodePort. This service type is accessible from the internet, but only on the port that is exposed on the worker nodes. We do not expect the users to know the IP addresses of our worker nodes.

The only thing that changes when we change the service type from NodePort to LoadBalancer is that the service type LoadBalancer will create a load balancer in the cloud provider, and will expose the service on an IP and port that is accessible from the internet.

<details>
<summary>:bulb: More Details</summary>
The type LoadBalancer is only available for use, if your k8s cluster is setup in one of the public cloud providers like GCE, AWS, etc. or if the admin of a local cluster has set it up.

TODO: mention metallb and other solutions for local clusters

</details>

```
while true; do  curl --connect-timeout 1 -m 1 -s <loadbalancerIP> ; sleep 0.5; done
```

Expected output:

```
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.36 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.1.150 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.37 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.37 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.36 <BR></p>
```

We see that when we query the LoadBalancer IP, it is giving us result/content from all four containers. None of the curl commands is timed out. Now, if we kill three out of four pods, the service should still respond, without timing out. We let the loop run in a separate terminal, and kill three pods of this deployment from another terminal.

```
kubectl delete pod customnginx-3557040084-1z489 customnginx-3557040084-3hhlt customnginx-3557040084-c6skw
```

Expected output:

```
pod "customnginx-3557040084-1z489" deleted
pod "customnginx-3557040084-3hhlt" deleted
pod "customnginx-3557040084-c6skw" deleted
```

Immediately check the other terminal for any failed curl commands or timeouts.

```
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-4w4gf - 10.244.0.19
```

Expected output:

```
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-h2dbg - 10.244.0.21
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-5xbjc - 10.244.0.22
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-h2dbg - 10.244.0.21
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-4wn9c - 10.244.0.20
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-5xbjc - 10.244.0.22
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-h2dbg - 10.244.0.21
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-5xbjc - 10.244.0.22
```

We notice that no curl command failed, and actually we have started seeing new IPs. Why is that? It is because, as soon as the pods are deleted, the deployment sees that it's desired state is four pods, and there is only one running, so it immediately starts three more to reach that desired state. And, while the pods are in process of starting, one surviving pod takes the traffic.

```
kubectl get pods
```

Expected output:

```
NAME                           READY     STATUS        RESTARTS   AGE
customnginx-3557040084-0s7l8   1/1       Running       0          15s
customnginx-3557040084-1z489   1/1       Terminating   0          16m
customnginx-3557040084-3hhlt   1/1       Terminating   0          16m
customnginx-3557040084-bvtnh   1/1       Running       0          15s
customnginx-3557040084-c6skw   1/1       Terminating   0          16m
customnginx-3557040084-fw1t3   1/1       Running       0          16m
customnginx-3557040084-xqk1n   1/1       Running       0          15s
```

This proves, Kubernetes provides us High Availability, using multiple replicas of a pod.


## Exercise

### Overview

- Turn the backend pod manifests into a deployment manifest
- Apply the backend deployment manifest
- Scale the deployment by adding a replicas key
- Turn frontend pod manifests into a deployment manifest
- Apply the frontend deployment manifest
- Add frontend service type loadbalancer
- Test service promise of high availability 

> :bulb: If you get stuck somewhere along the way, you can check the solution in the done folder.

### Step by step instructions

- Go into the deployments-loadbalancer directory and the start folder.

In the folder we have the pod manifests for the backend and frontend that have been created in the previous exercises. We also have two services, one for the backend (type ClusterIP) and one for the frontend (type NodePort).

- Deploy the frontend pod as well as the two services. Use the `kubectl apply -f` command.

- Verify that the frontend is accessible from the browser.
TODO: hint on how to get the IP

**Turn the backend pod manifests into a deployment manifest**

- Open both the backend-deployment.yaml and the backend-pod.yaml files in your editor.

- add the api-version and kind keys to the backend-deployment.yaml file. The api-version should be `apps/v1` and the kind should be `Deployment`.
- Give the deployment a name of backend under `metadata.name` key.
- Add a label of `run: backend` under `metadata.labels` key.
- The `spec.replicas` key denotes how many replicas we would like. Set it to 1 to begin with.

Before we go to the selector key, we need to add the pod template. The pod template is the same as the pod manifest we have been using.

We want to populate the deployment manifest with the information from the pod manifest. 

- Copy the `metadata` and `spec` contents of the backend-pod.yaml file into the backend-deployment.yaml file under the `spec.template` key.

<details>
<summary>:bulb: hint</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: # Deployment name
  labels: # Deployment labels
spec:
    replicas: # the number of pods to run
    selector: # How to select pods belonging to this deployment. Must match the pod template's labels
        matchLabels: # List of labels
    template: # This is the pod template, paste in the pod spec from frontend-pod.yaml
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - image: ghcr.io/eficode-academy/flask-quotes-backend:release
        name: flask-quotes-backend
```
</details>

Now we want the deployment controller to manage the pods. We need to add a selector to the deployment manifest.

- Add a selector key under the `spec` key. The selector key should have a matchLabels key. The matchLabels key should have a `run: backend` key-value pair.

<details>
<summary>:bulb: hint</summary>

the matchLabels key should look like this:

```yaml
matchLabels:
  run: backend
```
The same as the labels key in the metadata key of the pod template.

</details>

**Apply the deployment manifest**

- Apply the deployment manifest, the same way we have applied the pod manifests, just denoting a different file.

```
kubectl apply -f backend-deployment.yaml
```

Expected output:

```
deployment.apps/backend-deployment created
```

- Check that the deployment has been created.

```
kubectl get deployments
```

Expected output:

```
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
backend-deployment   1         1         1            1           1m
```

- Check that the pod has been created.

```
kubectl get pods
```

Expected output:

```
NAME                                READY     STATUS    RESTARTS   AGE
backend-deployment-5f4b8b7b4-5x7xg   1/1       Running   0          1m
```

- Access the frontend again from the browser. It should now be able to access the backend.

- If this works, please delete the `backend-pod.yaml` file, as we now have upgrated to a deployment!


**Scale the deployment by adding a replicas key**

- Scale the deployment by changing the replicas key in the deployment manifest. Set the replicas key to 3.

- Apply the deployment manifest again.

```
kubectl apply -f backend-deployment.yaml
```

Expected output:

```
deployment.apps/backend-deployment configured
```

- Check that the deployment has been scaled.

```
kubectl get deployments
```

Expected output:

```
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
backend-deployment   3         3         3            3           2m
```

- Check that the pods have been scaled.

```
kubectl get pods
```

Expected output:

```
NAME                                READY     STATUS    RESTARTS   AGE
backend-deployment-5f4b8b7b4-5x7xg   1/1       Running   0          2m
backend-deployment-5f4b8b7b4-6j6xg   1/1       Running   0          1m
backend-deployment-5f4b8b7b4-7x7xg   1/1       Running   0          1m
```

- Access the frontend again from the browser. It should now periodically change the `hostname` part of the website.

<details>
<summary>Extra</summary>
TODO: what is the relationship between the pod name and the hostname?
</details>

**Turn frontend pod manifests into a deployment manifest**

We will now do the same for the frontend, so therefore we will highlight steps in a high level.

- Open both the frontend-deployment.yaml and the frontend-pod.yaml files in your editor.
- add the api-version and kind keys to the frontend-deployment.yaml file.
- Give the deployment a name of frontend-deployment under `metadata.name` key.
- Add a label of `run: frontend` under `metadata.labels` key.
- Set `spec.replicas` to 3.
- Copy the `metadata` and `spec` contents of the frontend-pod.yaml file into the frontend-deployment.yaml file under the `spec.template` key.
- Add a selector key under the `spec` key. The selector key should have a matchLabels key. The matchLabels key should have a `run: frontend` key-value pair.

**Apply the frontend deployment manifest**

- First, delete the frontend pod.

```
kubectl delete pod frontend
```

Expected output:

```
pod "frontend" deleted
```

- Apply the frontend deployment manifest.

```
kubectl apply -f frontend-deployment.yaml
```

Expected output:

```
deployment.apps/frontend-deployment created
```

- Check that the deployment has been created.

```
kubectl get deployments
```

Expected output:

```
NAME                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
backend-deployment    3         3         3            3           3m
frontend-deployment   3         3         3            3           1m
```

- Check that the pod has been created.

```
kubectl get pods
```

Expected output:

```
NAME                                 READY     STATUS    RESTARTS   AGE
backend-deployment-5f4b8b7b4-5x7xg    1/1       Running   0          3m
backend-deployment-5f4b8b7b4-6j6xg    1/1       Running   0          2m
backend-deployment-5f4b8b7b4-7x7xg    1/1       Running   0          2m
frontend-deployment-47b45fb8b-4x7xg   1/1       Running   0          1m
frontend-deployment-47b45fb8b-4j6xg   1/1       Running   0          1m
frontend-deployment-47b45fb8b-4x7xg   1/1       Running   0          1m
```

- Access the frontend again from the browser. Note that both the frontend and backend hostname parts of the website should change periodically.

- If this works, please delete the `frontend-pod.yaml` file, as we now have upgrated to a deployment!

**Add frontend service type loadbalancer** 

- Change the frontend service type to `LoadBalancer` in the frontend-service.yaml file.

- Apply the frontend service manifest file again.

```
kubectl apply -f frontend-service.yaml
```

Expected output:

```
service/frontend-service configured
```

- Check that the service has been created.

```
kubectl get services
```

Expected output:

```
NAME       TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)          AGE
backend    ClusterIP      172.20.211.99   <none>                                                                   5000/TCP         3h13m
frontend   LoadBalancer   172.20.30.195   a99b267dc38c94ec3b0507427c1a2665-362778330.eu-west-1.elb.amazonaws.com   5000:32146/TCP   13m
```

> Note: The EXTERNAL-IP will be different for you.
> Note: It may take a few minutes for the EXTERNAL-IP to be assigned.

- Access the frontend through the EXTERNAL-IP from the browser. Rembmer to add the port to the url like: `http://a99b267dc38c94ec3b0507427c1a2665-362778330.eu-west-1.elb.amazonaws.com:5000/`

**Test service promise of high availability**

<details>
<summary>More Details</summary>

**take the same bullet names as above and put them in to illustrate how far the student have gone**

- all actions that you believe the student should do, should be in a bullet

> :bulb: Help can be illustrated with bulbs in order to make it easy to distinguish.

</details>

### Clean up
TODO: 

- Delete the frontend deployment.

```
kubectl delete -f frontend-deployment.yaml
```

Expected output:

```
deployment.apps "frontend-deployment" deleted
```
