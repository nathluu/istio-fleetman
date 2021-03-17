#!/usr/bin/env sh
ISTIO_REVISION="1-9-1"
VM_APP="staff-service"
VM_NAMESPACE="vm"
WORK_DIR="Deployment"
SERVICE_ACCOUNT="staff-service"
CLUSTER_NETWORK=""
VM_NETWORK=""
CLUSTER="Kubernetes"

mkdir -p "${WORK_DIR}"

istioctl operator init

istioctl install -y
kubectl apply -f addons/
sleep 3
kubectl apply -f addons/

cat <<EOF > ./vm-cluster.yaml
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

istioctl install -f vm-cluster.yaml -y

sh samples/multicluster/gen-eastwest-gateway.sh --single-cluster --revision ${ISTIO_REVISION} | istioctl install -y -f -
kubectl apply -f samples/multicluster/expose-istiod.yaml
#Configure the VM namespace
if [[ "$VM_NAMESPACE" != "default" ]]; then
  kubectl create namespace "${VM_NAMESPACE}"
fi
kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${VM_NAMESPACE}"

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

istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --clusterID "${CLUSTER}"
