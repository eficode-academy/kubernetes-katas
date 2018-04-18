# Ingress on google cloud

GoogleKubernetesEngine (GKE) does Ingress a bit differently. For reference, those brave of you who want to play with Minikube, I have two more you can do - [nginx](03-ingress-nginx.md) and [traefik](03-ingress-traefik.md).

However because we are running things on GKE, we are going to focus on that today. 

An ingress is loosely translatable to DNS namespace, and makes it so that: 
- Traffic to port 80 (http) and port 443 (https) goes to ingress rules instead AND
- A name call to (example) myapplication.example.local gets translated to an IP and then routed to a container.


Create an nginx deployment and service, exposing the service as a nodeport. If you need a hint as to how this is done, look at [the getting started](01-getting-started.md).

GKE automatically exposes NodePorts through a Loadbalancer, but the 'correct' way is the ingress rule, which will work on all infrastructure. 

Google cloud need an address created. All the steps running gcloud commands, are unusual and can be disregarded for a normal Kubernetes setup outside of GKE. 

```
gcloud compute addresses create <my-name> --global
```
Ingress can be told by annotation, where the source request came from. This is useful when going through multiple networks, as the ingress rule then understand things like sticky sessions and other networking things like SSL termination and so on. 

```
annotations:
  kubernetes.io/ingress.global-static-ip-name: "my-name"
```

The above only works for GKE, but an equivalent for nginx would look like this: 

```
annotations:
  kubernetes.io/ingress.class: "nginx"
  nginx.org/ssl-services: "my-service"
```

So lets make the following ingress: 

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "my-name"
spec:
  backend:
    serviceName: nginx
    servicePort: 80
```

And create it! 
```
kubectl apply -f ingressfile.yml
```

Find it in the Kubernetes cluster (hint, get ing nginx)

The address bit, should match what the following command outputs: 
```
gcloud compute addresses \
  describe kubernetes-ingress --global \
  --format='value(address)'
```

You should be able to visit this address, and see the nginx homesite! 

Normally you *COULD* add a dns rule, and say "I want nginx.local to route to this container" and it would look something like this: 
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
  - host: nginx.local
    http:
      paths:
      - path: /
        backend:
          serviceName: ingress-test
          servicePort: replaceport
```

Because GKE "makes ingress easy", these things need a DNS setup on GKE which we are not going to do. But this should give an impression of ingress. 

I thoroughly recommend looking at minikube and ingress, if you plan to use this more extensively.