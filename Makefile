.PHONY: help setup k8s-bad k8s-good iac-bad iac-good iac-fixtures gitops-bad gitops-good reset

help:
	@echo "Platform Guardrails Demo — make targets:"
	@echo "  make setup         Install kind cluster, Kyverno, Argo CD"
	@echo "  make iac-fixtures  Conftest against AWS-shaped plan JSON (safest demo)"
	@echo "  make iac-bad       terraform plan + Conftest (should fail)"
	@echo "  make iac-good      terraform plan + Conftest (should pass)"
	@echo "  make k8s-bad       kubectl apply unsafe Deployment (Kyverno blocks)"
	@echo "  make k8s-good      kubectl apply safe Deployment (admitted)"
	@echo "  make gitops-bad    Argo CD applies unsafe path; admission blocks"
	@echo "  make gitops-good   Argo CD applies safe path; sync succeeds"
	@echo "  make reset         Delete kind cluster + terraform state"

setup:
	@./demo.sh setup

k8s-bad:
	@./demo.sh k8s-bad

k8s-good:
	@./demo.sh k8s-good

iac-bad:
	@./demo.sh iac-bad

iac-good:
	@./demo.sh iac-good

iac-fixtures:
	@./demo.sh iac-fixtures

gitops-good:
	@./demo.sh gitops-good

gitops-bad:
	@./demo.sh gitops-bad

reset:
	@./demo.sh reset
