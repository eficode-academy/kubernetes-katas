# Storage

There are several ways for making data peristent. Few of them will be explained in this kata.

## emtpryDir
An “emptyDir” volume type is always empty at the pod start time and gets data from whatever the container process(es) - or other containers in the same pod - fill it with. As soon as the pod exits - or dies - the emptyDir volume is deleted with it. If the pod moves from one node to another, the contents of emptyDir are deleted permanently. So this is not really an example of data persistence. But it helps explain certain point.

Some uses for an emptyDir are:
* scratch space, such as for a disk-based merge sort
* checkpointing a long computation for recovery from crashes
* holding files that a content-manager container fetches while a webserver container serves the data

Example:
Say you have a git repository, which contains your static web-content; which you want to serve through a web server running in a container. For this to work, you use a multi-container pod, with web-server being the main container; and a helper container, which pulls the latest from the web-content git repository and put it in a special emptyDir based volume. This volume is then shared with the web-server, which mounts the same volume on it’s document-root mount point, and serves that content. We have already seen this in the init-containers exercise [02-init-and-multi-container-pods.md](02-init-and-multi-container-pods.md). Here it is once again:

```
$ cat support-files/init-container-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-container-demo
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: web-content-dir
      mountPath: /usr/share/nginx/html
  initContainers:
  - name: helper
    image: alpine/git
    command:
    - git 
    - clone
    - https://github.com/Praqma/simple-website.git
    - /web-content/
    volumeMounts:
    - name: web-content-dir
      mountPath: "/web-content"
  volumes:
  - name: web-content-dir
    emptyDir: {}
```


## hostPath
A `hostPath` volume type will always mount a directory from the host file system into a mount point inside the pod. Whatever the contents of the said host directory, will show up in the mount point in the container. On a Kubernetes cluster, hostPath volume will prove to be a nightmare for its use as a general persistent-storage for running containers, because what if the container moves from one node to another? How will the volume move from one node to another? It won’t - and that is not the use-case for this type of volume. 

Containers which are more of *system* containers, and are concerned with only one node on which they run, may use this volume type. Say you want to monitor/read/process information about any running containers on a node. To be able to do that, the monitoring container would need to mount certain host directories from the host on certain mount points inside that container. **cAdvisor** is an example of a container which needs to mount host paths. 

Another special case where you can use hostPath as persistent storage option is the test/development single node clusters, such as minikube. On such clusters, since there is just one node, you can pretty much assure that whenever a pod restarts, it will always be on the same node and will find it's data; and also, that the data in certain host directories /hostPath), will be safe / persistent. 

However, one important one to keep under consideration is that the files or directories created on the underlying hosts are only writable by `root`. You either need to run your process as root in a privileged Container or modify the file permissions on the host to be able to write to a hostPath volume. This will be a challenge most of the time, and that is what makes hostPath a bad choice for being used as persistent storage.

Below is an example of a pod using hostPath.


```
$ cat support-files/hostPath-example-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-example-pod
spec:
  containers:
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: web-volume
      mountPath: /usr/share/nginx/html
  volumes:
  - name: web-volume
    hostPath:
      # directory location on host
      path: /data/web-server
      type: Directory
```

Create the pod:

```
$ kubectl create -f support-files/hostPath-example-pod.yaml 
pod "hostpath-example-pod" created
```

Notice the pod remains in `ContainerCreating` status:
```
$ kubectl get pods -w
NAME                         READY     STATUS              RESTARTS   AGE
hostpath-example-pod         0/1       ContainerCreating   0          45s
multitool-5558fd48d4-pqkj5   1/1       Running             0          2d
```

Investigate by describing the pod:
```
$ kubectl describe pod hostpath-example-pod
. . . 
Status:             Pending
. . . 
Events:
  Type     Reason       Age              From               Message
  ----     ------       ----             ----               -------
  Normal   Scheduled    1m               default-scheduler  Successfully assigned default/hostpath-example-pod to minikube
  Warning  FailedMount  5s (x8 over 1m)  kubelet, minikube  MountVolume.SetUp failed for volume "web-volume" : hostPath type check failed: /data/web-server is not a directory
```

On the actual host (kubernetes worker node), the hostPath directory does not exist.

Check by logging into the host, in this case minikube:

``` 
$ minikube ssh

# ls -l /data/
total 4
drwxr-xr-x 3 root root 4096 Mar 10 00:08 minikube
# 
```

So there is no directory called `web-server` on the host. Lets create it:

