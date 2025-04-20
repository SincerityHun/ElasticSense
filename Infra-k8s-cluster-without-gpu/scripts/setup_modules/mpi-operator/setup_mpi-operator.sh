#!/usr/bin/env bash
set -euxo pipefail
cd /tmp/setup_modules/mpi-operator

########################################
# Step1: MPI Operator Installation
########################################
kubectl apply --server-side -f https://raw.githubusercontent.com/kubeflow/mpi-operator/v0.6.0/deploy/v2beta1/mpi-operator.yaml