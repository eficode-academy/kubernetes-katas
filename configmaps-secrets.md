# ConfigMaps and Secrets

## Learning Goals

- learn how to create configmaps and secrets
- learn how to use configmaps and secrets in a deployment

## Introduction

Configmaps and secrets are a way to store information that is used by several deployments and pods in your cluster. In that way you have one place to change the information.

Both configmaps and secrets are key-value pairs, but secrets are encoded and configmaps are not.

> :bulb: Secrets are not encrypted, but they are encoded. This means that if someone gets access to the cluster, they can still read the values, but they are not in plain text.


## ConfigMaps

Use a ConfigMap to keep your application code separate from your configuration.

It is an important part of creating a Twelve-Factor Application.

This lets you change easily configuration depending on the environment (development, production, testing) and to dynamically change configuration at runtime. 

TODO: add more information
<details>
<summary>:bulb: If an explanaition becomes too long, the more detailed parts can be encapsulated in a drop down section</summary>
</details>

## Secrets

Secrets are a way to store things that you do not want floating around in your code.

It's things like passwords for databases, API keys and certificates.

Rather than hardcode this sensitive information and commit it to git for all the world to see, we source these values from environment variables.
TODO: add more information

## Exercise

### Overview

- Add the database part of the application
- Change the database user into a configmap and implement that in both backend and database
- Change the database password into a secret, and implement that in both backend and database.

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
**Change the database user into a configmap and implement that in both backend and database**
We want to change the database user into a configmap, so that we can change it in one place, and use it on all deployments that needs it.

- create a configmap with the name `database-user` and the key `username` and the value `postgres`


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