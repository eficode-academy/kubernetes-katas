# Kubernetes cluster

Create the cluster on Google Kubernetes Engine

Things to remember:

- Open the firewall to the cluster `gcloud compute firewall-rules create alltcpmike --allow tcp`
- Need to create an IAM -> service account in the project and give it the role `Kubernetes Engine -> Kubernetes Engine Developer`
- Make sure you use the region `europe-west1-b`
- Make sure you use the name `training-cluster-instructor-name` or `training-cluster-clientname--date` .


# Trainer notes by Kamran
* Login to GCP [https://cloud.google.com](https://cloud.google.com) with your Praqma ID (or personal ID - if you want)
* There is a project titled "praqma-education", use that project, but **DO NOT DELETE THIS PROJECT** . 
**Note:** In case you are using your private/personal google ID, you are free to create any (new) project , as you will be responsible for it's billing. Though billing/cost for a 2-3 node k8s cluster for one day is negligible anyhow.
* Once you have selected a project, you can now create a cluster inside it. Create a cluster with clear name, such as `test-cluster-client-X-20190617` . Normally a single 3 node cluster (with 3.7 GB RAM in each node)  is good enough for ~20 participants. Make sure to add tags/labels which can be used to identify who created this cluster, why and when; and a date after which the cluster can be deleted by any admin for cleanup purpose.
- Make sure you use the region `europe-west1-b`. This is important for admins to find all clusters at one place, and they don't have to hunt for clusters in every GCP zone during clean-up.
- Normally, if you are an owner of a project, you don't need special permissions/roles assigned to you, nor you need to create additional service accounts under IAM. However, if there is a need, you can create a new service account under  `IAM -> service account` in the project, and give it the role `Kubernetes Engine -> Kubernetes Engine Admin`. 
* It is also best to create a separate (small - 1 CPU, 1.7 GB RAM) VM which will work as **Jumpbox** for all students. This is the machine you will create multiple OS/SSH accounts for all students ( very easily done through a bash script). **Note:** With a  smaller VM you will experience high CPU usage on the jumpbox and will become painfully unusable.
* This VM is also where you will install `kubectl` and `helm` binaries. VMs created in GCP already have gcloud utility installed in them! This will avoid all the headache of installing kubectl or helm on a student's PC (Linux, MAC, Windows). 
* For the sake of training, modify `/etc/ssh/sshd_config` on the Jumpbox to allow password based SSH login. Key based authentication should be disabled, for simplicity's sake - during the training. This will make life much easier for the trainer. Restart sshd service after the modifications.
```
$ sudo sed -i 's/^PasswordAuthentication\ no/PasswordAuthentication\ yes/g' /etc/ssh/sshd_config
$ systemctl restart sshd
```
* To experiment with NodePorts, the students will need to access some ports on worker nodes. This means you need to add a firewall rule to allow traffic to those ports. Go to `VPC Network -> Firewall rules` and add a rule with following conditions:
 * Name: ports-for-nodeport-services
 * Network: default
 * Tarffic direction: Ingress
 * Action on match: Allow
 * Targets: All instances in the network
 * Source Filter: IP range
 * Source IP range: 0.0.0.0/0
 * Protocols and ports: Specified protocols and ports (tcp: 30000-32767)
* If you have gcloud configured on your work computer to talk to correct project, then you can also use the following command to create  similar firewall rule:
```
$ gcloud compute firewall-rules create ports-for-nodeport-services --action=ALLOW --allow=tcp:30000-32767
```
**Note: If no port or port range is specified, the rule applies to all destination ports. 
* Login to the jumpbox VM using over SSH as the main user, then switch to root - optional.
* Install `kubectl` and `helm` binaries; and also `git`.
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl


curl -LO https://get.helm.sh/helm-v2.14.1-linux-amd64.tar.gz
tar xzf helm-v2.14.1-linux-amd64.tar.gz
chmod +x linux-amd64/helm
sudo mv linux-amd64/helm  /usr/local/bin/helm 

sudo yum -y install git
```

* Now on the jumpbox, (for the main user (kamran)) ,you need to have `.kube/config` (the credentials to connect to the kubernetes cluster).
* Login to jumpbox as regular user and run the following commands:

```
[kamran@kamran-jumpbox ~]$ gcloud config set account kaz@praqma.net
Updated property [core/account].

[kamran@kamran-jumpbox ~]$ gcloud auth login

You are running on a Google Compute Engine virtual machine.
It is recommended that you use service accounts for authentication.

You can run:

  $ gcloud config set account `ACCOUNT`

to switch accounts if necessary.

Your credentials may be visible to others with access to this
virtual machine. Are you sure you want to authenticate with
your personal account?

Do you want to continue (Y/n)?  Y

Go to the following link in your browser:

    https://accounts.google.com/o/oauth2/auth?redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&prompt=select_account&response_type=code&client_id=1234567890.apps.googleusercontent.com&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fappengine.admin+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcompute+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Faccounts.reauth&access_type=offline


Enter verification code: 9/DAE-0-4bmfgfgfsd3-Gsddfsdyh5-Dgdtm9n

WARNING: `gcloud auth login` no longer writes application default credentials.
If you need to use ADC, see:
  gcloud auth application-default --help

You are now logged in as [kaz@praqma.net].

Your current project is [praqma-education].  You can change this setting by running:

  $ gcloud config set project PROJECT_ID
```


* Now you need to fetch the kubernetes credentials. Go to "Kubernetes Engine -> Clusters", and press the `Connect` button for your cluster. This will show you the connect command you need to run to get credentials.
```
$ gcloud container clusters get-credentials kamran-test-cluster-0617 --zone europe-north1-a --project praqma-education
```

```
[kamran@kamran-jumpbox ~]$ gcloud container clusters get-credentials kamran-test-cluster-0617 --zone europe-north1-a --project praqma-education
Fetching cluster endpoint and auth data.
kubeconfig entry generated for kamran-test-cluster-0617.
[kamran@kamran-jumpbox ~]$ 
```

**Note:** You may get an error, something like this:
```
[kamran@kamran-jumpbox ~]$ gcloud container clusters get-credentials kamran-test-cluster-0617 --zone europe-north1-a --project praqma-education
Fetching cluster endpoint and auth data.
ERROR: (gcloud.container.clusters.get-credentials) ResponseError: code=403, message=Request had insufficient authentication scopes.
[kamran@kamran-jumpbox ~]$ 
```
The above means that you are not authenticated to GCP properly. Run the `gcloud auth login` command again, and use the correct google ID to authenticate to GCP.

* At this point, you should be able to connect to the cluster, and list nodes:
```
[kamran@kamran-jumpbox ~]$ kubectl get nodes -o wide
NAME                                                  STATUS   ROLES    AGE    VERSION         INTERNAL-IP   EXTERNAL-IP     OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-kamran-test-cluster--default-pool-6d441d21-3r0l   Ready    <none>   105m   v1.12.8-gke.6   10.166.0.2    35.228.253.32   Container-Optimized OS from Google   4.14.119+        docker://17.3.2
[kamran@kamran-jumpbox ~]$ 
```

* Now you need to create multiple SSH/OS user-accounts for students and propagate this `.kube/config` file to all the student accounts. There is a bash script in this repository, which does this. Copy the bash script to jumpbox, and run it as `root`. Or, clone this git repository on jumpbox, which will automatically provide you this file. It is located in `support-files`.

```
[root@kamran-jumpbox ~]# ./setup-student-accounts.sh 1 kamran

Creating user: student-1 with password: student-06-17-19
Changing password for user student-1.
passwd: all authentication tokens updated successfully.
[root@kamran-jumpbox ~]# ls -la /home/student-1/.kube/
total 8
drwxr-xr-x. 4 student-1 student-1   51 Jun 17 22:37 .
drwx------. 3 student-1 student-1   75 Jun 17 22:37 ..
drwxr-x---. 3 student-1 student-1   23 Jun 17 22:37 cache
-rw-------. 1 student-1 student-1 2540 Jun 17 22:37 config
drwxr-x---. 3 student-1 student-1 4096 Jun 17 22:37 http-cache
[root@kamran-jumpbox ~]# su - student-1
[student-1@kamran-jumpbox ~]$ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE    VERSION
gke-kamran-test-cluster--default-pool-6d441d21-3r0l   Ready    <none>   127m   v1.12.8-gke.6
[student-1@kamran-jumpbox ~]$ 
```

Congratulations! your jumpbox is ready! All you need to do is to provide SSH credentials of `student-X` accounts to your students, and ask them to login to the jumpbox to start using the kubernetes cluster.


------------------------

# Other notes - please ignore - for now:

Logged in to student user and tried a kubernetes command, which failed. Apparently some sort of auth token has expired.
```
[root@kamran-jumpbox ~]# su - student-1
Last login: Mon Jun 17 22:38:11 UTC 2019 on pts/0

[student-1@kamran-jumpbox ~]$ kubectl get services
error: You must be logged in to the server (Unauthorized)
```


It seems to work with the main user-account!
```
[student-1@kamran-jumpbox ~]$ logout

[root@kamran-jumpbox ~]# su - kamran
Last login: Mon Jun 17 21:52:07 UTC 2019 on pts/0

[kamran@kamran-jumpbox ~]$ kubectl get services
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.47.240.1   <none>        443/TCP   11h

[kamran@kamran-jumpbox ~]$ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE   VERSION
gke-kamran-test-cluster--default-pool-6d441d21-3r0l   Ready    <none>   11h   v1.12.8-gke.6

[kamran@kamran-jumpbox ~]$ kubectl get services
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.47.240.1   <none>        443/TCP   11h
```

Shortest way is to delete the student user-account and re-create it.
```
[kamran@kamran-jumpbox ~]$ logout

[root@kamran-jumpbox ~]# userdel -r student-1

[root@kamran-jumpbox ~]# ./setup-student-accounts.sh 1 kamran

Creating user: student-1 with password: student-06-18-19
Changing password for user student-1.
passwd: all authentication tokens updated successfully.

[root@kamran-jumpbox ~]# su - student-1

[student-1@kamran-jumpbox ~]$ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE   VERSION
gke-kamran-test-cluster--default-pool-6d441d21-3r0l   Ready    <none>   11h   v1.12.8-gke.6

[student-1@kamran-jumpbox ~]$ kubectl get services
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.47.240.1   <none>        443/TCP   11h
[student-1@kamran-jumpbox ~]$ 
```

