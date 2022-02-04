# Service Discovery and Loadbalancing

## Accessing a service

To access any service inside any given pod (e.g. nginx web service), we need to *expose* the related deployment as a *service*. We have three main ways of exposing the deployment , or in other words, we have three ways to define a *service* , which we can access in three different ways. A service is (normally) created on top of an existing deployment.

We are switching our approach from the imperative (`kubectl create`) to declarative (`kubectl apply -f`) and yaml files.

### Setup

Deploy both `nginx` and `network-multitool` deployments that is going to be used in the exercise.

#### Tasks

* Look at the two deployments in the folder `service-discovery-loadbalancing`
* Deploy the multitool `kubectl apply -f service-discovery-loadbalancing/multitool-deployment.yaml`
* Deploy Nginx `kubectl apply -f service-discovery-loadbalancing/nginx-deployment.yaml`

### Service type: ClusterIP

Services of type ClusterIP will only create a DNS entry with the name of the service, as well as an internal cluster IP that routes traffic over to the deployments hit by the `selector` part of the service.

The service type ClusterIP does not have any external IP. This means it is not accessible over internet, but we can still access it from within the cluster using its `CLUSTER-IP`.

The first thing we need is to create the service file so we can `apply` it afterwards.

#### Tasks

Expose the nginx deployment as a service of type ClusterIP:

* Create the service file with kubectl: `kubectl expose deployment nginx -o yaml --dry-run=client --type=ClusterIP --port=80 > service-discovery-loadbalancing/nginx-svc.yaml`

<details>
    <summary> :bulb: Explanaition of what that command just did</summary>

* `kubectl` kubernetes commandline
* `expose` expose a
* `deployment` type deployment
* `nginx` with the name `nginx`
* `-o yaml` formats the output to YAML format
* `--dry-run=client`  makes sure that the kubectl command will not be sent to the Kubernetes API server
* `--type=ClusterIP` creates the service of type `ClusterIP`
* `--port=80` makes the service exposed on port `80`
* `>` linux command to pipe all from standard output (what you see in the terminal) to a file
* `service-discovery-loadbalancing/nginx-svc.yaml` the name of the file

>:bulb: Using this approach of -o and dry-run is a very good way to create skeleton templates for all kubernetes objects like services/deployments/configmaps etc.

</details>

* Look at the service file you just created in `service-discovery-loadbalancing/nginx-svc.yaml`
* Apply the service `kubectl apply -f service-discovery-loadbalancing/nginx-svc.yaml`
* Check the list of services:

```shell
$ kubectl get services
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
nginx        ClusterIP   100.70.204.237   <none>        80/TCP    4s
```

We here can see both the cluster ip where the service is reachable, and on what port.

Let's see if we can access this service from within our multitool, the one from the Pods and Deployments exercise.

* Get the name of the `multitool` pod with:

```shell
$ kubectl get pods
NAME                         READY     STATUS    RESTARTS   AGE
multitool-5c8676565d-rc982   1/1       Running   0          3s
```

* Run an interactive shell inside the `network-multitool`-container in the pod with:

```shell
$ kubectl exec -it multitool-5c8676565d-rc982 -c network-multitool -- bash
bash-5.0#
```

> :bulb:
> `kubectl exec` can be used to execute a command inside a container inside a pod.
> Since the multitool-5c8676565d-rc982 pod only runs a single container, called `network-multitool`,
> we do not have to specify the container explicitly, i.e.
> ```shell
> kubectl exec -it multitool-5c8676565d-rc982 -- bash
> ```
> Would yield the same result.
> `-it` attaches our terminal interactively to the container,
> and `bash` is the command we enter the container with. The `--` separates the kubectl command from the command being run inside the container and is particularly important when the command have arguments.

* Try to `curl` the `CLUSTER-IP` of the `nginx`-service above:

```shell
bash-4.4# curl -s 100.70.204.237 | grep h1
<h1>Welcome to nginx!</h1>
```

It worked! But there's more... we can also access a service using DNS.

The DNS shortname of a service is simply its name:

```shell
bash-4.4# curl -s nginx | grep h1
<h1>Welcome to nginx!</h1>
```

> :bulb: We can use this to access services in our current namespace.
> To access a service in a different namespace, use its full DNS name:
> `<service name>.<namespace>.svc.cluster.local`

* If you're doing this exercise along others, try to `curl` their nginx-service with:

```shell
bash-4.4# curl -s nginx.<namespace>.svc.cluster.local | grep h1
<h1>Welcome to nginx!</h1>
```

* Log out of the bash in the multitool container with the `exit` command, or by pressing `ctrl+d`.

#### Describe

You can use the `describe` command to describe any Kubernetes object in more detail. e.g. we use `describe` to see more details about our nginx service:

```shell
$ kubectl describe service nginx
Name:              nginx
Namespace:         default
Labels:            app=nginx
Annotations:       <none>
Selector:          app=nginx
Type:              ClusterIP
IP:                100.70.204.237
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         100.96.1.148:80
Session Affinity:  None
Events:            <none>
```

