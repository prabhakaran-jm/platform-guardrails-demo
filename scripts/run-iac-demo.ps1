param(
    [string]$Scenario
)

$PolicyPath = "../../iac-policies/terraform.rego"

Write-Host "========================================" -ForegroundColor Cyan
if ($Scenario -eq "bad") {
    Write-Host "IaC Guardrail Demo: Bad Infrastructure" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Expected result: The Terraform plan should be blocked by Conftest." -ForegroundColor Yellow
    Write-Host ""
    
    Push-Location -Path "terraform/bad"
    terraform init
    terraform plan -out=tfplan
    $json = terraform show -json tfplan
    [System.IO.File]::WriteAllText(
        (Join-Path (Get-Location) "tfplan.json"),
        $json,
        (New-Object System.Text.UTF8Encoding($false))
    )
    
    $output = conftest test tfplan.json -p $PolicyPath 2>&1
    $exitCode = $LASTEXITCODE
    
    Pop-Location
    
    Write-Host $output
    Write-Host ""
    
    if ($exitCode -eq 0) {
        Write-Host "ERROR: Bad plan was unexpectedly ACCEPTED. Demo failed!" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "Result:" -ForegroundColor Green
        Write-Host "The platform guardrail blocked the unsafe change before it reached production." -ForegroundColor Green
        exit 0
    }

} elseif ($Scenario -eq "good") {
    Write-Host "IaC Guardrail Demo: Good Infrastructure" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Expected result: The Terraform plan passes policies." -ForegroundColor Yellow
    Write-Host ""
    
    Push-Location -Path "terraform/good"    
    terraform init
    terraform plan -out=tfplan
    $json = terraform show -json tfplan
    [System.IO.File]::WriteAllText(
        (Join-Path (Get-Location) "tfplan.json"),
        $json,
        (New-Object System.Text.UTF8Encoding($false))
    )
    
    $output = conftest test tfplan.json -p $PolicyPath 2>&1
    $exitCode = $LASTEXITCODE
    
    Pop-Location
    
    Write-Host $output
    Write-Host ""
    
    if ($exitCode -eq 0) {
        Write-Host "Result:" -ForegroundColor Green
        Write-Host "The safe change passed the platform guardrails." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "ERROR: Good plan unexpectedly failed. Demo failed!" -ForegroundColor Red
        exit 1
    }
}
