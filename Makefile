.PHONY: setup k8s-bad k8s-good iac-bad iac-good reset

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

reset:
	@./demo.sh reset
