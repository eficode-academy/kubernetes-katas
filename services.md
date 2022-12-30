# Services

## Learning Goals

Ability to communicate between pods using services

## Introduction

In this exercise you'll learn about how pods can be exposed using services and test connectivity between them.

## Accessing a service

To access any service inside any given pod (e.g. backend service), we need to _expose_ the pod as a _service_. We have three main ways of exposing the pods, or in other words, we have three ways to define a _service_ , which we can access in three different ways. A service is (normally) created on top of an existing pod.

## Service types

### Kind

A generic service manifest file looks like this: 

```yaml
apiVersion:  # v1
kind:  # Service
metadata: 
  labels: # list of labels for this service
  name: # Service name
spec:
  ports: # Ports to expose
  - port: 
    protocol: # TCP or UDP
    targetPort: # Pod port to expose
  selector: # List of labels to match pods
  type: # ClusterIP, NodePort or LoadBalancer
```
### ClusterIP

Services of type ClusterIP will only create a DNS entry with the name of the service, as well as an internal cluster IP that routes traffic over to the deployments hit by the `selector` part of the service.

The service type ClusterIP does not have any external IP. This means it is not accessible over the internet, but we can still access it from within the cluster using its `CLUSTER-IP`.

<details>
    <summary> :bulb: More about Cluster-IP</summary>

- The IPs assigned to services as Cluster-IP are from a different Kubernetes network called _Service Network_, which is a completely different network altogether. i.e. it is not connected (nor related) to pod-network or the infrastructure network. Technically it is actually not a real network per-se; it is a labeling system, which is used by Kube-proxy on each node to setup correct iptables rules. (This is an advanced topic, and not our focus right now).
- No matter what type of service you choose while _exposing_ your pod, Cluster-IP is always assigned to that particular service.
- Every service has end-points, which point to the actual pod serving as a backend of a particular service.
- As soon as a service is created, and is assigned a Cluster-IP, an entry is made in Kubernetes' internal DNS against that service, with this service name and the Cluster-IP. e.g. `backend.default.svc.cluster.local` would point to Cluster-IP `172.20.114.230` .

</details>

### NodePort

Services of type NodePort will create a DNS entry with the name of the service, as well as an internal cluster IP that routes traffic over to the pod hit by the `selector` part of the service. In addition to this, it will also create a port on each node in the cluster, which will route traffic to the service.

Notice that we still don't have an external IP, but we now have an extra port e.g. `32593` for this service.

This port is a **NodePort** exposed on the worker nodes. So now, if we know the IP of our nodes, we can access this service from the internet.

### Other types

There are other types of services, but we won't cover them in this exercise.

## Exercise

### Overview

- Apply both frontend and backend pods
- Create backend service with type ClusterIP
- Exec into frontend pod, reach backend through service dns name
- Create frontend service with type NodePort
- Access it from the nodes IP address

:bulb: If you get stuck somewhere along the way, you can check the solution in the done folder.

### Step by step instructions
* Go into the `services` directory and the `start` folder.
* Apply the backend-pod.yaml & frontend-pod.yaml files.

<details>
<summary>:bulb: hint on how you do that </summary>
you can use the `kubectl apply -f` command to deploy the pod. The pod is defined in the `backend-pod.yaml` file. Hint: The apply command can take more than one `-f` parameter to apply more than one yaml file 
</details>

* Check that the pods are running with `kubectl get pods` command.

You should see something like this:

```
NAME          READY   STATUS    RESTARTS   AGE
pod/backend   1/1     Running   0          28s
pod/frontend  1/1     Running   0          20s
```

* Create the service file for backend
* Apply backend-svc.yaml that you just created.

* Check that the service is created with `kubectl get services` command.

you should see something like this:

```
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/backend   ClusterIP   172.20.114.230   <none>        5000/TCP   23s
```

* Exec into frontend pod
`kubectl exec -it frontend -- bash`

you should see something like this:

```
root@frontend:/app#
```

Make sure that you are inside a pod and not in your terminal window.

* Try to reach backend pod through backend service Cluster-IP from within your frontend pod

`curl 172.20.114.230:5000`

you should see something like this:

```
Hello from the backend!
```
* Try accessing the service using dns name now

`curl 172.20.114.230:5000`

you should see the same output as above.

You can type `exit` to exit from your container.

* Create the service file for frontend with type NodePort
* Apply frontend-svc.yaml that you just created.

* Check that the service is created with `kubectl get services` command.

you should see something like this:

```
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
frontend     NodePort    10.106.136.250   <none>        5000:31941/TCP   23s
```

- Access it from the nodes IP address
run `kubectl get nodes -o wide`

you should see something like this:

```
NAME                                        STATUS   ROLES    AGE    VERSION               INTERNAL-IP   EXTERNAL-IP      OS-IMAGE         KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-0-33-234.eu-west-1.compute.internal   Ready    <none>   152m   v1.23.9-eks-ba74326   10.0.33.234   54.194.220.73    Amazon Linux 2   
5.4.219-126.411.amzn2.x86_64   docker://20.10.17
ip-10-0-38-95.eu-west-1.compute.internal    Ready    <none>   152m   v1.23.9-eks-ba74326   10.0.38.95    34.244.123.152   Amazon Linux 2   
5.4.219-126.411.amzn2.x86_64   docker://20.10.17
ip-10-0-57-206.eu-west-1.compute.internal   Ready    <none>   152m   v1.23.9-eks-ba74326   10.0.57.206   34.242.240.121   Amazon Linux 2   
5.4.219-126.411.amzn2.x86_64   docker://20.10.17
ip-10-0-62-15.eu-west-1.compute.internal    Ready    <none>   152m   v1.23.9-eks-ba74326   10.0.62.15    54.246.17.102    Amazon Linux 2   
5.4.219-126.411.amzn2.x86_64   docker://20.10.17
```

Copy the external IP address of any one of the nodes, for example, `34.244.123.152` and paste it in your browser. Copy the port from your frontend service that looks something like `31941` and paste it next to your IP in the browser, for example, `34.244.123.152:31941` and hit it.

Alternatively, you could also test it using curl from your terminal window.
`curl 34.244.123.152:31941 | grep h1`

You should see something like this:

```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3051  100  3051    0     0   576k      0 --:--:-- --:--:-- --:--:--  595k
        <h1>Programming Quotes</h1>
```

<details>
<summary>:bulb: food for thought </summary>
Think about why you didn't need to exec into a pod to test frontend service but needed it to test backend service.
</details>

### Clean up

Delete the pods and services with `kubectl delete pod frontend backend` and `kubectl delete service frontend backend` commands.

You have succesfully tested connectivity between frontend and backend pods using services.


### Extra: Filter on the basis of labels

To filter the output of kubectl get pods based on a label, you can use the --selector flag followed by the label key and value. For example, to filter the pods based on a label with the key foo and the value bar, you would run the following command:

`kubectl get pods --selector=foo=bar`

This will return a list of all the pods that have a label with the key foo and the value bar.

You can use the != operator to specify that you want to exclude resources with a particular label value. For example, to filter the pods based on a label with the key foo but exclude those with the value bar, you would run the following command:

`kubectl get pods --selector=foo!=bar`

Try to apply the application again and write four commands that does the following:

* List only the pods with the label app=frontend
* List only the pods with the label app=backend
* List only the pods where label app is not frontend
* List only the pods where label app is not backend

The documentation on this can be found here: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/

Remember to clean up after you are done.



