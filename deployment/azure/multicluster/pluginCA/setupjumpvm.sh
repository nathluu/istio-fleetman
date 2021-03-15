curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
curl -sL https://istio.io/downloadIstioctl | sh -
curl -LO https://dl.k8s.io/release/v1.19.7/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
export PATH=$PATH:$HOME/.istioctl/bin
