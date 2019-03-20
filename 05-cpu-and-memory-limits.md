It is important to learn about CPU and memory limits at this point in time, because this knowledge will be useful in next excercises.

# Why to use CPU and memory limits?
It is possible that the worker node in the kubernetes cluster you received from your instructor, is a small spec node (1 CPU and 1.7 GB RAM). In that case, please note that certain *system pods* running in **kube-system** namespace take away as much as 60% (or 600m) of the CPU, and you are left with 40% of CPU to run your pods in order to do these excercises. It is also important to note that by default each `nginx` and `nginx:alpine` instance will take away 10% (or 100m) CPU. (This behavior was seen on a small one-node k8s cluster in GCP). This means, that at any given time, you will not be able to run more than four (light weight) pods in total. So when you do the **scaling** and **rolling updates** exercises, you need to keep that in mind. You can limit the use of CPU and Memory resources in your pods and assign them very little CPU. e.g. Allocating `5m` CPU to nginx pods does not have any negative effect, and they just run fine.

If you are running a cluster of your own such as minikube or kubeadm based cluster, and if you setup the VMs to have multiple CPUs during the VM setup, you will not likely encounter this limitation. But you should still make a note of it. However, this does not mean that you do not setup these limits in your deployments just because you have large sized worker nodes. It is actually highly recommended that you setup the CPU and memory limits for all your pods/deployments to protect abuse of system resources. This abuse may happen if an application has a fault in it's code and starts over-consuming cpu and/or memory. It is also possible that someone gains access to a pod running inside your cluster, and starts abusing with malicious intent, such as sending spam, or mining coins, etc. We have actually seen this happening! :) 

It is also useful to set these limits because it is useful for the Kubernetes Scheduler. If the scheduler knows how much cpu and memory a pod needs , it will find the right nodes to run those pods on. If there are no cpu and memory limits defined, then the scheduler has absolutely no clue on where to place thse pods, and it just uses it's best guess to place it on a node and hopes that it works! :) (There is a bit more to it, but this is the essence). 

Check this document for more information: [https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/)


## Example of not setting CPU and memory limits:
Lets create and run a simple nginx deployment without using any CPU or memory limits and see what is going on in the cluster:

```
$ kubectl run nginx --image=nginx:alpine
deployment.apps "nginx" created

$ kubectl get rs
NAME                   DESIRED   CURRENT   READY     AGE
multitool-5558fd48d4   1         1         1         10d
nginx-6b4b85b77b       1         1         1         15m

$ kubectl get pods
NAME                         READY     STATUS    RESTARTS   AGE
multitool-5558fd48d4-pqkj5   1/1       Running   1          10d
nginx-6b4b85b77b-w8xww       1/1       Running   0          15s
```


You can *describe* the nginx deployment and the related pod and replica-set. If no cpu and memory limits were provided when this deployment was created, then you will not find that information in the describe deployment|rs|pod commands. 

```
$ kubectl describe deployment nginx

$ kubectl describe rs nginx-6b4b85b77b

$ kubectl describe pod nginx-6b4b85b77b-w8xww
```


Let's check which node the pod is running on and investigate the node:
```
$ kubectl get pods -o wide
NAME                         READY     STATUS    RESTARTS   AGE       IP           NODE
multitool-5558fd48d4-pqkj5   1/1       Running   1          10d       172.17.0.4   minikube
nginx-6b4b85b77b-w8xww       1/1       Running   0          17m       172.17.0.5   minikube
```

We have *some* information about resources in the worker node.

```
$ kubectl describe node minikube
Name:               minikube
Roles:              master
. . . 
Addresses:
  InternalIP:  192.168.122.249
  Hostname:    minikube
Capacity:
 cpu:                2
 ephemeral-storage:  16058792Ki
 hugepages-2Mi:      0
 memory:             1942288Ki
 pods:               110
Allocatable:
 cpu:                2
 ephemeral-storage:  14799782683
 hugepages-2Mi:      0
 memory:             1839888Ki
 pods:               110
. . . 
Non-terminated Pods:         (11 in total)
  Namespace                  Name                                CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ---------                  ----                                ------------  ----------  ---------------  -------------
  default                    multitool-5558fd48d4-pqkj5          0 (0%)        0 (0%)      0 (0%)           0 (0%)
  default                    nginx-6b4b85b77b-w8xww              0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                coredns-86c58d9df4-fhqpl            100m (5%)     0 (0%)      70Mi (3%)        170Mi (9%)
  kube-system                coredns-86c58d9df4-pljtz            100m (5%)     0 (0%)      70Mi (3%)        170Mi (9%)
  kube-system                etcd-minikube                       0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                kube-addon-manager-minikube         5m (0%)       0 (0%)      50Mi (2%)        0 (0%)
  kube-system                kube-apiserver-minikube             250m (12%)    0 (0%)      0 (0%)           0 (0%)
  kube-system                kube-controller-manager-minikube    200m (10%)    0 (0%)      0 (0%)           0 (0%)
  kube-system                kube-proxy-4k6vs                    0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                kube-scheduler-minikube             100m (5%)     0 (0%)      0 (0%)           0 (0%)
  kube-system                storage-provisioner                 0 (0%)        0 (0%)      0 (0%)           0 (0%)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ------------  ----------  ---------------  -------------
  755m (37%)    0 (0%)      190Mi (10%)      340Mi (18%)
Events:         <none>
```


