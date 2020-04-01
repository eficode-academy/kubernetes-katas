# Kubernetes storage (PV and PVC):

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

> Hint. You learned about exposing deployments on a NodePort in the [service
> discovery](02-service-discovery-and-loadbalancing.md) exercise.
> 
> Hint 2. You can curl the nodeport from any device you have access to from the internet; Your machine, your cloud instance, or the multitool container in the cluster. You learned about the multitool and running command inside a container pod in the [service discovery](02-service-discovery-and-loadbalancing.md) exercise.

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

Exit the multitool pod again if you are using that.

Create a file in the `html` dir inside the nginx pod and add some text in it:

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

Again, from multitool, curl the new nginx pod. You should see the page you created in the previous step:

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
