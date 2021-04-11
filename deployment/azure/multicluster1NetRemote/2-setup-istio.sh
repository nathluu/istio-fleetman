#!/usr/bin/env bash
set -euxo pipefail

#Trust configuration for all clusters
ctxs=$(kubectl config view -o jsonpath='{.contexts[*].name}' | sed 's/ /\n/g' | grep -v "docker-desktop")
for ctx in $ctxs; do
kubectl config use-context $ctx
kubectl create namespace istio-system
kubectl create secret generic cacerts -n istio-system \
      --from-file=pluginCA/certs/$ctx/ca-cert.pem \
      --from-file=pluginCA/certs/$ctx/ca-key.pem \
      --from-file=pluginCA/certs/$ctx/root-cert.pem \
      --from-file=pluginCA/certs/$ctx/cert-chain.pem
done

#Install Istio control plane on cluster1
kubectl config use-context cluster1
# istioctl operator init
cat <<EOF > cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
  namespace: istio-system
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF

istioctl install -f cluster1.yaml -y
if ! kubectl apply -f addons/; then
  sleep 5 && kubectl apply -f addons/
fi

#Install eastwest gateway on cluster1
bash samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster cluster1 --network network1 | \
    istioctl install -y -f -

IDX=1
DISCOVERY_ADDRESS=""
while [[ -z "$DISCOVERY_ADDRESS" && $IDX -lt 10 ]]; do
echo "Checking ........"
sleep 10
DISCOVERY_ADDRESS=$(kubectl get svc/istio-eastwestgateway -n istio-system  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Eastwest gateway IP: $DISCOVERY_ADDRESS"
let IDX=${IDX}+1
done

#Expose services
kubectl apply -n istio-system -f samples/multicluster/expose-istiod.yaml
istioctl x create-remote-secret --context=cluster2 --name=cluster2 | kubectl apply -f - --context=cluster1

#Install Istio control plane on cluster2
kubectl config use-context cluster2
cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: remote
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network1
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF

istioctl install -f cluster2.yaml -y
