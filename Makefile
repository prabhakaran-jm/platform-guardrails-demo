.PHONY: setup k8s-bad k8s-good iac-bad iac-good iac-fixtures gitops-bad gitops-good reset

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