Notice that the `CPU Requests`, `CPU Limits`, `Memory Requests` and `Memory Limits` are all set to `0` or `0%` - for nginx pod. This means there are no limits for this pod, and if this pod is somehow abused, it can consume entire CPU and memory of this worker node.


## Example of CPU and memory limits - using nginx:

Lets delete the existing nginx deployment.

```
$ kubectl delete deployment nginx
```

Create a new one with some limits. Here is what the deployment file looks like, with cpu and memory limits defined in it
```
$ cat support-files/nginx-with-cpu-memory-limit.yaml 
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx          # arbitrary label(s) assigned to this deployment. This can be used by an upstream object, such as - a service.
spec:
  replicas: 1
  selector:
    matchLabels:        # labels 'used' by the deployment and replica-set selector, to find related pods.
      app: nginx
  template:
    metadata:
      labels:
        app: nginx      # label assigned to the pods of this deployment
    spec:
      containers:
      - name: nginx
        image: nginx:1.9.1
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "1m"
            memory: "5Mi"
          limits:
            cpu: "5m"
            memory: "10Mi"
```


Create the deployment:
```
$ kubectl create -f nginx-with-cpu-memory-limit.yaml 
deployment.extensions/nginx created

$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
multitool-5558fd48d4-pqkj5   1/1     Running   1          10d
nginx-84cc7d8b59-5flwm       1/1     Running   1          5s
```

Now, lets check deployment, rs and pods for cpu and memory information.

```
$ kubectl describe deployment nginx
Name:                   nginx
Namespace:              default
. . . 
  Containers:
   nginx:
    Image:      nginx:1.9.1
    Port:       80/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     5m
      memory:  10Mi
    Requests:
      cpu:        1m
      memory:     5Mi
. . . 
```


Check the related replica-set for the same information:
```
$ kubectl describe rs nginx-84cc7d8b59
Name:           nginx-84cc7d8b59
Namespace:      default
. . . 
Controlled By:  Deployment/nginx
. . . 
  Containers:
   nginx:
    Image:      nginx:1.9.1
    Port:       80/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     5m
      memory:  10Mi
    Requests:
      cpu:        1m
      memory:     5Mi
. . . 
```

Check the pod for cpu and memory information:

```
$ kubectl describe pod nginx-84cc7d8b59-5flwm
Name:               nginx-84cc7d8b59-5flwm
Namespace:          default
. . . 
Node:               minikube/192.168.122.249
. . . 
Controlled By:      ReplicaSet/nginx-84cc7d8b59
Containers:
  nginx:
    Image:          nginx:1.9.1
. . .
    Limits:
      cpu:     5m
      memory:  10Mi
    Requests:
      cpu:        1m
      memory:     5Mi
. . .
QoS Class:       Burstable
. . . 
```

This time all three objects (deployment, replica-set and pods), have the cpu and memory information. Also notice that the QoS class for the pod has changed from "Best Effort" to "Burstable". You will notice this if you did a `describe` earlier, on a pod without cpu and memory limits set.


If we do a `describe` on the worker node now, we will see that the node knows about these limits for the nginx pod.

```
$ kubectl describe node minikube
Name:               minikube
Roles:              master
. . . 
Taints:             <none>
. . .
  Hostname:    minikube
. . . 
Non-terminated Pods:         (11 in total)
  Namespace                  Name                                CPU Requests  CPU Limits  Memory Requests  Memory Limits  AGE
  ---------                  ----                                ------------  ----------  ---------------  -------------  ---
  default                    multitool-5558fd48d4-pqkj5          0 (0%)        0 (0%)      0 (0%)           0 (0%)         10d
  default                    nginx-84cc7d8b59-5flwm              1m (0%)       5m (0%)     5Mi (0%)         10Mi (0%)      12m
  kube-system                coredns-86c58d9df4-fhqpl            100m (5%)     0 (0%)      70Mi (3%)        170Mi (9%)     19d
  kube-system                coredns-86c58d9df4-pljtz            100m (5%)     0 (0%)      70Mi (3%)        170Mi (9%)     19d
  kube-system                etcd-minikube                       0 (0%)        0 (0%)      0 (0%)           0 (0%)         19d
  kube-system                kube-addon-manager-minikube         5m (0%)       0 (0%)      50Mi (2%)        0 (0%)         19d
  kube-system                kube-apiserver-minikube             250m (12%)    0 (0%)      0 (0%)           0 (0%)         19d
  kube-system                kube-controller-manager-minikube    200m (10%)    0 (0%)      0 (0%)           0 (0%)         19d
  kube-system                kube-proxy-4k6vs                    0 (0%)        0 (0%)      0 (0%)           0 (0%)         4d13h
  kube-system                kube-scheduler-minikube             100m (5%)     0 (0%)      0 (0%)           0 (0%)         19d
  kube-system                storage-provisioner                 0 (0%)        0 (0%)      0 (0%)           0 (0%)         19d
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                756m (37%)   5m (0%)
  memory             195Mi (10%)  350Mi (19%)
  ephemeral-storage  0 (0%)       0 (0%)
Events:              <none>
```


