#!/usr/bin/env sh
VM_APP="position-simulator"
VM_NAMESPACE="default"
export WORK_DIR="istio-fleetman-deployment"
SERVICE_ACCOUNT="position-simulator"
# Customize values for multi-cluster/multi-network as needed
CLUSTER_NETWORK="kube-network"
VM_NETWORK="vm-network"
CLUSTER="cluster1"

mkdir -p "${WORK_DIR}"

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

istioctl install -f vm-cluster.yaml
sh samples/multicluster/gen-eastwest-gateway.sh \
--mesh mesh1 --cluster "${CLUSTER}" --network "${CLUSTER_NETWORK}" --revision 1-9-1 | \
istioctl install -y -f -

kubectl apply -f samples/multicluster/expose-istiod.yaml
kubectl apply -n istio-system -f samples/multicluster/expose-services.yaml
#Configure the VM namespace
kubectl create namespace "${VM_NAMESPACE}"
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

ssh-keygen -b 4096 -f my_id_rsa
echo "Please add my_id_rsa.pub to your VM and proceed next step!"