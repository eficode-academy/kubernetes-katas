# Kubernetes secrets and Config maps

This exercise is targeted towards both developers and system administrators. Most of the time developers are interested in passing certain types of secrets to the containers, such as usernames, passwords, API keys, etc. Similarly most of the time system administrators are interested in passing configuration files, keys, certificate files, etc to the containers. So this excercise has something for both situations.


## A simple .js application:
Our [maginificent app](./secrets/secretapp.js) requries an API key and a value for the variable `LANGUAGE`. Here is what our application looks like initially:

```
$ cat secrets/secretapp.js 
var http = require('http');
var server = http.createServer(function (request, response) {
  const LANGUAGE = 'English';
  const API_KEY = 'abc-123-456-789-xyz';
  response.write(`Language: ${LANGUAGE}\n`);
  response.write(`API Key: ${API_KEY}\n`);
  response.end(`\n`);
});
server.listen(3000);
```

Notice, we have hard-coded the values for API_KEY and LANGUAGE:

```
  const LANGUAGE = 'English';
  const API_KEY = 'abc-123-456-789-xyz';
```

Rather than hardcode this sensitive information and commit it to git repository for all the world to see, we should source these values from environment variables. 

The first step to fixing it, would be to make sure that our variables get their values from the process's environment. So, we change the code like this:

```shell
  const LANGUAGE = process.env.LANGUAGE;
  const API_KEY = process.env.API_KEY;
```

Lets create a Docker container for this app and pass these values as environment variables in the container:

```shell
$ cat secrets/Dockerfile

FROM node:9.1.0-alpine
EXPOSE 3000
ENV LANGUAGE English
ENV API_KEY abc-123-456-789-xyz
COPY secretapp.js .
ENTRYPOINT node secretapp.js
```

Lets run this Docker container image as a pod in our Kubernetes cluster. (This container image is available as `praqma/secrets-demo`). We can run that in our Kubernetes cluster by using the [the deployment file](secrets/deployment.yml). Here is what the deployment file looks like:

```
$ cat secrets/deployment.yml 
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: envtest
spec:
  replicas: 1
  template:
    metadata:
      labels:
        name: envtest
    spec:
      containers:
      - name: envtest
        image: praqma/secrets-demo
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
        env:
        - name: LANGUAGE
          value: Polish
        - name: API_KEY
          value: def-333-444-555-jkl
```

Notice the env values added at the bottom of the deployment file. Create/run the deployment:

```shell
$ kubectl apply -f secrets/deployment.yml
deployment.extensions/envtest created
```

Expose the deployment on a nodeport. Remember that this application runs on port `3000`.

```
$ kubectl get deployments
NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
envtest     1         1         1            0           14s
multitool   1         1         1            1           2h
nginx       4         4         4            4           2h

$ kubectl expose deployment envtest --type=NodePort
service/envtest exposed

$ kubectl get services
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE
envtest   NodePort       10.59.252.33    <none>          3000:30771/TCP   9s
nginx     LoadBalancer   10.59.240.197   146.148.21.83   80:32423/TCP     1h
```

Now, notice that despite the default value in the Dockerfile, it should now be overwritten by the values of environment variables in deployment  file! Though the problem still is, that we moved the hard coded values from our application code to the deployment file. The deployment file will of-course be part of the related git repository, and these variables and their values will be visible to anyone. We need to find a better way of passing the variables to the application/pod.

### Secrets using the kubernetes secret resource

Let's create the API key as a kubernetes **secret**:

```shell
$ kubectl create secret generic apikey --from-literal=API_KEY=def-333-444-555-jkl
secret/apikey created
```

Kubernetes supports different kinds of preconfigured secrets, but for now we'll deal with a generic one.

Similarly create `language` as kubernetes **configmap**:

```shell
$ kubectl create configmap language --from-literal=LANGUAGE=German
configmap/language created
```

Now run `kubectl get secets` and `kubectl get configmap` to see if these objects are created:

```shell
$ kubectl get secrets
NAME                  TYPE                                  DATA      AGE
apikey                Opaque                                1         4m
default-token-td78d   kubernetes.io/service-account-token   3         3h
```

```shell
$ kubectl get configmaps
NAME       DATA      AGE
language   1         2m
```

> Try to investigate the secret by using the kubectl describe command:
> ```shell
> $ kubectl describe secret apikey
> ```
> Note that the actual value of API_KEY is not shown. To see the encoded value use:
> ```shell
> $ kubectl get secret apikey -o yaml
> ```

Last step is to change the Kubernetes deployment (secrets/deployment.yml) file to use the secrets.

Change this:

```shell
        env:
        - name: LANGUAGE
          value: Polish
        - name: API_KEY
          value: def-333-444-555-jkl
```

To this:

```shell
        env:
        - name: LANGUAGE
          valueFrom:
            configMapKeyRef:
              name: language
              key: LANGUAGE
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: apikey
              key: API_KEY
```

After you have edited the `deployment.yml` file (or you can use the prepared one `secrets/final.deployment.yml`), you need to apply the new version of the file by using: `kubectl apply -f deployment.yml` .

You should now see the variables being loaded from configmap and secret respectively.

#### What happens when secrets and configmaps change?
Pods are not recreated automatically when serets or configmaps change. After you change the secrets and config maps values, you need to restart the pods which are using those secrets and config maps. 

Here is an example of changing/updating an existing secret and config map:
```shell
$ kubectl create configmap language --from-literal=LANGUAGE=German -o yaml --dry-run | kubectl replace -f -
configmap/language replaced

$ kubectl create secret generic apikey --from-literal=API_KEY=klm-333-444-555-pqr -o yaml --dry-run | kubectl replace -f -
secret/apikey replaced
```

Then delete the pod (so it's recreated with the replaced configmap and secret) :

```shell
$ kubectl delete pod envtest-3380598928-kgj9d
pod "envtest-3380598928-kgj9d" deleted
```

Access it in a web browser again, to see the updated values. You need the (external) IP of any of the worker nodes to reach this service over NodePort.

```
$ kubectl get nodes -o wide
NAME                                                  STATUS   ROLES    AGE   VERSION          INTERNAL-IP   EXTERNAL-IP     OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-ndc-oslo-training-cl-default-pool-654cdad8-5gpf   Ready    <none>   4h    v1.11.7-gke.12   10.123.0.8    104.155.27.73   Container-Optimized OS from Google   4.14.91+         docker://17.3.2
gke-ndc-oslo-training-cl-default-pool-654cdad8-g1qf   Ready    <none>   4h    v1.11.7-gke.12   10.123.0.7    35.233.51.246   Container-Optimized OS from Google   4.14.91+         docker://17.3.2
gke-ndc-oslo-training-cl-default-pool-654cdad8-r09t   Ready    <none>   4h    v1.11.7-gke.12   10.123.0.6    35.240.117.25   Container-Optimized OS from Google   4.14.91+         docker://17.3.2 
```


----------

## nginx web-server on SSL - uses secrets (as files) and configmaps (as files):
This example is more suited for system administrators. In this example, we want to run nginx web-server, which listens on port 443, by using some self-signed SSL certificates. This involves:

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