## Example of CPU and memory limits - using stress:

In this exercise, you create a Pod that has one Container. The Container has a request of 0.5 CPU and a limit of 1 CPU. Here is the configuration file for the Pod: 

```
$ cat support-files/stress-cpu-request-limit-pod.yaml 

apiVersion: v1
kind: Pod
metadata:
  name: cpu-stress-demo
spec:
  containers:
  - name: cpu-stress-demo
    image: vish/stress
    resources:
      limits:
        cpu: "1"
      requests:
        cpu: "0.5"
    args:
    - -cpus
    - "2"

```


Lets run this pod and see what it does.

```
$ kubectl create -f support-files/stress-cpu-request-limit-pod.yaml 
pod/cpu-stress-demo created

$ kubectl get pods -o wide
NAME                         READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
cpu-stress-demo              1/1     Running   0          6s    172.17.0.6   minikube   <none>           <none>
multitool-5558fd48d4-pqkj5   1/1     Running   1          10d   172.17.0.4   minikube   <none>           <none>
nginx-84cc7d8b59-5flwm       1/1     Running   1          29m   172.17.0.5   minikube   <none>           <none>
```

Lets check the node's status straight away:

```
$ kubectl describe node minikube
Name:               minikube
Roles:              master
Taints:             <none>
. . . 
  Namespace                  Name                                CPU Requests  CPU Limits  Memory Requests  Memory Limits  AGE
  ---------                  ----                                ------------  ----------  ---------------  -------------  ---
  default                    cpu-stress-demo                     500m (25%)    1 (50%)     0 (0%)           0 (0%)         41s
  default                    multitool-5558fd48d4-pqkj5          0 (0%)        0 (0%)      0 (0%)           0 (0%)         10d
  default                    nginx-84cc7d8b59-5flwm              1m (0%)       5m (0%)     5Mi (0%)         10Mi (0%)      29m
. . . 
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                1256m (62%)  1005m (50%)
  memory             195Mi (10%)  350Mi (19%)
  ephemeral-storage  0 (0%)       0 (0%)
Events:              <none>
```

If you login to your worker node over ssh, you will see the process hogging the CPU and load average going high:

Load Average:
```
$ uptime
 11:06:24 up 4 days, 21:45,  1 user,  load average: 1.43, 0.98, 0.73
```

CPU usage - using OS `top` command:
```
$ top -b -o %CPU
top - 11:10:38 up 4 days, 21:49,  1 user,  load average: 3.66, 1.59, 0.98
Tasks: 132 total,   2 running, 130 sleeping,   0 stopped,   0 zombie
%Cpu0  :  20.0/46.7   67[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||                                 ]
%Cpu1  :  12.5/43.8   56[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||                                           ]
GiB Mem : 68.1/1.9      [                                                                                                    ]
GiB Swap:  6.5/1.0      [                                                                                                    ]

  PID USER      PR  NI    VIRT    RES  %CPU  %MEM     TIME+ S COMMAND
24966 root      20   0    5.4m   3.7m 100.0   0.2   6:20.23 S /stress -logtostderr -cpus 2
 2991 root      20   0   10.1g  80.5m   6.2   4.2 121:05.99 S etcd --advertise-client-urls=https://192.168.39.48:2379 --cert-file=/var+
    1 root      20   0  181.2m   7.7m   0.0   0.4   0:23.64 S /sbin/init noembed norestore
    2 root      20   0    0.0m   0.0m   0.0   0.0   0:00.01 S [kthreadd]
    4 root       0 -20    0.0m   0.0m   0.0   0.0   0:00.00 I [kworker/0:0H]
    6 root       0 -20    0.0m   0.0m   0.0   0.0   0:00.00 I [mm_percpu_wq]
```

Lets kill this pod.

```
$ kubectl delete -f support-files/stress-cpu-request-limit-pod.yaml 
pod "cpu-stress-demo" deleted
```



# Best practice
Often the developers forget to setup the cpu and memory requirement/limits for their applications in the deployment definitions. If an abusive/broken app is run, it can take down an entire worker node; and if that app has multiple replicas running on multiple worker nodes, then multiple worker nodes will be severely affected. It is best to setup a very low default CPU and memory limit on namespace level, so if someone runs a deployment without the limits, their applications will either not start, or will be very slow. They can then incorporate these requirements and limits in their pod/deployment definitions to fix this.

Check this document on how to setup default CPU and memory limits on namespace level: [https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/)
