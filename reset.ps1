Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleaning up demo environment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$clusters = kind get clusters 2>$null
if ($clusters -contains "platform-guardrails-demo") {
    Write-Host "Deleting kind cluster 'platform-guardrails-demo'..."
    kind delete cluster --name platform-guardrails-demo
} else {
    Write-Host "Cluster already deleted."
}

Write-Host "Cleaning Terraform files..."
$tfDirs = Get-ChildItem -Path "terraform" -Filter ".terraform" -Recurse -Directory -ErrorAction SilentlyContinue
foreach ($dir in $tfDirs) { Remove-Item -Path $dir.FullName -Recurse -Force }

$tfLocks = Get-ChildItem -Path "terraform" -Filter ".terraform.lock.hcl" -Recurse -File -ErrorAction SilentlyContinue
foreach ($file in $tfLocks) { Remove-Item -Path $file.FullName -Force }

$tfPlans = Get-ChildItem -Path "terraform" -Filter "tfplan*" -Recurse -File -ErrorAction SilentlyContinue
foreach ($file in $tfPlans) { Remove-Item -Path $file.FullName -Force }

Write-Host "Reset complete. Source files kept intact." -ForegroundColor Green
