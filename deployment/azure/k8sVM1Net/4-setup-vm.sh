#!/usr/bin/env bash
WORK_DIR="Deployment"

sudo mkdir -p /etc/certs
sudo cp $HOME/$WORK_DIR/root-cert.pem /etc/certs/root-cert.pem

sudo  mkdir -p /var/run/secrets/tokens
sudo cp $HOME/$WORK_DIR/istio-token /var/run/secrets/tokens/istio-token

curl -L https://storage.googleapis.com/istio-release/releases/1.9.1/deb/istio-sidecar.deb -o /tmp/istio-sidecar.deb
sudo dpkg -i /tmp/istio-sidecar.deb

sudo cp $HOME/$WORK_DIR/cluster.env /var/lib/istio/envoy/cluster.env
sudo cp $HOME/$WORK_DIR/mesh.yaml /etc/istio/config/mesh
cat $HOME/$WORK_DIR/hosts | sudo tee -a /etc/hosts

sudo mkdir -p /etc/istio/proxy
sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem

sudo systemctl start istio





