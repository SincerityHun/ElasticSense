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
# Step5: Join Master Node
########################################
sudo cp /mnt/nfs_client/k8s_join_command.sh /tmp/k8s_join_command.sh
sudo chmod +x /tmp/k8s_join_command.sh
sudo /tmp/k8s_join_command.sh