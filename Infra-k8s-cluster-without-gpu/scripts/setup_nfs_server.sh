#!/usr/bin/env bash

set -euxo pipefail
########################################
# Step1: Install NFS server packages
########################################
sudo apt-get update -y
sudo apt-get install -y nfs-kernel-server

########################################
# Step2: Disk Partition format (Ubuntu)
########################################
sudo mkfs.ext4 /dev/sdb || true

########################################
# Step3: Fix the permission of the NFS share directory
########################################
sudo mkdir /mnt/nfs_share
sudo chown nobody: /mnt/nfs_share
sudo chmod 777 /mnt/nfs_share


########################################
# Step4:  Mount the disk
########################################
sudo mount /dev/sdb /mnt/nfs_share
echo '/dev/sdb /mnt/nfs_share ext4 defaults 0 0' | sudo tee -a /etc/fstab # fstab 등록
echo '/mnt/nfs_share *(rw,sync,no_subtree_check,no_root_squash,insecure)' | sudo tee -a /etc/exports # NFS exports 등록
sudo exportfs -rav # IP Open
sudo systemctl restart nfs-kernel-server # NFS 서버 재시작

########################################
# Step5:  TEST NFS
########################################
# TO CHECK => {sudo exportfs -v && showmount -e localhost}
if ! sudo showmount -e | grep -q '/mnt/nfs_share'; then
    echo "[ERROR] NFS export failed. Please check the NFS server configuration."
    exit 1
else
    echo "[INFO] NFS export successful."
fi



