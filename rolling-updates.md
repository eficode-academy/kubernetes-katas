# Rolling Updates

## Learning Goals

- Learn about how to update deployments 
- Learn about how to test resiliency of your deployment

## Introduction

In this exercise you'll learn about how to update a deployment. You'll also learn about how to test resiliency of a deployment.

## Subsections

Rollout strategies

<details>
<summary>:bulb: If an explanaition becomes too long, the more detailed parts can be encapsulated in a drop down section</summary>
</details>

## Exercise

### Overview

- Roll out new version of the either the frontend or backend and see the changes
- Test resiliency of deployments by deleting pods
- Roll out a new version that does not exist

### Step by step instructions

* Create backend deployment

> :bulb: All files for the exercise are found in the `rolling-updates/start` folder.

- Look at the backend deployment files `backend-deployment.yaml` and `frontend-deployment.yaml`
- Look at the service files in `backend-svc.yaml` and `frontend-svc.yaml`

Now go ahead and `apply` the deployments and the services:

- `kubectl apply -f .`

> :bulb: this will apply all the files in the current directory

Access the frontend by the NodePort service:

- `kubectl get svc frontend`
- `kubectl get nodes -o wide`
- Access <node-ip>:<node-port> in your browser

## Update Deployment

Now we will try to roll out an update to the backend image.

- Set image tag to `1.0.1`:

```yaml
    ...
    spec:
      containers:
      - image: ghcr.io/eficode-academy/flask-quotes-backend:1.0.1
```

- Apply the new version of your deployment.

- Check the rollout status: `kubectl rollout status deployment backend`

- Investigate rollout history: `kubectl rollout history deployment backend`

- Try rolling out other image version by repeating the commands from above. Suggested image versions are `1.0.1`, `1.0.2`, `1.0.3`.

- Try also rolling out a version that does not exist:

```yaml
    spec:
      containers:
      - image: ghcr.io/eficode-academy/flask-quotes-backend:not-a-version
        name: backend
```

What happened - do the curl operation still work?

- Investigate the running pods with: `kubectl get pods`

## maxSurge and maxUnavailable
TODO: Add explanation about maxSurge and maxUnavailable

## Clean up

Delete deployments and services as follow:

- `kubectl delete deployment backend`
- `kubectl delete service backend`
