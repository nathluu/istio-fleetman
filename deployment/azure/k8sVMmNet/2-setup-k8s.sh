#!/usr/bin/env bash
set -euxo pipefail

VM_APP="staff-service"
VM_NAMESPACE="vm"
WORK_DIR="Deployment"
SERVICE_ACCOUNT="staff-service" # Empty means default service account
# Customize values for multi-cluster/multi-network as needed
CLUSTER_NETWORK="kube-network"
VM_NETWORK="vm-network"
CLUSTER="cluster1"

mkdir -p "${WORK_DIR}"

istioctl operator init

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
EOF

istioctl install -f vm-cluster.yaml --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION=true --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_HEALTHCHECKS=true -y

if ! kubectl apply -f addons/; then
  sleep 5 && kubectl apply -f addons/
fi

bash samples/multicluster/gen-eastwest-gateway.sh \
--mesh mesh1 --cluster "${CLUSTER}" --network "${CLUSTER_NETWORK}" | \
istioctl install -y -f -

kubectl apply -f samples/multicluster/expose-istiod.yaml
kubectl apply -n istio-system -f samples/multicluster/expose-services.yaml
#Configure the VM namespace
if ! kubectl get namespace "${VM_NAMESPACE}"; then
  kubectl create namespace "${VM_NAMESPACE}"
  kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${VM_NAMESPACE}"
fi

cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: "${VM_APP}"
  namespace: "${VM_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${VM_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${VM_NETWORK}"
EOF

kubectl apply --namespace "${VM_NAMESPACE}" -f workloadgroup.yaml

IDX=1
INGRESSIP=""
while [[ -z "$INGRESSIP" && $IDX -lt 10 ]]; do
echo "Checking ........"
sleep 10
INGRESSIP=$(kubectl get svc/istio-eastwestgateway -n istio-system  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Eastwest gateway IP: $INGRESSIP"
let IDX=${IDX}+1
done

istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --clusterID "${CLUSTER}" --ingressIP "$INGRESSIP" --autoregister
kubectl label namespace default istio-injection=enabled
kubectl label namespace vm istio-injection=enabled
