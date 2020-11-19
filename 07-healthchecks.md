# Kubernetes health checks

Kubernetes have two built-in ways of making a
health check on a pod:

- _readnissprobe_ that finds out if your pod is
  ready to receive traffic
- _livelinessprobe_ that finds out if your pod is
  alive and well

When a container runs in a pod, Kubernetes reports
back four things:

```
NAME                     READY   STATUS    RESTARTS   AGE
probe-59cf4f5578-vwllc   1/1     Running   1          10m
```

The difference between a container being healthy
or unhealthy, is vital. A container can be
creating, failing or otherwise deployed but
unavailable - and in this state Kubernetes will
choose not to route traffic to the container if it
deems it unhealthy.

## Tasks

Apply the deployment and service found in the
`health-checks` folder:

- `kubectl apply -f kubernetes-katas/health-checks/probes.yaml `
- `kubectl apply -f kubernetes-katas/health-checks/probes-svc.yaml`
- Try to access the service through the public IP
  of one of the nodes, just like we worked with in
  the
  [service discovery assignment](./02-service-discovery-and-loadbalancing.md).
- Scale the deployment by changing the `replicas`
  amount to 2 in the `probes.yaml`
- Access it again through your browser multiple
  times to see that you hit both of the instances
- Execute a bash session in one of the instances
  `kubectl exec -ti probe-59cf4f5578-vwllc bash`
- First, remove the file `/tmp/ready`, and monitor
  that the browser will eventually not route
  traffic to that pod.
- remove the file `/tmp/alive`, and observe that
  you within a short while will get kicked out of
  the container, as the pod is restarting.
- observe that the pod has now been restarted when
  you list the pods with `kubectl get pods`
- Look at the logs:
  `kubectl describe pod probe-59cf4f5578-vwllc`
  and see the events that you have triggered
  through this exercise.

Congratulations!

You have now tried out both to pause traffic to a
given pod when its readinessprobe is failing, and
trigger a pod restart when the livelinessprobe is
failing.
