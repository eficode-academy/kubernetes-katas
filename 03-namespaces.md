# Namespaces:
Namespaces are the default way for kubernetes to separate resources. Namespaces do not share anything between them, which is important to know. This is quite powerful concept, but not unusual, as in computing - we are used to having isolated environments such as home directories, jailed environments, etc. Kubernetes clusters come with a namespace called **default**.

When you execute a kubectl command without specifying a namespace, it is run in/against the namespace named **default**! So far all the commands you have executed in the previous exercise, have been executed in the *default* namespace. You can optionally use the namespace flag (-n <namespace>) to execute the command a specific namespace. When you are creating Kubernetes objects though *yaml* files, you can specify a namespace for a particular resource. 

**Note:** In case, you are on a shared cluster for this workshop, then watch out for which namespace you are using to deploy your objects in. 

It is also possible to limit namespaces and resources at user level, but it would be a bit too involved for your first experience with Kubernetes

## Create a namespace

Use the following syntax to create a namespace and to list objects from a namespace:
```
kubectl create namespace <name>

kubectl get pods -n <name>
```

Here are few examples:
```
$ kubectl create namespace dev
namespace "dev" created

$ kubectl create namespace test
namespace "test" created

$ kubectl create namespace prod
namespace "prod" created
```

```
$ kubectl get namespaces
NAME          STATUS    AGE
default       Active    2d
dev           Active    12s
prod          Active    5s
test          Active    8s
```


The below commands do the same thing, because kubernetes commands will default to the *default* namespace:

```
kubectl get pods -n default
kubectl get pods
```

## Manage Kubernetes objects in a namespace:

So let's try to create an nginx deployment in the *dev* namespace.

```
$ kubectl --namespace=dev run nginx --image=nginx
deployment "nginx" created

$ kubectl get pods -n dev
NAME                     READY     STATUS    RESTARTS   AGE
nginx-4217019353-fk9ph   1/1       Running   0          10s
```

So, you get the idea. You include `-n <namespacename>` in any kubectl invokation, and it will operate on the given namespace only. You can also use `--all-namespaces=true" to get objects from all namespaces.

The yaml files for the coming exercises will give you a better impression of what is sensible.