```
$ minikube ssh

# mkdir /data/web-server
# ls -l /data/
total 8
drwxr-xr-x 3 root root 4096 Mar 10 00:08 minikube
drwxr-xr-x 2 root root 4096 Mar 12 12:27 web-server
# 
```

Delete the failing pod and re-create it:
```
$ kubectl delete pod hostpath-example-pod
pod "hostpath-example-pod" deleted

$ kubectl create -f support-files/hostPath-example-pod.yaml 
pod "hostpath-example-pod" created
```

```
$ kubectl get pods -o wide
NAME                         READY     STATUS    RESTARTS   AGE       IP           NODE
hostpath-example-pod         1/1       Running   0          56s       172.17.0.5   minikube
multitool-5558fd48d4-pqkj5   1/1       Running   0          2d        172.17.0.4   minikube
```


Login to the pod and check if there is any file under `/usr/share/nginx/html` . There shouldn't be any. So lets create an `index.html` file there.

```
$ kubectl exec -it hostpath-example-pod /bin/sh

/ # ls -l /usr/share/nginx/html/
total 0
/ # 

/ # echo "Nginx - This is an example of hostPath data persistence!" > /usr/share/nginx/html/index.html 

/ # cat /usr/share/nginx/html/index.html 
Nginx - This is an example of hostPath data persistence!
/ # 
```


Now, check minikube node for the hostPath directory. It should have this file there.

```
$ minikube ssh

# ls -l /data/web-server/
total 4
-rw-r--r-- 1 root root 57 Mar 12 12:32 index.html

# cat  /data/web-server/index.html 
Nginx - This is an example of hostPath data persistence!
```

It goes without saying that if you access this web server from another container, you will see the same contents. Lets try our trusted multitool.

```
$ kubectl exec -it multitool-5558fd48d4-pqkj5 bash

bash-4.4# curl 172.17.0.5
Nginx - This is an example of hostPath data persistence!
bash-4.4# 
```

Now, we check for persistence. Lets delete the pod, and re-create it. It should be able to mount the same directory from the host and serve the same content.

```
$ kubectl delete pod hostpath-example-pod 
pod "hostpath-example-pod" deleted
```

Check the contents of the file on the hostPath on the host. It should exist.

```
$ minikube ssh

# cat  /data/web-server/index.html 
Nginx - This is an example of hostPath data persistence!
```

Good! Lets re-create the same pod:

```
$ kubectl create -f support-files/hostPath-example-pod.yaml 
pod "hostpath-example-pod" created

$ kubectl get pods -o wide
NAME                         READY     STATUS    RESTARTS   AGE       IP           NODE
hostpath-example-pod         1/1       Running   0          4s        172.17.0.6   minikube
multitool-5558fd48d4-pqkj5   1/1       Running   0          2d        172.17.0.4   minikube
```



Lets examine the container from inside it, and also access the web-server container from another container. We should be able to see the same contents.

```
$ kubectl exec -it hostpath-example-pod /bin/sh

/ # ls -l /usr/share/nginx/html/index.html 
-rw-r--r--    1 root     root            57 Mar 12 12:32 /usr/share/nginx/html/index.html

/ # cat  /usr/share/nginx/html/index.html 
Nginx - This is an example of hostPath data persistence!
```

```
$ kubectl exec -it multitool-5558fd48d4-pqkj5 bash
bash-4.4# 

bash-4.4# curl 172.17.0.6
Nginx - This is an example of hostPath data persistence!
```

Great! so hostPath works, and our data is persistent!


----------

## Kubernetes storage (PV and PVC):

I have two examples. One is PV on a worker node, using hostpath. The other is NFS based PV.

### Persistent Volume / PV - based on hostPath 

```
$ cat support-files/pv-as-hostpath.yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-hostpath
spec:
  storageClassName: ""
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/opt/data"
```

Make sure to create this hostPath on the worker node. This example assumes that you have only one worker node. This (hostPath) method is meaningless on multi-node cluster.
```
$ minikube ssh

$ sudo -i

# mkdir /opt/data

# ls -l /opt/data/
total 0
```



We will create PV and PVC manually, to show how it works. 
```
$ kubectl create -f support-files/pv-as-hostpath.yaml 
persistentvolume "pv-hostpath" created
```

Note that a PV is global resource. It cannot be confined within a namespace.
```
$ kubectl get pv
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM               STORAGECLASS   REASON    AGE
pv-hostpath   100Mi      RWO            Retain           Bound     default/pvc-nginx                            59s 
```


