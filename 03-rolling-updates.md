# Replicas and Rolling update

## Create Deployment

> :bulb: All files for the exercise are found in the `rolling-updates` folder.

* Look at the nginx deployment yaml file in `rolling-updates/nginx-deployment.yaml`
* Look at the service file in `rolling-updates/nginx-svc.yaml`

Now go ahead and `apply` the deployment and the service:

* Apply the nginx deployment: `$ kubectl apply -f rolling-updates/nginx-deployment.yaml`
* Apply the service: `$ kubectl apply -f rolling-updates/nginx-svc.yaml`

> :bulb: Remember that it might take a few minutes for the cloud infrastructure to deploy the load balancer, i.e. the external IP might be shown as `pending`

* Note down the loadbalancer IP from the services command: `$ kubectl get service`
* Increase the replicas to four in the deployment yaml file:

```yaml
spec:
  replicas: 4
```

* Apply the service again to increase the replica count of your deployment.

From another terminal check which version is currently running and to see changes when rollout is happening:

```shell
$ while true; do  curl --connect-timeout 1 -m 1 -sI <loadbalancerIP>  | grep Server; sleep 0.5; done
```

## Update Deployment

Now we will try to roll out an update to the image.

* Set image tag to `1.9`:

```YAML
    ...
    spec:
      containers:
      - image: nginx:1.9
```

* Apply the new version of your deployment.

* Check the rollout status: `$ kubectl rollout status deployment nginx`

* Investigate rollout history: `$ kubectl rollout history deployment nginx`

* Try rolling out other image version by repeating the commands from above. Suggested image versions are `1.12.2`, `1.13.12`, `1.14.1`, `1.15.2`.

* Try also rolling out a version that does not exist:

```YAML
    spec:
      containers:
      - image: nginx:not-a-version
        name: nginx
```

What happened - do the curl operation still work?

* Investigate the running pods with: `$ kubectl get pods`

## Undo Update

The rollout above using a non-existing image version caused some pods to be
non-functioning. Next, we will undo this faulty deployment.

* Investigate rollout history: `kubectl rollout history deployment nginx`

* Undo the rollout and restore the previous version: `kubectl rollout undo deployment nginx`

* Investigate the running pods: `kubectl get pods`

## Clean up

Delete deployments and services as follow:

* `kubectl delete deployment nginx`
* `kubectl delete service nginx`
