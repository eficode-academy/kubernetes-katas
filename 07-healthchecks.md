# Kubernetes health checks
Working with Kubernetes, you eventually need to understand the "magic". 

When a container runs in a pod, Kubernetes reports back four things: 
```
NAME                                       READY     STATUS    RESTARTS   AGE
mypod-somenumbers-guid                     1/1       Running   0          3h
```

This workshop assignment looks at the ready part, which is the internal health check Kubernetes performs on a container. 

The difference between a container being healthy or unhealthy, is vital. A container can be creating, failing or otherwise deployed but unavailable - and in this state Kubernetes will choose not to route traffic to the container if it deems it unhealthy. 

However, in some cases an app looks "healthy" despite having issues. This is where customized health checks become important. 

Examples include the database running but being unreachable, the app functioning but a volume to store files in being unavailable and so on. 

[This deployment](health-checks/deployment.yml) shows this quite nicely. 

For the first 30 seconds of the pod's lifespan, it will be healthy. After this, the custom health check will fail. 

The magic in Kubernetes, is that it will recreate an unhealthy container. 

First, apply the deployment file with the `kubectl apply -f` command. Remember to specify the path.

Look at the logs: 
```
kubectl describe pod liveness-exec
```  

Notice that the pod fails after 30 seconds. What happens after?

# This concludes the exercise for health checks!
