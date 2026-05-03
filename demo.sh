#!/usr/bin/env bash
set -e

COMMAND=$1

case "$COMMAND" in
  setup)
    echo "Starting Setup..."
    ./scripts/check-prereqs.sh
    ./scripts/setup-kind.sh
    ./scripts/install-kyverno.sh
    ./scripts/install-argocd.sh
    echo "Setup complete."
    ;;
  k8s-bad)
    ./scripts/run-k8s-demo.sh bad
    ;;
  k8s-good)
    ./scripts/run-k8s-demo.sh good
    ;;
  iac-bad)
    ./scripts/run-iac-demo.sh bad
    ;;
  iac-good)
    ./scripts/run-iac-demo.sh good
    ;;
  iac-fixtures)
    ./scripts/run-iac-fixtures.sh
    ;;
  gitops-good)
    ./scripts/run-gitops-demo.sh good
    ;;
  gitops-bad)
    ./scripts/run-gitops-demo.sh bad
    ;;
  reset)
    ./reset.sh
    ;;
  *)
    echo "Usage: $0 {setup|k8s-bad|k8s-good|iac-bad|iac-good|iac-fixtures|gitops-bad|gitops-good|reset}"
    exit 1
    ;;
esac
