#!/bin/bash
if [ -d certs ]; then
  echo "certs folder exists. Backing it up ..."
  mv certs certsbak
else
  mkdir -p certs
fi

pushd certs
make -f ../tools/certs/Makefile.selfsigned.mk root-ca

ctxs=$(kubectl config view -o jsonpath='{.contexts[*].name}' | grep -v "docker-desktop" | sed 's/ /\n/g')
for ctx in $ctxs
do
make -f ../tools/certs/Makefile.selfsigned.mk "$ctx-cacerts"
kubectl config use-context $ctx
kubectl create namespace istio-system
kubectl create secret generic cacerts -n istio-system \
      --from-file=$ctx/ca-cert.pem \
      --from-file=$ctx/ca-key.pem \
      --from-file=$ctx/root-cert.pem \
      --from-file=$ctx/cert-chain.pem
done
popd