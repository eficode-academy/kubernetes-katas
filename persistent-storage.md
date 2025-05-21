# Persistent Storage

In this exercise you will learn how to persist the filesystem state of your containers using
dynamic volume provisioning.

## Learning Goals

- How to attach a volume to container in a pod
- How to use dynamic volume provisioning to create persistent block storage to save the
  state of your applications
- How to create PersistentVolumes and use them with PersistentVolumeClaims

## Introduction

Kubernetes, a persistent volume claim (PVC) is a request for storage by a user. It is a way for a
pod to request a specific amount of storage from the cluster. When a PVC is created, it is
automatically bound to a persistant volume (PV) that satisfies the PVC's requirements.

A storage class (SC) is a way to define the properties of a PV. It is a blueprint for creating PVs,
and it specifies things like the type of storage, the amount of storage, and the access modes for
the PV. The cluster then uses the storage class to find or create a PV that matches the PVC's
requirements.

In summary:

- PVs are the actual storage resources in the cluster
- PVCs are requests for storage made by users
- SCs are the specifications for creating PVs.

## Exercise

### Overview

- Observe that the state of the postgres database is not persisted between pod lifecycles
- Inspect the Available StorageClasses (sc) of the cluster
- Create a PersistentVolume (pv) using dynamic volume provisioning
- Consume the PersistentVolume using a PersistentVolumeClaim (pvc) and mounting the volume to a pod
- Delete pod with volume attached and observe that state is persisted when a new pod is created

### Step by step instructions

<details>
<summary>
Step by step:
</summary>

### Observe that the state of the postgres database is not persisted between pod lifecycles

Deploy the manifests located in `persistent-storage/start`

> :bulb: If you have resources already deployed from a previous exercise, you might want to clean
> them up first.

- Open the frontend webpage in your browser.
- Observe that the frontend reports that it is connected to the database.
- Add some quotes. We will need them later to test persistency
- Retrieve all of the quotes, observe that your quotes are part of the retrieved quotes.
- Now delete the postgres pod using `kubectl delete pod <pod-name>`
- In the frontend webpage, retrieve quotes, and observe that you now only get the default 5 quotes
  from the database.

What we have observed here is that the state of our database is not persisted between pod lifecycles!
In order to fix this, we need to persist the filesystem state of our database container to a `volume`.

### Inspect the Available StorageClasses (sc) of the cluster

Use `kubectl` to get the available `StorageClasses` in the cluster, the shortname for `StorageClass`
is `sc`:

```shell
kubectl get StorageClasses
```

Expected output:

```shell
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  54m
```

We see that we indeed have a `StorageClass` available and ready for use!

<details>

<summary>:bulb: What do the columns mean?</summary>

The output of the `kubectl get sc` command provides some useful information about the StorageClass:

- `PROVISIONER` what is the underlying storage provider, in this case `AWS EBS` (Elastic Block Storage)
- `RECLAIMPOLICY` what will happen with the volume when the `PersistentVolume` resource is deleted,
  in this case `Delete` will delete the block storage.
- `VOLUMEBINDINGMODE` specifies how to provision the actual volume, `WaitForFirstConsumer` will
  provision the actual volume object once there is a matching claim.
- `ALLOWVOLUMEEXPANSION` defines whether a volume can be expanded in size at a later point in time.

</details>

### Create a PersistentVolume (pv) using dynamic volume provisioning

Let's create a `PersistentVolume` (pv)!

While we could create a manifest for a `PersistentVolume` manually we will not do that in this exercise.

In practice we will almost always create a `PersistentVolume` by creating `PersistentVolumeClaim`,
which uses a `StorageClass` to create the actual volume.

Create a new file `persistent-storage/start/postgres-pvc.yaml`

Copy and paste the below boilerplate yaml to the new file:

```yaml
apiVersion:
kind:
metadata:
  name:
spec:
  storageClassName:
  accessModes:
    -
  resources:
    requests:
      storage:
```

Next we fill in the values:

- The `apiVersion` should be `v1`
- The `kind` is `PersistentVolumeClaim`
- The `metadata.name` should be `postgres-pvc`
- From the previous section we know that we have one available `StorageClass`, so the value of
  `spec.storageClassName` is the name of that, in this case `"gp2"` (with quotes)
- The `spec.accessModes` list should contain one item with the value `ReadWriteOnce`
- the `spec.resources.requests.storage` is the size of the volume in Gibibytes (Gi), set it to `5Gi`

<details>
<summary>The finished manifest should look like this</summary>

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  storageClassName: "gp2"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

