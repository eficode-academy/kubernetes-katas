[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)][gitpod]

# kubernetes-katas

A selection of [katas][kata-def] for Kubernetes (K8s).

The exercises are ordered in the way we think it makes sense to introduce
Kubernetes concepts.

There are three variants of the ingress exercise - one of them is Google
Kubernetes Engine (gke) specific, whereas the two others are generic and should
work on any Kubernetes cluster.

You can find a summary of many of the commands used in the exercises in the
[cheatsheet.md](cheatsheet.md).

> :exclamation: The katas expect that you have access to a kubernetes cluster.
> Please have a look at the [Setup](#setup) section if that is not the case.
> There are plenty of free and easy options.

## Katas

- [01-pods-deployments.md](01-pods-deployments.md)
- [02-declarative-deployment.md](02-declarative-deployment.md)
- [03-service-discovery-and-loadbalancing.md](03-service-discovery-and-loadbalancing.md)
- [04-rolling-updates.md](04-rolling-updates.md)
- [05-secrets-configmaps.md](05-secrets-configmaps.md)
- [06-storage.md](06-storage.md)
- [07-healthchecks.md](07-healthchecks.md)

## Extra Credits

- Ingress
  - [08-ingress-gke.md](extras/08-ingress-gke.md)
  - [08-ingress-nginx.md](extras/08-ingress-nginx.md)
  - [08-ingress-traefik.md](extras/08-ingress-traefik.md)
- [09-helm-package-manager.md](extras/09-helm-package-manager.md)
- [10-secrets-ssl-certs-in-nginx.md](extras/10-secrets-ssl-certs-in-nginx.md)

## Setup

There are several ways to get a free Kubernetes cluster for running the
exercises.

Both [Amazon][eks], [Google][gke], [Microsoft][aks] and [Oracle][oke] provide
various degrees of free managed clusters.

Alternatively, you can set up a local cluster with [Docker
Desktop][docker-desktop] or [Kind][kind].

Once you have access to a cluster, the following exercises will help you get
setup for running the katas.

- [00-setup-kubectl-linux](exercise_setup/00-setup-kubectl-linux.md) - Skip if
  you've already installed `kubectl` and have access to a cluster.
- [00-setup-namespace](exercise_setup/00-setup-namespace.md) - Skip if you've
  already created a personal namespace and set it as your default.

### kubectl autocompletion

On Linux, using bash, run the following commands:

```shell
echo "source <(kubectl completion bash)" >> ~/.bashrc
. ~/.bashrc
```

The commands above will enable kubectl autocompletion when you start a new bash
session and source (reload) bashrc i.e. enable kubectl autocompletion in your
current session.

See: [Kubernetes.io - Enabling shell autocompletion][autocompletion] for more
info.

# Cheatsheet

A collection of useful commands to use throughout the exercises:

```
kubectl api-resources         # List resource types


kubectl explain <resource>    # Show information about a resource
kubectl explain deployment


# List resources in cluster
kubectl get <resource>                    # In current namespace
kubectl get <resource> -n <namespace>     # In specific namespace
kubectl get <resource> --all-namespaces   # In all namespaces
kubectl get <resource> -o wide            # Add extended information
kubectl get <resource> -o yaml            # output in YAML format
kubectl get <resource> -o json            # output in JSON format

# Example
kubectl get pods [-n abc|--all-namespaces] [-o wide|yaml|json]

```

See:
[kubectl - Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
for a more extended overview of the `kubectl` command.

[gitpod]: https://gitpod.io/#https://github.com/eficode-academy/kubernetes-katas
[kata-def]: https://en.wikipedia.org/wiki/Kata
[eks]: https://aws.amazon.com/ecs/pricing/
[gke]:
  https://cloud.google.com/kubernetes-engine/pricing#cluster_management_fee_and_free_tier
[aks]: https://azure.microsoft.com/en-us/pricing/free-services/
[oke]: https://www.oracle.com/cloud/free/#free-cloud-trial
[docker-desktop]: https://docs.docker.com/desktop/
[kind]: https://kind.sigs.k8s.io/
[autocompletion]:
  https://kubernetes.io/docs/tasks/tools/install-kubectl/#enabling-shell-autocompletion
