#!/usr/bin/env bash
SCENARIO=$1
POLICY_PATH="../../iac-policies/terraform.rego"

echo "========================================"
if [ "$SCENARIO" == "bad" ]; then
    echo "IaC Guardrail Demo: Bad Infrastructure"
    echo "========================================"
    echo "Expected result: The Terraform plan should be blocked by Conftest."
    echo ""
    
    cd terraform/bad
    terraform init
    terraform plan -out=tfplan
    terraform show -json tfplan > tfplan.json
    
    set +e
    OUTPUT=$(conftest test tfplan.json -p $POLICY_PATH 2>&1)
    EXIT_CODE=$?
    set -e
    
    echo "$OUTPUT"
    echo ""
    cd ../..
    if [ $EXIT_CODE -eq 0 ]; then
        echo "ERROR: Bad plan was unexpectedly ACCEPTED. Demo failed!"
        exit 1
    else
        echo "Result:"
        echo "The platform guardrail blocked the unsafe change before it reached production."
        exit 0
    fi

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
    OUTPUT=$(conftest test tfplan.json -p $POLICY_PATH 2>&1)
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
fi
