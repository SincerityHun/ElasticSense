#!/usr/bin/env bash
set -e

# 1) Install NFS client packages ( Ubuntu )
sudo apt-get update -y
sudo apt-get install -y nfs-common

# 2) NFS mount
sudo mkdir -p /mnt/nfs_client
sudo mount -t nfs ${NFS_SERVER_IP}:/mnt/nfs_share /mnt/nfs_client

# 3) fstab 등록
echo "${NFS_SERVER_IP}:/mnt/nfs_share /mnt/nfs_client nfs defaults 0 0" | sudo tee -a /etc/fstab

# 4) TO CHECK => {df -h /mnt/nfs_client}