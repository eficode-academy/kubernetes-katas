# Secrets (and configmaps)

Before we start, make sure you have set your working namespace
````
kubectl config set-context $(kubectl config current-context) --namespace=<insert-namespace-name-here>
````

Secrets are a way to store things that you do not want floating around in your code. 

It's things like passwords for databases, API keys and certificates.

Similarly configmaps are for configuration, that doesn't really belong in code but needs to change. Examples include loadbalancer configurations, jenkins configuration and so forth. 

We will look at both these in this coming exercise. 

## Secrets as environment variables

Our [maginificent app](./secrets/secretapp.js) requries it's API key and language.  Rather than hardcode this sensitive information and  commit it to git for all the world to see, we source these values from environment variables.

The first step to fixing it, would be to make our variables as environmental variables.

We have sourced the values in the code like this:
```
  const language = process.env.LANGUAGE;
  const API_KEY = process.env.API_KEY;
```

Because we are reading from the env variables we can specify some default in the Dockerfile.  We have used this: 

```
FROM node:9.1.0-alpine
EXPOSE 3000
ENV LANGUAGE English
ENV API_KEY 123-456-789
COPY secretapp.js .
ENTRYPOINT node secretapp.js
```

This image is available as `praqma/secrets-demo`. We can run that in our Kubernetes cluster by using the [the deployment file](./secrets/deployment.yml). Notice the env values added in the bottom. 

Set your namespace in the file and run the deployment by writing: 
```
kubectl apply -f deployment.yml 
```

Expose the deployment on a nodeport, so you can see the running container. 

Despite the default value in the Dockerfile, it should now be overwritten by the deployment env values! 

However we just moved it from being hardcoded in our app to being hardcoded in our Dockerfile. 

## Secrets using the kubernetes secret resource

Let's move the API key to a (generic) secret: 

```
kubectl create secret generic apikey --from-literal=API_KEY=oneringtorulethemall
```

Kubernetes supports different kinds of preconfigured secrets, but for now we'll deal with a generic one. 

Similarly for the language into a configmap: 
```
kubectl create configmap language --from-literal=LANGUAGE=Orcish
```

Similarly to all other objects, you can run "get" on them. 

```
kubectl get secrets
kubectl get configmaps
```

Try to describe the secret. 

Last step is to change the Kubernetes deployment file to use the secrets. 

Change:
```
    env:
        - name: LANGUAGE
          value: Polish
        - name: API_KEY
          value: 333-444-555
```

To: 
```
    env:
        - name: LANGUAGE
          valueFrom:
            configMapKeyRef:
              name: language
              key: LANGUAGE
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: apikey
              key: API_KEY
```

You should now see the variables being loaded from configmap and secret respectively.

To hot swap the values, you need to keep in mind that pods have a cache, so it becomes a two step process: 

```
kubectl create configmap language --from-literal=LANGUAGE=Elvish -o yaml --dry-run | kubectl replace -f -

kubectl create secret generic apikey --from-literal=API_KEY=andinthedarknessbindthem -o yaml --dry-run | kubectl replace -f -
```

Then delete the pod (so it recreates) : 
```
kubectl delete pod envtest-3380598928-kgj9d
```

This concludes the exercise on secrets and configuration maps. 


# Cheatsheet

````
kubectl expose deployment envtest --type=NodePort --port=3000
kubectl delete pod <podname>
kubectl describe configmap language
kubectl describe secret apikey
kubectl describe service envtest
````

If you are stuck - take a look at `final.deployment.yml`
