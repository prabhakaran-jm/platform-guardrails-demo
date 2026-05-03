param(
    [string]$Scenario
)

Write-Host "========================================" -ForegroundColor Cyan
if ($Scenario -eq "bad") {
    Write-Host "Kubernetes Guardrail Demo: Bad Workload" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Expected result: This deployment should be blocked by Kyverno." -ForegroundColor Yellow
    Write-Host ""
    
    $output = kubectl apply -f k8s/bad/deployment.yaml 2>&1
    $exitCode = $LASTEXITCODE
    
    Write-Host $output
    Write-Host ""
    
    if ($exitCode -eq 0) {
        Write-Host "ERROR: Bad deployment was unexpectedly ACCEPTED. Demo failed!" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "Result:" -ForegroundColor Green
        Write-Host "The platform guardrail blocked the unsafe change before it reached production." -ForegroundColor Green
        exit 0
    }
} elseif ($Scenario -eq "good") {
    Write-Host "Kubernetes Guardrail Demo: Good Workload" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Expected result: This deployment passes policies and applies successfully." -ForegroundColor Yellow
    Write-Host ""
    
    $output = kubectl apply -f k8s/good/deployment.yaml 2>&1
    $exitCode = $LASTEXITCODE
    
    Write-Host $output
    Write-Host ""
    
    if ($exitCode -eq 0) {
        Write-Host "Result:" -ForegroundColor Green
        Write-Host "The safe change passed the platform guardrails." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "ERROR: Good deployment unexpectedly failed. Demo failed!" -ForegroundColor Red
        exit 1
    }
}