```
$ kubectl describe pv pv-hostpath
Name:            pv-hostpath
Labels:          <none>
Annotations:     <none>
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    
Status:          Available
Claim:           
Reclaim Policy:  Retain
Access Modes:    RWO
VolumeMode:      Filesystem
Capacity:        100Mi
Node Affinity:   <none>
Message:         
Source:
    Type:          HostPath (bare host directory volume)
    Path:          /opt/data
    HostPathType:  
Events:            <none>
```


Now, lets create a PVC, which takes a slice of storage out of this PV. That PVC will then be used/consumed by a pod. Note that I have set storageClassName to null, because I want the PVC to not use any storage classes. (more on this later). By default - if storageClassName directive is missing - then, the "default" (or "standard") storage class is used automatically.


```
$ cat pvc-nginx-manual.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nginx
spec:
  storageClassName: ""
  accessModes:
    # Though accessmode is already defined in pv definition. It is still needed here.
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Mi
```


```
$ kubectl create -f support-files/pvc-nginx-manual.yaml 
persistentvolumeclaim "pvc-nginx" created
```

Verify that the PVC is created and is boud to the PV. Also note that PVC is namespace dependent. PVCs are not visible across different namespaces.

```
$ kubectl get pvc 
NAME        STATUS    VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nginx   Bound     pv-hostpath   100Mi      RWO                           1m
```

Describe the pvc to learn more about it:

```
$ kubectl describe pvc pvc-nginx 
Name:          pvc-nginx
Namespace:     default
StorageClass:  
Status:        Bound
Volume:        pv-hostpath
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed=yes
               pv.kubernetes.io/bound-by-controller=yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      100Mi
Access Modes:  RWO
VolumeMode:    Filesystem
Events:        <none>
```


Note that by this time, there is no change in the actual hostPath directory on the worker node.

```
$ minikube ssh

$ sudo -i

# ls -la /opt/data/
total 0
drwxr-xr-x 2 root root 0 Mar 12 13:23 .
drwxr-xr-x 5 root root 0 Mar 12 13:23 ..
```

Lets create a pod, which uses this PVC to store it's data.

```
$ cat nginx-pod-using-pvc.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-using-pvc
spec:
  volumes:
  - name: nginx-htmldir
    persistentVolumeClaim:
      claimName: pvc-nginx
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - mountPath: "/usr/share/nginx/html"
      name: nginx-htmldir
```



```
$ kubectl create -f nginx-pod-using-pvc.yaml 
pod "nginx-pod-using-pvc" created

$ kubectl get pods -o wide
NAME                         READY     STATUS    RESTARTS   AGE       IP           NODE
multitool-5558fd48d4-pqkj5   1/1       Running   0          2d        172.17.0.4   minikube
nginx-pod-using-pvc          1/1       Running   0          1m        172.17.0.6   minikube
```


Describe the pod to verify that it has mounted the PVC as a volume:
```
$ kubectl describe pod nginx-pod-using-pvc 
Name:               nginx-pod-using-pvc
. . . 
Containers:
  nginx:
. . . 
    Mounts:
      /usr/share/nginx/html from nginx-htmldir (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-9m6nh (ro)
. . . 
Volumes:
  nginx-htmldir:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  pvc-nginx
    ReadOnly:   false
. . . 
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  3m    default-scheduler  Successfully assigned default/nginx-pod-using-pvc to minikube
  Normal  Pulled     3m    kubelet, minikube  Container image "nginx:alpine" already present on machine
  Normal  Created    3m    kubelet, minikube  Created container
  Normal  Started    3m    kubelet, minikube  Started container
```

Let's quickly check if there is something on the hostPath on the worker node. There is nothing yet.

```
$ minikube ssh

$ sudo -i

# ls -la /opt/data/
total 0
drwxr-xr-x 2 root root 0 Mar 12 13:23 .
drwxr-xr-x 5 root root 0 Mar 12 13:23 ..
```

Remember, our volume is empty at this time. So nginx will not have any `index.html` file under `/usr/share/nginx/html` directory inside the container.


```
$ kubectl exec -it nginx-pod-using-pvc /bin/sh
/ # ls -l /usr/share/nginx/html/
total 0
/ # 
```


Let's create a file in this directory, while we are inside the nginx container.

```
/ # echo "Nginx! webcontent to see PV and PVC in action" > /usr/share/nginx/html/index.html 
```

As soon as you create the file in the container, you will see that this file pop up on the hostPath on the worker node:

```
$ minikube ssh

$ ls -la /opt/data/
total 4
drwxr-xr-x 2 root root  0 Mar 12 14:27 .
drwxr-xr-x 5 root root  0 Mar 12 13:23 ..
-rw-r--r-- 1 root root 46 Mar 12 14:27 index.html
```


Check the nginx pod by accessing it through multitool:
```
$ kubectl exec -it multitool-5558fd48d4-pqkj5 bash

bash-4.4# curl 172.17.0.6
Nginx! webcontent to see PV and PVC in action
```


Delete the nginx pod:

```
$ kubectl delete pod nginx-pod-using-pvc
pod "nginx-pod-using-pvc" deleted
```


Verify that the PV and PVC still exist:
```
$ kubectl get pv
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM               STORAGECLASS   REASON    AGE
pv-hostpath   100Mi      RWO            Retain           Bound     default/pvc-nginx                            15m

$ kubectl get pvc
NAME        STATUS    VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nginx   Bound     pv-hostpath   100Mi      RWO                           15m
```

Verify that the file still exists on the hostPath on the node:
```
$ minikube ssh

$ ls -la /opt/data/
total 4
drwxr-xr-x 2 root root  0 Mar 12 14:27 .
drwxr-xr-x 5 root root  0 Mar 12 13:23 ..
-rw-r--r-- 1 root root 46 Mar 12 14:27 index.html
```



Create the pod again.
```
$ kubectl create -f nginx-pod-using-pvc.yaml 
pod "nginx-pod-using-pvc" created

$ kubectl get pods -o wide
NAME                         READY     STATUS    RESTARTS   AGE       IP           NODE
multitool-5558fd48d4-pqkj5   1/1       Running   0          2d        172.17.0.4   minikube
nginx-pod-using-pvc          1/1       Running   0          8s        172.17.0.5   minikube
```


Check if the files are there:
```
$ kubectl exec -it nginx-pod-using-pvc /bin/sh

/ # ls -l /usr/share/nginx/html/
total 4
-rw-r--r--    1 root     root            46 Mar 12 14:06 index.html

/ # cat  /usr/share/nginx/html/index.html 
Nginx! webcontent to see PV and PVC in action
/ # 
```

Great! So it works! 


### Persistent Volume / PV - based on NFS

When you have personal self installed kubernetes clusters (minikube / kubeadm, etc), then you don't have the option of persistent disks, such as the ones available in GCP, or AWS, or Azure, etc. In those situations, NFS can be very inexpensive and useful service to have on the network. Your pods can then use the NFS storage for persistent storage. Please note that for pods to be able to mount NFS shares from a NFS server, the worker nodes need to have a nfs client package present / installed. On minikube it is already installed. 

**Note:** On cloud provisioned clusters, NFS client is already enabled / installed on worker nodes. On kubeadm based systems , or any bare-metal installations, which you setup yourself, you will need to install nfs client utilities on worker nodes - yourself.

In this example, I have a NFS server running on the physical hosts I am running my (k8s) VMs on. It could actually be running anywhere in the network - even inside the kubernetes cluster - but it is much wiser to run it **outside** the kubernetes cluster. Below is how my NFS server is setup.


Note: Each directory inside `/home/nfsshare` will be considered a **PD** (persistent/physical disk), and will therefore be mapped-to/used-by a **PV** (persistent volume).

```
[root@kworkhorse ~]# mkdir -p /home/nfsshare/nginx-data

[root@kworkhorse ~ ]# cat /etc/exports
/home/nfsshare/nginx-data *(rw,no_root_squash)

[root@kworkhorse ~]# ls -l /home/nfsshare
total 4
drwxr-xr-x 2 root root 4096 Mar 13 08:35 nginx-data
```

```
[root@kworkhorse ~]# systemctl restart nfs

[root@kworkhorse ~]# systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; disabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Wed 2019-03-13 07:35:49 CET; 1s ago
  Process: 22464 ExecStopPost=/usr/sbin/exportfs -f (code=exited, status=0/SUCCESS)
  Process: 22463 ExecStopPost=/usr/sbin/exportfs -au (code=exited, status=0/SUCCESS)
  Process: 22462 ExecStop=/usr/sbin/rpc.nfsd 0 (code=exited, status=0/SUCCESS)
  Process: 22485 ExecStart=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SU>
  Process: 22473 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 22472 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 22485 (code=exited, status=0/SUCCESS)

Mar 13 07:35:49 kworkhorse.oslo.praqma.com systemd[1]: Starting NFS server and services...
Mar 13 07:35:49 kworkhorse.oslo.praqma.com systemd[1]: Started NFS server and services.
[root@kworkhorse ~]#
```

