#!/usr/bin/env bash
set -euxo pipefail
# https://github.com/kubeflow/manifests/tree/v1.10.0#installation
cd /tmp/setup_modules/kubeflow

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

MAX_RETRY=5
apply_with_retry () {
  local attempt=1
  while true; do
    # $* 전체를 파이프로 실행하려면 eval 사용
    if eval "$*"; then
      echo "✅ apply succeeded"
      break
    fi

    if [[ $attempt -ge $MAX_RETRY ]]; then
      echo "❌ apply failed after $attempt attempts"
      exit 1
    fi

    echo "🔄 apply failed (attempt $attempt). Retrying in 20 s..."
    sleep 20
    attempt=$((attempt + 1))
  done
}

########################################
# Step2.1: Cert-manager Installation
# Issue: Webhook readiness timeout (https://cert-manager.io/docs/troubleshooting/webhook/) -> Firewall issue, open port 6080
########################################
apply_with_retry "kustomize build common/cert-manager/base | kubectl apply -f -"
kubectl wait --for=condition=Ready pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kubectl wait --for=jsonpath='{.subsets[0].addresses[0].targetRef.kind}'=Pod endpoints -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
apply_with_retry "kustomize build common/cert-manager/kubeflow-issuer/base | kubectl apply -f -"

########################################
# Step2.2: Istio-system Installation
# Reference: https://istio.io/latest/docs/setup/install/helm/
########################################
apply_with_retry "kustomize build common/istio-1-24/istio-crds/base | kubectl apply -f -"
apply_with_retry "kustomize build common/istio-1-24/istio-namespace/base | kubectl apply -f -"
apply_with_retry "kustomize build common/istio-1-24/istio-install/overlays/oauth2-proxy | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout 300s

########################################
# Step2.3: Oauth2-proxy Installation
########################################
apply_with_retry "kustomize build common/oauth2-proxy/overlays/m2m-dex-only/ | kubectl apply -f -"
kubectl wait --for=condition=Ready pod -l 'app.kubernetes.io/name=oauth2-proxy' --timeout=180s -n oauth2-proxy

########################################
# Step2.4: Dex Installation
########################################
apply_with_retry "kustomize build common/dex/overlays/oauth2-proxy | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n auth

########################################
# Step2.5: Knative Serving Installation
########################################
apply_with_retry "kustomize build common/knative/knative-serving/overlays/gateways | kubectl apply -f -"
apply_with_retry "kustomize build common/istio-1-24/cluster-local-gateway/base | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n knative-serving

########################################
# Step2.6: Kubeflow Namespace Creation
########################################
apply_with_retry "kustomize build common/kubeflow-namespace/base | kubectl apply -f -"

########################################
# Step2.7: Network Policies Installation
########################################
apply_with_retry "kustomize build common/networkpolicies/base | kubectl apply -f -"

########################################
# Step2.8: Kubeflow Roles Installation
########################################
apply_with_retry "kustomize build common/networkpolicies/base | kubectl apply -f -"
########################################
# Step2.9: Kubeflow Istio Resources Installation
########################################
apply_with_retry "kustomize build common/istio-1-24/kubeflow-istio-resources/base | kubectl apply -f -"

########################################
# Step2.10: Kubeflow Pipelines Installation
########################################
apply_with_retry "kustomize build apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.11: Kserve Installation
########################################
apply_with_retry "kustomize build apps/kserve/kserve | kubectl apply --server-side --force-conflicts -f -" 
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow
apply_with_retry "kustomize build apps/kserve/models-web-app/overlays/kubeflow | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.12: Katib Installation
########################################
apply_with_retry "kustomize build apps/katib/upstream/installs/katib-with-kubeflow | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.13: Central Dashboard Installation
########################################
apply_with_retry "kustomize build apps/centraldashboard/overlays/oauth2-proxy | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.14: Admission Webhook Installation
########################################
apply_with_retry "kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.15: Notebooks & Jupyter Web App Installation
########################################
apply_with_retry "kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

apply_with_retry "kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.16: PVC Viewer Controller Installation
########################################
apply_with_retry "kustomize build apps/pvcviewer-controller/upstream/base | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.17: Profiles + KFAM Installation
########################################
apply_with_retry "kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.18: Volumes Web App Installation
########################################
apply_with_retry "kustomize build apps/volumes-web-app/upstream/overlays/istio | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.19: Tensorboard & Tensorboard Web App Installation
########################################
apply_with_retry "kustomize build apps/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

apply_with_retry "kustomize build apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.20: Training Operator Installation
########################################
apply_with_retry "kustomize build apps/training-operator/upstream/overlays/kubeflow | kubectl apply --server-side --force-conflicts -f -"
kubectl wait --for=condition=Ready pods --all --timeout=180s -n kubeflow

########################################
# Step2.21: User Namespace Creation
########################################
apply_with_retry "kustomize build common/user-namespace/base | kubectl apply -f -"

########################################
# Step3: Kubeflow External Access
# 외부요청 -> ExternalIP:NodePort -> istio-ingressgateway 서비스 -> istio-ingressgateway 파드 -> Istio Gateway/VirtualService -> Kubeflow CentralDashboard
# HTTPS을 설정하고 싶다면: 
#         1. OpenSSL(또는 다른 인증서 홈페이지)을 이용하여 인증서 생성 후, 
#         2. 시크릿만들고 (kubectl create secret tls kubeflow-tls-secret --cert=cert.pem --key=key.pem -n kubeflow)
#         3. kubeflow gateway을 edit 해서 tls 설정을 추가한다. (secret 이름은 kubeflow-tls-secret으로 설정)
########################################
kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec": {"type": "NodePort"}}'

# HTTPS Setting 
cd /tmp/setup_modules/kubeflow
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=Example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
kubectl create secret tls kubeflow-tls-secret --cert=example.com.crt --key=example.com.key -n kubeflow
kubectl patch gateway kubeflow-gateway -n kubeflow --type merge -p '{"spec": {"servers": [{"port": {"number": 443, "name": "https", "protocol": "HTTPS"},"tls": {"mode": "SIMPLE", "credentialName": "kubeflow-tls-secret"}, "hosts": ["*"]},{"port": {"number": 80, "name": "http", "protocol": "HTTP"}, "hosts": ["*"]}]}}'

# role binding with user & clusterrole
kubectl create -f rbac-kubeflow-user-full-access.yaml
kubectl create -f rbac-pipeline-user-full-access.yaml