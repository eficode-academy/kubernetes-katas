# Rolling Updates

## Learning Goals

- Learn about how to update deployments 
- Learn about how to test resiliency of your deployment
- Learn about how to control the rollout process with `maxSurge` and `maxUnavailable`

## Introduction

In this exercise you'll learn about how to update a deployment.
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

* Access the frontend by the NodePort service

<details>
<summary>:bulb: How is it that you do that?</summary>

* Find the service with `kubectl get services` command.

* Note down the port number for the frontend service. In this case it is `31941`

* Get the nodes EXTERNAL-IP address. Run `kubectl get nodes -o wide`.

Copy the external IP address of any one of the nodes, for example, `34.244.123.152` and paste it in your browser. 

Copy the port from your frontend service that looks something like `31941` and paste it next to your IP in the browser, for example, `34.244.123.152:31941` and hit it.

</details>

## Update Deployment

Now we will try to roll out an update to the backend image.

- Set image tag to `2.0.0`:

```yaml
    ...
    spec:
      containers:
      - image: ghcr.io/eficode-academy/flask-quotes-backend:2.0.0
```

- Apply the new version of your deployment.

- Check the rollout status: `kubectl rollout status deployment backend`

expected output:

```
deployment "backend" successfully rolled out
```

- Check the version of the backend image in the browser

- Try rolling out other image version while looking at the frontend. You can do it by repeating the commands from above. Suggested image versions are `1.0.0` and `3.0.0`.

- Try also rolling out a version that does not exist:

```yaml
    spec:
      containers:
      - image: ghcr.io/eficode-academy/flask-quotes-backend:not-a-version
        name: backend
```

What happened - do the frontend still work?

- Investigate the running pods with: `kubectl get pods`

- Reset back to a version that exists.
## maxSurge and maxUnavailable

We will now try to control the rollout process by setting `maxSurge` and `maxUnavailable` parameters.

In one terminal TODO

- Set `maxSurge` to `1` and `maxUnavailable` to `0`:

```yaml
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```



## Clean up

Delete deployments and services as follow:

- `kubectl delete -f .`
