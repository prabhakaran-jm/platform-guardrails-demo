$ErrorActionPreference = "Stop"

# Pin chart version for reliable demo runs (see README Known Assumptions).
$ArgoCdChartVersion = "9.5.11"

Write-Host "Installing Argo CD (${ArgoCdChartVersion})..." -ForegroundColor Cyan

& helm repo add argo https://argoproj.github.io/argo-helm 2>$null | Out-Null
& helm repo update | Out-Null

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ValuesFile = Join-Path $RepoRoot "gitops/argocd-demo-values.yaml"

& helm upgrade --install argocd argo/argo-cd `
  -n argocd --create-namespace `
  --version $ArgoCdChartVersion `
  -f $ValuesFile `
  --wait `
  --timeout 5m

if ($LASTEXITCODE -ne 0) {
    Write-Host "Helm failed to install Argo CD." -ForegroundColor Red
    exit $LASTEXITCODE
}

kubectl rollout status deployment/argocd-server -n argocd --timeout=180s
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=180s

$ignored = kubectl get deployment argocd-application-controller -n argocd -o name 2>$null
if ($LASTEXITCODE -eq 0) {
    kubectl rollout status deployment/argocd-application-controller -n argocd --timeout=180s
} else {
    kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=180s
}

Write-Host "Argo CD installation complete." -ForegroundColor Green
Write-Host "Retrieve initial admin password (run once):" -ForegroundColor Cyan
Write-Host '  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }; echo'
Write-Host "UI via port-forward (TLS warning is expected with insecure mode):" -ForegroundColor Cyan
Write-Host "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
