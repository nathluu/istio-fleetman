#!/bin/bash
if [ -d certs ]; then
  echo "certs folder exists. Backing it up ..."
  mv certs certsbak
else
  mkdir -p certs
fi

cd certs
make -f ../tools/certs/Makefile.selfsigned.mk root-ca

ctxs=$(kubectl config view -o jsonpath='{.contexts[*].name}' | grep -v "docker-desktop" | sed 's/ /\n/g')
for ctx in $ctxs
do
make -f ../tools/certs/Makefile.selfsigned.mk "$ctx-cacerts"
done
