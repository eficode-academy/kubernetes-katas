# Init containers:
At times you may want to do some prep work for a container before starting it. That pre-work could be done by another container, which would do it's thing and exit before the main container starts. One example could be that you want to serve some static website content which exists as a git hub repository. So you would want something to pull that static content and provide it to the web server. This is called init-container. 

Below is an example. We have a "simple-website" which exists as `https://github.com/Praqma/simple-website.git` , we want to serve it through the nginx service.


```
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
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
