# Replicas and Rolling update:

## Create Deployment

Recreate the nginx deployment that we did earlier:

```shell
$ kubectl create deployment nginx --image=nginx:1.7.9
```

And, expose the pod using a load balancer service (remember that it might take a
few minutes for the cloud infrastructure to deploy the load balancer, i.e. the
external IP might be shown as `pending`):

```shell
$ kubectl expose deployment nginx --port 80 --type LoadBalancer
```

Note down the loadbalancer IP from the services command:

```shell
$ kubectl get service
```

In case, you are doing this excercise on your local kubernetes clsuter (minikube, kubeadm, etc), then you can simply expose this service as NodePort and use the worker-node-name/IP:nodeport to achieve the same.

```
$ kubectl expose deployment nginx --port 80 --type NodePort
```

```
$ kubectl get services
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.32.0.1     <none>        443/TCP        1h
nginx        NodePort    10.32.254.6   <none>        80:30900/TCP   7m
$ 
```


Increase the replicas to four:

```shell
$ kubectl scale deployment nginx --replicas=4
```

From another terminal on your machine check (using load balancer IP) which version is currently running and to see changes when rollout is happening:

```shell
$ while true; do  curl -sI 35.205.60.29  | grep Server; sleep 2; done
```

On local kubernetes cluster, it would be:
```
$ while true; do  curl -sI k8s-worker-node:30900  | grep Server; sleep 1; done
```


## Update Deployment

Rollout an update to  the image:

```shell
$ kubectl set image deployment nginx nginx=nginx:1.9.1 --record
```

Check the rollout status:

```shell
$ kubectl rollout status deployment nginx
```

Investigate rollout history:

```shell
$ kubectl rollout history deployment nginx
```

Try rolling out other image version by repeating the `set image` command from
above.  Suggested image versions are 1.12.2, 1.13.12, 1.14.1, 1.15.2.

Try also rolling out a version that does not exist:

```shell
$ kubectl set image deployment nginx nginx=nginx:100.200.300 --record
```

what happened - do the curl operation still work?  Investigate the running pods with:

```shell
$ kubectl get pods
```
You should see `ImagePullBackOff` under STATUS of some of the pods. 


## Undo Update

The rollout above using a non-existing image version caused some pods to be
non-functioning. Next, we will undo this faulty deployment. First, investigate
rollout history:

```shell
$ kubectl rollout history deployment nginx
```

Undo the rollout and restore the previous version:

```shell
$ kubectl rollout undo deployment nginx
```

Investigate the running pods:

```shell
$ kubectl get pods
```

## Clean up

Delete deployments and services as follow:

```shell
$ kubectl delete deployment nginx
$ kubectl delete service nginx
```
