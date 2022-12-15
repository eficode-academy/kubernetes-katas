# ConfigMaps and Secrets

## Learning Goals

- learn how to create configmaps and secrets
- learn how to use configmaps and secrets in a deployment

## Introduction

Configmaps and secrets are a way to store information that is used by several deployments and pods in your cluster. In that way you have one place to change the information.

Both configmaps and secrets are key-value pairs, but secrets are encoded and configmaps are not.

> :bulb: Secrets are not encrypted, but they are encoded. This means that if someone gets access to the cluster, they can still read the values, but they are not in plain text.


## ConfigMaps

You use a ConfigMap to keep your application code separate from your configuration.

It is an important part of creating a [Twelve-Factor Application](https://12factor.net/).

This lets you change easily configuration depending on the environment (development, production, testing) and to dynamically change configuration at runtime. 

A ConfigMap kind looks like this in yaml:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
    key1: value1
    key2: value2
```

There are three ways to create ConfigMaps using the `kubectl create configmap` command.

* Use the contents of an entire directory with kubectl create configmap my-config --from-file=./my/dir/path/
* Use the contents of a file or specific set of files with kubectl create configmap my-config --from-file=./my/file.properties

<details>
<summary>:bulb: more info</summary>

Env-files contain a list of environment variables.
These syntax rules apply:
-  Each line in an env file has to be in VAR=VAL format.
-  Lines beginning with # (i.e. comments) are ignored.
-  Blank lines are ignored.
-  There is no special handling of quotation marks (i.e. they will be part of the ConfigMap value)).


```properties
enemies=aliens
lives=3
allowed="true"

# This comment and the empty line above it are ignored
```

will be rendered as:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
    enemies: aliens
    lives: "3"
    allowed: "true"
```

[resource](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-configmaps-from-files)


</details>

* Use literal key-value pairs defined on the command line with kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2

> :bulb: remember the `--dry-run=client -o yaml` trick to see what the yaml file will look like before you apply it.

<details>
<summary>:bulb: more info</summary>
https://matthewpalmer.net/kubernetes-app-developer/articles/ultimate-configmap-guide-kubernetes.html

</details>

## Secrets

Secrets are a way to store things that you do not want floating around in your code.

It's things like passwords for databases, API keys and certificates.

Rather than hardcode this sensitive information and commit it to git for all the world to see, we source these values from environment variables.
TODO: add more information

## Using ConfigMaps and Secrets in a deployment

To use a configmap or secret in a deployment, you can either mount it in as a volume, or use it directly as an environment variable.

### Mounting a configMap as environment variables

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
    replicas: 1
    selector:
        matchLabels:
        app: my-app
    template:
        metadata:
        labels:
            app: my-app
        spec:
        containers:
        - name: my-app
            image: my-app:latest
            ports:
            - containerPort: 8080
            envFrom:
            - configMapRef: # this is the configmap that we want to use
                name: my-config # the name of the configmap we want to use
```


## Exercise

### Overview

- Add the database part of the application
- Change the database user into a configmap and implement that in the backend
- Change the database password into a secret, and implement that in the backend.
- Change database deployment to use the configmap and secret.

### Step by step instructions

> :bulb: All files for the exercise are found in the `configmap-secrets/start` folder.

**Add the database part of the application**

We have already created the database part of the application, with a deployement and a service. 

- Look at the database deployment file `database-deployment.yaml`. Notice the database username and password is stored directly as environment variables.

> :bulb: This is not a good practice, as it is not secure. We will fix this in the next steps.

- Look at the service file in `database-svc.yaml`. It provides a service for the database, so that the backend can connect to it.

- Apply the whole folder with `kubectl apply -f .`

- Check that the applications are running with `kubectl get pods`

expected output:

```bash
NAME                                   READY   STATUS    RESTARTS   AGE
backend-deployement-7d64597fcf-98vv5   1/1     Running   0          4s
backend-deployement-7d64597fcf-npvnq   1/1     Running   0          4s
backend-deployement-7d64597fcf-nrchp   1/1     Running   0          4s
frontend-deployment-5f9b5f46c8-jkw9n   1/1     Running   0          4s
postgres-6fbd757dd7-ttpqj              1/1     Running   0          4s
```
**Change the database user into a configmap and implement that in the backend**
We want to change the database user into a configmap, so that we can change it in one place, and use it on all deployments that needs it.

- create a configmap with the name `postgres-config` and filename `postgres-config.yaml` and the information about database configuration as follows:
```yaml
      db_host: postgres
      db_port: 5432
      db_user: superuser
      db_password: complicated
      db_name: quotes
```

:bulb: If you are unsure how to do this, look at the [configmap section](#configmaps) above.

<details>
<summary>Help me out!</summary>
If you are stuck, here is the solution:

```bash
kubectl create configmap my-config --from-literal=db_host=postgres --from-literal=db_port=5432 --from-literal=db_user=superuser --from-literal=db_password=complicated --from-literal=db_name=quotes --dry-run=client -o yaml > postgres-config.yaml

```
</details>

- In the `backend-deployment.yaml`, change the environment variables to use the configmap instead of the hardcoded values.

Change this:

```yaml
env:
- name: DB_HOST
  value: postgres
- name: DB_PORT
    value: "5432"
- name: DB_USER
    value: superuser
- name: DB_PASSWORD
    value: complicated
- name: DB_NAME
    value: quotes
```

To this:

```yaml
env:
- envFrom:
  - configMapRef:
      name: postgres-config
```

- re-apply the backend deployment with `kubectl apply -f backend-deployment.yaml`
- check that the website is still running.

**Change the database password into a secret, and implement that in the backend.**

We want to change the database password into a secret, so that we can change it in one place, and use it on all deployments that needs it.
In order for this, we need to change the backend deployment to use the secret instead of the configmap for the password itself.


- create a secret with the name `postgres-secret` and the secret as follows:
```yaml
      db_password: complicated
```

<details>
<summary>Help me out!</summary>
If you are stuck, here is the solution:

```bash
kubectl create secret generic postgres-secret --from-literal=db_password=complicated --dry-run=client -o yaml > postgres-secret.yaml

```
</details>

- apply the secret with `kubectl apply -f postgres-secret.yaml`

- In the `backend-deployment.yaml`, change the environment variables to use the secret instead of the configmap for the password.

Change this:

```yaml
env:
- envFrom:
  - configMapRef:
      name: postgres-config
```

To this:

```yaml
env:
- envFrom:
  - configMapRef:
      name: postgres-config
  - secretRef:
      name: postgres-secret
```

- Delete the password part from the configmap, and re-apply the configmap with `kubectl apply -f postgres-config.yaml`

- re-apply the backend deployment with `kubectl apply -f backend-deployment.yaml`

- check that the website is still running.

**Change database deployment to use the configmap and secret.**

We are going to implement the configmap and secret in the database deployment as well.
Since Postgres have defined the environment varialbe names, we need to add the configmap and secrets with a different function than we did before.

- open the `database-deployment.yaml` file, and change the way the environment variables are defined to use the configmap and secret.
    
```yaml
          ### using configMapKeyRef
          env:
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  name: postgres-config
                  key: db_user
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: db_password
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  name: postgres-config
                  key: db_name
```

- re-apply the database deployment with `kubectl apply -f database-deployment.yaml`
- check that the website is still running, and that the new database can be reached from the backend.

Congratulations! You have now created a configmap and a secret, and used them in your application.

## extra


<details>
<summary>More Details</summary>

**take the same bullet names as above and put them in to illustrate how far the student have gone**

- all actions that you believe the student should do, should be in a bullet

> :bulb: Help can be illustrated with bulbs in order to make it easy to distinguish.

</details>

### Extra

If you have time, try to get the secret data decoded again.

Here is a snippet to get you started:

```bash
kubectl get secret <secret-name> -o jsonpath="{.data.password}" | base64 --decode
```


### Clean up

If anything needs cleaning up, here is the section to do just that.