You can of-course use `... describe pod ...` , `... describe deployment ...` , etc.

<details>
    <summary> :bulb: Additional notes about the Cluster-IP</summary>

* The IPs assigned to services as Cluster-IP are from a different Kubernetes network called *Service Network*, which is a completely different network altogether. i.e. it is not connected (nor related) to pod-network or the infrastructure network. Technically it is actually not a real network per-se; it is a labeling system, which is used by Kube-proxy on each node to setup correct iptables rules. (This is an advanced topic, and not our focus right now).
* No matter what type of service you choose while *exposing* your deployment, Cluster-IP is always assigned to that particular service.
* Every service has end-points, which point to the actual pods serving as a backends of a particular service.
* As soon as a service is created, and is assigned a Cluster-IP, an entry is made in Kubernetes' internal DNS against that service, with this service name and the Cluster-IP. e.g. `nginx.default.svc.cluster.local` would point to `100.70.204.237` .

</details>

### Service type: NodePort

A service type NodePort creates a port on the service that is reachable from the outside. Notice that we still don't have an external IP, but we now have an extra port e.g. `32593` for this service.

This port is a **NodePort** exposed on the worker nodes. So now, if we know the IP of our nodes, we can access this service from the internet.

#### Tasks

Our nginx service is still not reachable from outside, so now we re-create this service as NodePort.

* Change the type from `ClusterIP` to `NodePort` in `service-discovery-loadbalancing/nginx-svc.yaml`
* Apply the new version of the service with `kubectl apply -f service-discovery-loadbalancing/nginx-svc.yaml`
* Check that the service have changed type:

```shell
$ kubectl get svc
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx        NodePort    100.65.29.172  <none>        80:32593/TCP   8s
```

 First, we find the public IP of one of the worker nodes:

```shell
$ kubectl get nodes -o wide
NAME                                            STATUS    ROLES     AGE       VERSION        EXTERNAL-IP     OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-dcn-cluster-35-default-pool-dacbcf6d-3918   Ready     <none>    17h       v1.8.8-gke.0   35.205.22.139   Container-Optimized OS from Google   4.4.111+         docker://17.3.2
gke-dcn-cluster-35-default-pool-dacbcf6d-c87z   Ready     <none>    17h       v1.8.8-gke.0   35.187.90.36    Container-Optimized OS from Google   4.4.111+         docker://17.3.2
```

Even though we have only one pod (and two worker nodes), we can access any of the nodes with this port, and it will eventually be routed to our pod.

* try to access it through curl:

```shell
$ curl -s 35.205.22.139:32593 | grep h1
<h1>Welcome to nginx!</h1>
```

It works!

* Check multiple of the node external IP's to see that it does not matter which of them is hit.

### Service type: LoadBalancer

So far so good; but, we do not expect the users to know the IP addresses of our worker nodes.

It is not a flexible way of doing things.

So we re-create the service as type `LoadBalancer`. The type LoadBalancer is only available for use, if your k8s cluster is setup in any of the public cloud providers, GCE, AWS, etc or that the admin of a local cluster have set it up.

#### Tasks

* Change the type from `NodePort` to `LoadBalancer` in `service-discovery-loadbalancing/nginx-svc.yaml`
* Apply the new version of the service with `kubectl apply -f service-discovery-loadbalancing/nginx-svc.yaml`
* Check that the service have changed type:

```shell
$ kubectl get svc
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx        LoadBalancer   100.69.15.89   <pending>     80:31354/TCP   5s
```

In few minutes of time the external IP will have some value instead of the word 'pending' .

```shell
$ kubectl get svc
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx        LoadBalancer   100.69.15.89   35.205.60.29  80:31354/TCP   5s
```

Now, we can access this service without using any special port numbers:

* try to curl the external ip of the loadbalancer:

```shell
$ curl -s 35.205.60.29 | grep h1
<h1>Welcome to nginx!</h1>
```

* Even if the type is of `LoadBalancer` can you still reach the site as you did with the type `NodePort`?

<details>
    <summary> :bulb: Additional notes about Load Balancer</summary>

> A service defined as LoadBalancer will still have some high-range port number assigned to it's main service port, just like NodePort. This has a clever purpose, but is an advance topic and is not our focus at this point.

</details>

# High Availability

So far we have seen pods, deployments and services. We have also seen Kubernetes keeping up it's promise of resilience. Now we see how we can have **high availability** on Kubernetes. The easiest and preferred way to do this is by having multiple replicas for a deployment.

Let's increase the number of replicas of our nginx deployment to four(4):

* Change the `replicas` from 1 to 4 in `service-discovery-loadbalancing/nginx-deployment.yaml`
* Apply the new version of the deployment with `kubectl apply -f service-discovery-loadbalancing/nginx-deployment.yaml`
* Check the deployment and pods:

```shell
$ kubectl get deployments
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
multitool   1/1     1            1           24m
nginx       4/4     4            4           34m
```

