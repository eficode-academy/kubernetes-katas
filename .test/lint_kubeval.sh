#!/bin/bash

# Select all yaml files, except the Helmsman related ones. These are
# detected by exluding files with filenames starting with "helmfile." or "values-".
KUBERNETES_RESOURCE_FILES=$(find * -type f \( -iname '*.yml' -or -iname '*.yaml' \) -and ! \( -iname "helmfile.yaml" -or -iname "values-*.yaml" -or -iname "*docker-compose*" \))

# Run all files through kubeval
docker run --rm -v `pwd`:/fixtures -w /fixtures garethr/kubeval $KUBERNETES_RESOURCE_FILES

