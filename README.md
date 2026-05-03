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
- conftest **≥ 0.68** (bundles OPA 1.x; matches [`iac-policy-check`](.github/workflows/iac-policy-check.yml) and `iac-policies/terraform.rego` Rego v1 syntax)
- git (for GitOps demos and optional HTTPS `origin` inference)
- make (optional, for Linux/macOS users)

## Setup & Demo Flow

The demo scripts provide easy commands for your talk.

### macOS / Linux (Bash)

1. Setup: `./demo.sh setup`
2. IaC fixtures (AWS-shaped plan JSON, no terraform init needed): `./demo.sh iac-fixtures`
3. Bad IaC (terraform plan + Conftest): `./demo.sh iac-bad`
4. Good IaC: `./demo.sh iac-good`
5. Bad K8s workload (Kyverno blocks at admission): `./demo.sh k8s-bad`
6. Good K8s workload: `./demo.sh k8s-good`
7. _Optional_ GitOps unhealthy path (requires public fork): `./demo.sh gitops-bad`
8. _Optional_ GitOps healthy path: `./demo.sh gitops-good`
9. Cleanup: `./demo.sh reset`

> **Recording flow tip:** for a 15‑minute pre-recorded talk, keep `iac-fixtures` + `k8s-bad` + `k8s-good` on camera. They are deterministic, need no remote network, and produce one-screen output. Run GitOps off-camera or replace it with a slide.

For GitOps, fork this repo on GitHub and push your commits, then either `export DEMO_GITOPS_REPO_URL=https://github.com/your-handle/platform-guardrails-demo` or rely on the inferred `origin` HTTPS URL. The `gitops-*` commands now precheck reachability with `git ls-remote` and abort early with a clear error if the fork can't be reached.

### Windows (PowerShell — No WSL required)

Same flow as Bash, swapping commands for `.\demo.ps1`:

1. Setup: `.\demo.ps1 setup`
2. `.\demo.ps1 iac-fixtures`
3. `.\demo.ps1 iac-bad` / `.\demo.ps1 iac-good`
4. `.\demo.ps1 k8s-bad` / `.\demo.ps1 k8s-good`
5. _Optional_: `.\demo.ps1 gitops-bad` / `.\demo.ps1 gitops-good` (requires public fork; precheck will tell you if it isn't reachable)
6. `.\demo.ps1 reset`

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

On some Linux workstations, **`argocd-repo-server`** can crash with `failed to create fsnotify Watcher: too many open files` until you raise **`fs.inotify.max_user_watches`** / **`max_user_instances`** on the Docker/Podman host—see [`docs/troubleshooting.md`](docs/troubleshooting.md).

## Common Failure Points

- **Docker not running:** Ensure Docker Desktop / daemon is started before running `setup`.
- **Ports in use:** kind needs API server mappings; clashes fail setup fast.
- **Execution Policies (Windows):** Run `Set-ExecutionPolicy RemoteSigned -Scope Process` before scripts if PowerShell refuses them.
- **Argo repo URL missing:** `./demo.sh gitops-*` now fails fast—set `DEMO_GITOPS_REPO_URL`.
- **`gitops-good` timeouts:** Fork must include the manifests on `DEMO_GITOPS_REVISION`; Argo cannot sync private repos without PAT/SSH credential setup.
- **Argo repo-server crash loop:** Logs often cite **fsnotify** / **too many open files**; raise host **inotify** limits (linked troubleshooting doc).
