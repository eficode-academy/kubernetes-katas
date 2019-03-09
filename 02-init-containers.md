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


