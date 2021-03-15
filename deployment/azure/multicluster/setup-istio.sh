#!/usr/bin/env sh
#set -euxo pipefail

ctxs=$(kubectl config view -o jsonpath='{.contexts[*].name}' | grep -v "docker-desktop" | sed 's/ /\n/g')
for ctx in $ctxs
do
kubectl config use-context $ctx
kubectl create namespace istio-system
kubectl create secret generic cacerts -n istio-system \
      --from-file=pluginCA/certs/$ctx/ca-cert.pem \
      --from-file=pluginCA/certs/$ctx/ca-key.pem \
      --from-file=pluginCA/certs/$ctx/root-cert.pem \
      --from-file=pluginCA/certs/$ctx/cert-chain.pem
istioctl operator init
cat <<EOF > $ctx.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: $ctx
      network: network1
EOF
istioctl install -f $ctx.yaml -y
kubectl apply -f addons/
sleep 5
kubectl apply -f addons/
done
