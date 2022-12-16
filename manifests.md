# Manifests

## Learning Goals

Write your own declarative manifest to run a simple web application in a pod

## Introduction

## Manifest files

A [manifest][manifest_def] describes the `desired state` of an object that you want Kubenetes to manage. Manifests are described in Yaml files and have the following general structure:

```yaml
apiVersion:
kind:
metadata:
  labels:
spec:
```

[manifest_def]: https://kubernetes.io/docs/reference/glossary/?all=true#term-manifest

<details>
<summary>:bulb: Describe the general struture of a declarative manifest</summary>

TODO: Explain how this works
</details>

## Exercise


### Overview

- Write your own `pod` manifest.
- Apply the `pod` manifest.
- Verify the the `pod` is created correctly.

### Step by step instructions

- Go into the `manifests` directory and the `start` folder.
- Open the `frontend-pod.yaml` file.

It looks like this:

```yaml
apiVersion:
kind:
metadata:
  name:
spec:
  containers:
  - name:
    image:
    ports:
```

- Find the API version for the `pod` resource in the [Kubernetes API documentation][pod-api] and fill out the `apiVersion`

[pod-api]: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/

- the version is `v1`
- the `kind` should be `Pod`
- the `name` should be `frontend`
- the `image` should be `ghcr.io/eficode-academy/flask-quotes-frontend:release`
- the `containerPort` section should have `5000`

<details>
<summary>:bulb: Help me out!</summary>

The entire manifest should look like this:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend
spec:
  containers:
  - name: frontend
    image: ghcr.io/eficode-academy/flask-quotes-frontend:release
    ports:
    - containerPort: 5000
```

</details>

- try to apply the manifest with `kubectl apply -f frontend-pod.yaml` command.

- check the status of the pod with `kubectl get pods` command.

expected output:

```bash
NAME       READY   STATUS    RESTARTS   AGE
frontend   1/1     Running   0          1m
```


### Clean up

Delete the pod with `kubectl delete pod frontend` command.

Congratulations! You have now learned how to make temporary connections to a pod inside the cluster via `kubectl port-forward`.