#!/usr/bin/env bash
# Renders gitops/argocd-applications/*.yaml.in via token replacement.
# Set DEMO_GITOPS_REPO_URL / DEMO_GITOPS_REVISION; if URL is unset, infer from git remote origin (HTTPS form).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IN_DIR="${ROOT}/gitops/argocd-applications"

REV="${DEMO_GITOPS_REVISION:-main}"
REPO="${DEMO_GITOPS_REPO_URL:-}"

if [[ -z "$REPO" ]]; then
  REMOTE=$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)
  if [[ "$REMOTE" =~ ^https:// ]]; then
    REPO="${REMOTE%.git}"
  elif [[ "$REMOTE" =~ ^git@ ]]; then
    stripped="${REMOTE#git@}"
    host="${stripped%%:*}"
    path="${stripped#*:}"
    path="${path%.git}"
    REPO="https://${host}/${path}"
  fi
fi

if [[ -z "$REPO" ]]; then
  echo "ERROR: DEMO_GITOPS_REPO_URL is unset and could not be inferred from git remote." >&2
  echo "Set DEMO_GITOPS_REPO_URL to a Git HTTPS URL Argo CD can clone (typically your fork on GitHub)." >&2
  exit 2
fi

render_file() {
  local src=$1
  local c
  c=$(cat "$src")
  c="${c//__DEMO_REPO_URL__/${REPO}}"
  c="${c//__DEMO_REVISION__/${REV}}"
  printf '%s\n' "$c"
}

print_all() {
  shopt -s nullglob
  for src in "${IN_DIR}"/*.yaml.in; do
    echo "---"
    render_file "$src"
  done
}

case "${1:-}" in
  --kubectl-apply)
    fname="${2:-}"
    if [[ -z "$fname" ]]; then
      echo "Usage: $0 --kubectl-apply <file.yaml.in>" >&2
      exit 2
    fi
    render_file "${IN_DIR}/${fname}" | kubectl apply -f -
    ;;
  --kubectl-apply-all)
    TMPDIR=$(mktemp -d "/tmp/platform-guardrails-gitops-render.XXXXXX")
    trap 'rm -rf "$TMPDIR"' EXIT
    shopt -s nullglob
    for src in "${IN_DIR}"/*.yaml.in; do
      base=$(basename "${src%.in}")
      render_file "$src" >"${TMPDIR}/${base}"
    done
    kubectl apply -f "$TMPDIR"
    ;;
  "")
    print_all
    ;;
  *)
    echo "Usage: $0 [--kubectl-apply <file.yaml.in> | --kubectl-apply-all | (no args: print YAML to stdout)]" >&2
    exit 2
    ;;
esac
