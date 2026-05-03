Write-Host "Installing Kyverno..." -ForegroundColor Cyan

helm repo add kyverno https://kyverno.github.io/kyverno/ | Out-Null
helm repo update | Out-Null

Write-Host "Installing Kyverno release via Helm (--wait --timeout 5m)." -ForegroundColor DarkGray

$helmArgs = @(
    "upgrade", "--install", "kyverno", "kyverno/kyverno",
    "-n", "kyverno", "--create-namespace",
    "--version", "3.1.4",
    "--set", "admissionController.replicas=1",
    "--wait",
    "--timeout", "5m"
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

Write-Host "Waiting for ClusterPolicies to report Ready..." -ForegroundColor Cyan
foreach ($policy in @("disallow-privileged-containers", "require-resource-limits", "require-owner-label")) {
    kubectl wait --for=condition=Ready "clusterpolicy/$policy" --timeout=60s 2>$null | Out-Null
}
Start-Sleep -Seconds 3

Write-Host "Kyverno installation and policy application complete." -ForegroundColor Green
