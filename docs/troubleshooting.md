
Troubleshooting
Docker not running
Symptom: ERROR: Docker daemon is not running.
Fix: Start Docker Desktop or your local Docker engine and verify it works by running docker ps.

kind cluster already exists
Symptom: Setup warns the cluster already exists.
Fix: The scripts are idempotent. If you want a totally fresh cluster, run ./demo.sh reset (or .\demo.ps1 reset) to destroy it and start over.

kubectl points to the wrong context
Symptom: Kyverno fails to install or Kubernetes policies fail to apply.
Fix: Run kubectl config use-context kind-platform-guardrails-demo to ensure you are targeting the right cluster.

Kyverno pods are not ready
Symptom: The setup script times out waiting for Kyverno pods.
Fix: Ensure your machine has enough memory allocated to Docker (at least 2GB is recommended for kind + Kyverno). Run kubectl get pods -n kyverno to investigate.

Helm install fails
Symptom: Helm says "cannot re-use a name that is still in use".
Fix: Run ./demo.sh reset and restart the setup.

Terraform provider download fails
Symptom: terraform init fails.
Fix: Ensure you have outbound internet connectivity. If you're on a corporate VPN, it may be blocking access to HashiCorp's registry.

Argo CD Helm fails: Kyverno blocked argocd-redis-secret-init Job
Symptom: `validate.kyverno.svc-fail` denies Job in namespace `argocd` for owner label / resource limits.
Fix: Policies exclude platform namespaces (`argocd`, `kyverno`, `kube-system`). Run `kubectl apply -f policies/kyverno/`, then `helm uninstall argocd -n argocd` (if stuck) and `./scripts/install-argocd.sh`.

Helm timed out installing Kyverno (post-upgrade hooks)
Symptom: `UPGRADE FAILED: post-upgrade hooks failed: timed out waiting for the condition` after `Installing Kyverno`.
Fix: Scripts now use Helm `--timeout 20m`; if it still fails, give Docker/Podman more RAM/CPU, run `kubectl get pods -n kyverno`, `kubectl describe pod -n kyverno …`, `kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller`, and retry `./scripts/install-kyverno.sh`.

Conftest is missing
Symptom: ERROR: conftest is not installed or not in PATH.
Fix: Follow the official Conftest installation instructions: https://www.conftest.dev/install/

PowerShell execution policy blocks scripts
Symptom: Windows errors saying demo.ps1 cannot be loaded because running scripts is disabled on this system.
Fix: Run the following command in PowerShell as Administrator (or just for your current Process):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
