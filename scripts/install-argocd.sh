#!/usr/bin/env bash
set -e

# Pin chart version for reliable demo runs (see README Known Assumptions).
ARGO_CD_CHART_VERSION="9.5.11"

echo "Installing Argo CD (${ARGO_CD_CHART_VERSION})..."

helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALUES_FILE="${SCRIPT_DIR}/../gitops/argocd-demo-values.yaml"

helm upgrade --install argocd argo/argo-cd \
  -n argocd --create-namespace \
  --version "${ARGO_CD_CHART_VERSION}" \
  -f "${VALUES_FILE}" \
  --wait \
  --timeout 5m

kubectl rollout status deployment/argocd-server -n argocd --timeout=180s
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=180s
for rc in deployment/argocd-application-controller statefulset/argocd-application-controller; do
  if kubectl get "${rc}" -n argocd &>/dev/null; then
    kubectl rollout status "${rc}" -n argocd --timeout=180s
    break
  fi
done

echo "Argo CD installation complete."
echo "Retrieve initial admin password (run once):"
echo '  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo'
echo "UI via port-forward (TLS warning is expected with insecure mode):"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
