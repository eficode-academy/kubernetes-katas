# Storage

This exercise shows how to provide persistent storage to your pods, so your data is safe across pod creation cycles. You will learn ho to create **PVs** and **PVCs** and how to use **storage classes**.

## Automatic / Dynamic provisionsing:
A **storage class** has actual physical storage underneath it - provided/managed by the cloud provider; though, the storage class hides this information, and provides an abstraction layer for you. Normally, all cloud providers have a default storage class created for you, ready to be used.

**Note:** Minikube provides a `standard` storageclass of type `hostPath` out of the box. Kubeadm based clusters do not. 

When you want to provide some persistent storage to your pods, you define/create a persistent volume claim (PVC), which the pod consumes by the mounting this PVC at a certain mount point in the file system. As soon as the PVC is created (using dynamic provisioning), a corresponding persistent volume (PV) is created. The PV in-turn takes a slice of storage from the storage class, and as soon as it acquires this storage slice, it binds to the PVC. 


Lets check what classes are available to us:

```shell
$ kubectl get sc

NAME                 PROVISIONER		AGE
standard (default)   kubernetes.io/gce-pd	1d
```
Good, so we have a storage class named `standard` , which we can use to create PVCs and PVs.


Here is what storageclasses looks like on minikube - just for completeness sake: 
```
$ kubectl get storageclass
NAME                 PROVISIONER                AGE
standard (default)   k8s.io/minikube-hostpath   19d
```

**Note:** It does not matter if you are using GCP, AWS, Azure, minikube, kubeadm, etc. Till the time you have a name for the storage class - which you can use in your PVC claims, you have no concern about the underlying physical storage. So, if you have a pvc claim definition file,(like the one below), and you are using it to create PVC on a **minikube** cluster, you can simply use the same PVC claim file to create a PVC with the same name on a **GCP** cluster. The abstraction allows you to *develop anywhere, deploy anywhere* !


If you do not have a storage class, you can create/define it yourself. All you need to know is type of provisioner to use. Here is a definition file to create a storage class named **slow** on a GCP k8s cluster:

```
$ cat support-files/gcp-storage-class.yaml 

kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: slow
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
  replication-type: none
```

```
$ kubectl create -f support-files/gcp-storage-class.yaml
storageclass "slow" created
```

```
$ kubectl get sc

NAME                 PROVISIONER		AGE
standard (default)   kubernetes.io/gce-pd	1d
slow		     kubernetes.io/gce-pd	1h
```

## Create and use a PVC:

Lets create a claim for a dynamically provisioned volume (PVC) for nginx. Here is the file to create a PVC named `pvc-nginx`:
```shell
$ cat support-files/pvc-nginx.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nginx
  labels:
    name: pvc-nginx
spec:
  storageClassName: "standard"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
```

```shell
$ kubectl create -f support-files/pvc-nginx.yaml
```

Check that the PVC exists and is bound:

```shell
$ kubectl get pvc
NAME        STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nginx   Bound     pvc-e8a4fc89-2bae-11e8-b065-42010a8400e3   100Mi      RWO            standard       4m
```

There should be a corresponding auto-created persistent volume (PV) against this PVC:

```shell
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM               STORAGECLASS   REASON    AGE
pvc-e8a4fc89-2bae-11e8-b065-42010a8400e3   100Mi      RWO            Delete           Bound     default/pvc-nginx   standard                 5m
```
**Note:** Above may be confusing, and demands some explanation. The PVC has a name `pvc-nginx` , but since the PV is being created automatically, kubernetes cannot guess it's name, so it gives it a name which begins with **pvc** and gives it an ID. This ID is reflected in the **VOLUME**  column of the `kubectl get pvc` command.


Next, we are going to create a deployment, and it's pod will use this storage. Here is the file `support-files/nginx-persistent-storage.yaml` , which shows how it is defined in yaml format:

```
$ cat support-files/nginx-persistent-storage.yaml

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

Create the deployment: 

```shell
$ kubectl create -f support-files/nginx-persistent-storage.yaml
```

After the deployment is created and the pod starts, you should examine it by using `kubectl describe pod nginx`, and look out for volume declarations.

Optionally, create a service (of type ClusterIP) out of this deployment.

Run a multitool deployment if you don't have it running - to help you access nginx container:
```
$ kubectl run multitool --image=praqma/network-multitool 
```

Now you access the Nginx pod/service using curl from the multitool pod. You should get a "403 Forbidden". This is because PVC volume you mounted, is empty!

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
```

Exit the multitool pod and *exec* into the nginx pod.

Create an `index.html` file in the `/usr/share/nginx/html/` dirrectory, and add some text in it:

```shell
$ kubectl exec -it nginx-deployment-6665c87fd8-cc8k9 -- bash

root@nginx-deployment-6665c87fd8-cc8k9:/# echo "<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage."  > /usr/share/nginx/html/index.html
```

Exit the nginx pod. *exec* into the multitool container, again and run curl - again. This time, you should see the web page:

```shell
$ kubectl exec -it multitool-69d6b7fc59-gbghn bash

bash-4.4#
 curl 10.0.96.7
<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage.
bash-4.4#
```

Ok. Lets kill this nginx pod:

```shell
$ kubectl delete pod nginx-deployment-6665c87fd8-cc8k9
pod "nginx-deployment-6665c87fd8-cc8k9" deleted
```

Since the nginx pod was part of the deployment, it will be re-created, and the PVC volume will be mounted. 

Verify that the pod is up (notice a new pod id):

```shell
$ kubectl get pods -o wide
NAME                                READY     STATUS    RESTARTS   AGE       IP          NODE
multitool-69d6b7fc59-gbghn          1/1       Running   0          10m       10.0.97.8   gke-dcn-cluster-2-default-pool-4955357e-txm7
nginx-deployment-6665c87fd8-nh7bs   1/1       Running   0          1m        10.0.96.8   gke-dcn-cluster-2-default-pool-4955357e-8rnp
```

Again, from multitool, curl the new nginx pod. You should see the page you created in previous step - **not** `403 Forbidden`:

```shell
$ kubectl exec -it multitool-69d6b7fc59-gbghn bash

bash-4.4# curl 10.0.96.8
<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage.
bash-4.4# 
```

This proved that the volume behind the PVC retained the data even though the pod which used it was deleted.

**Note:** Since the goal of dynamic provisioning is to completely automate the lifecycle of storage resources, the default reclaim policy for dynamically provisioned volumes is **delete**. This means that when a PersistentVolumeClaim (PVC) is released, the dynamically provisioned volume is de-provisioned (deleted) on the storage provider and the data is likely irretrievable. If this is not the desired behavior, the user must change the reclaim policy on the corresponding PersistentVolume (PV) object after the volume is provisioned. You can change the reclaim policy by editing the PV object and changing the “persistentVolumeReclaimPolicy” field to the desired value.

## Clean up

```shell
$ kubectl delete deployment multitool
$ kubectl delete deployment nginx-deployment
$ kubectl delete service nginx-deployment
$ kubectl delete pvc pvc-nginx
```
