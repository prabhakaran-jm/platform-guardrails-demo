#!/usr/bin/env bash
set -euo pipefail

SCENARIO=${1:?}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${ROOT:-}" ]]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
cd "${ROOT}"

if [[ ! -d scripts ]]; then
  echo "ERROR: scripts/ not found — run from the repository root."
  exit 2
fi

if ! kubectl get namespace argocd &>/dev/null; then
  echo "ERROR: namespace argocd not found. Run: ./demo.sh setup"
  exit 2
fi

# Fork reachability precheck — Argo can only sync a repoURL it can clone.
REPO="${DEMO_GITOPS_REPO_URL:-}"
if [[ -z "$REPO" ]]; then
  REMOTE=$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)
  if [[ "$REMOTE" =~ ^https:// ]]; then
    REPO="${REMOTE%.git}"
  elif [[ "$REMOTE" =~ ^git@ ]]; then
    stripped="${REMOTE#git@}"; host="${stripped%%:*}"; path="${stripped#*:}"; path="${path%.git}"
    REPO="https://${host}/${path}"
  fi
fi
if [[ -z "$REPO" ]] || [[ ! "$REPO" =~ ^https:// ]]; then
  echo "ERROR: GitOps demo requires a public HTTPS fork URL."
  echo "  Set DEMO_GITOPS_REPO_URL or push your fork as 'origin' over HTTPS."
  echo "  For the recording, prefer ./demo.sh k8s-bad / k8s-good (no remote needed)."
  exit 2
fi
echo "Checking fork reachability: ${REPO}"
if ! git ls-remote "${REPO}" "${DEMO_GITOPS_REVISION:-main}" &>/dev/null; then
  echo "ERROR: Cannot reach ${REPO}@${DEMO_GITOPS_REVISION:-main}."
  echo "  Push your fork (with the latest manifests) before running gitops-* demos."
  exit 2
fi

cleanup_apps() {
  kubectl delete applications.argoproj.io demo-gitops-good demo-gitops-bad \
    -n argocd --ignore-not-found
}

poll_good() {
  local attempt
  local sync_health_ok=0
  local progress_printed=0

  echo "Waiting for Argo CD to sync the healthy application (up to ~3 minutes)..."
  for attempt in $(seq 1 90); do
    local SYNC
    SYNC=$(kubectl get applications.argoproj.io demo-gitops-good -n argocd \
      -o jsonpath="{.status.sync.status}" 2>/dev/null || echo "")

    local HEALTH
    HEALTH=$(kubectl get applications.argoproj.io demo-gitops-good -n argocd \
      -o jsonpath="{.status.health.status}" 2>/dev/null || echo "")

    if [[ "$SYNC" == "Synced" && "$HEALTH" == "Healthy" ]]; then
      sync_health_ok=1
      if [[ "${progress_printed}" -eq 1 ]]; then
        printf "\n"
      fi
      echo "Application reports Synced / Healthy."
      break
    fi

    # Avoid a transient "sync=? health=?" row while Argo has not populated status yet.
    if [[ -n "$SYNC" || -n "$HEALTH" ]] || [[ "${attempt}" -ge 5 ]]; then
      printf "\r[%02d/%02d] sync=%s health=%s" "$attempt" 90 "${SYNC:-?}" "${HEALTH:-?}"
      progress_printed=1
    fi
    sleep 2
  done

  # Finish the spinner line only when we timed out (success message already owns its line).
  if [[ "${sync_health_ok}" -eq 0 ]] && [[ "${progress_printed}" -eq 1 ]]; then
    printf "\n"
  fi

  if [[ "$sync_health_ok" -eq 0 ]]; then
    echo "ERROR: Timed out waiting for demo-gitops-good to become Healthy."
    kubectl get applications.argoproj.io demo-gitops-good -n argocd -o yaml | tail -n 40 || true
    exit 1
  fi

  kubectl rollout status deployment/demo-app-good -n default --timeout=120s
}

poll_bad_blocked() {
  local attempt

  echo "Waiting for Kyverno to block admission during Argo sync (up to ~3 minutes)..."

  for attempt in $(seq 1 90); do
    local MSG PHASE
    MSG=$(kubectl get applications.argoproj.io demo-gitops-bad -n argocd \
      -o jsonpath="{.status.operationState.message}" 2>/dev/null || echo "")
    PHASE=$(kubectl get applications.argoproj.io demo-gitops-bad -n argocd \
      -o jsonpath="{.status.operationState.phase}" 2>/dev/null || echo "")

    local has_privileged=0 owner=0 limits=0
    if grep -Fq "privileged containers are not allowed" <<<"$MSG"; then has_privileged=1; fi
    if grep -Fq "owner label is required" <<<"$MSG"; then owner=1; fi
    if grep -Fq "resource requests and limits are" <<<"$MSG"; then limits=1; fi

    if [[ $has_privileged -eq 1 && $owner -eq 1 && $limits -eq 1 ]]; then
      printf "\r[%02d/%02d] phase=%s (Kyverno messages present)\n" "$attempt" 90 "${PHASE:-?}"
      echo ""
      echo "${MSG}"
      echo ""
      echo "Result:"
      echo "Argo CD applied Git state, but admission control prevented the unsafe Pods from scheduling."
      return 0
    fi

    printf "\r[%02d/%02d] phase=%s sniffing kyverno output..." "$attempt" 90 "${PHASE:-?}"
    sleep 2
  done
  printf "\n"

  echo "ERROR: Timed out without seeing combined Kyverno enforcement output on the Application."
  echo "kubectl get application demo-gitops-bad -n argocd -o yaml excerpt:"
  kubectl get applications.argoproj.io demo-gitops-bad -n argocd -o yaml | tail -n 60 || true
  exit 1
}

echo "========================================"
if [[ "${SCENARIO}" == "bad" ]]; then
  echo "GitOps Guardrail Demo: Unsafe manifest via Argo CD"
  echo "========================================"
  echo "Expected result: Admission control blocks Pods (Kyverno) while Argo reports a failed sync."
  echo ""

  cleanup_apps
  ./scripts/render-gitops-applications.sh --kubectl-apply demo-gitops-bad.yaml.in
  poll_bad_blocked
elif [[ "${SCENARIO}" == "good" ]]; then
  echo "GitOps Guardrail Demo: Healthy manifest via Argo CD"
  echo "========================================"
  echo "Expected result: Sync succeeds and the Deployment becomes ready."
  echo ""

  cleanup_apps
  ./scripts/render-gitops-applications.sh --kubectl-apply demo-gitops-good.yaml.in
  poll_good

  echo "Result:"
  echo "GitOps synced a compliant workload past admission control successfully."
else
  echo "Usage: $0 {bad|good}"
  exit 1
fi