</details>

Apply your new `PersistenVolumeClaim` with `kubectl apply`:

```shell
kubectl apply -f persistent-storage/start/postgres-pvc.yaml
```

Expected output:

```text
persistentvolumeclaim/postgres-pvc created
```

Check that the `PersistentVolumeClaim` was created using `kubectl get`:

```shell
kubectl get persistentvolumeclaim
```

Expected output:

```text
NAME           STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
postgres-pvc   Pending                                      gp2            3m19s
```

Check if a `PersistentVolume` was created using `kubectl get`:

```shell
kubectl get persistentvolume
```

Expected output

```text
No resources found
```

> :bulb: `PersistentVolumes` objects are `cluster-wide`, ie. "not-namespaced", so you might see
> `PersistentVolumes` belonging to other users.

We expect that a PersistentVolume has not been created _yet._

As we can see in the `kubectl get persistentvolumeclaim` output above, our `PersistenVolumeClaim`
is in the `Pending` status.

This is because the `VOLUMEBINDINGMODE` of the StorageClass is set to `WaitForFirstConsumer`, as we
saw in the previous section.

`WaitForFirstConsumer` will not create the actual volume object until it is used by a pod.

> :bulb: The reason you might not want to not always create volumes as soon as `pvc` objects are
> created is to reduce costs, by not creating resources that are not used before they are attached
> to a pod.

Let's attach the PersistenVolumeClaim to our postgres pod!

### Consume the PersistentVolume using a PersistentVolumeClaim (pvc) and mounting the volume to a pod

Open the postgres deployment manifest in your text editor `persistent-storage/start/postgres-deployment.yaml`.

In the `spec.template.spec` add the following section:

```yaml
    ...
    spec:
      volumes:
        - name:
          persistentVolumeClaim:
            claimName:
      ...
```

Add the values to the snippet:

- `spec.template.spec.volumes[0].name` is the name we will reference when we mount the volume to a
  container in a moment. Set it to `postgres-pvc`.
- `spec.template.spec.volumes[0].persistentVolumeClaim.claimName` is the `name` of the
  `PersistenVolumeClaim` we have created above, set it to the name you used, e.g. `postgres-pvc`.

> :bulb: In this case the volume name and reference to the `pvc` name are the same, this is
> coincidental, and they can be different.

<details>
<summary>How the finished manifest should look</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  ...
spec:
  ...
  template:
    metadata:
      ...
    spec:
      volumes:
        - name: postgres-pvc # name we can reference below in container
          persistentVolumeClaim:
            claimName: postgres-pvc # name of the actual pvc
      containers:
      ...
```

</details>

Next we mount the volume we have defined to the postgres container:

In the deployment manifest file, add the following section to the postgres container spec, e.g. `spec.template.spec.containers[0].volumeMounts`

```yaml
volumeMounts:
  - name:
    mountPath:
    subPath:
```

Fill in the values:

- `name` should be the name we specified above when we declared the available volumes.
  In this case this should be `postgres-pvc`
- `mountPath` is the path in container to mount the volume to. For postgres, the database state is
  stored to the path `/var/lib/postgresql/data`
- `subPath` should be `postgres`, and specifies a directory to be created within the volume, we need
  this because of a quirk with combining `AWS EBS` with Postgres. (If you are curios why:
  <https://stackoverflow.com/a/51174380>)

<details>
<summary>The finished manifest should look like this</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  ...
spec:
  ...
  template:
    metadata:
      ...
    spec:
      volumes:
        - name: postgres-pvc # name we can reference below in container
          persistentVolumeClaim:
            claimName: postgres-pvc # name of the actual pvc
      containers:
        - image: docker.io/library/postgres:14.3
          name: postgres
          ...
          env:
            ...
          volumeMounts:
            - name: postgres-pvc
              mountPath: /var/lib/postgresql/data
              subPath: postgres
```

</details>

Apply the changes to the postgres deployment using `kubectl apply`:

```shell
kubectl apply -f persistent-storage/start/postgres-deployment
```

Expected output:

```text
deployment.apps/postgres configured
```

Observe that the `PersistentVolume` is now created:

```shell
kubectl get persistentvolumeclaims,persistentvolumes
```

Expected output:

