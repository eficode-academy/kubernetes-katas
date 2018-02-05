# The Kubernetes package manager
[Enter Helm](https://github.com/kubernetes/helm) - the answer to how to pacakage multi-container applications, and how to easily install packages on Kubernetes.

Install the Helm client ([Linux](https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-linux-amd64.tar.gz), [Linux 32-bit](https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-linux-386.tar.gz), [Windows](https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-windows-amd64.tar.gz),[OSX](https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-darwin-amd64.tar.gz)) and let's play with it!

To setup the Helm server on your targeted cluster, run: 
```
helm init
```

This will install a tiller server in the Kubernetes cluster, which Helm uses to fetch and unpackage resources in the cluster.

Instead of figuring out which docker images to run manually, we will let helm find them. 
Update Helm, then install mySql: 

```
helm repo update
helm install stable/mysql
```

This will output information about your newly deployed mysql setup similar to this: 

```
NAME:   invinvible-serval
LAST DEPLOYED: Tue Nov 14 14:46:15 2017
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1beta1/Deployment
NAME                     DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
invinvible-serval-mysql  1        1        1           0          0s

==> v1/Secret
NAME                     TYPE    DATA  AGE
invinvible-serval-mysql  Opaque  2     0s

==> v1/PersistentVolumeClaim
NAME                     STATUS  VOLUME                                    CAPACITY  ACCESSMODES  STORAGECLASS  AGE
invinvible-serval-mysql  Bound   pvc-2f95ebb1-c942-11e7-9e2e-080027f4e367  8Gi       RWO          standard      0s

==> v1/Service
NAME                     CLUSTER-IP  EXTERNAL-IP  PORT(S)   AGE
invinvible-serval-mysql  10.0.0.25   <none>       3306/TCP  0s
```

Running ```helm ls``` will show all current deployments and ```helm delete <deployment name>``` (in above example helm delete invinvible-serval) will remove the service again. 

Helm deals with the concept of [charts](https://github.com/kubernetes/charts) for its deployment logic. Stable/mysql was a chart, [found here](https://github.com/kubernetes/charts/tree/master/stable/mysql) that describes how helm should deploy it. It interpolates values into the deployment, which for mysql looks [like this](https://github.com/kubernetes/charts/blob/master/stable/mysql/templates/deployment.yaml). 

The charts describe which values can be given for overwriting default behaviour, and there is an active community around it. 

Praqma also has [Helmsman](https://github.com/Praqma/Helmsman) which is another layer of abstraction on top of Helm, allowing it to be automated as code deployments. 






