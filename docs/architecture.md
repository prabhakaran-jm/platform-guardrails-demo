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
    GitOps desired state (Optional in demo)
        ↓
    Kubernetes admission control (Kyverno)
        ↓
    Observability and audit (Blocked/Allowed Requests)
```

Explaining the Flow
IaC guardrails run before infrastructure changes are applied. By testing the generated JSON plan from Terraform with Conftest, we prevent expensive cloud misconfigurations without needing manual security reviews.
Kubernetes guardrails run at admission time. Policies are validated by Kyverno acting as a validating admission webhook in the K8s API flow.
GitOps is optional in this demo. For simplicity, we use local CLI operations to simulate fast developer loops. However, the exact same patterns can easily move into CI/CD or an ArgoCD GitOps architecture.
