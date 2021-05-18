#!/usr/bin/env bash
#set -euxo pipefail

ctxs=$(kubectl config view -o jsonpath='{.contexts[*].name}' | sed 's/ /\n/g' | grep -v "docker-desktop")
for ctx in $ctxs
do
kubectl config use-context $ctx
kubectl create namespace istio-system
kubectl create secret generic cacerts -n istio-system \
      --from-file=pluginCA/certs/$ctx/ca-cert.pem \
      --from-file=pluginCA/certs/$ctx/ca-key.pem \
      --from-file=pluginCA/certs/$ctx/root-cert.pem \
      --from-file=pluginCA/certs/$ctx/cert-chain.pem

# istioctl operator init

cat <<EOF > $ctx.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
  namespace: istio-system
spec:
  profile: default
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: $ctx
      network: network1
  meshConfig:
    defaultConfig:
      proxyMetadata:
        # Enable basic DNS proxying
        ISTIO_META_DNS_CAPTURE: "true"
        # Enable automatic address allocation, optional
        ISTIO_META_DNS_AUTO_ALLOCATE: "true"
EOF

istioctl install -f $ctx.yaml -y --set values.pilot.env.PILOT_ENABLE_EDS_FOR_HEADLESS_SERVICES=true
if ! kubectl apply -f addons/; then
  sleep 5 && kubectl apply -f addons/
fi
done

for ctx in $ctxs; do
#Enable Endpoint Discovery
REMOTES=$(kubectl config view -o jsonpath='{.contexts[*].name}' | sed 's/ /\n/g' | grep -v "docker-desktop" | grep -v ${ctx})
istioctl x create-remote-secret --context="${ctx}" --name=${ctx} > ${ctx}-remote-secret.yaml
for REMOTE in $REMOTES; do
  kubectl apply -f ${ctx}-remote-secret.yaml --context="${REMOTE}"
done
done
