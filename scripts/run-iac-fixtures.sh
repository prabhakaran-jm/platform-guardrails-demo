#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${ROOT:-}" ]]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
cd "${ROOT}"

POLICY="./iac-policies/terraform.rego"
GOOD_FIXTURE="./iac-policies/fixtures/plan-s3-good.json"
BAD_FIXTURE="./iac-policies/fixtures/plan-s3-bad.json"

echo "========================================"
echo "IaC fixture checks (AWS-shaped plan JSON)"
echo "========================================"

echo "Fixture (should pass): ${GOOD_FIXTURE}"
conftest test "${GOOD_FIXTURE}" -p "${POLICY}"

echo ""
echo "Fixture (should fail): ${BAD_FIXTURE}"
set +e
OUTPUT_BAD=$(conftest test "${BAD_FIXTURE}" -p "${POLICY}" 2>&1)
EXIT_BAD=$?
set -e

echo "${OUTPUT_BAD}"
echo ""

if [[ ${EXIT_BAD} -eq 0 ]]; then
  echo "ERROR: Bad fixture was unexpectedly accepted."
  exit 1
fi

if grep -Fq "public access is not allowed" <<<"${OUTPUT_BAD}"; then :; else
  echo "ERROR: Missing expected denial: public access is not allowed"
  exit 1
fi

if grep -Fq "encryption must be enabled" <<<"${OUTPUT_BAD}"; then :; else
  echo "ERROR: Missing expected denial: encryption must be enabled"
  exit 1
fi

if grep -Fq "owner tag is required" <<<"${OUTPUT_BAD}"; then :; else
  echo "ERROR: Missing expected denial: owner tag is required"
  exit 1
fi

if grep -Fq "environment tag is required" <<<"${OUTPUT_BAD}"; then :; else
  echo "ERROR: Missing expected denial: environment tag is required"
  exit 1
fi

echo "Result:"
echo "Unsafe S3-shaped plan fixtures are blocked consistently by the same principles as Terraform null mocks."
exit 0
