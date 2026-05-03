#!/usr/bin/env bash
set -e

echo "Installing Kyverno..."

helm repo add kyverno https://kyverno.github.io/kyverno/ || true
helm repo update

# Pinning version for reliable demo runs
helm upgrade --install kyverno kyverno/kyverno \
  -n kyverno --create-namespace \
  --version 3.1.4 \
  --set admissionController.replicas=1 \
  --wait

echo "Waiting for Kyverno webhook to be fully ready..."
kubectl rollout status deployment/kyverno-admission-controller -n kyverno --timeout=120s

echo "Applying Kubernetes Guardrail Policies..."
kubectl apply -f policies/kyverno/

echo "Waiting 5 seconds for webhooks to register policies globally..."
sleep 5

echo "Kyverno installation and policy application complete."
