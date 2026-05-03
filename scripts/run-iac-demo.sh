#!/usr/bin/env bash
set -e

SCENARIO=$1
POLICY_PATH="../../iac-policies/terraform.rego"

echo "========================================"

if [ "$SCENARIO" == "bad" ]; then
    echo "IaC Guardrail Demo: Bad Infrastructure"
    echo "========================================"
    echo "Expected result: The Terraform plan should be blocked by Conftest."
    echo "  Expected denials:"
    echo "    - public access is not allowed"
    echo "    - encryption must be enabled"
    echo "    - owner tag is required"
    echo "    - environment tag is required"
    echo ""

    cd terraform/bad
    terraform init
    terraform plan -out=tfplan
    terraform show -json tfplan > tfplan.json

    set +e
    OUTPUT=$(conftest test tfplan.json -p "$POLICY_PATH" 2>&1)
    EXIT_CODE=$?
    set -e

    echo "$OUTPUT"
    echo ""
    cd ../..

    if [ $EXIT_CODE -eq 0 ]; then
        echo "ERROR: Bad plan was unexpectedly ACCEPTED. Demo failed!"
        exit 1
    fi

    if echo "$OUTPUT" | grep -q "public access is not allowed"; then
        echo "Result:"
        echo "The platform guardrail blocked the unsafe change before it reached production."
        exit 0
    fi

    echo "ERROR: Conftest failed, but not with the expected guardrail output."
    echo "This usually means a policy syntax error or tool error."
    exit 1

elif [ "$SCENARIO" == "good" ]; then
    echo "IaC Guardrail Demo: Good Infrastructure"
    echo "========================================"
    echo "Expected result: The Terraform plan passes policies."
    echo ""

    cd terraform/good
    terraform init
    terraform plan -out=tfplan
    terraform show -json tfplan > tfplan.json

    set +e
    OUTPUT=$(conftest test tfplan.json -p "$POLICY_PATH" 2>&1)
    EXIT_CODE=$?
    set -e

    echo "$OUTPUT"
    echo ""
    cd ../..

    if [ $EXIT_CODE -eq 0 ]; then
        echo "Result:"
        echo "The safe change passed the platform guardrails."
        exit 0
    else
        echo "ERROR: Good plan unexpectedly failed. Demo failed!"
        exit 1
    fi
else
    echo "Usage: $0 {bad|good}"
    exit 1
fi