param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("setup", "k8s-bad", "k8s-good", "iac-bad", "iac-good", "reset")]
    [string]$Command
)

$ErrorActionPreference = "Stop"

switch ($Command) {
    "setup" {
        Write-Host "Starting Setup..." -ForegroundColor Cyan
        & .\scripts\check-prereqs.ps1
        & .\scripts\setup-kind.ps1
        & .\scripts\install-kyverno.ps1
        Write-Host "Setup complete." -ForegroundColor Green
        exit $LASTEXITCODE
    }

    "k8s-bad" {
        & .\scripts\run-k8s-demo.ps1 bad
        exit $LASTEXITCODE
    }

    "k8s-good" {
        & .\scripts\run-k8s-demo.ps1 good
        exit $LASTEXITCODE
    }

    "iac-bad" {
        & .\scripts\run-iac-demo.ps1 bad
        exit $LASTEXITCODE
    }

    "iac-good" {
        & .\scripts\run-iac-demo.ps1 good
        exit $LASTEXITCODE
    }

    "reset" {
        & .\reset.ps1
        exit $LASTEXITCODE
    }
}