Here is the host side information - for completeness:

```
[root@kworkhorse ~]# virsh net-list 
 Name                 State      Autostart     Persistent
----------------------------------------------------------
 default              active     yes           yes
 k8s-kubeadm-net      active     yes           yes
 minikube-net         active     yes           yes


[root@kworkhorse ~]# virsh net-info minikube-net
Name:           minikube-net
UUID:           5235a6ca-b19a-4c52-91d2-8cd0797deedf
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         virbr1

[root@kworkhorse ~]# ip addr show | grep virbr1
29: virbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    inet 192.168.39.1/24 brd 192.168.39.255 scope global virbr1
[root@kworkhorse ~]# 

```

So now we know that from the VM I can safely reach this fixed IP `192.168.39.1` and I will always reach my physical host, and in-turn the nfs service.

 
Now, we will see how to use this NFS share directly inside an NFS pod for persistent storage - without creating a PV or PVC, etc.


```
$ cat support-files/hostPath-example-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nfs-example-pod
spec:
  containers:
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: web-volume
      mountPath: /usr/share/nginx/html
  volumes:
  - name: web-volume
    nfs:
      # directory location on host
      server: 192.168.39.1
      path: /home/nfsshare/nginx-data
```


Create the pod:
```
$ kubectl create -f nfs-example-pod.yaml 
pod "nfs-example-pod" created


$ kubectl get pods -o wide
NAME                         READY     STATUS    RESTARTS   AGE       IP           NODE
multitool-5558fd48d4-pqkj5   1/1       Running   0          3d        172.17.0.4   minikube
nfs-example-pod              1/1       Running   0          3s        172.17.0.5   minikube
```

Examine the pod to make sure that we have NFS share mounted correctly:

```
$ kubectl describe pod nfs-example-pod
Name:               nfs-example-pod
Status:             Running
IP:                 172.17.0.5
Containers:
  web-server:
    Image:          nginx:alpine
. . . 
    Mounts:
      /usr/share/nginx/html from web-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-9m6nh (ro)
. . . 
Volumes:
  web-volume:
    Type:      NFS (an NFS mount that lasts the lifetime of a pod)
    Server:    192.168.39.1
    Path:      /home/nfsshare/nginx-data
    ReadOnly:  false
. . .
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  1m    default-scheduler  Successfully assigned default/nfs-example-pod to minikube
  Normal  Pulled     1m    kubelet, minikube  Container image "nginx:alpine" already present on machine
  Normal  Created    1m    kubelet, minikube  Created container
  Normal  Started    1m    kubelet, minikube  Started container
```

The mount point should be empty right now, both inside the pod, and also in the NFS share on the physical host.

```
$ kubectl exec -it nfs-example-pod /bin/sh

/ # ls -l /usr/share/nginx/html/
total 0
```

```
[root@kworkhorse ~]# ls -l /home/nfsshare/nginx-data/
total 0
```

Lets create a file inside the pod:

```
$ kubectl exec -it nfs-example-pod /bin/sh


/ # echo "NGINX - NFS direct mount example!" > /usr/share/nginx/html/index.html

/ # cat  /usr/share/nginx/html/index.html 
NGINX - NFS direct mount example!
```

On the NFS server, we see that the file is visible:

```
[root@kworkhorse ~]# ls -l /home/nfsshare/nginx-data/
total 4
-rw-r--r-- 1 root root 34 Mar 13 08:59 index.html
```

Check from our trusted multitool:
```
$ kubectl exec -it multitool-5558fd48d4-pqkj5 bash

bash-4.4# curl 172.17.0.5
NGINX - NFS direct mount example!
```

Kill the pod:

```
$ kubectl delete pod nfs-example-pod
pod "nfs-example-pod" deleted

$ kubectl get pods 
NAME                         READY     STATUS    RESTARTS   AGE
multitool-5558fd48d4-pqkj5   1/1       Running   0          3d
```


Re-create the pod so we see that it mounts the same NFS share:
```
$ kubectl create -f nfs-example-pod.yaml 
pod "nfs-example-pod" created

$ kubectl get pods -o wide
NAME                         READY     STATUS    RESTARTS   AGE       IP           NODE
multitool-5558fd48d4-pqkj5   1/1       Running   0          3d        172.17.0.4   minikube
nfs-example-pod              1/1       Running   0          7s        172.17.0.5   minikube
```


