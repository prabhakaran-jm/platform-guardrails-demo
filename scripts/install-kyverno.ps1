Write-Host "Installing Kyverno..." -ForegroundColor Cyan

helm repo add kyverno https://kyverno.github.io/kyverno/ | Out-Null
helm repo update | Out-Null

Write-Host "Installing Kyverno release via Helm (--wait --timeout 20m). This can take several minutes on kind/Podman." -ForegroundColor DarkGray

$helmArgs = @(
    "upgrade", "--install", "kyverno", "kyverno/kyverno",
    "-n", "kyverno", "--create-namespace",
    "--version", "3.1.4",
    "--set", "admissionController.replicas=1",
    "--wait",
    "--timeout", "20m"
)
if ($env:INSTALL_KYVERNO_NO_HOOKS -eq "1") {
    Write-Host "WARNING: INSTALL_KYVERNO_NO_HOOKS=1 — skipping Helm hooks." -ForegroundColor Yellow
    $helmArgs += "--no-hooks"
}

& helm @helmArgs

if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "Waiting for Kyverno webhook to be fully ready..." -ForegroundColor Cyan
kubectl rollout status deployment/kyverno-admission-controller -n kyverno --timeout=180s

Write-Host "Applying Kubernetes Guardrail Policies..." -ForegroundColor Cyan
kubectl apply -f policies/kyverno/

Write-Host "Waiting 5 seconds for webhooks to register policies globally..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

Write-Host "Kyverno installation and policy application complete." -ForegroundColor Green
