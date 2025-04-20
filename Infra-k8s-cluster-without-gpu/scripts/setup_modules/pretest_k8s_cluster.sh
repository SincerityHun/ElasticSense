#!/usr/bin/env bash
set -euxo pipefail
########################################
# Step1: Checking cluster status -> Controlplan Components Check
########################################
echo "[INFO] Checking Kubernetes component statuses..."
COMPONENT_STATUSES=$(kubectl get cs --no-headers || true)
# 명령어 실패 확인
if [[ -z "$COMPONENT_STATUSES" ]]; then
  echo "[ERROR] 'kubectl get cs' command failed or returned empty."
  exit 1
fi
# Unhealthy 상태 확인
if echo "$COMPONENT_STATUSES" | grep -Eq "(Unhealthy|unready|Unknown)"; then
  echo "[ERROR] Some Kubernetes components are not healthy."
  exit 1
fi
echo "[INFO] All Kubernetes components appear to be healthy."

########################################
# Step2: kubectl version (클라이언트/서버 버전 확인)
########################################
echo "[INFO] Checking 'kubectl version'..."
kubectl version || {
  echo "[ERROR] 'kubectl version' command failed."
  exit 1
}

########################################
# Step3: kubectl get nodes (노드 목록 확인)
########################################
echo "[INFO] Checking 'kubectl get nodes'..."
kubectl get nodes || {
  echo "[ERROR] 'kubectl get nodes' command failed."
  exit 1
}

########################################
# Step4: 모든 노드가 Ready 상태인지 확인
########################################
WAIT_TIME=60
SLEEP_INTERVAL=3
ALL_NODES=$(kubectl get nodes --no-headers | awk '{print $1}')

for (( i=1; i <= WAIT_TIME ; i+= SLEEP_INTERVAL)); do
    echo "[INFO] Checking node readiness... (elapsed: $((i - 1))s / max: ${WAIT_TIME}s)"
    all_ready=true
    # 노드 확인
    for node in $ALL_NODES; do
        NODE_STATUS=$(kubectl get node "$node" --no-headers | awk '{print $2}')
        if [[ "$NODE_STATUS" != "Ready" ]]; then
            echo "[ERROR] Node '$node' is not in 'Ready' state. Current status: $NODE_STATUS"
            all_ready=false
        fi
    done
    # 모든 노드가 Ready 상태인지 확인
    if [[ "$all_ready" == true ]]; then
        echo "[INFO] All nodes are in 'Ready' state."
        break
    else
        echo "[INFO] Not all nodes are in 'Ready' state. Waiting for $SLEEP_INTERVAL seconds..."
        sleep $SLEEP_INTERVAL
    fi
    # Timeout 확인
    if [[ $i -eq WAIT_TIME ]]; then
        echo "[ERROR] Timeout: Not all nodes are in 'Ready' state after $WAIT_TIME seconds."
        exit 1
    fi
done

########################################
# Step5: 쉘 자동완성
########################################
echo "[INFO] Setting up shell completion for kubectl..."
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >> ~/.bashrc 
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null 
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc