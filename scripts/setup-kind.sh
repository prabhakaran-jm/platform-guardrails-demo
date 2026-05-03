#!/usr/bin/env bash
set -e

CLUSTER_NAME="platform-guardrails-demo"
NODE_IMAGE="kindest/node:v1.29.2" # Pinning stable version

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Kind cluster '${CLUSTER_NAME}' already exists. Skipping creation."
else
    echo "Creating kind cluster '${CLUSTER_NAME}'..."
    kind create cluster --name ${CLUSTER_NAME} --image ${NODE_IMAGE}
fi

kubectl cluster-info --context kind-${CLUSTER_NAME}
echo "Kind setup successful."
