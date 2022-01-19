# Kubernetes storage (PV and PVC):

List the available storage classes:

```shell
$ kubectl get storageclass
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

> NB: if it's not bound, try to `describe` it and see the message?
>
> Notice the output from `kubectl get storageclass`, if it says
> `VOLUMEBINDINGMODE=WaitForFirstConsumer`
> then you need a Pod or Deployment to "use" it first.
> There's a deployment like that, a couple of lines down from here.


There should be a corresponding auto-created persistent volume (PV) against this PVC:

```shell
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM               STORAGECLASS   REASON    AGE
pvc-e8a4fc89-2bae-11e8-b065-42010a8400e3   5Gi        RWO            Delete           Bound     default/pvc-nginx   standard                 5m
```

We are going to use the file `support-files/nginx-persistent-storage.yaml` file to use storage/volume directives:

```yaml,k8s
apiVersion: apps/v1
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

Now, try to access the Nginx instance using curl. You should get a "403 Forbidden", because now the volume you mounted is empty.

> Hint. In order to access the nginx instance, you can expose the nginx deployment on a NodePort as we learned in the [service
> discovery](02-service-discovery-and-loadbalancing.md) exercise. And afterwards you can curl it on the NodePort from any computer connected at the Internet and that has curl.

Create a file in the `html` dir inside the nginx pod and add some text in it:

```shell
$ kubectl exec -it nginx-deployment-6665c87fd8-cc8k9 -- bash

root@nginx-deployment-6665c87fd8-cc8k9:/# echo "<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage."  > /usr/share/nginx/html/index.html
root@nginx-deployment-6665c87fd8-cc8k9:/#
```

Exit the nginx pod again. Run curl again, you should see the web page:

```shell
$ curl 35.205.60.29:32078
<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage.
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
nginx-deployment-6665c87fd8-nh7bs   1/1       Running   0          1m        10.0.96.8   gke-dcn-cluster-2-default-pool-4955357e-8rnp
```

Again, curl the new nginx pod. You should see the page you created in previous step:

```shell
$ curl 35.205.60.29:32078
<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage.
```

## Clean up

```shell
$ kubectl delete deployment nginx-deployment
$ kubectl delete service nginx-deployment
$ kubectl delete pvc pvc-nginx
```
