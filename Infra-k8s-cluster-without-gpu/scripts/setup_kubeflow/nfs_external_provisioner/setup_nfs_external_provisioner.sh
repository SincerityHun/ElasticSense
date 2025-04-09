#!/usr/bin/env bash
set -euxo pipefail
cd /tmp/setup_kubeflow/nfs_external_provisioner
########################################
# Step1: Fix NFS deployment
########################################
sed -ie "s/NFS_SERVER_IP/${NFS_SERVER_IP}/g" deployment.yaml
sed -ie 's/NFS_FOLDER_PATH/\/mnt\/nfs_share/g' deployment.yaml


########################################
# Step2: Apply NFS deployment
########################################
kubectl apply -f rbac.yaml
kubectl apply -f deployment.yaml
kubectl apply -f class.yaml


########################################
# Step3: Set NFS as default storage class
########################################
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
# TO CHECK => kubectl apply -f pvc-test.yaml
