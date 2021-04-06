#!/bin/bash
find . -iname "*.md" -exec sh -c "cat {} | sh .test/parse_k8s_from_md.sh > {}.yaml" \;
