# GitOps and platform guardrails

GitOps controllers reconcile Git into the cluster—but **they are not a substitute for admission control**.

## Why Kyverno still wins

When an unsafe workload lands in Git and makes it past CI gaps, GitOps happily tries to apply it.

Our Kyverno policies attach to the Kubernetes API as validating admission webhooks, so controllers like **Argo CD** fail the sync—the cluster boundary blocks the Pods even though automation attempted the rollout.

This repository automates both roles:

| Layer | Responsibility |
| --- | --- |
| Argo CD | Pulls manifests from Git and pushes them toward the desired state inside the cluster. |
| Kyverno | Validates *every* AdmissionReview (kubectl, controllers, Helm post-render, etc.). |

The flow is scripted end-to-end: `./demo.sh setup` installs Kyverno **and** Argo CD, then `./demo.sh gitops-{good,bad}` render real `Applications` that point at [`k8s/good/`](../k8s/good) and [`k8s/bad/`](../k8s/bad). Argo clones your repository, so **`DEMO_GITOPS_REPO_URL` must resolve to HTTPS Git remotes Argo CD can reach**—fork this repo publicly or expose your fork to the tooling.

Rendered manifests live beside their templates inside [`gitops/argocd-applications`](argocd-applications). Use `./scripts/render-gitops-applications.sh` manually if you prefer to inspect the YAML before handing it off to kubectl.
