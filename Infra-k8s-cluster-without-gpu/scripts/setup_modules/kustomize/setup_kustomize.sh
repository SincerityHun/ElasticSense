#!/usr/bin/env bash
set -euxo pipefail
cd /tmp/setup_modules/kustomize
########################################
# Step1: Kustomize extract (version v5.4.3)
# https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.4.3
########################################
curl -L https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.3/kustomize_v5.4.3_linux_amd64.tar.gz -o kustomize
tar -xzf kustomize
sudo mv kustomize /usr/local/bin/kustomize
sudo chmod +x /usr/local/bin/kustomize
# TO CHECK => {kustomize version}
########################################