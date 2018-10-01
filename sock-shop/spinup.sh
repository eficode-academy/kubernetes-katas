#!/bin/sh

set -uex

kubectl create -f tiller-serviceaccount.yaml
helm init --wait --service-account tiller-kube-system --tiller-image gcr.io/kubernetes-helm/tiller:v2.10.0

kubectl create -f grafana-prometheus-datasource.yaml

GRAFANA_ADMIN_PASSWD=adminPW helmfile -f helmfile.yaml sync

kubectl create ns sock-shop
kubectl -nsock-shop create cm plogo --from-file=logo.png
kubectl create -f complete-demo.yaml
kubectl -nsock-shop create -f grafana-configmap.yaml

cat << EOF | xargs -I{} kubectl -nsock-shop annotate svc {} prometheus.io/scrape='true'
carts
carts-db
catalogue
catalogue-db
front-end
orders
orders-db
payment
queue-master
rabbitmq
shipping
user
user-db
EOF
