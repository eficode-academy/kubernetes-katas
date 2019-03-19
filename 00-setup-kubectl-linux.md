# Setup kubectl

It is assumed that you are provided with a kubernetes cluster by the instructor. Before you are able to do anything on the cluster, you need to be able to *talk* to this cluster from/using your computer. **kubectl** - short for Kubernetes Controller (or Kube Control) - is *the* command line tool to talk to a Kubernetes cluster. 

## What is kubectl?
`kubectl` is a *go* binary which allows you to execute commands on your cluster. Your cluster could be a single node VM, such as [minikube](https://github.com/kubernetes/minikube), or a set of VMs on your local computer or somewhere on a host in your data center, a bare-metal cluster, or a cluster provided by any of the cloud providers - as a service - such as GCP. In any case, the person who sets up the kubernetes cluster will provide you with the credentials to access the cluster. Normally it the credentials are in a form of a file called `.kube/config`, which is generated automatically when you provision a kubernetes cluster using `minikube` , `kubeadm` or `kube-up.sh` or any other methods.

For the remainder of this workshop, we assume you have a Kubernetes cluster on google cloud. For instructions on connecting to minikube and kubeadm based clusters, the information is available [here](https://github.com/KamranAzeem/learn-kubernetes/tree/master/minikube), and [here](https://github.com/KamranAzeem/learn-kubernetes/blob/master/kubeadm/README.md). 

**Note:** It is useful to know that `kubectl` binary is also part of **Google Cloud SDK** . If you install google-cloud-sdk, then you can use gcloud to install the `kubectl` component/binary. If you are already provided with a kubernetes cluster *config* file by your instructor, then you probably don't need to install google-cloud-sdk. In that case you will need to follow these instructions to install `kubectl` on your computer.

To get `kubectl` on your computer, you have to use the following commands:

## Linux:
Run the following commands:
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl
```

## macOS:
Run the following commands:
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl
```

## Windows:
First, check the latest version of kubectl from [https://storage.googleapis.com/kubernetes-release/release/stable.txt](https://storage.googleapis.com/kubernetes-release/release/stable.txt)

Then, using the version information you got from the above link, run the following `curl` command to download the `kubectl.exe` file on your computer. (Replace `v1.13.0` with the version you got from the above link)
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/windows/amd64/kubectl.exe
```


# Configure kubectl to access your cluster:

There are several ways to configure kubectl to be able to talk to your kubernetes cluster. Some/most-useful are described in the sections below.

**Note:** This will be a straight-forward procedure for most of the students, who are new to Kubernetes, and this is their first interaction with a kubernetes cluster. However, there will be some students, who may already have access to some clusters, and they will have their `kubectl` configured to talk to those clusters. They may be concerned that the procedure below may over-write their configurations, or they may lose access to their existing clusters. This is to assure you that nothing bad will happen to your existing `kubectl` configurations. Whenever you configure `kubectl` to talk to a cluster, it adds a new set of entries on your existing `~/.kube/config` file. However, to be safe, and for peace of mind, you should backup your `~/.kube/config` before proceeding with the instructions below.

## Configure kubectl to connect to your cluster - using `config` file provided by instructor:
In case you are provided by the `config` file, simply create a `.kube` directory under your home directory, place it inside it. i.e. `/home/<username>/.kube/`. This file already contains all information to correctly authenticate and connect to the cluster assigned to you.  Make sure to backup any existing `.kube/config` before you do this. 

**Note:** Windows users need to adjust the path to the home directory in the instructions above. 

## Authenticate to your Google k8s cluster - using gcloud utility:
(Of-course, this does not apply to minikube and kubeadm based clusters). 

This step is needed if you are **not** provided with a `config` file by your instructor, or, you have a kubernetes cluster of your own in google cloud, which you want to connect to.

To authenticate against your cluster, you will need a gmail account. You also need `gcloud` utility from Google Cloud SDK installed on your computer. The Cloud SDK is a set of tools for Cloud Platform. It contains gcloud, gsutil, and bq command-line tools, which you can use to access Google Compute Engine, Google Cloud Storage, Google BigQuery, and other products and services from the command-line.

The following commands will install Google Cloud SDK on your computer, and also run the authentication process to connect to your cluster - using `gcloud` command. 

### Debian / Ubuntu:

**Note:** Make sure Python 2.7 is installed on your system before you proceed with installing google cloud SDK. Check with `python -V` command.

Install the google-cloud-sdk:
```shell
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install google-cloud-sdk
```

Create key file on your vm - the instructor will mail you the contents
```
vi keyfile.json
```

Authenticate to google cloud with `keyfile.json`:
```
gcloud auth activate-service-account --key-file keyfile.json
```

Get the cluster credentials for kubectl:
```
gcloud container clusters get-credentials training-cluster --zone europe-west1-b --project praqma-education
```

Google will do some magic under the hood, which does a few things:
* Fetches certificates and tokens (secrets)
* Puts them into the Kubernetes configuration file, located at `/home/<username>.kube/config`

More information about installing google-cloud-sdk is here: [https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu](https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu)

### CENTOS / Fedora / RedHat:
The following instructions are tested on CENTOS 7, RHEL 7, and Fedora 29.

**Note:** Make sure Python 2.7 is installed on your system before you proceed with installing google cloud SDK. Check with `python -V` command.

Create Cloud SDK YUM repo:
```shell
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
```
Note: The indentation for the 2nd line of gpgkey (above) is important.


Install the Cloud SDK:
```
sudo yum install google-cloud-sdk
```

Create key file on your vm - the instructor will mail you the contents
```
vi keyfile.json
```

Authenticate to google cloud with `keyfile.json`:
```
gcloud auth activate-service-account --key-file keyfile.json
```

Get the cluster credentials for kubectl:
```
gcloud container clusters get-credentials training-cluster --zone europe-west1-b --project praqma-education
```

Google will do some magic under the hood, which does a few things:
* Fetches certificates and tokens (secrets)
* Puts them into the Kubernetes configuration file, located at `/home/<username>.kube/config`

More information about installing google-cloud-sdk is here: [https://cloud.google.com/sdk/docs/quickstart-redhat-centos](https://cloud.google.com/sdk/docs/quickstart-redhat-centos)

### Linux - Generic:

**Note:** Make sure Python 2.7 is installed on your system before you proceed with installing google cloud SDK. Check with `python -V` command.

Download the `google-cloud-sdk.tar.gz` archive file from [https://cloud.google.com/sdk/docs/quickstart-linux](https://cloud.google.com/sdk/docs/quickstart-linux). Visit the link to obtain the information about the latest version of SDK, and use that in the command below:

```
cd ~
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-238.0.0-linux-x86_64.tar.gz
```

Extract the archive to any location on your file system; preferably, your Home folder. You can use this command:
```
tar xzf  google-cloud-sdk-238.0.0-linux-x86_64.tar.gz  google-cloud-sdk
```

Above command will create a directory under your home directory, i.e. `/home/<username>/google-cloud-sdk/` . 

Then, run the google cloud SDK installer, which will update your PATH environment variable also.

```
./google-cloud-sdk/install.sh
```

After gcloud-cloud-sdk installation is finished, restart your command terminal, so the changes (e..g PATH) could take effect.

Next, run the following commands to authenticate to the google kubernetes cluster you are assigned:

Create key file on your vm - the instructor will mail you the contents
```
vi keyfile.json
```

Authenticate to google cloud with `keyfile.json`:
```
gcloud auth activate-service-account --key-file keyfile.json
```

Get the cluster credentials for kubectl:
```
gcloud container clusters get-credentials training-cluster --zone europe-west1-b --project praqma-education
```

Google will do some magic under the hood, which does a few things:
* Fetches certificates and tokens (secrets)
* Puts them into the Kubernetes configuration file, located at `/home/<username>.kube/config`

More information about installing google-cloud-sdk is here: [https://cloud.google.com/sdk/docs/quickstart-linux](https://cloud.google.com/sdk/docs/quickstart-linux)



### macOS:

**Note:** Make sure Python 2.7 is installed on your system before you proceed with installing google cloud SDK. Check with `python -V` command.

Visit [https://cloud.google.com/sdk/docs/quickstart-macos](https://cloud.google.com/sdk/docs/quickstart-macos), and find and download the tarball of latest version of google-cloud-sdk for your operating system. 

Extract the archive to any location on your file system; preferably, your Home directory. On macOS, this can be achieved by opening the downloaded .tar.gz archive file in the preferred location.

Use the install script `install.sh` to add Cloud SDK tools to your path. You will also be able to opt-in to command-completion for your bash shell and usage statistics collection during the installation process. Run the script using this command:

```
./google-cloud-sdk/install.sh
```


After gcloud-cloud-sdk installation is finished, restart your command terminal, so the changes (e..g PATH) could take effect.

Next, run the following commands to authenticate to the google kubernetes cluster you are assigned:

Create key file on your vm - the instructor will mail you the contents
```
vi keyfile.json
```

Authenticate to google cloud with `keyfile.json`:
```
gcloud auth activate-service-account --key-file keyfile.json
```

Get the cluster credentials for kubectl:
```
gcloud container clusters get-credentials training-cluster --zone europe-west1-b --project praqma-education
```

Google will do some magic under the hood, which does a few things:
* Fetches certificates and tokens (secrets)
* Puts them into the Kubernetes configuration file, located at `/home/<username>.kube/config`

For more information about installing google-cloud-sdk on macOS, visit this link: [https://cloud.google.com/sdk/docs/quickstart-macos](https://cloud.google.com/sdk/docs/quickstart-macos)

### Windows: 

Download the Google Cloud SDK installer from here: [https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe](https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe)

You need to have the google cloud project details of your cluster before you start the installer. Your instructor will provide you with this information.

Launch installer and follow the prompts. On the last screen of the install wizard, make sure that the following are selected:

* Start Google Cloud SDK Shell
* Run 'gcloud init'

The installer then starts a terminal window and runs the gcloud init command. Use the cloud project details you already have during the `gcloud init` process.


For more information, visit this link: [https://cloud.google.com/sdk/docs/quickstart-windows](https://cloud.google.com/sdk/docs/quickstart-windows)


## Verify configuration:

Now that you have completed the `kubectl` setup, you need to verify that you have configured `kubectl` *correctly*, and it is able to *talk to* your kubernetes cluster.

```
kubectl config view
```

You should see something like this:

```
$ kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: REDACTED
    server: https://1.2.3.4
  name: gke_praqma-education_europe-west1-b_dcn-cluster-35
contexts:
- context:
    cluster: gke_praqma-education_europe-west1-b_dcn-cluster-35
    user: gke_praqma-education_europe-west1-b_dcn-cluster-35
  name: gke_praqma-education_europe-west1-b_dcn-cluster-35
current-context: gke_praqma-education_europe-west1-b_dcn-cluster-35
kind: Config
preferences: {}
users:
- name: gke_praqma-education_europe-west1-b_dcn-cluster-35
  user:
    password: secret-password-ea4a2fb76dc9
    username: admin
```

There is also a `kubectl cluster-info` command, which gives you the address of the master node:
```
$ kubectl cluster-info
Kubernetes master is running at https://1.2.3.4
KubeDNS is running at https://1.2.3.4:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

If `kubectl cluster-info` returns the url response but you can’t access your cluster, to check whether it is configured properly, use:
```
kubectl cluster-info dump
```

At this point, you should now have access to the google cloud cluster! Verify by looking at the nodes for the cluster:

```
kubectl get nodes
```

You should be able to see something similar to what is shown below:
```
$ kubectl get nodes
NAME                                             STATUS    ROLES     AGE       VERSION
ip-172-20-40-108.eu-central-1.compute.internal   Ready     master    1d      v1.8.0
ip-172-20-49-54.eu-central-1.compute.internal    Ready     node      1d      v1.8.0
ip-172-20-60-255.eu-central-1.compute.internal   Ready     node      1d      v1.8.0
```

If you add the `-o wide` parameters to the above command, you will also see the public IP addresses of the nodes:

```
$ kubectl get nodes -o wide
NAME                                            STATUS    ROLES     AGE       VERSION        EXTERNAL-IP     OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-dcn-cluster-35-default-pool-dacbcf6d-3918   Ready     <none>    17h       v1.8.8-gke.0   35.205.22.139   Container-Optimized OS from Google   4.4.111+         docker://17.3.2
gke-dcn-cluster-35-default-pool-dacbcf6d-c87z   Ready     <none>    17h       v1.8.8-gke.0   35.187.90.36    Container-Optimized OS from Google   4.4.111+         docker://17.3.2
```

**Note:** On Kubernetes clusters provided by a Kubernetes service provider, you will only see worker nodes as a result of executing the above command. On other clusters, you will see both master and worker nodes.

```
$ kubectl get nodes -o wide
NAME                                             STATUS    ROLES     AGE     VERSION   EXTERNAL-IP     OS-IMAGE                      KERNEL-VERSION   CONTAINER-RUNTIME
ip-172-20-40-108.eu-central-1.compute.internal   Ready     master    1d      v1.8.0    1.2.3.4         Debian GNU/Linux 8 (jessie)   4.4.78-k8s       docker://1.12.6
ip-172-20-49-54.eu-central-1.compute.internal    Ready     node      1d      v1.8.0    2.3.4.5         Debian GNU/Linux 8 (jessie)   4.4.78-k8s       docker://1.12.6
ip-172-20-60-255.eu-central-1.compute.internal   Ready     node      1d      v1.8.0    5.6.7.8         Debian GNU/Linux 8 (jessie)   4.4.78-k8s       docker://1.12.6
```

**Note:** Depending on the setup for this workshop, you may not be the only tenant on the cluster; you may be sharing it with the rest of the people around you in the course! So be careful!
