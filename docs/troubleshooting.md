
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

Argo CD `argocd-repo-server` CrashLoopBackOff — fsnotify / too many open files
Symptom: `kubectl get pods -n argocd` shows `argocd-repo-server` restarting; logs say `failed to create fsnotify Watcher: too many open files`.
Why it happens: The repo-server starts a filesystem watcher on the GPG key directory; on Linux hosts with low **`fs.inotify`** limits or many existing watchers (IDEs, other containers), **`inotify`** or file-descriptor exhaustion can trigger this fatal error inside the pod.
Immediate diagnosis:
  kubectl logs -n argocd deploy/argocd-repo-server --tail=80
Fix (recommended — on the **host** that runs Docker/Podman/kind, not only inside the VM):
Temporary (until reboot):
  sudo sysctl fs.inotify.max_user_watches=524288 fs.inotify.max_user_instances=1024
Persist: create `/etc/sysctl.d/99-argocd-inotify.conf` owned by root with:
  fs.inotify.max_user_watches = 524288
  fs.inotify.max_user_instances = 1024
then run `sudo sysctl --system`.
Then delete the repo-server pod so it restarts: `kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-repo-server`.
If limits are already high, check **`ulimit -n`** on the host and Docker/Podman daemon settings; freeing other heavy watchers briefly confirms the diagnosis.

Helm timed out installing Kyverno (post-upgrade hooks)
Symptom: `UPGRADE FAILED: post-upgrade hooks failed: timed out waiting for the condition` after `Installing Kyverno`.
Fix: Scripts now use Helm `--timeout 20m`; if it still fails, give Docker/Podman more RAM/CPU, run `kubectl get pods -n kyverno`, `kubectl describe pod -n kyverno …`, `kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller`, and retry `./scripts/install-kyverno.sh`.

Kyverno Helm stuck pending-upgrade; hook or cleanup pods ImagePullBackOff
Symptom: `kubectl get pods -n kyverno` shows `kyverno-admission-controller` Running, but pods like `kyverno-hook-post-upgrade-*` or `kyverno-cleanup-*` are `ErrImagePull` / `ImagePullBackOff`; `helm status kyverno -n kyverno` shows `pending-upgrade`.

Why it happens:
- The webhook (admission-controller) pulls `ghcr.io/kyverno/kyverno:v1.x` and usually works first.
- Cleanup CronJobs and post-upgrade Hooks often pull a **different** image—rate limits, registry DNS, offline/VPN environments, or Podman quirks can prevent that pull while the main controllers still run.

Immediate diagnosis:
1. Inspect the failing pod for the concrete error:
   kubectl describe pod -n kyverno -l batch.kubernetes.io/controller-uid=<uid>
   Faster: kubectl describe pod -n kyverno kyverno-hook-post-upgrade-<suffix> 
   kubectl describe pod -n kyverno $(kubectl get pods -n kyverno -o name | grep cleanup | head -1)
   Look under Events for the image URI and reason (Unauthorized, Timeout, denied, pull access denied).

2. Confirm host can pull the same image listed in Events:
   podman pull "<image-from-events>"   # or docker pull ...

If demos are urgent and admission is Healthy:
3. Policies can still validate workloads when `kyverno-admission-controller` is Ready. Finish the scripted flow manually:
   kubectl apply -f policies/kyverno/
   ./scripts/install-argocd.sh
   Still fix pull issues before relying on CronJob cleanup/reporting hygiene in longer-lived clusters.

Unblock Helm (pick one lane):
Lane A — Prefer fixing pulls: resolve network/auth, VPN, GHCR/container registry access; delete the stale hook Job if Helm allows retry; rerun ./scripts/install-kyverno.sh.

Lane B — Roll back Helm and redo:
   helm history kyverno -n kyverno
   helm rollback kyverno <last-working-revision> -n kyverno
   Retry ./scripts/install-kyverno.sh after confirming podman/docker can pull the hook/cleanup images.

Lane C — Experimental last resort (`INSTALL_KYVERNO_NO_HOOKS=1`; see scripts/install-kyverno.sh). Skipping hooks can leave upgrade validation incomplete—only after you understand missing hook effects.

Helm list looks empty after pasting commands
Symptom: `helm list` appears to print blank output even though Kyverno is deployed.
Fix: Run `helm list -n kyverno` on its own line. Avoid pasting multi-line blobs that concatenate `helm status …` output with following commands (your shell may not run `helm list` as a separate invocation).

Conftest is missing
Symptom: ERROR: conftest is not installed or not in PATH.
Fix: Follow the official Conftest installation instructions: https://www.conftest.dev/install/

PowerShell execution policy blocks scripts
Symptom: Windows errors saying demo.ps1 cannot be loaded because running scripts is disabled on this system.
Fix: Run the following command in PowerShell as Administrator (or just for your current Process):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
