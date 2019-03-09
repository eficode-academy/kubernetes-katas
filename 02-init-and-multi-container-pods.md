I find it appropriate to introduce multiple containers earlier in this course, so the students can really grasp the idea of having multiple containers in a single pod early on. This will help distinguide kubernetes from docker right from the beginning.

# Init containers:
At times you may want to do some prep work for a container before starting it. That pre-work could be done by another container, which would do it's thing and exit before the main container starts. One example could be that you want to serve some static website content which exists as a git hub repository. So you would want something to pull that static content and provide it to the web server. This is called init-container. 

Below is an example, in which we have a "simple-website". The website exists as git repository at `https://github.com/Praqma/simple-website.git` , we want to serve it through the nginx service.

Here is the yaml file which contains the definition of a pod that uses an init container.
```
$ cat support-files/init-container-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-container-demo
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: web-content-dir
      mountPath: /usr/share/nginx/html
  initContainers:
  - name: helper
    image: alpine/git
    command:
    - git 
    - clone
    - https://github.com/Praqma/simple-website.git
    - /web-content/
    volumeMounts:
    - name: web-content-dir
      mountPath: "/web-content"
  volumes:
  - name: web-content-dir
    emptyDir: {}
```

Create the pod using the following command:

```
$ kubectl create -f support-files/init-container-pod.yaml 
pod "init-container-demo" created
$ 
```

Watch the pod going through several phases:
```
$ kubectl get pods -w
NAME                         READY     STATUS     RESTARTS   AGE
init-container-demo          0/1       Init:0/1   0          0s
multitool-5558fd48d4-snr8j   1/1       Running    0          22h
init-container-demo   0/1       Init:0/1   0         4s
init-container-demo   0/1       PodInitializing   0         6s
init-container-demo   1/1       Running   0         7s
$ 
```

Final state would look like this:
```
$ kubectget pods 
NAME                         READY     STATUS    RESTARTS   AGE
init-container-demo          1/1       Running   0          1m
multitool-5558fd48d4-snr8j   1/1       Running   0          22h
$ 
```

Examine the pod using `kubectl describe` and also by logging into it using `kubectl exec` .

# Multi-container pods and side-cars:
There are instances when you may have two containers in the same pod. A very primitiv example would be a pod in which one container generates the web content on continuous basis, and another container serves the web content. This is different from init container example. In the init-container example, the "puller" pulls the static content only once, saves it in a shared storage, and exists, and the main web-server container serves that static content. In this example there is no puller, instead there is a "content-generator", which will run as a **side-car** , and will constantly add content in the the shared storage volume, which the web server will use to serve the content.

Here is the code for such a multi-contianer pod:

```
$ cat multi-container-pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-demo
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: web-content-dir
      mountPath: /usr/share/nginx/html
  - name: content-generator
    image: busybox
    command: ['sh', '-c', 'while true; do echo Date and Time is $(date) >> /web-content/index.html && sleep 5; done']
    volumeMounts:
    - name: web-content-dir
      mountPath: "/web-content"

  volumes:
  - name: web-content-dir
    emptyDir: {}
$ 
```


Lets create this pod:

```
$ kubectl create -f multi-container-pod.yaml 
pod "multi-container-demo" created
$

$ kubectl get pods -o wide
NAME                         READY     STATUS    RESTARTS   AGE       IP            NODE
multi-container-demo         2/2       Running   0          21s       10.200.0.22   kubeadm-node1
multitool-5558fd48d4-snr8j   1/1       Running   0          23h       10.200.1.28   kubeadm-node2
$
```

Lets login into the multitool and try to access the web page of the nginx container from the multicontainer-pod.

```
$ kubectl exec -it multitool-5558fd48d4-snr8j bash

bash-4.4# curl 10.200.0.22

Date and Time is Sat Mar 9 16:21:28 UTC 2019
Date and Time is Sat Mar 9 16:21:33 UTC 2019
Date and Time is Sat Mar 9 16:21:38 UTC 2019
Date and Time is Sat Mar 9 16:21:43 UTC 2019
Date and Time is Sat Mar 9 16:21:48 UTC 2019
bash-4.4#
```

Notice that the web page has entries with time difference of 5 seconds. If you "watch" this, you will see it in action.

```
bash-4.4# watch curl -s 10.200.0.22
Date and Time is Sat Mar 9 16:21:28 UTC 2019
Date and Time is Sat Mar 9 16:21:33 UTC 2019
Date and Time is Sat Mar 9 16:21:38 UTC 2019
Date and Time is Sat Mar 9 16:21:43 UTC 2019
Date and Time is Sat Mar 9 16:21:48 UTC 2019
Date and Time is Sat Mar 9 16:21:53 UTC 2019
Date and Time is Sat Mar 9 16:21:58 UTC 2019
Date and Time is Sat Mar 9 16:22:03 UTC 2019
```

Lets exec into the content-generator container in this multi-container pod. If you try to exec into any of the container in a multi-container pod, without specifying the name of the container, you will see the following message:

```
$ kubectl exec -it multi-container-demo /bin/sh
Defaulting container name to nginx.
Use 'kubectl describe pod/multi-container-demo -n default' to see all of the containers in this pod.
/ #
```

You can see that if you do not specify the container name while doing exec (or even log - later), you will be sent to the first container kubernetes sees in the pod, which may not be the correct one. In our case it defaulted to the nginx container. You need to use `kubectl describe pod <pod-name>` command to get the list of containers of a pod. In our case the name of the container is "content-generator".

So, now we will specify the exact container in the pod to exec into:

```shell
$ kubectl exec -it multi-container-demo -c content-generator /bin/sh
/ # ls
bin          etc          proc         sys          usr          web-content
dev          home         root         tmp          var

/ # ps
PID   USER     TIME  COMMAND
    1 root      0:00 sh -c while true; do echo Date and Time is $(date) >> /web-content/index.html && sleep 5; done
   74 root      0:00 /bin/sh
   84 root      0:00 sleep 5
   86 root      0:00 ps
/ # exit
$
``` 
I checked the processes running in that container and see that the command I specified in the container's specification, is running. 

Similarly, if I want to check logs of a container in a multi-container pod, I have to do the same:

```
$ kubectl logs -f multi-container-demo -c nginx 
10.200.1.28 - - [09/Mar/2019:16:22:05 +0000] "GET / HTTP/1.1" 200 360 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:21 +0000] "GET / HTTP/1.1" 200 495 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:28 +0000] "GET / HTTP/1.1" 200 540 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:35 +0000] "GET / HTTP/1.1" 200 630 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:37 +0000] "GET / HTTP/1.1" 200 630 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:39 +0000] "GET / HTTP/1.1" 200 675 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:41 +0000] "GET / HTTP/1.1" 200 675 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:43 +0000] "GET / HTTP/1.1" 200 675 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:45 +0000] "GET / HTTP/1.1" 200 720 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:47 +0000] "GET / HTTP/1.1" 200 720 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:49 +0000] "GET / HTTP/1.1" 200 765 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:51 +0000] "GET / HTTP/1.1" 200 765 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:53 +0000] "GET / HTTP/1.1" 200 765 "-" "curl/7.61.1" "-"
10.200.1.28 - - [09/Mar/2019:16:22:55 +0000] "GET / HTTP/1.1" 200 810 "-" "curl/7.61.1" "-"
```





