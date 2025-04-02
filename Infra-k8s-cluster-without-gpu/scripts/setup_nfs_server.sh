#!/usr/bin/env bash
# This script sets up an NFS server on a Linux machine.
# It installs the necessary packages, creates a directory for NFS exports,
# and configures the NFS server to allow access from a specified IP address.

set -e

# Install NFS server packages
sudo apt-get update -y
sudo apt-get install -y nfs-kernel-server

# Disk Partition format (Ubuntu)
sudo mkfs.ext4 /dev/sdb || true

# Mount the disk
sudo mkdir /mnt/nfs_share
sudo mount /dev/sdb /mnt/nfs_share
echo '/dev/sdb /mnt/nfs_share ext4 defaults 0 0' | sudo tee -a /etc/fstab # fstab 등록
echo '/mnt/nfs_share *(rw,sync,no_subtree_check)' | sudo tee -a /etc/exports # NFS exports 등록
sudo exportfs -rav # IP Open
sudo systemctl restart nfs-kernel-server # NFS 서버 재시작

# Fix the permission of the NFS share directory
sudo chown nobody:nogroup /mnt/nfs_share
sudo chmod 777 /mnt/nfs_share