# Kubernetes health checks
Working with Kubernetes, you eventually need to understand the "magic". 

When a container runs in a pod, Kubernetes reports back four things: 
```
NAME                                       READY     STATUS    RESTARTS   AGE
mypod-somenumbers-guid                     1/1       Running   0          3h
```

This workshop assignment looks at the ready part, which is the internal health check Kubernetes performs on a container. 

The difference between a container being healthy or unhealthy, is vital. A container can be creating, failing or otherwise deployed but unavailable - and in this state Kubernetes will choose not to route traffic to the container if it deems it unhealthy. 

Howevever in some cases an app looks "healthy" despite having issues. This is where customized health checks become important. 

Examples include the database running, but being unreachable, the app functioning but a volume to store files in being unavailable and so on. 

[This deployment](health-checks/deployment.yml) shows this quite nicely. 

For the first 30 seconds of the pod's lifespan, it will be healthy. After this, the custom health check will fail. 

The magic in Kubernetes, is that it will recreate an unhealthy container. 

First, apply the deployment file with the ´kubectl apply -f´ command. Remember to specify the path.

Look at the logs: 
```
kubectl describe pod liveness-exec
```  

Any (http) code greater than or equal to 200 and less than 400 indicates success. Any other code indicates failure.

Let's go back to our applications, and create a custom health check. 

Create an endpoint that does something customized, and returns 200. (Make sure it can fail and return an error above 500 if you want to test). 

Push the container, and create a deployment for it and include: 

```
  livenessProbe:
      httpGet:
        path: /healthz #Your endpoint for health check.
        port: 8080
        httpHeaders:
        - name: X-Custom-Header
          value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3
```

Verify that the healthcheck fails when conditions are not met. 

This concludes the exercise for health checks!
