# Ingress
If we look at Service as an endpoint, then the Kubernetes ingress object is a DNS.
It takes care of things like load balancing traffic, terminating SSL and naming among other things. 

To enable an ingress object, we need an ingress controller. In this example we will be using [Træfik](https://traefik.io/). If you prefer [NGINX there is another exercise doing it with NGINX](./03-ingress-nginx.md).

So, therefore we start with the ingress controller: 
```
kubectl create -f ingress-traefik/traefik-ingress-controller.yml
```

Ingress has a nice little GUI which shows current ingress rules and settings in a cluster, which we can take advantage of to create an overview. 

Create the service: 
```
kubectl create -f ingress-traefik/traefik-service.yml
```
... and the ingress rule: 
```
kubectl create -f ingress-traefik/traefik-ingress.yml
```

Instead of going through the trouble of setting up a proper DNS, we can modify the host file - below is an example of doing this for minikube:
```
echo "$(minikube ip) traefik-ui.local" | sudo tee -a /etc/hosts
```

To make it work for your cluster, replace the minikube ip with a node ip. 

Which means you can access it like by clicking http://traefik-ui.local

So the magic here is that: 
- You send a request which is translated to the node ip
- The node looks up the incoming name record and finds it in an ingress. 
- The ingress rule says that traffic from traefik-ui.local needs to go to backend service 'traefik-web-ui' on port 80
    * kubectl get svc traefik-web-ui -n kube-system
- The service then redirects to the container, in this case the ingress controller itself, on port 8080. 

Let's try with a different container. Deploy any given image and expose a service for it. 

```
kubectl run ingress-test --image=<your-image> --replicas=3
kubectl expose deployment ingress-test --port=<your-port>
```

Then [go to the ingress] and modify the port (servicePort: replaceport), followed by: 
```
kubectl create -f ingress-traefik/my-ingress.yml
echo "$(minikube ip) myapp.local" | sudo tee -a /etc/hosts
```

Access it on http://myapp.local. 

This concludes the exercise for ingress. 

