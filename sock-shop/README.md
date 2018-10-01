# Demo deployment of Sock-shop

This is a deployment of [Sock-shop](https://github.com/microservices-demo/microservices-demo), Prometheus and Grafana.

Prerequisites is a empty cluster, with a local kubectl authenticated towards the
cluster.  Helm and helmfile are used to deploy Prometheus and Grafana and should
thus be available on the host from where spinup.sh is executed.

Prometheus has been configured with a scape interval of 10s and has been
auto-configured as a datasource in Grafana.

Commands to spin-up all components are in spinup.sh (see also this file for how
to customize Grafana password).

Sock-shop is available at node-port 30001 and Grafana is available at node-port 30009.

Load-testing can be done with Apache-bench like this:

```
ab -c10 -t 360 -n 10000000 http://192.168.122.240:30001/
```

This will load the front-end, which can be scaled from one instance to e.g. three by:

```
kubectl scale --replicas 3 deploy front-end
```

Pod CPU load can be seen in the 'Kubernetes Pod Resources' dashboard (change the
update frequency to e.g. 5s and the horison to e.g. to 5min to get a better
view).  The front-end QPS can be seen in the bottom of the 'Sock-Shop
Performance' dashboard.
