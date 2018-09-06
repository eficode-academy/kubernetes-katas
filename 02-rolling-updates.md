# Replicas and Rolling update:

Increase replicas:
```
kubectl scale deployment nginx --replicas=4
```

Rollout an update to  the image:
```
kubectl set image deployment/nginx nginx=nginx:1.9.1
```

Check the rollout status:
```
kubectl rollout status deployment/nginx
```

From another terminal check (LB IP) if rollout is happening:
```
while true; do  curl -sI 35.205.60.29  | grep Server; sleep 2; done
```

