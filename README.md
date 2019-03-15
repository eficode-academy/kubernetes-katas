# kubernetes-katas

This is a selection of exercises learn how to use Kubernetes (K8s). The exercises are ordered in the way we think it makes sense to introduce Kubernetes concepts.


You can find a summary of many of the commands used in the exercises in the [cheatsheet.md](cheatsheet.md).

## Important note about worker node resources:
In a group excercise, normally each student gets a single node cluster setup on a cloud platform (GCP). It is possible that the worker node is a small spec node (1 CPU and 1.7 GB RAM). In that case, please note that certain *system pods* running in **kube-system** namespace take away as much as 60% of the CPU, and you are left with 40% of CPU to run your pods to do these excercises. It is also important to note that by default each `nginx` and `nginx:alpine` instance will take away 10% CPU. This means, that at any given time, you will note be able to run more than four (light weight) pods in total. So when you do the **scaling** and **rolling updates** exercises, you need to keep that in mind.

If you are running a cluster of your own such as minikube or kubeadm based cluster, and if you setup the VMs to have multiple CPUs during the VM setup, you will not likely encounter this limitation. But you should still make a note of it. 


## Setup

* [00-setup-kubectl-linux](00-setup-kubectl-linux.md) -
    Skip if you've already installed `kubectl` and have access to a cluster.
* [00-setup-namespace](00-setup-namespace.md) -
    Skip if you've already created a personal namespace and set it as your default.

## Exercises

* [01-pods-deployments-namespaces.md](01-pods-deployments-namespaces.md)
* [02-service-discovery-and-loadbalancing.md](02-service-discovery-and-loadbalancing.md)
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


**Note:** There are three variants of the ingress exercise - one of them is Google Kubernetes Engine (gke) specific, whereas the two others are generic and should work on any Kubernetes cluster.

## [Optional] kubectl command autocompletion

On Linux, using bash, run the following commands:

```shell
$ echo "source <(kubectl completion bash)" >> ~/.bashrc
$ . ~/.bashrc
```

The commands above will enable kubectl autocompletion when you start a new bash session and source (reload) bashrc i.e. enable kubectl autocompletion in your current session.

See [Kubernetes.io - Enabling shell autocompletion](https://kubernetes.io/docs/tasks/tools/install-kubectl/#enabling-shell-autocompletion) for more info.

# Command Cheatsheet

A collection of useful commands to use throughout the exercises. 

The first thing you should know about your setup is what is your client (kubectl) version and what is the server version. Having this information helps in many situations.

```shell
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"10", GitVersion:"v1.10.8", GitCommit:"7eab6a49736cc7b01869a15f9f05dc5b49efb9fc", GitTreeState:"clean", BuildDate:"2018-09-14T16:06:30Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"13", GitVersion:"v1.13.3", GitCommit:"721bfa751924da8d1680787490c54b9179b1fed0", GitTreeState:"clean", BuildDate:"2019-02-01T20:00:57Z", GoVersion:"go1.11.5", Compiler:"gc", Platform:"linux/amd64"}
```

Other useful commands:

```shell
$ kubectl api-resources         # List resource types - kubectl 1.11+

OR

$ kubectl api-versions         # List resource types 


$ kubectl explain <resource-type>    # Show information about a resource (e.g. api version, etc); not to confuse with "describe"
$ kubectl explain pod 


# List resources in cluster
$ kubectl get <resource-type> [resource-name]    # In current namespace
$ kubectl get <resource-type> -n <namespace>     # In specific namespace
$ kubectl get <resource> --all-namespaces   # In all namespaces
$ kubectl get <resource> -o wide            # Add extended information
$ kubectl get <resource> -o yaml            # output in YAML format
$ kubectl get <resource> -o json            # output in JSON format

# Examples
$ kubectl get pods 
$ kubectl get pods nginx-76542036-5431 -n development


# Describe a resource in detail
$ kubectl describe <resource-type> [resource-name]

# Examples
$ kubectl describe pod nginx-76542036-5431


# Exec into a pod:
$ kubectl exec -it nginx-76542036-5431 /bin/sh


# Check logs of pod:
$ kubectl logs -f nginx-76542036-5431

# Check kubernetes events:
$ kubectl get events --sort-by=.metadata.creationTimestamp

```

You can get a list of all possible commands by simply typing `kubectl` without any parameters. Note that each (newer) version of `kubectl` will have more  commands/options than the previous version. The output of `kubectl` command below is from kubectl-1.10.8.

```
$ kubectl 

kubectl controls the Kubernetes cluster manager. 

Find more information at: https://kubernetes.io/docs/reference/kubectl/overview/

Basic Commands (Beginner):
  create         Create a resource from a file or from stdin.
  expose         Take a replication controller, service, deployment or pod and expose it as a new Kubernetes Service
  run            Run a particular image on the cluster
  set            Set specific features on objects
  run-container  Run a particular image on the cluster. This command is deprecated, use "run" instead

Basic Commands (Intermediate):
  get            Display one or many resources
  explain        Documentation of resources
  edit           Edit a resource on the server
  delete         Delete resources by filenames, stdin, resources and names, or by resources and label selector

Deploy Commands:
  rollout        Manage the rollout of a resource
  rolling-update Perform a rolling update of the given ReplicationController
  scale          Set a new size for a Deployment, ReplicaSet, Replication Controller, or Job
  autoscale      Auto-scale a Deployment, ReplicaSet, or ReplicationController

Cluster Management Commands:
  certificate    Modify certificate resources.
  cluster-info   Display cluster info
  top            Display Resource (CPU/Memory/Storage) usage.
  cordon         Mark node as unschedulable
  uncordon       Mark node as schedulable
  drain          Drain node in preparation for maintenance
  taint          Update the taints on one or more nodes

Troubleshooting and Debugging Commands:
  describe       Show details of a specific resource or group of resources
  logs           Print the logs for a container in a pod
  attach         Attach to a running container
  exec           Execute a command in a container
  port-forward   Forward one or more local ports to a pod
  proxy          Run a proxy to the Kubernetes API server
  cp             Copy files and directories to and from containers.
  auth           Inspect authorization

Advanced Commands:
  apply          Apply a configuration to a resource by filename or stdin
  patch          Update field(s) of a resource using strategic merge patch
  replace        Replace a resource by filename or stdin
  convert        Convert config files between different API versions

Settings Commands:
  label          Update the labels on a resource
  annotate       Update the annotations on a resource
  completion     Output shell completion code for the specified shell (bash or zsh)

Other Commands:
  api-versions   Print the supported API versions on the server, in the form of "group/version"
  config         Modify kubeconfig files
  help           Help about any command
  plugin         Runs a command-line plugin
  version        Print the client and server version information

Usage:
  kubectl [flags] [options]

Use "kubectl <command> --help" for more information about a given command.
Use "kubectl options" for a list of global command-line options (applies to all commands).
```

Also see [the online kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) for commonly used commands with examples.
