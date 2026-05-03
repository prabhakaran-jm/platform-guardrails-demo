#!/usr/bin/env bash
set -e

COMMAND=$1

case "$COMMAND" in
  setup)
    echo "Starting Setup..."
    ./scripts/check-prereqs.sh
    ./scripts/setup-kind.sh
    ./scripts/install-kyverno.sh
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
  reset)
    ./reset.sh
    ;;
  *)
    echo "Usage: $0 {setup|k8s-bad|k8s-good|iac-bad|iac-good|reset}"
    exit 1
    ;;
esac
