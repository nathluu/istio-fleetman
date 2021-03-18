echo "Installing AKS tools..."
ISTIO_VERSION=1.9.1
pushd .
cd /tmp
sudo apt install make -y
if [[ -x "$(which az)" ]]; then
  echo "az is already installed!"
else
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

if [[ -x "$(which istioctl)" ]]; then
  echo "istioctl is already installed!"
else
#   curl -sL https://istio.io/downloadIstioctl | sh -
  curl -sL "https://github.com/istio/istio/releases/download/$ISTIO_VERSION/istioctl-$ISTIO_VERSION-linux-amd64.tar.gz" | tar xz
  sudo install -o root -g root -m 0755 istioctl /usr/local/bin/istioctl
fi

if [[ -x "$(which kubectl)" ]]; then
  echo "kubectl is already installed!"
else
  curl -LO https://dl.k8s.io/release/v1.19.7/bin/linux/amd64/kubectl
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi
popd
