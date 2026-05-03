$ErrorActionPreference = "Stop"

git rev-parse --show-toplevel 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Set-Location (git rev-parse --show-toplevel)
} else {
    Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$PolicyPath = "iac-policies/terraform.rego"
$GoodFixture = "iac-policies/fixtures/plan-s3-good.json"
$BadFixture = "iac-policies/fixtures/plan-s3-bad.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IaC fixture checks (AWS-shaped plan JSON)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ("Fixture (should pass): {0}" -f $GoodFixture) -ForegroundColor Yellow
conftest test $GoodFixture -p $PolicyPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Good fixture unexpectedly failed policy checks." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host ("Fixture (should fail): {0}" -f $BadFixture) -ForegroundColor Yellow

$output = cmd /c "conftest test $BadFixture -p $PolicyPath 2>&1"
$exitBad = $LASTEXITCODE

Write-Host $output

if ($exitBad -eq 0) {
    Write-Host "ERROR: Bad fixture was unexpectedly accepted." -ForegroundColor Red
    exit 1
}

$expectedMessages = @(
    "public access is not allowed",
    "encryption must be enabled",
    "owner tag is required",
    "environment tag is required"
)

$missingMessages = @()
foreach ($message in $expectedMessages) {
    if ($output -notmatch [regex]::Escape($message)) {
        $missingMessages += $message
    }
}

if ($missingMessages.Count -gt 0) {
    Write-Host "ERROR: Fixture failed but missing expected denial markers." -ForegroundColor Red

    foreach ($message in $missingMessages) {
        Write-Host "- $message" -ForegroundColor Yellow
    }

    Write-Host ""
    exit 1
}

Write-Host "Result:" -ForegroundColor Green
Write-Host "Unsafe S3-shaped plan fixtures failed policy checks exactly as intended." -ForegroundColor Green
exit 0
