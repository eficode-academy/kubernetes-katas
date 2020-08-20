#!/bin/bash
find . -iname "*.md" | xargs -I {} -n2 sh -c "cat {} | sh .test/parse_k8s_from_md.sh > {}.yaml"
