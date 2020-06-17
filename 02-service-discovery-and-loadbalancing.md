# Service Discovery and Loadbalancing

## Accessing a service

To access any service inside any given pod (e.g. nginx web service), we need to *expose* the related deployment as a *service*. We have three main ways of exposing the deployment , or in other words, we have three ways to define a *service* , which we can access in three different ways. A service is (normally) created on top of an existing deployment.

> NB: this exercise assumes you have the nginx and multitool deployments from exercise 1 running. If not, you can start them with
> ```shell
> $ kubectl create deployment multitool --image=praqma/network-multitool
> deployment.apps/multitool created
> $ kubectl create deployment nginx --image=nginx:1.7.9
> deployment.apps/nginx created
> ```

### Service type: ClusterIP

Expose the deployment as a service - type=ClusterIP:

```shell
$ kubectl expose deployment nginx --port 80 --type ClusterIP
service/nginx exposed
```

Check the list of services:

```shell
$ kubectl get services
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
nginx        ClusterIP   100.70.204.237   <none>        80/TCP    4s
```


The service in focus is nginx, which does not have any external IP, nor does it say anything about any other ports except 80/TCP. This means it is not accessible over internet, but we can still access it from within the cluster using its `CLUSTER-IP`. Let's see if we can access this service from within our multitool, the one from the Pods and Deployments exercise.

Get the name of the `multitool` pod with:

```shell
$ kubectl get pods
NAME                         READY     STATUS    RESTARTS   AGE
multitool-5c8676565d-rc982   1/1       Running   0          3s
```

Run an interactive shell inside the `network-multitool`-container in the pod with:

```shell
$ kubectl exec -it multitool-5c8676565d-rc982 -c network-multitool -- bash
bash-5.0#
```

> `kubectl exec` can be used to execute a command inside a container inside a pod.
> Since the multitool-5c8676565d-rc982 pod only runs a single container, called `network-multitool`,
> we do not have to specify the container explicitly, i.e.
> ```shell
> kubectl exec -it multitool-5c8676565d-rc982 -- bash
> ```
> Would yield the same result.
> `-it` attaches our terminal interactively to the container,
> and `bash` is the command we enter the container with. The `--` separates the kubectl command from the command being run inside the container and is particularly important when the command have arguments.

Try to `curl` the `CLUSTER-IP` of the `nginx`-service above:

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

We can use this to access services in our current namespace.
    To access a service in a different namespace, use its full DNS name:
    `<service name>.<namespace>.svc.cluster.local`:

If you're doing this exercise along others, try to `curl` their nginx-service with:

```shell
bash-4.4# curl -s nginx.<namespace>.svc.cluster.local | grep h1
<h1>Welcome to nginx!</h1>
```

Log out of the bash in the multitool container with the `exit` command,
    or by pressing `ctrl+d`.

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

#### Additional notes about the Cluster-IP

* The IPs assigned to services as Cluster-IP are from a different Kubernetes network called *Service Network*, which is a completely different network altogether. i.e. it is not connected (nor related) to pod-network or the infrastructure network. Technically it is actually not a real network per-se; it is a labeling system, which is used by Kube-proxy on each node to setup correct iptables rules. (This is an advanced topic, and not our focus right now).
* No matter what type of service you choose while *exposing* your deployment, Cluster-IP is always assigned to that particular service.
* Every service has end-points, which point to the actual pods serving as a backends of a particular service.
* As soon as a service is created, and is assigned a Cluster-IP, an entry is made in Kubernetes' internal DNS against that service, with this service name and the Cluster-IP. e.g. `nginx.default.svc.cluster.local` would point to `100.70.204.237` .

### Service type: NodePort

Our nginx service is still not reachable from outside, so now we re-create this service as NodePort.

```shell
$ kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
nginx        ClusterIP   100.70.204.237   <none>        80/TCP    15m
```

```shell
$ kubectl delete svc nginx
service "nginx" deleted
```

```shell
$ kubectl expose deployment nginx --port 80 --type NodePort
service/nginx exposed
```

```shell
$ kubectl get svc
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx        NodePort    100.65.29.172  <none>        80:32593/TCP   8s
```

Notice that we still don't have an external IP, but we now have an extra port `32593` for this pod. This port is a **NodePort** exposed on the worker nodes. So now, if we know the IP of our nodes, we can access this nginx service from the internet. First, we find the public IP of the nodes:

```shell
$ kubectl get nodes -o wide
NAME                                            STATUS    ROLES     AGE       VERSION        EXTERNAL-IP     OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-dcn-cluster-35-default-pool-dacbcf6d-3918   Ready     <none>    17h       v1.8.8-gke.0   35.205.22.139   Container-Optimized OS from Google   4.4.111+         docker://17.3.2
gke-dcn-cluster-35-default-pool-dacbcf6d-c87z   Ready     <none>    17h       v1.8.8-gke.0   35.187.90.36    Container-Optimized OS from Google   4.4.111+         docker://17.3.2
```

