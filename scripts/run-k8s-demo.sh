#!/usr/bin/env bash
SCENARIO=$1

echo "========================================"
if [ "$SCENARIO" == "bad" ]; then
    echo "Kubernetes Guardrail Demo: Bad Workload"
    echo "========================================"
    echo "Expected result: This deployment should be blocked by Kyverno."
    echo ""
    
    set +e
    OUTPUT=$(kubectl apply -f k8s/bad/deployment.yaml 2>&1)
    EXIT_CODE=$?
    set -e
    
    echo "$OUTPUT"
    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
        echo "ERROR: Bad deployment was unexpectedly ACCEPTED. Demo failed!"
        exit 1
    else
        echo "Result:"
        echo "The platform guardrail blocked the unsafe change before it reached production."
        exit 0
    fi

elif [ "$SCENARIO" == "good" ]; then
    echo "Kubernetes Guardrail Demo: Good Workload"
    echo "========================================"
    echo "Expected result: This deployment passes policies and applies successfully."
    echo ""
    
    kubectl apply -f k8s/good/
    EXIT_CODE=$?
    
    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Result:"
        echo "The safe change passed the platform guardrails."
        exit 0
    else
        echo "ERROR: Good deployment unexpectedly failed. Demo failed!"
        exit 1
    fi
fi
