#!/bin/bash
kubectl --namespace=kube-system create secret generic secret-aws-dns-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=AKIAV6U4CCTT5IZOOUGV \
  --from-literal=AWS_SECRET_ACCESS_KEY=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 \
  --from-literal=AWS_DEFAULT_REGION=eu-central-1 \
  --from-literal=AWS_HOSTED_ZONE_ID=ZO5ESCGCDQT6O


# * `AWS_ACCESS_KEY_ID: 'AKIAJSNVTLH43A2Q'`
# * `AWS_SECRET_ACCESS_KEY: 'uC2QCpfDBUEWGG4L4693Hltm0HZchbb83'`
# * `AWS_DEFAULT_REGION: 'eu-central-1'`
# * `AWS_HOSTED_ZONE_ID: 'Z1SVJKHSFGHRL7'`


