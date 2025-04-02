#!/usr/bin/env bash
set -euxo pipefail
# Master Node -> Worker Node
########################################
# Step1: Delete Kubernetes Cluster
########################################
sudo systemctl stop kubelet
sudo systemctl disable kubelet
sudo systemctl stop containerd
sudo systemctl disable containerd
sudo kubeadm reset
sudo apt-get -y purge kubeadm kubectl kubelet kubernetes-cni kube*   
sudo apt-get -y autoremove  
sudo rm -rf ~/.kube
sudo rm -rf /etc/cni/net.d
sudo rm -rf /etc/kubernetes

########################################
# Step2: Delete CNI Cache
########################################
sudo rm /etc/cni/net.d
# clean up iptables rules or IPVS tables.
sudo apt install ipvsadm
sudo ipvsadm --clear