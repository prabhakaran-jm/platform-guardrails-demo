# Architecture

```text
    Developer
        ↓
    Pull request / Local Terminal
        ↓
    CI / local validation (Conftest + Rego)
        ↓
    Terraform plan policy check (Blocks unsafe IaC)
        ↓
    GitOps desired state (Argo CD — optional scripted path)
        ↓
    Kubernetes admission control (Kyverno)
        ↓
    Observability and audit (Blocked/Allowed Requests)
```

Explaining the Flow
IaC guardrails run before infrastructure changes are applied. By testing the generated JSON plan from Terraform with Conftest, we prevent expensive cloud misconfigurations without needing manual security reviews.
Kubernetes guardrails run at admission time. Policies are validated by Kyverno acting as a validating admission webhook in the K8s API flow.
GitOps is optional depending on narrative depth: `./demo.sh k8s-*` covers admission-only demos, while `./demo.sh gitops-*` runs Argo CD against the fork you configure through `DEMO_GITOPS_REPO_URL`. Regardless of pathway, Kyverno still blocks unsafe Pods at admission time.
