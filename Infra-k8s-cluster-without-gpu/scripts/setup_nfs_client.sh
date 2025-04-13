#!/usr/bin/env bash
set -euxo pipefail

########################################
# Step1: Install NFS client packages ( Ubuntu )
########################################
sudo apt-get update -y
sudo apt-get install -y nfs-common

########################################
# Step2: NFS mount
########################################
sudo mkdir -p /mnt/nfs_client
sudo mount -t nfs ${NFS_SERVER_IP}:/mnt/nfs_share /mnt/nfs_client


########################################
# Step3: fstab 등록
########################################
echo "${NFS_SERVER_IP}:/mnt/nfs_share /mnt/nfs_client nfs defaults 0 0" | sudo tee -a /etc/fstab

########################################
# Step4: TEST NFS Client
########################################
CHECK_MOUNT=$(df -h /mnt/nfs_client | grep "/mnt/nfs_client")
if [[ -z "$CHECK_MOUNT" ]]; then
    echo "[ERROR] NFS Client mount failed. Please check the NFS client configuration."
    exit 1
else
    echo "[INFO] NFS Client mount successful."
fi