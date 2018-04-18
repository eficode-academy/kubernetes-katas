#!/bin/bash
# This script generates SSL certs (.crt and .key) to be used with nginx.
# The files are generated in .PEM format.

echo "Generating self signed certificate:"
openssl req \
  -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout tls.key -out tls.crt -subj '/CN=localhost'

echo

echo "Creating a combined PEM file out of the two certificate files:"
cat tls.crt tls.key > tls.pem


ls tls.*