Checking from multitool should be enough. If it works, we know that the pod has mounted the NFS share correctly!

```
$ kubectl exec -it multitool-5558fd48d4-pqkj5 bash

bash-4.4# curl 172.17.0.5
NGINX - NFS direct mount example!
```


It works!

So we have see how we can use NFS share directly inside the pod and have data persistence! But, you have noticed that this can become very complicated if every pod needs to have the name of the NFS server and the share name, and if something changes at NFS level, then everything dependent on this information will need to be changed. So now, we will see how can we create PV and PVC out of this NFS share and use it inside the pod.


### PV and PVC using NFS:

(to do)






-------------------

# Automatic / Dynamic provisionsing:

List the available storage classes:

```shell
kubectl get storageclass
```

Create a claim for a dynamically provisioned volume (PVC) for nginx. 

```shell
$ kubectl create -f support-files/pvc-nginx.yaml
```

Check that the PVC exists and is bound:

```shell
$ kubectl get pvc
```

Example:

```shell
$ kubectl get pvc
NAME        STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nginx   Bound     pvc-e8a4fc89-2bae-11e8-b065-42010a8400e3   5Gi        RWO            standard       4m
```

There should be a corresponding auto-created persistent volume (PV) against this PVC:

```shell
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM               STORAGECLASS   REASON    AGE
pvc-e8a4fc89-2bae-11e8-b065-42010a8400e3   5Gi        RWO            Delete           Bound     default/pvc-nginx   standard                 5m
```

We are going to use the file `support-files/nginx-persistent-storage.yaml` file to use storage/volume directives:

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      volumes:
      - name: nginx-htmldir-volume
        persistentVolumeClaim:
          claimName: pvc-nginx
      containers:
      - name: nginx
        image: nginx:1.9.1
        ports:
        - containerPort: 443
        - containerPort: 80
        volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: nginx-htmldir-volume
```

Deploy nginx again. 

```shell
$ kubectl create -f support-files/nginx-persistent-storage.yaml
```

After it starts, you may want to examine it by using `kubectl describe pod nginx` and look out for volume declarations.

Now, you access the Nginx instance using curl. You should get a "403 Forbidden", because now the volume you mounted is empty.

> Hint. You learned about exposing deployments on the network in the [service
> discovery](02-service-discovery-and-loadbalancing.md) exercise.

Try to reach the nginx pod by executing a bash shell inside a multitool pod.

> Hint. You learned about the multitool and running command inside a container pod in the [service
> discovery](02-service-discovery-and-loadbalancing.md) exercise.

```shell
$ kubectl exec -it multitool-<ID> bash
bash-4.4# curl 10.0.96.7
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.9.1</center>
</body>
</html>
bash-4.4# 
```

Exit the multitool pod again.

Create a file in the htmldir inside the nginx pod and add some text in it:

```shell
$ kubectl exec -it nginx-deployment-6665c87fd8-cc8k9 -- bash

root@nginx-deployment-6665c87fd8-cc8k9:/# echo "<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage."  > /usr/share/nginx/html/index.html
root@nginx-deployment-6665c87fd8-cc8k9:/#
```

Exit the nginx pod again. From the multitool container, run curl again, you should see the web page:

```shell
$ kubectl exec -it multitool-69d6b7fc59-gbghn bash

bash-4.4#
 curl 10.0.96.7
<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage.
bash-4.4#
```

Kill the pod:

```shell
$ kubectl delete pod nginx-deployment-6665c87fd8-cc8k9
pod "nginx-deployment-6665c87fd8-cc8k9" deleted
```

Check if it is up (notice a new pod):

```shell
$ kubectl get pods -o wide
NAME                                READY     STATUS    RESTARTS   AGE       IP          NODE
multitool-69d6b7fc59-gbghn          1/1       Running   0          10m       10.0.97.8   gke-dcn-cluster-2-default-pool-4955357e-txm7
nginx-deployment-6665c87fd8-nh7bs   1/1       Running   0          1m        10.0.96.8   gke-dcn-cluster-2-default-pool-4955357e-8rnp
```

Again, from multitool, curl the new nginx pod. You should see the page you created in previous step:

```shell
$ kubectl exec -it multitool-69d6b7fc59-gbghn bash
bash-4.4# curl 10.0.96.8
<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage.
bash-4.4# 
```

## Clean up

```shell
$ kubectl delete deployment multitool
$ kubectl delete deployment nginx-deployment
$ kubectl delete service nginx-deployment
$ kubectl delete pvc pvc-nginx
```
