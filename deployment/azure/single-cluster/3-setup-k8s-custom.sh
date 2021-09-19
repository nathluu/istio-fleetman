#!/usr/bin/env bash
set -euxo pipefail

CLUSTER_NETWORK=""
CLUSTER="Kubernetes" #This is a fixed value

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
  meshConfig:
    accessLogFile: /dev/stdout
  components:
    base:
      enabled: true
    pilot:
      enabled: true
    egressGateways:
    - name: istio-egressgateway
      enabled: false
    # Istio CNI feature
    cni:
      enabled: false
    # istiod remote configuration wwhen istiod isn't installed on the cluster
    istiodRemote:
      enabled: false
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        k8s:
          service:
            ports:
              - port: 15021
                targetPort: 15021
                name: status-port
                protocol: TCP
              - port: 80
                targetPort: 8080
                name: http2
                protocol: TCP
              - port: 443
                targetPort: 8443
                name: https
                protocol: TCP
              - port: 15012
                targetPort: 15012
                name: tcp-istiod
                protocol: TCP
              # This is the port where sni routing happens
              - port: 15443
                targetPort: 15443
                name: tls
                protocol: TCP
              # Custom User ports
              - port: 6650
                targetPort: 6650
                name: tcp-pulsar
                protocol: TCP
              - port: 6651
                targetPort: 6651
                name: tls-pulsar
                protocol: TCP
EOF

istioctl apply -f vm-cluster.yaml -y

#if ! kubectl apply -f addons/; then
#  sleep 5 && kubectl apply -f addons/
#fi

# kubectl label namespace default istio-injection=enabled
