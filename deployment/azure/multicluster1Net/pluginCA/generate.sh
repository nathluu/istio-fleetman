#!/usr/bin/env sh
if [ -d certs ]; then
  echo "certs folder exists"
else
  mkdir -p certs
fi

cd certs
if [[ ! -f root-cert.pem ]];then
  make -f ../tools/certs/Makefile.selfsigned.mk root-ca
fi

ctxs=$(kubectl config view -o jsonpath='{.contexts[*].name}' | grep -v "docker-desktop" | sed 's/ /\n/g')
for ctx in $ctxs
do
  make -f ../tools/certs/Makefile.selfsigned.mk "$ctx-cacerts"
done
