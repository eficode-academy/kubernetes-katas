# kubernetes-katas
Deliberate exercises for Kubernetes.

Below are some exercises ordered in the way we think it makes sence to introduce
Kubernetes concepts.  There are tree variants of the ingress exercise - one of
them is Google Kubernetes Engine (gke) specific, whereas the two others are
generic and should work on any Kubernetes cluster.

You can find a summary of many of the commands used in the exercises in the
[cheatsheet.md](cheatsheet.md).

* [Setup kubectl](00-setup-kubectl.md)
* [01-pods-deployments.md](01-pods-deployments.md)
* [01-service-discovery-and-loadbalancing.md](01-service-discovery-and-loadbalancing.md)
* [03-rolling-updates.md](03-rolling-updates.md)
* [04-secrets-configmaps.md](04-secrets-configmaps.md)
* [05-storage.md](05-storage.md)
* [06-ingress-gke.md](06-ingress-gke.md)
* [06-ingress-nginx.md](06-ingress-nginx.md)
* [06-ingress-traefik.md](06-ingress-traefik.md)
* [07-healthchecks.md](07-healthchecks.md)
* [08-helm-package-manager.md](08-helm-package-manager.md)
* [09-secrets-ssl-certs-in-nginx.md](09-secrets-ssl-certs-in-nginx.md)

* [Setup your own cluster with kubeadm](beyond-this-course-setting-up-your-own.md)
* [Spinup a Sock-Shop application with Grafana and Prometheus monitoring](sock-shop/README.md)