$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleaning up demo environment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ClusterName = "platform-guardrails-demo"
$clusters = @()

try {
    $clusterOutput = & kind get clusters 2>$null

    if ($LASTEXITCODE -eq 0 -and $clusterOutput) {
        $clusters = @($clusterOutput)
    }
}
catch {
    $clusters = @()
}

if ($clusters -contains $ClusterName) {
    Write-Host "Deleting kind cluster '$ClusterName'..." -ForegroundColor Cyan
    & kind delete cluster --name $ClusterName
}
else {
    Write-Host "Cluster already deleted." -ForegroundColor Yellow
}

Write-Host "Cleaning Terraform files..." -ForegroundColor Cyan

$tfDirs = Get-ChildItem -Path "terraform" -Filter ".terraform" -Recurse -Directory -ErrorAction SilentlyContinue

foreach ($dir in $tfDirs) {
    Remove-Item -Path $dir.FullName -Recurse -Force
}

$tfLocks = Get-ChildItem -Path "terraform" -Filter ".terraform.lock.hcl" -Recurse -File -ErrorAction SilentlyContinue

foreach ($file in $tfLocks) {
    Remove-Item -Path $file.FullName -Force
}

$tfPlans = Get-ChildItem -Path "terraform" -Filter "tfplan*" -Recurse -File -ErrorAction SilentlyContinue

foreach ($file in $tfPlans) {
    Remove-Item -Path $file.FullName -Force
}

$tfStates = Get-ChildItem -Path "terraform" -Filter "terraform.tfstate*" -Recurse -File -ErrorAction SilentlyContinue

foreach ($file in $tfStates) {
    Remove-Item -Path $file.FullName -Force
}

Write-Host "Reset complete. Source files kept intact." -ForegroundColor Green