```shell
$ kubectl get pods
NAME                         READY     STATUS    RESTARTS   AGE
multitool-3148954972-k8q06   1/1       Running   0          24m
nginx-569477d6d8-4msf8       1/1       Running   0          20m
nginx-569477d6d8-bv77k       1/1       Running   0          34s
nginx-569477d6d8-s6lsn       1/1       Running   0          34s
nginx-569477d6d8-v8srx       1/1       Running   0          35s
```

> :bulb: The nginx deployment says Ready=4/4, Up-to-date=4, Available=4. And the pods also show the same. There are now 4 nginx pods running; one of them was already running (being older), and the other three are started just now.

You can also scale down! - e.g. to 2:

* Try to adjust the number of replicas to 2 and apply as before.
* Quickly thereafter, run `kubectl get pods`:

```shell
$ kubectl get pods
NAME                         READY     STATUS        RESTARTS   AGE
multitool-3148954972-k8q06   1/1       Running       0          25m
nginx-569477d6d8-4msf8       1/1       Running       0          21m
nginx-569477d6d8-bv77k       0/1       Terminating   0          1m
nginx-569477d6d8-s6lsn       0/1       Terminating   0          1m
nginx-569477d6d8-v8srx       1/1       Running       0          2m
```

Notice that unnecessary pods are killed immediately.

```shell
$ kubectl get pods
NAME                         READY     STATUS    RESTARTS   AGE
multitool-3148954972-k8q06   1/1       Running   0          26m
nginx-569477d6d8-4msf8       1/1       Running   0          22m
nginx-569477d6d8-v8srx       1/1       Running   0          2m
```

You can delete the deployments and service at this point. We have no use for these anymore. Besides, you can always re-create them, as they are described _as code_.

```shell
$ kubectl delete -f service-discovery-loadbalancing/
deployment.apps "multitool" deleted
deployment.apps "nginx" deleted
service "nginx" deleted
```

## Extra-credit: High Availability Exercise

To prove that multiple pods of the same deployment provide high availability, we do a small exercise. To visualize it, we need to run a small web server which could return us some unique content when we access it.

We will use our multitool image for it. Let's run it as a separate deployment and access it.

* Look at the deployment and service in `service-discovery-loadbalancing/extra/`
* Apply them to the cluster `kubectl apply -f service-discovery-loadbalancing/extra/`
* Observe that the pods are running:

```shell
$ kubectl get pods
NAME                           READY     STATUS    RESTARTS   AGE
customnginx-3557040084-1z489   1/1       Running   0          49s
customnginx-3557040084-3hhlt   1/1       Running   0          49s
customnginx-3557040084-c6skw   1/1       Running   0          49s
customnginx-3557040084-fw1t3   1/1       Running   0          49s
```

* Verify the service and note the public IP address:

```shell
$ kubectl get services
NAME          TYPE           CLUSTER-IP    EXTERNAL-IP        PORT(S)        AGE
customnginx   LoadBalancer   100.67.40.4   35.205.60.41       80:30087/TCP   1m
```

Query the service, so we know it works as expected:

```shell
$ curl -s 35.205.60.41
Eficode Academy Network MultiTool (with NGINX) - customnginx-7cf9899b84-rjgrb - 10.8.2.47/24
```

Next, setup a small bash loop on your local computer to curl this IP address, and get it's IP address.

```shell
$ while true; do  curl --connect-timeout 1 -m 1 -s <loadbalancerIP> ; sleep 0.5; done
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.36 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.1.150 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.37 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.37 <BR></p>
Eficode Academy Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.36 <BR></p>
^C
```

We see that when we query the LoadBalancer IP, it is giving us result/content from all four containers. None of the curl commands is timed out. Now, if we kill three out of four pods, the service should still respond, without timing out. We let the loop run in a separate terminal, and kill three pods of this deployment from another terminal.

```shell
$ kubectl delete pod customnginx-3557040084-1z489 customnginx-3557040084-3hhlt customnginx-3557040084-c6skw
pod "customnginx-3557040084-1z489" deleted
pod "customnginx-3557040084-3hhlt" deleted
pod "customnginx-3557040084-c6skw" deleted
```

Immediately check the other terminal for any failed curl commands or timeouts.

```shell
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-4w4gf - 10.244.0.19
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-h2dbg - 10.244.0.21
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-5xbjc - 10.244.0.22
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-h2dbg - 10.244.0.21
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-4wn9c - 10.244.0.20
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-5xbjc - 10.244.0.22
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-h2dbg - 10.244.0.21
Eficode Academy Network MultiTool (with NGINX) - customnginx-59db6cff7b-5xbjc - 10.244.0.22
```

We notice that no curl command failed, and actually we have started seeing new IPs. Why is that? It is because, as soon as the pods are deleted, the deployment sees that it's desired state is four pods, and there is only one running, so it immediately starts three more to reach that desired state. And, while the pods are in process of starting, one surviving pod takes the traffic.

```shell
$ kubectl get pods
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

## Clean up

Delete deployments and services as follows:

* `kubectl delete -f service-discovery-loadbalancing/extra`
