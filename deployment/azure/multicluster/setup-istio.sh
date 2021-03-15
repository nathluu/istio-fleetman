#!/bin/bash
set -euxo pipefail
pushd pluginCA
bash generate.sh

ctxs=$(kubectl config view -o jsonpath='{.contexts[*].name}' | grep -v "docker-desktop" | sed 's/ /\n/g')
for ctx in $ctxs
do
kubectl config use-context $ctx
kubectl create namespace istio-system
kubectl create secret generic cacerts -n istio-system \
      --from-file=$ctx/ca-cert.pem \
      --from-file=$ctx/ca-key.pem \
      --from-file=$ctx/root-cert.pem \
      --from-file=$ctx/cert-chain.pem
popd
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
sleep 10
kubectl apply -f ../addons/
sleep 10
kubectl apply -f ../addons/
done
