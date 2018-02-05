# First encounter with Kubernetes

## 1.1 Set up kubectl

For development it is necessary to be able to deploy services locally.

Normally the way you would do this is to deploy in a development namespace on your production cluster, but here we are going to get a simple little cluster up and running in no time.

Before we can do that however, we need to get [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) which is short for kubernetes controller.

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.7.5/bin/linux/amd64/kubectl && chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl
```

Kubectl is a go binary which allows you to execute commands against your cluster. Normally [minikube](https://github.com/kubernetes/minikube) serves as a local Kubernetes one node cluster, but due to restrictions with virtualization inside a virtual machine, you cannot run minikube on cloud machines.
Minikube is a part of the Kubernetes open source project, with the single goal of getting a simple cluster up and running with just one virtual machine acting as node.

For the remainder of this workshop, we will therefore be executing on a Kubernetes cluster on google cloud.


To authenticate against the cluster, you will need a gmail account. Run:

```
# cluster connection via service account

# Install the tools
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install google-cloud-sdk

# Create key file on your vm - the instructor will mail you the contents
vi keyfile.json

# authenticate with cloud
gcloud auth activate-service-account --key-file keyfile.json

# Get the cluster credentials for kubectl
gcloud container clusters get-credentials cluster-london --zone europe-west1-b --project praqma-education
```

Google will do some magic under the hood, which does a few things:
- Fetches certificates and tokens or basically secrets.
- Puts them into the Kubernetes configuration file, located at /home/.kube/config
- Sets the kubectl binary to target the cluster on google cloud.

You can verify this by looking at the config file:
```
kubectl config view
```
Furthermore you should now have access to the google cloud cluster!

Verify by looking at the nodes (slave machines) for the cluster:

```
kubectl get nodes
```
Be aware that you are not the only tenant on the cluster, you are sharing with the rest of the people around you in the course!

## 1.2 Create a namespace and create a deployment with three pods

```
kubectl create namespace <name>
kubectl get pods -n <name>
```

Namespaces are the default way for kubernetes to separate resources. Namespaces do not share anything between them, which is important to know.

This is quite powerful. On a user level, it is also possible to limit namespaces and resources by users but it is a bit too involved for your first experience with Kubernetes. Therefore, please be aware that other people's namespaces are off limits for this workshop even if you do have access. ;)

Every time you run a kubectl command, you can opt to use the namespace flag (-n mynamespace) to execute the command on that namespace.

Similarly in the yaml files, you can specify namespace. Most errors you will get throughout the rest of the workshop will 99% be deploying into a namespace where someone already did that before you so ensure you are using your newly created namespace!

Kubernetes clusters come with a namespace called 'default', which should contain some pods (containers) deployed previously by Praqma.

The below commands do the same thing, because kubernetes commands will default to the default namespace:

```
kubectl get pods -n default
kubectl get pods
```

So let's try to use some of the Kubernetes objects, starting with a deployment.

```
kubectl run ngingo --image=praqma/ngingo --replicas=3 -n <namespace>
```

We can check the 3 containers are running (dont forget the namespace):

```
kubectl get pods (-n <namespace>)

```

To look closer at a pod, you can describe it:

```
kubectl describe pod ngingo-<unique-pod-name> -n <namespace>
```
However the pods are currently not accessible, since no port forwarding is happening to the container.

## 1.3 Expose the service

We need to set up another Kubernetes object - a service. Think of a service as a port and ip endpoint, allowing you to reach a container. We tell it which port to target (for ngingo core it is 80) and what type of service, here it is NodePort which also opens an external port on the Kubernetes node.

```
kubectl expose deployment ngingo --type=NodePort --port=80 -n <namespace>
```

Similarly to how it was done for a pod, you can describe a service. Here we need the NodePort:
```
kubectl describe svc ngingo -n <namespace> | grep NodePort
```

Which should return a port above 30000, which is serving our container. Since the port is serving as a NodePort, we need to hit a node in the cluster.

To reach an application in a container inside the cluster, we need to reach a node on the exposed port.
For this we require the ip address or dns of the node, and the exposed port:

```
kubectl get nodes
kubectl describe node <Node Name e.g. gke-cluster-1-default-pool-847fbafa-4cpk> | grep ExternalIP
kubectl describe svc ngingo -n <namespace> | grep NodePort  
```
Then we simply access it in a browser, like so:

```
http://192.168.99.100:32112
```

The final thing you need to be aware of is that the kubectl commands, while more comfortable, have an equivalent in yaml. Keeping things as code is important, so we are going to learn that as well.

If you delete a namespace for example, everything running in the namespace is similarly deleted. Having everything as code makes spinning it up again quite easy.

Extract the yaml from Kubernetes for our deployment:

```
kubectl get deployment ngingo -o yaml -n <namespace> > myapp-deployment.yml
cat myapp-deployment.yml
```

Have a look at the file. This is how Kubernetes sees the deployment. A lot of these things can be cleaned up, and default values will be given when you deploy.

For example creationTimestamp is not good practice to keep in a yaml file.

If you want to target your own namespace instead of default every time without the -n command, run:
```
kubectl config set-context $(kubectl config current-context) --namespace=<insert-namespace-name-here>
```

The yaml files for the coming exercises will give you a better impression of what is sensible.

This concludes the exercise, happy coding!

------------------

## Useful commands

    kubectl config current-context
    kubectl config use-context docker-for-desktop
    kubectl version
    kubectl cluster-info
    kubectl get nodes
