param (
    [Parameter(Mandatory=$false)]
    [string]$Command = ""
)

$ErrorActionPreference = "Stop"

switch ($Command) {
    "setup" {
        Write-Host "Starting Setup..." -ForegroundColor Cyan
        & .\scripts\check-prereqs.ps1
        & .\scripts\setup-kind.ps1
        & .\scripts\install-kyverno.ps1
        Write-Host "Setup complete." -ForegroundColor Green
    }
    "k8s-bad" {
        & .\scripts\run-k8s-demo.ps1 -Scenario "bad"
    }
    "k8s-good" {
        & .\scripts\run-k8s-demo.ps1 -Scenario "good"
    }
    "iac-bad" {
        & .\scripts\run-iac-demo.ps1 -Scenario "bad"
    }
    "iac-good" {
        & .\scripts\run-iac-demo.ps1 -Scenario "good"
    }
    "reset" {
        & .\reset.ps1
    }
    default {
        Write-Host "Usage: .\demo.ps1 {setup|k8s-bad|k8s-good|iac-bad|iac-good|reset}" -ForegroundColor Yellow
        exit 1
    }
}
