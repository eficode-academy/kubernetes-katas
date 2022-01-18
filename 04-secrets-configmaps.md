# Secrets and ConfigMaps

Secrets are a way to store things that you do not want floating around in your code.

It's things like passwords for databases, API keys and certificates.

Similarly, configmaps are for configuration, that doesn't really belong in code but needs to change. Examples include loadbalancer configurations, jenkins configuration and so forth.

We will look at both these in this coming exercise.

## Secrets as environment variables

Our [magnificent app](./secrets/secretapp.js) requires its API key and language. Rather than hardcode this sensitive information and commit it to git for all the world to see, we source these values from environment variables.

The first step to fixing it, would be to make our variables as environmental variables.

We have sourced the values in the code like this:

```shell
  const language = process.env.LANGUAGE;
  const API_KEY = process.env.API_KEY;
```

Because we are reading from the env variables we can specify some default in the `Dockerfile`.  We have used this:

```shell
FROM node:9.1.0-alpine
EXPOSE 3000
ENV LANGUAGE English
ENV API_KEY 123-456-789
COPY secretapp.js .
ENTRYPOINT node secretapp.js
```

This image is available as `praqma/secrets-demo`. We can run that in our Kubernetes cluster by using the [the deployment file](./secrets/deployment.yml). Notice the env values added in the bottom.

Run the deployment by writing:

```shell
$ kubectl apply -f secrets/deployment.yml
deployment.extensions/envtest created
```

Expose the deployment on a nodeport, so you can see the running container.

> You learned about exposing nodeports in the [service discovery](02-service-discovery-and-loadbalancing.md) exercise. And remember that the application is running on port `3000`

<details>
    <summary> :bulb: Recap of how to expose a service</summary>

Example: This is the example of how you should do it. But it won't work to copy paste, you need to adapt the command:

Breakdown of the command: `kubectl expose deployment nginx -o yaml --dry-run=client --type=ClusterIP --port=80 > service-discovery-loadbalancing/nginx-svc.yaml`

>* `kubectl` kubernetes commandline
>* `expose` expose a
>* `deployment` type deployment
>* `nginx` with the name `nginx`
>* `-o yaml` formats the output to YAML format
>* `--dry-run=client`  makes sure that the kubectl command will not be sent to the Kubernetes API server
>* `--type=ClusterIP` creates the service of type `ClusterIP`
>* `--port=80` makes the service exposed on port `80`
>* `>` linux command to pipe all from standard output (what you see in the terminal) to a file
>* `service-discovery-loadbalancing/nginx-svc.yaml` the name of the file
>
>:bulb: Using this approach of -o and dry-run is a very good way to create skeleton templates for all kubernetes objects like services/deployments/configmaps etc.

</details>

Despite the default value in the `Dockerfile`, it should now be overwritten by the deployment env values!

However we just moved it from being hardcoded in our app to being hardcoded in our deployment file.

## Secrets using the kubernetes secret resource

Let's move the API key to a (generic) secret:

```shell
$ kubectl create secret generic apikey --from-literal=API_KEY=oneringtorulethemall
secret/apikey created
```

Kubernetes supports different kinds of preconfigured secrets, but for now we'll deal with a generic one.

Similarly for the language into a configmap:

```shell
$ kubectl create configmap language --from-literal=LANGUAGE=Orcish
configmap/language created
```

Similarly to all other objects, you can run "get" on them.

```shell
$ kubectl get secrets
NAME                  TYPE                                  DATA      AGE
apikey                Opaque                                1         4m
default-token-td78d   kubernetes.io/service-account-token   3         3h
```

```shell
$ kubectl get configmaps
NAME       DATA      AGE
language   1         2m
```

> Try to investigate the secret by using the kubectl describe command:
> ```shell
> $ kubectl describe secret apikey
> ```
> Note that the actual value of API_KEY is not shown. To see the encoded value use:
> ```shell
> $ kubectl get secret apikey -o yaml
> ```

Last step is to change the Kubernetes deployment file to use the secrets.

Change:

```shell
        env:
        - name: LANGUAGE
          value: Polish
        - name: API_KEY
          value: 333-444-555
```

To:

```shell
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

After you have edited the `deployment.yml` file (or you can use the prepared one
`secrets/final.deployment.yml`), you need to apply the new edition of the file
by issuing: `kubectl apply -f secrets/deployment.yml` .

You should now see the variables being loaded from configmap and secret respectively.

Pods are not recreated automatically when secrets or configmaps change, i.e. to
hot swapping the values becomes a two step process:

```shell
$ kubectl create configmap language --from-literal=LANGUAGE=Elvish -o yaml --dry-run=client | kubectl replace -f -
configmap/language replaced
$ kubectl create secret generic apikey --from-literal=API_KEY=andinthedarknessbindthem -o yaml --dry-run=client | kubectl replace -f -
secret/apikey replaced
```

Then delete the pod (so it's recreated with the replaced configmap and secret) :

```shell
$ kubectl delete pod envtest-3380598928-kgj9d
pod "envtest-3380598928-kgj9d" deleted
```

Access it in a webbrowser again, to see the updated values.

## Clean up

```shell
$ kubectl delete deployment envtest
$ kubectl delete service envtest
$ kubectl delete configmap language
$ kubectl delete secret apikey
```
