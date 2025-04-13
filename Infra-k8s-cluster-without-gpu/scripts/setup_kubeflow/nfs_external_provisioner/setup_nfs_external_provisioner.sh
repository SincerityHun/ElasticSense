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

########################################
# Step4: Check NFS Provisoner work
########################################
kubectl apply -f pvc-test.yaml
WAIT_TIME=30
for i in $(seq 1 $WAIT_TIME); do
    STATUS=$(kubectl get pvc pvc-test -o jsonpath='{.status.phase}' || echo "Pending")
    if [[ "$STATUS" == "Bound" ]]; then
        echo "[INFO] NFS Provisioner is working correctly."
        break
    else
        echo "[INFO] Waiting for NFS Provisioner to work... ($i/$WAIT_TIME)"
        sleep 1
    fi
    if [[ $i -eq $WAIT_TIME ]]; then
        echo "[ERROR] PVC 'pvc-test' did not reach Bound status within $WAIT_TIME seconds."
        exit 1
    fi
done

kubectl delete -f pvc-test.yaml
echo "[INFO] PVC 'pvc-test' test completed and deleted."
