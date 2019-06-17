# Ingress - Traefik

In the previous exercises, you that Kubernetes provides service discovery for any services within the cluster. So any pod can reach any service just by using a certain service name or a DNS name - visible only within the cluster. But, what about traffic coming in from outside? Well, Kubernetes has a special object to receive/handle traffic coming in from the internet - called **Ingress**. Ingress is a DNS look-alike and it enables you to define DNS names for the services you want to access from outside the cluster network. 

For example, you have a nginx web server, which you want to reach from the internet by using the DNS name `nginx.example.com`, or as `www.example.com`. You may also have a custom application handling bookings from the internet, and the DNS name for this service would be `booking.example.com` . Of-course you can define these services as `type: LoadBalancer`, update your DNS on the internet, and reach them from the internet. For a couple of services it may be ok, but if you have many services, then there would be many *load balancers* you would be creating. Load balancers cost extra on any cloud provider. It is also a hassle to maintain the IP address of each new load balancer and update various DNS entries in your DNS zone files. 

Traefik provides an easier way to achieve what is described above. Traefik is an **inggress controller**. It means that it looks for any *ingress* objects inside the cluster, and sets up a frontend-backend maps for them. By using an ingress controller, you do not need to expose all of your services as load balancers. Instead, you can define all your services as `type: ClusterIP`, with an *ingress* object defined on top of them. Then, you only define the **traefik service** as `type: LoadBalancer`. By doing this it receives/handles traffic coming in from the internet for - say - `nginx.example.com`, `www.example.com`, `booking.example.com`, `traefik.example.com`, etc, and routes them to correct backends, on correct ports. 

Traefik takes care of things like load balancing traffic, terminating SSL, auto discovery, tracing, metrics, etc. Full detail about Traefik can be found here: [https://traefik.io/](https://traefik.io/)

If you want to use nginx as reverse proxy, then there is a separate exercise available in this repository.

Reference for Kubernetes specific configuration: [https://docs.traefik.io/user-guide/kubernetes/](https://docs.traefik.io/user-guide/kubernetes/)

## RBAC configuration:
For Kubernetes 1.6+ , RBAC is enabled by default. For Traefik to work correctly, we have to give it necessary permissions. We start by Creating necessary RBAC rules/bindings for Traefik. 

Create a file named `traefik-rbac.yaml` with the following contents. This will setup a service account and correct global cluster role binding.

```
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
- kind: ServiceAccount
  name: traefik-ingress-controller
  namespace: kube-system
```

Create the traefik RBAC configuration using:
```
kubectl create -f ingress-traefik/traefik-rbac.yaml
```

## Deploy Traefik:
Create a file named `traefik-deployment.yaml` with the following contents.

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik-ingress-controller
  namespace: kube-system
---
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: traefik-ingress-controller
  namespace: kube-system
  labels:
    k8s-app: traefik-ingress-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: traefik-ingress-controller
  template:
    metadata:
      labels:
        k8s-app: traefik-ingress-controller
        name: traefik-ingress-controller
    spec:
      serviceAccountName: traefik-ingress-controller
      terminationGracePeriodSeconds: 60
      containers:
      - image: traefik
        name: traefik-ingress-controller
        ports:
        - name: http
          containerPort: 80
        - name: https
          containerPort: 443
        - name: webui
          containerPort: 8080
        args:
        - --api
        - --kubernetes
        - --logLevel=INFO
---
kind: Service
apiVersion: v1
metadata:
  name: traefik-ingress-service
  namespace: kube-system
spec:
  selector:
    k8s-app: traefik-ingress-controller
  ports:
    - name: http
      port: 80
      protocol: tcp
    - name: https
      port: 443
      protocol: tcp
    # We don't need to define the webui port in the traefik service,
    #   as it will never be used from outside through this service.
    # Port 8080 will be reached through a separate ingress, which uses a separate service,
    #   defined separately. (further below)
    #- name: webui
    #  port: 8080
    #  protocol: tcp

  type: LoadBalancer
```
**Note:** You can also use type: **NodePort** in the Service section above. 


Create the objects defined in the `traefik-deployment.yaml`:
```
kubectl create -f ingress-traefik/traefik-deployment.yaml
```


## Create Ingress for Traefik Web-UI:
Create a file `traefik-webui-ingress.yaml` with the following contents to create a Service and an Ingress that will expose the Traefik Web UI.
```
apiVersion: v1
kind: Service
metadata:
  name: traefik-web-ui
  namespace: kube-system
spec:
  selector:
    k8s-app: traefik-ingress-controller
  ports:
  - name: http
    port: 80
    targetPort: 8080
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: traefik-web-ui
  namespace: kube-system
spec:
  rules:
  - host: traefik-ui.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: traefik-web-ui
          servicePort: http
``` 

Create the objects:
```
kubectl create -f traefik-webui-ingress.yaml
```


You can check the public IP of the Traefik service, and on your local computer, edit the `/etc/hosts` file to set up name resolution for this IP as:

```
127.0.0.1   	localhost localhost.localdomain
35.240.21.22	traefik-ui.example.com www.example.com nginx.example.com booking.example.com 
```

OR. If you have a domain under your control, setup DNS accordingly. You can use any other DNS name for your setup other than example.com. 

Now visit the address `traefik-ui.example.com` , you should see a dashboard.

![](ingress-traefik/traefik-dashboard.png)

## Setup additional ingress for your application(s):
Its time to setup an additional service for any of our application. For now, I will use a simple nginx web server. Create a file examplenginx-deployment.yaml with the following contents:

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.9
        ports:
        - containerPort: 80

---

apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    name: nginx
    app: nginx
spec:
  ports:
    - port: 80
  selector:
    app: nginx

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  namespace: default
  name: example-nginx-ingress
  labels:
    app: nginx
spec:
  rules:
  - host: www.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: nginx
          servicePort: 80
```

Create the objects from the above file:

```
kubectl create -f ingress-traefik/example-nginx-deployment.yaml
```


If you visit the Traefik dashboard now, you should be able to see a new ingress pop up. Visit the web page [http://www.example.com](http://www.example.com) to verify that you can access the nginx web server.

![](ingress-traefik/nginx-on-traefik-dashboard.png)


Visiting [http://www.example.com](http://www.example.com) should show nginx webpage:

```
[kamran@kworkhorse kubernetes-katas]$ curl www.example.com
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
[kamran@kworkhorse kubernetes-katas]$ 
```

