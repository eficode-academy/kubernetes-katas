# Replicas and Rolling update:

Recreate the nginx deployment that we did earlier:

`kubectl run nginx --image=nginx:1.7.9`

And make a load balancer service:

`kubectl expose deployment nginx --port 80 --type LoadBalancer`

Note down the loadbalancer IP from the services command:

`kubectl get svc`

Increase the replicas to four:
```
kubectl scale deployment nginx --replicas=4
```

From another terminal on your machine check (using load balancer IP) which version is currently running and to see changes when rollout is happening:
```
while true; do  curl -sI 35.205.60.29  | grep Server; sleep 2; done
```

Rollout an update to  the image:
```
kubectl set image deployment/nginx nginx=nginx:1.9.1
```

Check the rollout status:
```
kubectl rollout status deployment/nginx
```

Undo the rollout and restore the previous version:
```
kubectl rollout undo deployment/nginx
```
