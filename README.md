# Platform Guardrails Demo

This repository contains a cross-platform demo for the PlatformCon talk:
**"Designing Platform Guardrails Using Kubernetes and Infrastructure as Code"**

This demo illustrates a crucial platform engineering concept: **Guardrails are not approval gates.** Instead of forcing developers to wait for human reviews or ticket approvals, guardrails provide fast, automated feedback that enforces boundaries while developers maintain autonomy.

## Architecture & How It Works

- **Infrastructure as Code (Terraform)** is validated locally or in CI using `conftest` (Rego policies) before applying—including **AWS-shaped Terraform plan JSON fixtures** you can lint without provisioning anything.
- **Kubernetes Workloads** are validated upon admission using Kyverno—even if unsafe YAML arrives manually, via `./demo.sh k8s-bad`, or through **GitOps**.
- **GitOps (Argo CD)** runs inside the demo cluster (`./demo.sh setup` installs Helm releases for Kyverno and Argo). Argo clones your Git fork and syncs manifests from [`k8s/good/`](k8s/good) or [`k8s/bad/`](k8s/bad), but admission control still rejects unsafe Pods.

See [`gitops/README.md`](gitops/README.md) for the narration between Argo sync outcomes and Kyverno enforcement details.

## Prerequisites

- Docker
- kind (Kubernetes in Docker)
- kubectl
- helm
- terraform
- conftest
- git (for GitOps demos and optional HTTPS `origin` inference)
- make (optional, for Linux/macOS users)

## Setup & Demo Flow

The demo scripts provide easy commands for your talk.

### macOS / Linux (Bash)

1. Fork this repository (GitHub/GitLab) where Argo CD can reach it publicly and push your commits.
2. `export DEMO_GITOPS_REPO_URL=https://github.com/your-handle/platform-guardrails-demo` _(optional — defaults to inferred `origin` HTTPS URL)_.
3. Setup: `./demo.sh setup`
4. Test bad manual apply: `./demo.sh k8s-bad`
5. Test good manifest directory: `./demo.sh k8s-good`
6. Test GitOps unhealthy path (requires reachable Git fork): `./demo.sh gitops-bad`
7. Test GitOps healthy path: `./demo.sh gitops-good`
8. Test bad IaC: `./demo.sh iac-bad`
9. Test good IaC: `./demo.sh iac-good`
10. Lint AWS-shaped IaC fixtures: `./demo.sh iac-fixtures`
11. Cleanup: `./demo.sh reset`

### Windows (PowerShell — No WSL required)

Same flow as Bash, swapping commands for `.\demo.ps1`:

1. Optionally `setx DEMO_GITOPS_REPO_URL https://github.com/your-handle/platform-guardrails-demo` (restart shell) — or rely on HTTPS `git remote get-url origin`.
2. Setup: `.\demo.ps1 setup`
3. `.\demo.ps1 k8s-bad` / `.\demo.ps1 k8s-good`
4. `.\demo.ps1 gitops-bad` / `.\demo.ps1 gitops-good`
5. IaC demos: `.\demo.ps1 iac-bad` / `iac-good`
6. `.\demo.ps1 iac-fixtures`
7. `.\demo.ps1 reset`

After setup, bootstrap Argo credentials any time via:

```
kubectl port-forward svc/argocd-server -n argocd 8080:443  # HTTPS UI on https://localhost:8080 — accept the self-signed cert in dev/demo mode
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

## Known Assumptions

- Docker is running locally and can pull container images referenced by manifests.
- The script pins the `kind` node image (`v1.29.2`), Kyverno chart `3.1.4`, and Argo CD Helm chart **`9.5.11`** (from `https://argoproj.github.io/argo-helm`) for stability.
- Argo CD must clone `repoURL`; there is **no unsupported “pure local filesystem” Application source**.
- Terraform examples use the `null` provider to avoid cloud credentials **while** IaC fixtures under [`iac-policies/fixtures/`](iac-policies/fixtures) exercise cloud-shaped Terraform plan fragments without accounts.

### GitOps prerequisites

Export `DEMO_GITOPS_REPO_URL`/`DEMO_GITOPS_REVISION`, or clone this repo locally so `./scripts/render-gitops-applications.{sh,ps1}` can infer HTTPS `origin`. Argo rejects unknown hosts until you approve or register credentials—prefer public forks during talks.

Commit your changes (`k8s/*`, manifests, README updates) **before running `gitops-*` demos**—Argo always reconciles Git, not unstaged workstation copies.

### Resource hints

Kyverno + Argo CD + sample workloads comfortably fit in a workstation with Docker allocated **≥6 GB RAM** (4 GB is often workable but slows webhook warm-up Helm hooks).

## Common Failure Points

- **Docker not running:** Ensure Docker Desktop / daemon is started before running `setup`.
- **Ports in use:** kind needs API server mappings; clashes fail setup fast.
- **Execution Policies (Windows):** Run `Set-ExecutionPolicy RemoteSigned -Scope Process` before scripts if PowerShell refuses them.
- **Argo repo URL missing:** `./demo.sh gitops-*` now fails fast—set `DEMO_GITOPS_REPO_URL`.
- **`gitops-good` timeouts:** Fork must include the manifests on `DEMO_GITOPS_REVISION`; Argo cannot sync private repos without PAT/SSH credential setup.
