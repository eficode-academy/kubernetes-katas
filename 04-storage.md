# Kubernetes storage (PV and PVC):

Check the storage class:
```
kubectl get storageclass
```

Create a Dynamically Provisioned PVC for nginx:
```
kubectl create -f pvc-nginx.yaml
```

Check that the PVC exists and is bound:
```
kubectl get pvc
```

Example:
```
[demo@kworkhorse exercises]$ kubectl get pvc
NAME        STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nginx   Bound     pvc-e8a4fc89-2bae-11e8-b065-42010a8400e3   5Gi        RWO            standard       4m
[demo@kworkhorse exercises]$
```

There should be a corresponding (auto-created) PV against this PVC:
```
[demo@kworkhorse exercises]$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM               STORAGECLASS   REASON    AGE
pvc-e8a4fc89-2bae-11e8-b065-42010a8400e3   5Gi        RWO            Delete           Bound     default/pvc-nginx   standard                 5m
[demo@kworkhorse exercises]$ 
```


Update your nginx-ssl.yaml file to update storage/volume directives:
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
      - name: certs-volume
        secret:
          secretName: nginx-certs
      - name: config-volume
        configMap:
          name: nginx-config
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
        - mountPath: /certs
          name: certs-volume
        - mountPath: /etc/nginx/conf.d
          name: config-volume
        - mountPath: "/usr/share/nginx/html"
          name: nginx-htmldir-volume
```

Deploy nginx again. After it starts, you may want to examine it by using `kubectl describe pod nginx`.


Now, you can curl it. You should get a "403 Forbidden", because now the volume you mounted is empty.

```
[demo@kworkhorse exercises]$ kubectl exec -it multitool-69d6b7fc59-gbghn bash
[root@multitool-69d6b7fc59-gbghn /]# curl 10.0.96.7
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.9.1</center>
</body>
</html>
[root@multitool-69d6b7fc59-gbghn /]# 
```

Create a file in the htmldir inside the nginx pod:

```
[demo@kworkhorse exercises]$ kubectl exec -it nginx-deployment-6665c87fd8-cc8k9 bash

root@nginx-deployment-6665c87fd8-cc8k9:/# echo "<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage. This should exist no matter how many times we kill this pod. <HR><b>We NEVER lose</b>" > /usr/share/nginx/html/index.html
root@nginx-deployment-6665c87fd8-cc8k9:/#
```

From the multitool, curl again , you should see the web page:
```
[demo@kworkhorse exercises]$ kubectl exec -it multitool-69d6b7fc59-gbghn bash

[root@multitool-69d6b7fc59-gbghn /]#
 curl 10.0.96.7
<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage. This should exist no matter how many times we kill this pod. <HR><b>We NEVER lose</b>
[root@multitool-69d6b7fc59-gbghn /]#
```

Kill the pod:
```
[demo@kworkhorse exercises]$ kubectl delete pod nginx-deployment-6665c87fd8-cc8k9
pod "nginx-deployment-6665c87fd8-cc8k9" deleted
[demo@kworkhorse exercises]$ 
```

Check if it is up (notice a new pod):
```
[demo@kworkhorse exercises]$ kubectl get pods -o wide
NAME                                READY     STATUS    RESTARTS   AGE       IP          NODE
multitool-69d6b7fc59-gbghn          1/1       Running   0          10m       10.0.97.8   gke-dcn-cluster-2-default-pool-4955357e-txm7
nginx-deployment-6665c87fd8-nh7bs   1/1       Running   0          1m        10.0.96.8   gke-dcn-cluster-2-default-pool-4955357e-8rnp
[demo@kworkhorse exercises]$
```

Again, from multitool, curl the new nginx pod. You should see the page you created in previous step:
```
[demo@kworkhorse exercises]$ kubectl exec -it multitool-69d6b7fc59-gbghn bash
[root@multitool-69d6b7fc59-gbghn /]# curl 10.0.96.8
<h1>Welcome to Nginx</h1>This is Nginx with html directory mounted as a volume from GCE Storage. This should exist no matter how many times we kill this pod. <HR><b>We NEVER lose</b>
[root@multitool-69d6b7fc59-gbghn /]# 
```

**It works!**

