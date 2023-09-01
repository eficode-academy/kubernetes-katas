#!/bin/bash

# Select all yaml files, except the Helmsman related ones. These are
# detected by exluding files with filenames starting with "helmfile." or "values-".
KUBERNETES_RESOURCE_FILES=$(find * -type f \( -iname '*.yml' -or -iname '*.yaml' \) -and ! \( -iname "helmfile.yaml" -or -iname "values-*.yaml" -or -iname "*docker-compose*" \))

excludes=(
  deployments-loadbalancing/start/frontend-deployment.yaml
  deployments-loadbalancing/start/backend-deployment.yaml
  manifests/start/frontend-pod.yaml
  services/start/backend-svc.yaml
  services/start/frontend-svc.yaml
  old/support-files/traefik-rbac-serviceaccount.yaml
  old/ingress-nginx/ingress.yml
  old/support-files/traefik-service.yaml
  old/extras/08-ingress-gke.md.yaml
  old/extras/08-ingress-gke.md.yaml
  old/extras/08-ingress-traefik.md.yaml
  old/support-files/traefik-rbac-serviceaccount.yaml
  old/extras/08-ingress-traefik.md.yaml
  old/extras/08-ingress-traefik.md.yaml
  old/extras/08-ingress-traefik.md.yaml
  old/ingress-gke/ingress.yml
  old/ingress-traefik/traefik-rbac.yaml
  old/ingress-traefik/traefik-rbac.yaml
  old/ingress-traefik/traefik-webui-ingress.yaml
  old/ingress-traefik/example-ingress.yaml
  old/ingress-traefik/my-ingress.yml
  old/ingress-traefik/traefik-ingress-controller.yml
)
for exclude in ${excludes[@]}
do
   KUBERNETES_RESOURCE_FILES=("${KUBERNETES_RESOURCE_FILES[@]/$exclude}")
done

# Run all files through kubeconform
docker run --rm -v ${PWD}:/fixtures -w /fixtures ghcr.io/yannh/kubeconform -summary $KUBERNETES_RESOURCE_FILES
