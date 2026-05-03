# Platform Guardrails Demo

This repository contains a cross-platform demo for the PlatformCon talk: 
**"Designing Platform Guardrails Using Kubernetes and Infrastructure as Code"**

This demo illustrates a crucial platform engineering concept: **Guardrails are not approval gates.** Instead of forcing developers to wait for human reviews or ticket approvals, guardrails provide fast, automated feedback that enforces boundaries while developers maintain autonomy.

## Architecture & How It Works
* **Infrastructure as Code (Terraform)** is validated locally or in CI using `conftest` (Rego policies) before applying.
* **Kubernetes Workloads** are validated upon admission using Kyverno. Even if an unsafe resource makes it to the cluster (e.g., via a manual `kubectl apply` or GitOps), the admission webhook blocks it instantly.

## Prerequisites
* Docker
* kind (Kubernetes in Docker)
* kubectl
* helm
* terraform
* conftest
* make (optional, for Linux/macOS users)

## Setup & Demo Flow

The demo scripts provide easy commands for your talk. 

### macOS / Linux (Bash)
1. Setup: `./demo.sh setup`
2. Test bad K8s: `./demo.sh k8s-bad` (Blocked by Kyverno)
3. Test good K8s: `./demo.sh k8s-good` (Passes)
4. Test bad IaC: `./demo.sh iac-bad` (Blocked by Conftest)
5. Test good IaC: `./demo.sh iac-good` (Passes)
6. Cleanup: `./demo.sh reset`

### Windows (PowerShell - No WSL required)
1. Setup: `.\demo.ps1 setup`
2. Test bad K8s: `.\demo.ps1 k8s-bad`
3. Test good K8s: `.\demo.ps1 k8s-good`
4. Test bad IaC: `.\demo.ps1 iac-bad`
5. Test good IaC: `.\demo.ps1 iac-good`
6. Cleanup: `.\demo.ps1 reset`

## Known Assumptions
* You have a locally running Docker daemon.
* The script pins `kind` node image `v1.29.2` and Kyverno chart `3.1.4` for stability.
* Terraform tests use the `null` provider to avoid needing cloud credentials.

## Common Failure Points
* **Docker not running:** Ensure Docker Desktop / daemon is started before running `setup`.
* **Ports in use:** `kind` needs local ports to map the API server. If blocked, `setup` will fail.
* **Execution Policies (Windows):** If scripts are blocked, run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`.