```text
NAME                                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/postgres-pvc   Bound    pvc-60e5235b-e2bb-4d71-9136-3901ca4dece9   5Gi        RWO            gp2            <unset>                 3m55s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/pvc-00e46d16-c3a8-4b4c-8ccd-aaef24970f01   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-7    gp3            <unset>                          8d
persistentvolume/pvc-016b6e52-0dd5-4285-be5e-684128d0d2a1   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-56   gp3            <unset>                          8d
persistentvolume/pvc-02a003e1-2e97-410c-9499-ffe1ae982713   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-60   gp3            <unset>                          8d
persistentvolume/pvc-02d94c4e-556e-4f18-b3cf-dce6aa866016   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-59   gp3            <unset>                          8d
persistentvolume/pvc-045d9e12-3666-4666-9c47-011066cf4ab7   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-39   gp3            <unset>                          8d
persistentvolume/pvc-0aa311ea-7ec6-466b-ad6f-e78ac4bdca48   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-73   gp3            <unset>                          8d
persistentvolume/pvc-11f71f9c-a63f-4af7-a0ca-b970f0e119c0   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-45   gp3            <unset>                          8d
persistentvolume/pvc-1251ec6e-bd77-44b7-b718-98a1f2f1451c   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-64   gp3            <unset>                          8d
persistentvolume/pvc-1543a4ec-2565-43e9-b343-8d4c48468475   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-11   gp3            <unset>                          8d
persistentvolume/pvc-15683509-945a-42a3-a37b-7a5a6e967439   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-65   gp3            <unset>                          8d
persistentvolume/pvc-15a06ade-2da8-421a-99d3-2069e2b6c196   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-76   gp3            <unset>                          8d
persistentvolume/pvc-16c167ad-1933-4bdf-a93f-ec4f18267d90   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-42   gp3            <unset>                          8d
persistentvolume/pvc-1a19f657-9057-4e7a-ad79-12a02d374f82   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-17   gp3            <unset>                          8d
persistentvolume/pvc-1e302766-f772-44fa-85e6-b920c436897a   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-0    gp3            <unset>                          8d
persistentvolume/pvc-1e697605-f0aa-42ee-b30e-d53dfd6caa2b   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-20   gp3            <unset>                          8d
persistentvolume/pvc-1fff9f26-6be9-4c17-accf-88a00207cbcd   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-34   gp3            <unset>                          8d
persistentvolume/pvc-22470c21-2fca-42c4-9e1c-a06be4ddf7ad   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-53   gp3            <unset>                          8d
persistentvolume/pvc-24ea8c05-8bdb-485b-8541-3eb67d2de012   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-4    gp3            <unset>                          8d
persistentvolume/pvc-2a99943d-b33a-4e70-bedf-c76a4470dde1   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-84   gp3            <unset>                          8d
persistentvolume/pvc-2cb0beda-b70a-4801-b1b2-2cb05d851837   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-62   gp3            <unset>                          8d
persistentvolume/pvc-2ee41664-c2f7-46ac-a509-23dd905fb548   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-24   gp3            <unset>                          8d
persistentvolume/pvc-3068b592-6f5c-40af-8f66-2f954e591bcf   5Gi        RWO            Delete           Bound    student-76/postgres-pvc                              gp2            <unset>                          5m53s
persistentvolume/pvc-33c97802-67b5-483b-a8e8-d80884ec1196   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-29   gp3            <unset>                          8d
persistentvolume/pvc-3535a091-be7f-449b-8989-d148b70852d7   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-67   gp3            <unset>                          8d
persistentvolume/pvc-3792c72a-695a-4d68-9027-180963099f30   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-46   gp3            <unset>                          8d
persistentvolume/pvc-39ffeb2e-e62f-4dbe-8e2f-62a508467ed8   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-48   gp3            <unset>                          8d
persistentvolume/pvc-3b89ae32-81b0-44eb-bc21-bd836f573bf3   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-63   gp3            <unset>                          8d
persistentvolume/pvc-3ceef6f6-e4cc-4d5a-b03d-47b2bba6790f   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-55   gp3            <unset>                          8d
persistentvolume/pvc-3d8a2aad-22f2-4695-a386-90319679bc01   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-70   gp3            <unset>                          8d
persistentvolume/pvc-3f19b19a-19f3-4bcd-be6f-4e91d7259ee9   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-2    gp3            <unset>                          8d
persistentvolume/pvc-41c1411b-f01f-4f6e-872b-3cf15243b59e   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-41   gp3            <unset>                          8d
persistentvolume/pvc-42be04f9-d366-4422-8362-10b94e8a637a   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-21   gp3            <unset>                          8d
persistentvolume/pvc-4ef28400-5fe4-414f-bde4-4ad7bf85f67f   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-68   gp3            <unset>                          8d
persistentvolume/pvc-503543a6-2605-4774-852a-b5a113cc53f5   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-15   gp3            <unset>                          8d
persistentvolume/pvc-50391d8c-aecb-4846-bfa3-d7fef0d3b2fd   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-52   gp3            <unset>                          8d
persistentvolume/pvc-574f3e6a-d7fd-4aad-a883-060b3a96d020   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-50   gp3            <unset>                          8d
persistentvolume/pvc-5a245381-a2bc-4eb5-ba57-2da4c3b369c8   5Gi        RWO            Delete           Bound    default/postgres-pvc                                 gp2            <unset>                          8d
persistentvolume/pvc-5b78be48-effc-43a7-b97d-315647117934   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-25   gp3            <unset>                          8d
persistentvolume/pvc-5cfac69b-2987-41e9-a31d-64977c114be6   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-23   gp3            <unset>                          8d
persistentvolume/pvc-60a6bab6-d141-46c5-a5d9-ce4180cb0a67   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-57   gp3            <unset>                          8d
persistentvolume/pvc-60e5235b-e2bb-4d71-9136-3901ca4dece9   5Gi        RWO            Delete           Bound    student-19/postgres-pvc                              gp2            <unset>                          14s
persistentvolume/pvc-626158a5-6acc-41f3-a2f4-7d613dd426dd   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-79   gp3            <unset>                          8d
persistentvolume/pvc-6499594c-af86-4b63-bc01-5f5c886db94b   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-78   gp3            <unset>                          8d
persistentvolume/pvc-66056829-2e5d-49eb-be99-119ee33aa3cd   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-27   gp3            <unset>                          8d
persistentvolume/pvc-68780327-7dff-473b-91db-0da48068cc97   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-51   gp3            <unset>                          8d
persistentvolume/pvc-69cbb582-0cfc-4032-ac2c-2a762f0541eb   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-82   gp3            <unset>                          8d
persistentvolume/pvc-69ff0d85-7707-4707-93cd-25282c7b51aa   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-6    gp3            <unset>                          8d
persistentvolume/pvc-6d3194e3-43ff-4cc4-9768-37eee336e0ca   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-83   gp3            <unset>                          8d
persistentvolume/pvc-70a366a2-8e74-42ba-bf65-60c329426df5   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-32   gp3            <unset>                          8d
persistentvolume/pvc-70bd719a-5568-40cd-8887-6ca16a1cd033   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-22   gp3            <unset>                          8d
persistentvolume/pvc-70e1d13b-652d-4d00-aa61-f25ed9ec5c6c   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-10   gp3            <unset>                          8d
persistentvolume/pvc-790e4b48-75ab-4134-b5a0-215777ab5535   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-61   gp3            <unset>                          8d
persistentvolume/pvc-7b82b1c3-d2d6-4ffd-81f2-13083748db22   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-12   gp3            <unset>                          8d
persistentvolume/pvc-7fb97a98-ed1c-4f31-9b3f-6f8da86935c7   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-26   gp3            <unset>                          8d
persistentvolume/pvc-843bef94-9aa5-42ee-a1be-8719ae3cec3b   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-69   gp3            <unset>                          8d
persistentvolume/pvc-86454318-e4dd-4d89-bdfe-edc40a61f45d   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-81   gp3            <unset>                          8d
persistentvolume/pvc-86ddae43-4633-486d-8820-fd49a96d22fc   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-31   gp3            <unset>                          8d
persistentvolume/pvc-8851181b-bfb5-4543-8068-70f86b3add26   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-8    gp3            <unset>                          8d
persistentvolume/pvc-8b28aff0-a45b-404e-9184-d8589816eb09   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-9    gp3            <unset>                          8d
persistentvolume/pvc-8ee4147a-8fdf-4829-a82d-c9a645a89474   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-3    gp3            <unset>                          8d
persistentvolume/pvc-90832763-265b-4cd0-b59b-55aec86c71ef   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-35   gp3            <unset>                          8d
persistentvolume/pvc-923fdb6b-327c-4095-9396-b5b7bec34892   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-18   gp3            <unset>                          8d
persistentvolume/pvc-924a9572-6257-406b-ba40-37b952128cbb   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-71   gp3            <unset>                          8d
persistentvolume/pvc-93047b15-80e2-4dc1-8764-3c6ce9eea314   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-72   gp3            <unset>                          8d
persistentvolume/pvc-9451c373-d40a-4556-83d7-7172071580f7   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-36   gp3            <unset>                          8d
persistentvolume/pvc-9454a68d-153a-4d80-a170-0bb45d61dce6   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-44   gp3            <unset>                          8d
persistentvolume/pvc-94ede42f-75cc-45d6-9f84-63b5f9c4978e   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-54   gp3            <unset>                          8d
persistentvolume/pvc-9b24acf2-80c1-4b05-add5-753d268513ab   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-1    gp3            <unset>                          8d
persistentvolume/pvc-9cf3f0c5-935b-4a9a-bd60-7eacdfeb186a   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-16   gp3            <unset>                          8d
persistentvolume/pvc-a5f6d728-026d-48f9-b7ef-c7e49eea3199   5Gi        RWO            Delete           Bound    student-44/postgres-pvc                              gp2            <unset>                          9s
persistentvolume/pvc-aa995fa4-7c0b-4bd4-bf67-7745f739b6b4   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-47   gp3            <unset>                          8d
persistentvolume/pvc-abf09c27-03e0-4b6a-8454-48e435f71f6e   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-19   gp3            <unset>                          8d
persistentvolume/pvc-af5efa42-db08-416d-af61-e92354570d52   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-43   gp3            <unset>                          8d
persistentvolume/pvc-b0cee09a-bfa3-4a29-98f6-3471b926de65   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-14   gp3            <unset>                          8d
persistentvolume/pvc-baa0a4bf-8057-4490-8015-cd162356f931   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-37   gp3            <unset>                          8d
persistentvolume/pvc-be655c26-365e-47e5-9cf6-73feace5731b   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-58   gp3            <unset>                          8d
persistentvolume/pvc-c206e055-8fd9-47b2-bcbf-a5781e5d4b12   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-38   gp3            <unset>                          8d
persistentvolume/pvc-c242d1d4-3448-4b26-8f15-972215653f21   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-13   gp3            <unset>                          8d
persistentvolume/pvc-d46e9612-5eb2-4851-a4e6-c075e216172e   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-5    gp3            <unset>                          8d
persistentvolume/pvc-d7fe5335-fb15-4e76-af5d-73cc44149a34   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-77   gp3            <unset>                          8d
persistentvolume/pvc-d9eae565-f372-47ed-8df4-d4e493e0d9d6   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-74   gp3            <unset>                          8d
persistentvolume/pvc-dd509e0c-208a-44b1-b0bd-a950fa3f05fa   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-75   gp3            <unset>                          8d
persistentvolume/pvc-dfe846e0-2a66-4680-8884-f12e93a8097f   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-28   gp3            <unset>                          8d
persistentvolume/pvc-e30a23fe-55de-4d8e-9f88-a2ae0c983db8   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-40   gp3            <unset>                          8d
persistentvolume/pvc-e30cbac1-00e3-4d2a-a4c8-d7bf67069592   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-66   gp3            <unset>                          8d
persistentvolume/pvc-e37b322a-1a60-48ce-ab7c-f110989801e7   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-30   gp3            <unset>                          8d
persistentvolume/pvc-e3d0e01b-09c4-4ebf-b150-e2ef72ec7d46   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-49   gp3            <unset>                          8d
persistentvolume/pvc-e85c0f94-e1d3-4234-9eb8-19541fa9d38f   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-33   gp3            <unset>                          8d
persistentvolume/pvc-f2ad2087-120d-417b-aa53-26b0fe41d416   5Gi        RWO            Delete           Bound    student-0/postgres-pvc                               gp2            <unset>                          6h17m
persistentvolume/pvc-fa0dca95-bf4a-437b-9112-ad6b5ec7dacd   25Gi       RWO            Delete           Bound    code-server-workstations/coder-home-workstation-80   gp3            <unset>                          8d
persistentvolume/pvc-fc17f2e1-c7bc-4a43-8e3d-956dbedb0e97   8Gi        RWO            Delete           Bound    monitoring/prometheus-server                         gp2            <unset>                          8d
```

### Delete pod with volume attached and observe that state is persisted when a new pod is created

Now that the state of our postgres database is persisted to the volume, let's verify:

- Open the frontend webpage and add some quotes
- Retrieve quotes from the database, and observe that your quotes are among them
- Delete the database pod with `kubectl delete pod <postgres-pod-name>`
- Wait for the postgres pod to be recreated (you can watch for pod changes with `kubectl get pods --watch`)
- In the frontend webpage, retrieve quotes and obeserve that your quotes are among them

</details>

### Clean up

Delete all resources created using `kubectl delete -f <manifest-files>`

```shell
kubectl delete -f persistent-storage/start
```
