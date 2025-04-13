#!/usr/bin/env bash
set -euxo pipefail

########################################
# Step1: Linux Package Update
########################################
sudo apt-get update -y

########################################
# Step2: Kubelet, Kubeaddm, Kubectl Install (version 1.32.0) 
# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
########################################

sudo apt-get install -y apt-transport-https ca-certificates curl gnupg gnupg2 software-properties-common
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   

sudo apt update
sudo apt -y install vim git wget kubeadm=1.32.0-1.1 kubelet=1.32.0-1.1 kubectl=1.32.0-1.1 --allow-downgrades
sudo apt-get update -y
sudo apt-mark hold kubelet kubeadm kubectl
# TO CHECK => {kubectl version --client && kubeadm version}


########################################
# Step3: Iptable Configuration
########################################

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
# TO CHECK => {sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward}

########################################
# Step4: CRI Install (Containerd)
########################################
# Configure persistent loading of modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

# Load at runtime
sudo modprobe overlay
sudo modprobe br_netfilter

# Ensure sysctl params are set
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload configs
sudo sysctl --system

# Install required packages
sudo apt install -y gnupg2 software-properties-common

# Add Docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install containerd
sudo apt update
sudo apt install -y containerd.io

# Configure containerd and start service
sudo mkdir -p /etc/containerd
sudo containerd config default|sudo tee /etc/containerd/config.toml

# /etc/containerd/config.toml에서 systemd를 cgroup driver로 설정
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

########################################
# Step5: Master Node Initialize
########################################
# kubelet start
sudo systemctl enable kubelet

# kubeadm init
sudo kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock

# kubeadm init config (containerd setting & podSubnet cidr)
cd /tmp
cat > kube-config.yaml <<EOF
---
apiVersion: kubeadm.k8s.io/v1beta4
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: ywvyy1.4tj6smtqmklsdxx0
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.10.0.3
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock 
  imagePullPolicy: IfNotPresent
  imagePullSerial: true
  name: k8s-master
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane
timeouts:
  controlPlaneComponentHealthCheck: 4m0s
  discovery: 5m0s
  etcdAPICall: 2m0s
  kubeletHealthCheck: 4m0s
  kubernetesAPICall: 1m0s
  tlsBootstrap: 5m0s
  upgradeManifests: 5m0s
---
apiServer: {}
apiVersion: kubeadm.k8s.io/v1beta4
caCertificateValidityPeriod: 87600h0m0s
certificateValidityPeriod: 8760h0m0s
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
encryptionAlgorithm: RSA-2048
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.k8s.io
kind: ClusterConfiguration
kubernetesVersion: v1.32.3
networking:
  dnsDomain: cluster.local
  podSubnet: 172.24.0.0/24
  serviceSubnet: 10.96.0.0/12
proxy: {}
scheduler: {}
EOF

# Master cluster create
sudo kubeadm init --config kube-config.yaml # If not works -> {kubeadm config migrate --old-config kube-config.yaml --new-config new-kub-config.yaml}

########################################
# Step6: kubectl config
######################################## 
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


########################################
# Step7: Install CNI (Calico -v3.29.3)
# https://github.com/projectcalico/calico/releases
########################################
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/tigera-operator.yaml
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/custom-resources.yaml

# Apply the Tigera operator
kubectl create -f tigera-operator.yaml # Do not use apply - https://github.com/projectcalico/calico/issues/6491
kubectl wait --for=condition=Established --timeout=60s crd/installations.operator.tigera.io

# Custom Resource modify CIDR
sed -ie 's/192.168.0.0\/16/172.24.0.0\/24/g' custom-resources.yaml
kubectl create -f custom-resources.yaml 

# let master node can install pod
kubectl taint nodes --all  node-role.kubernetes.io/control-plane-

# Get the Token for it
kubeadm token create --print-join-command > /tmp/k8s_join_command.sh
sudo cp /tmp/k8s_join_command.sh /mnt/nfs_client/k8s_join_command.sh

########################################
# Step8: Install Helm (v3.17.0)
# https://helm.sh/docs/intro/install/
########################################
mkdir -p /tmp/helm
cd /tmp/helm
curl -L https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz -o helm-v3.17.0-linux-amd64.tar.gz
tar -xzf helm-v3.17.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm