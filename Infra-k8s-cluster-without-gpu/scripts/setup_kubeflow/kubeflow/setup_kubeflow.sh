#!/usr/bin/env bash
set -euxo pipefail
# https://github.com/kubeflow/manifests/tree/v1.10.0#installation
cd /tmp/setup_kubeflow/kubeflow
########################################
# Step1: Check Prequisites
########################################
RECOMMENDED_MEM_GB=16
RECOMMENDED_CPU=8
RECOMMENDED_USER_INSTANCES=2280
RECOMMENDED_USER_WATCHES=1255360
AVAILABLE_MEM_GB=$(free -g | awk '/^Mem:/{print $2}')
AVAILABLE_CPU=$(nproc --all)
CURRENT_USER_INSTANCES=$(sysctl -n fs.inotify.max_user_instances)
CURRENT_USER_WATCHES=$(sysctl -n fs.inotify.max_user_watches)
if [[ "$AVAILABLE_MEM_GB" -lt "$RECOMMENDED_MEM_GB" ]]; then
    echo "[ERROR] Insufficient memory. Recommended: ${RECOMMENDED_MEM_GB}GB, Available: ${AVAILABLE_MEM_GB}GB"
    exit 1
fi
if [[ "$AVAILABLE_CPU" -lt "$RECOMMENDED_CPU" ]]; then
    echo "[ERROR] Insufficient CPU cores. Recommended: ${RECOMMENDED_CPU}, Available: ${AVAILABLE_CPU}"
    exit 1
fi
echo "[INFO] System meets the recommended requirements for Kubeflow installation."

if (( CURRENT_USER_INSTANCES < RECOMMENDED_USER_INSTANCES )); then
  echo "[WARN] fs.inotify.max_user_instances(Current: $CURRENT_USER_INSTANCES) is smaller than $RECOMMENDED_USER_INSTANCES recommended value."
  echo "      sudo sysctl fs.inotify.max_user_instances=$RECOMMENDED_USER_INSTANCES"
fi

if (( CURRENT_USER_WATCHES < RECOMMENDED_USER_WATCHES )); then
  echo "[WARN] fs.inotify.max_user_watches(Current: $CURRENT_USER_WATCHES)is smaller than $RECOMMENDED_USER_WATCHES recommended value."
  echo "      sudo sysctl fs.inotify.max_user_watches=$RECOMMENDED_USER_WATCHES"
fi

if (( CURRENT_USER_INSTANCES >= RECOMMENDED_USER_INSTANCES && CURRENT_USER_WATCHES >= RECOMMENDED_USER_WATCHES )); then
  echo "[INFO] sysctl fs.inotify.max_user_instances and fs.inotify.max_user_watches are set to recommended values."
fi

########################################
# Step2: Kubeflow Installation
########################################
KUBEFLOW_VERSION="v1.10.0"
git clone --branch $KUBEFLOW_VERSION --depth 1 https://github.com/kubeflow/manifests.git
cd manifests

# 방법 1 -> 걍 원클릭 설치 (삭제: kustomize build example | kubectl delete -f -)
# while ! kustomize build example | kubectl apply --server-side --force-conflicts -f -; do echo "Retrying to apply resources"; sleep 20; done

# 방법 2 -> 각각 설치
########################################
# Step2.1: Cert-manager Installation
# 이슈1: webhook readness timeout (https://cert-manager.io/docs/troubleshooting/webhook/) -> 방화벽 문제, 포트 6080 개방
########################################

# 2. Istio-system

# 3. Dex

# 4. OIDC AuthService

# 5. Kubeflow Namespace

# 6. Kubeflow Roles

# 7. Kubeflow Istio Resources

# 8. Kubeflow Pipelines

# 9. Katib

# 10. Central Dashboard

# 11. Admission Webhook

# 12. Notebooks & Jupyter Web App

# 13. Profiles + KFAM

# 14. Volumes Web App

# 15. Tensorboard & Tensorboard Web App

# 16. Training Operator

# 17. User Namespace