Even though we have only one pod (and two worker nodes), we can access any of the nodes with this port, and it will eventually be routed to our pod. Let's try to access it from our local work computer:

```shell
$ curl -s 35.205.22.139:32593 | grep h1
<h1>Welcome to nginx!</h1>
```

It works!

### Service type: LoadBalancer

So far so good; but, we do not expect the users to know the IP addresses of our worker nodes. It is not a flexible way of doing things. So we re-create the service as `type=LoadBalancer`. The type LoadBalancer is only available for use, if your k8s cluster is setup in any of the public cloud providers, GCE, AWS, etc.

```shell
$ kubectl delete svc nginx
service "nginx" deleted
```

```shell
$ kubectl expose deployment nginx --port 80 --type LoadBalancer
service/nginx exposed
```

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

```shell
$ curl -s 35.205.60.29 | grep h1
<h1>Welcome to nginx!</h1>
```

**Additional notes about LoadBalancer:**

* A service defined as LoadBalancer will still have some high-range port number assigned to it's main service port, just like NodePort. This has a clever purpose, but is an advance topic and is not our focus at this point.

# High Availability

So far we have seen pods, deployments and services. We have also seen Kubernetes keeping up it's promise of resilience. Now we see how we can have **high availability** on Kubernetes. The easiest and preferred way to do this is by having multiple replicas for a deployment.

Let's increase the number of replicas of our nginx deployment to four(4):

```shell
$ kubectl scale deployment nginx --replicas=4
deployment.extensions/nginx scaled
```

Check the deployment and pods:

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

**Notice:** The nginx deployment says Ready=4/4, Up-to-date=4, Available=4. And the pods also show the same. There are now 4 nginx pods running; one of them was already running (being older), and the other three are started just now.

You can also scale down! - e.g. to 2:

```shell
$ kubectl scale deployment nginx --replicas=2
deployment.extensions/nginx scaled
```

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

You can delete the nginx deployment and service at this point. We have no use for these anymore. Besides, you can always re-create them.

```shell
$ kubectl delete deployment nginx
deployment.extensions "nginx" deleted
$ kubectl delete service nginx
service "nginx" deleted
```

## Extra-credit: High Availability Exercise

To prove that multiple pods of the same deployment provide high availability, we do a small exercise. To visualize it, we need to run a small web server which could return us some unique content when we access it. We will use our trusted multitool for it. Let's run it as a separate deployment and access it from our local computer.

```shell
$ kubectl create deployment customnginx --image=praqma/network-multitool
deployment.apps/customnginx created
$ kubectl scale deployment customnginx --replicas=4
deployment.extensions/customnginx scaled
```

```shell
$ kubectl get pods
NAME                           READY     STATUS    RESTARTS   AGE
customnginx-3557040084-1z489   1/1       Running   0          49s
customnginx-3557040084-3hhlt   1/1       Running   0          49s
customnginx-3557040084-c6skw   1/1       Running   0          49s
customnginx-3557040084-fw1t3   1/1       Running   0          49s
multitool-5f9bdcb789-k7f4q     1/1       Running   0          19m
```

Let's create a service for this deployment as a type=LoadBalancer:

```shell
$ kubectl expose deployment customnginx --port=80 --type=LoadBalancer
service/customnginx exposed
```

Verify the service and note the public IP address:

```shell
$ kubectl get services
NAME          TYPE           CLUSTER-IP    EXTERNAL-IP        PORT(S)        AGE
customnginx   LoadBalancer   100.67.40.4   35.205.60.41       80:30087/TCP   1m
```

Query the service, so we know it works as expected:

```shell
$ curl -s 35.205.60.41
Praqma Network MultiTool (with NGINX) - customnginx-7cf9899b84-rjgrb - 10.8.2.47/24
```

Next, setup a small bash loop on your local computer to curl this IP address, and get it's IP address.

```shell
$ while true; do sleep 1; curl -s 35.205.60.41; done
Praqma Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.36 <BR></p>
Praqma Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.1.150 <BR></p>
Praqma Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.37 <BR></p>
Praqma Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.37 <BR></p>
Praqma Network MultiTool (with NGINX) - customnginx-7fcfd947cf-zbvtd - 100.96.2.36 <BR></p>
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
Container IP: 100.96.1.150 <BR></p>
Container IP: 100.96.1.150 <BR></p>
Container IP: 100.96.2.37 <BR></p>
Container IP: 100.96.1.149 <BR></p>
Container IP: 100.96.1.149 <BR></p>
Container IP: 100.96.1.150 <BR></p>
Container IP: 100.96.2.36 <BR></p>
Container IP: 100.96.2.37 <BR></p>
Container IP: 100.96.2.37 <BR></p>
Container IP: 100.96.2.38 <BR></p>
Container IP: 100.96.2.38 <BR></p>
Container IP: 100.96.2.38 <BR></p>
Container IP: 100.96.1.151 <BR></p>
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

```shell
$ kubectl delete deployment customnginx
$ kubectl delete deployment multitool
$ kubectl delete service customnginx
```
