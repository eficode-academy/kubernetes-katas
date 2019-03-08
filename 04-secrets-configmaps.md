# Kubernetes secrets and Config maps

In this example, we want to run nginx which listens on port 443, by using some self-signed SSL certificates. This involves:
* providing SSL certificates to nginx pods, and,
* providing a custom nginx configuration, so the pods know how to use these certificates and what port to listen on.

To achieve these objectives, we will create SSL certs as secrets, and a custom nginx configuration as configmap, and use them in our deployment.



Generate self signed certs: (check support-files/  directory)
```
./generate-self-signed-certs.sh
```
This will create `tls.*` files.


Create  (tls type) secret for nginx:

```
kubectl create secret tls nginx-certs --cert=tls.crt --key=tls.key
```

Examine the secret you just created:
```
kubectl describe secret nginx-certs
```

```
kubectl get secret nginx-certs -o yaml
```


Create a custom configuration nginx: (check support-files/  directory)

```
$ cat support-files/nginx-connectors.conf
server {
    listen       80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}

server {
    listen       443;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    ssl on;
    ssl_certificate /certs/tls.crt;
    ssl_certificate_key /certs/tls.key;
}
```


```
kubectl create configmap nginx-config --from-file=support-files/nginx-connectors.conf
```

Examine the configmap you just created:

```
kubectl describe configmap nginx-config
```

```
kubectl get configmap nginx-config -o yaml
```


Create a nginx deployment with SSL support using the secret and config map you created in the previous steps (above): (check support-files/  directory)

```
$ cat support-files/nginx-ssl.yaml 
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx
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
      containers:
      - name: nginx
        image: nginx:1.15.1
        ports:
        - containerPort: 443
        - containerPort: 80
        volumeMounts:
        - mountPath: /certs
          name: certs-volume
        - mountPath: /etc/nginx/conf.d
          name: config-volume
```


```
kubectl create -f nginx-ssl.yaml
```

You should be able to see nginx running. Expose it as a service and curl it from your computer. You can also curl it through the multitool pod from within the cluster.




