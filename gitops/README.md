# GitOps and Platform Guardrails

GitOps is a powerful pattern for reconciling desired state into a cluster. However, **GitOps is not a substitute for admission control**. 

In this folder, we include identical workloads mapped as GitOps application manifests. We do not require Argo CD to run the demo, but this section explains how the two concepts integrate.

### Why Admission Control Matters in GitOps
If a developer creates a Pull Request updating a workload in Git with an unsafe configuration (like a privileged container), and the CI checks miss it, Argo CD will try to sync that bad workload.

Because our Kyverno policies are running inside the Kubernetes cluster as admission webhooks, Argo CD's sync will fail. The platform guardrail catches the failure at the boundary. The desired state is blocked, and the cluster remains secure.

### Optional Exploration
To see how these files structure:
* `apps/bad-app.yaml` maps to the bad workload.
* `apps/good-app.yaml` maps to the good workload.

These files mirror the structure you would manage in an enterprise GitOps workflow.
