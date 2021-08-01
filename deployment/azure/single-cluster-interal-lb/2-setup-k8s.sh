#!/usr/bin/env bash
set -euxo pipefail

CLUSTER_NETWORK=""
CLUSTER="Kubernetes" #This is a fixed value

# istioctl operator init

cat <<EOF > vm-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: "${CLUSTER}"
      network: "${CLUSTER_NETWORK}"
  meshConfig:
    accessLogFile: /dev/stdout
    enableTracing: true
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        serviceAnnotations:
          service.beta.kubernetes.io/azure-load-balancer-internal: "true"
          service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "default"
EOF

istioctl install -f vm-cluster.yaml -y

if ! kubectl apply -f addons/; then
  sleep 5 && kubectl apply -f addons/
fi

kubectl create ns test
kubectl label namespace test istio-injection=enabled
