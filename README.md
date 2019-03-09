# kubernetes-katas

A selection of exercises for Kubernetes (K8s).

The exercises are ordered in the way we think it makes sense to introduce Kubernetes concepts.


There are three variants of the ingress exercise - one of them is Google Kubernetes Engine (gke) specific, whereas the two others are generic and should work on any Kubernetes cluster.

You can find a summary of many of the commands used in the exercises in the [cheatsheet.md](cheatsheet.md).

## Setup

* [00-setup-kubectl-linux](00-setup-kubectl-linux.md) -
    Skip if you've already installed `kubectl` and have access to a cluster.
* [00-setup-namespace](00-setup-namespace.md) -
    Skip if you've already created a personal namespace and set it as your default.

## Exercises

* [01-pods-deployments-services-namespaces.md](01-pods-deployments-services-namespaces.md)
* [02-init-and-multi-container-pods.md](02-init-and-multi-container-pods.md)
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

## [Optional] kubectl command autocompletion

On Linux, using bash, run the following commands:

```shell
$ echo "source <(kubectl completion bash)" >> ~/.bashrc
$ . ~/.bashrc
```

The commands above will enable kubectl autocompletion when you start a new bash session and source (reload) bashrc i.e. enable kubectl autocompletion in your current session.

See [Kubernetes.io - Enabling shell autocompletion](https://kubernetes.io/docs/tasks/tools/install-kubectl/#enabling-shell-autocompletion) for more info.

# Command Cheatsheet

A collection of useful commands to use throughout the exercises:

```shell
$ kubectl api-resources         # List resource types


$ kubectl explain <resource-type>    # Show information about a resource, not to confuse with "describe"
$ kubectl explain pod


# List resources in cluster
$ kubectl get <resource-type> [resource-name]    # In current namespace
$ kubectl get <resource-type> -n <namespace>     # In specific namespace
$ kubectl get <resource> --all-namespaces   # In all namespaces
$ kubectl get <resource> -o wide            # Add extended information
$ kubectl get <resource> -o yaml            # output in YAML format
$ kubectl get <resource> -o json            # output in JSON format

# Describe a resource in detail
$ kubectl describe <resource-type> [resource-name]


# Examples
$ kubectl get pods 
$ kubectl get pods nginx-76542036-5431
$ kubectl describe pod nginx-76542036-5431

# Exec into a pod:
$ kubectl exec -it nginx-76542036-5431 /bin/sh


# Check logs of pod:
$ kubectl logs -f nginx-76542036-5431

# Check kubernetes events:
$ kubectl get events

```

See: [kubectl - Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) for a more extended overview of the `kubectl` command.
