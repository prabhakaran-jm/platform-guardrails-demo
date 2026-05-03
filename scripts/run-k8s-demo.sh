#!/usr/bin/env bash
set -uo pipefail

SCENARIO=${1:-}

echo "========================================"
if [ "$SCENARIO" == "bad" ]; then
    echo "Kubernetes Guardrail Demo: Bad Workload"
    echo "========================================"
    echo "Expected result: This deployment should be blocked by Kyverno."
    echo "  Policies that should fire:"
    echo "    - disallow-privileged-containers"
    echo "    - require-resource-limits"
    echo "    - require-owner-label"
    echo ""

    OUTPUT=$(kubectl apply -f k8s/bad/deployment.yaml -n default 2>&1)
    EXIT_CODE=$?

    echo "$OUTPUT"
    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
        echo "ERROR: Bad deployment was unexpectedly ACCEPTED. Demo failed!"
        exit 1
    fi

    echo "Result:"
    echo "The platform guardrail blocked the unsafe change before it reached production."
    exit 0

elif [ "$SCENARIO" == "good" ]; then
    echo "Kubernetes Guardrail Demo: Good Workload"
    echo "========================================"
    echo "Expected result: This deployment passes policies and applies successfully."
    echo ""

    if ! kubectl apply -f k8s/good/ -n default; then
        echo "ERROR: Good deployment unexpectedly failed at admission."
        exit 1
    fi

    echo ""
    echo "Waiting for rollout to complete..."
    if ! kubectl rollout status deployment/demo-app-good -n default --timeout=90s; then
        echo "ERROR: Deployment did not become ready in time."
        exit 1
    fi

    echo ""
    echo "Result:"
    echo "The safe change passed the platform guardrails and is running."
    exit 0
else
    echo "Usage: $0 {bad|good}"
    exit 1
fi
