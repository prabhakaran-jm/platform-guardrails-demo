param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("setup", "k8s-bad", "k8s-good", "iac-bad", "iac-good", "iac-fixtures", "gitops-bad", "gitops-good", "reset")]
    [string]$Command
)

$ErrorActionPreference = "Stop"

switch ($Command) {
    "setup" {
        Write-Host "Starting Setup..." -ForegroundColor Cyan
        & .\scripts\check-prereqs.ps1
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        & .\scripts\setup-kind.ps1
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        & .\scripts\install-kyverno.ps1
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        & .\scripts\install-argocd.ps1
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Write-Host "Setup complete." -ForegroundColor Green
        exit 0
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

    "iac-fixtures" {
        & .\scripts\run-iac-fixtures.ps1
        exit $LASTEXITCODE
    }

    "gitops-good" {
        & .\scripts\run-gitops-demo.ps1 good
        exit $LASTEXITCODE
    }

    "gitops-bad" {
        & .\scripts\run-gitops-demo.ps1 bad
        exit $LASTEXITCODE
    }

    "reset" {
        & .\reset.ps1
        exit $LASTEXITCODE
    }
}
