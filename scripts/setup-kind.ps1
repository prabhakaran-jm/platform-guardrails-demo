$ErrorActionPreference = "Stop"

$ClusterName = "platform-guardrails-demo"
$NodeImage = "kindest/node:v1.29.2"

Write-Host "Checking for existing kind cluster '$ClusterName'..." -ForegroundColor Cyan

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
    Write-Host "Kind cluster '$ClusterName' already exists. Skipping creation." -ForegroundColor Yellow
} else {
    Write-Host "Creating kind cluster '$ClusterName'..." -ForegroundColor Cyan
    & kind create cluster --name $ClusterName --image $NodeImage

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create kind cluster." -ForegroundColor Red
        exit 1
    }
}

& kubectl cluster-info --context "kind-$ClusterName"

if ($LASTEXITCODE -ne 0) {
    Write-Host "kubectl could not reach the kind cluster." -ForegroundColor Red
    exit 1
}

Write-Host "Kind setup successful." -ForegroundColor Green
