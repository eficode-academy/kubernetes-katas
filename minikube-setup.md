# MiniKube setup on Libvirt/KVM

Download minikube:

```
[root@kworkhorse ~]# yum install qemu-kvm
Last metadata expiration check: 2:08:46 ago on Fri 29 Jun 2018 08:29:07 AM CEST.
Package qemu-kvm-2:2.10.1-3.fc27.x86_64 is already installed, skipping.
Dependencies resolved.
Nothing to do.
Complete!

[root@kworkhorse ~]# curl -LO https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2 && chmod +x docker-machine-driver-kvm2 && sudo mv docker-machine-driver-kvm2 /usr/local/bin/
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 35.4M  100 35.4M    0     0   132k      0  0:04:34  0:04:34 --:--:--  105k

[root@kworkhorse ~]# curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 40.8M  100 40.8M    0     0   105k      0  0:06:35  0:06:35 --:--:-- 94594

[root@kworkhorse ~]# grep libvirt /etc/group
libvirt:x:981:demo

[root@kworkhorse ~]# gpasswd -a kamran libvirt
Adding user kamran to group libvirt

[root@kworkhorse ~]# gpasswd -a demo libvirt
Adding user demo to group libvirt

[root@kworkhorse ~]# 

```


```
[kamran@kworkhorse ~]$ minikube start --vm-driver kvm2
Starting local Kubernetes v1.10.0 cluster...
Starting VM...
Downloading Minikube ISO
 4.05 MB / 153.08 MB [=>-----------------------------------------]   2.64% 4m33s^C
[kamran@kworkhorse ~]$ minikube start --vm-driver kvm2
Starting local Kubernetes v1.10.0 cluster...
Starting VM...
Downloading Minikube ISO
 153.08 MB / 153.08 MB [============================================] 100.00% 0s
Getting VM IP address...
Moving files into cluster...
Downloading kubeadm v1.10.0
Downloading kubelet v1.10.0
Finished Downloading kubelet v1.10.0
Finished Downloading kubeadm v1.10.0
Setting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
Loading cached images from config file.

[kamran@kworkhorse ~]$ kubectl get pods
No resources found.

[kamran@kworkhorse ~]$ kubectl get nodes
NAME       STATUS    ROLES     AGE       VERSION
minikube   Ready     master    5m        v1.10.0
[kamran@kworkhorse ~]$ 
```



