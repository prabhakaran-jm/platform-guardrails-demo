param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("bad", "good")]
    [string]$Scenario
)

$ErrorActionPreference = "Stop"
$PolicyPath = "../../iac-policies/terraform.rego"

function Write-Section {
    param(
        [string]$Title,
        [string]$Expected
    )

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Expected result: $Expected" -ForegroundColor Yellow
    Write-Host ""
}

function Assert-LastCommandSucceeded {
    param(
        [string]$Step
    )

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: $Step failed." -ForegroundColor Red
        exit 1
    }
}

function Write-TerraformPlanJson {
    $json = terraform show -json tfplan
    Assert-LastCommandSucceeded "terraform show"

    $jsonText = $json -join [Environment]::NewLine

    [System.IO.File]::WriteAllText(
        (Join-Path (Get-Location) "tfplan.json"),
        $jsonText,
        (New-Object System.Text.UTF8Encoding($false))
    )
}

function Run-TerraformPlan {
    param(
        [string]$Directory
    )

    Push-Location -Path $Directory

    try {
        terraform init
        Assert-LastCommandSucceeded "terraform init"

        terraform plan -out=tfplan
        Assert-LastCommandSucceeded "terraform plan"

        Write-TerraformPlanJson

        $conftestOutput = conftest test tfplan.json -p $PolicyPath 2>&1
        $conftestExitCode = $LASTEXITCODE
        $conftestText = $conftestOutput -join [Environment]::NewLine

        return @{
            ExitCode = $conftestExitCode
            Output = $conftestText
        }
    }
    finally {
        Pop-Location
    }
}

if ($Scenario -eq "bad") {
    Write-Section `
        -Title "IaC Guardrail Demo: Bad Infrastructure" `
        -Expected "The Terraform plan should be blocked by Conftest."

    $result = Run-TerraformPlan -Directory "terraform/bad"

    Write-Host $result.Output
    Write-Host ""

    if ($result.ExitCode -eq 0) {
        Write-Host "ERROR: Bad plan was unexpectedly ACCEPTED. Demo failed!" -ForegroundColor Red
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
        if ($result.Output -notmatch [regex]::Escape($message)) {
            $missingMessages += $message
        }
    }

    if ($missingMessages.Count -eq 0) {
        Write-Host "Result:" -ForegroundColor Green
        Write-Host "The platform guardrail blocked the unsafe change before it reached production." -ForegroundColor Green
        exit 0
    }

    Write-Host "ERROR: Conftest failed, but not with the expected guardrail output." -ForegroundColor Red
    Write-Host "This usually means a policy syntax error or tool error." -ForegroundColor Red
    Write-Host ""
    Write-Host "Missing expected messages:" -ForegroundColor Yellow

    foreach ($message in $missingMessages) {
        Write-Host "- $message" -ForegroundColor Yellow
    }

    exit 1
}

if ($Scenario -eq "good") {
    Write-Section `
        -Title "IaC Guardrail Demo: Good Infrastructure" `
        -Expected "The Terraform plan passes policies."

    $result = Run-TerraformPlan -Directory "terraform/good"

    Write-Host $result.Output
    Write-Host ""

    if ($result.ExitCode -eq 0) {
        Write-Host "Result:" -ForegroundColor Green
        Write-Host "The safe change passed the platform guardrails." -ForegroundColor Green
        exit 0
    }

    Write-Host "ERROR: Good plan unexpectedly failed. Demo failed!" -ForegroundColor Red
    exit 1
}