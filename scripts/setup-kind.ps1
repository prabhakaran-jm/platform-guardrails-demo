$ClusterName = "platform-guardrails-demo"
$NodeImage = "kindest/node:v1.29.2"

$clusters = kind get clusters 2>$null

if ($clusters -contains $ClusterName) {
    Write-Host "Kind cluster '$ClusterName' already exists. Skipping creation." -ForegroundColor Yellow
} else {
    Write-Host "Creating kind cluster '$ClusterName'..." -ForegroundColor Cyan
    kind create cluster --name $ClusterName --image $NodeImage
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create kind cluster." -ForegroundColor Red
        exit 1
    }
}

kubectl cluster-info --context kind-$ClusterName
Write-Host "Kind setup successful." -ForegroundColor Green
