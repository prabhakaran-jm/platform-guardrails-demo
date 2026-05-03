#!/usr/bin/env bash
echo "========================================"
echo "Cleaning up demo environment"
echo "========================================"

# Delete kind cluster if it exists
if kind get clusters | grep -q "platform-guardrails-demo"; then
  echo "Deleting kind cluster 'platform-guardrails-demo'..."
  kind delete cluster --name platform-guardrails-demo
else
  echo "Cluster already deleted."
fi

# Drop the stale kubeconfig context so reruns start clean.
kubectl config delete-context kind-platform-guardrails-demo >/dev/null 2>&1 || true

# Clean Terraform state and plans
echo "Cleaning Terraform files..."
find terraform -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
find terraform -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
find terraform -type f -name "tfplan*" -delete 2>/dev/null || true

echo "Reset complete. Source files kept intact."
