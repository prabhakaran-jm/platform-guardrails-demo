param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("bad", "good")]
    [string]$Scenario
)

$Scenario = $Scenario.Trim().ToLowerInvariant()

function Invoke-KubectlApply {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ManifestPath
    )

    $output = cmd /c "kubectl apply -f $ManifestPath 2>&1"
    $exitCode = $LASTEXITCODE
    $text = $output -join [Environment]::NewLine

    return @{
        ExitCode = $exitCode
        Output = $text
    }
}

if ($Scenario -eq "bad") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Kubernetes Guardrail Demo: Bad Workload" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Expected result: This deployment should be blocked by Kyverno." -ForegroundColor Yellow
    Write-Host ""

    $result = Invoke-KubectlApply -ManifestPath "k8s/bad/deployment.yaml"

    Write-Host $result.Output
    Write-Host ""

    if ($result.ExitCode -eq 0) {
        Write-Host "ERROR: Bad deployment was unexpectedly ACCEPTED. Demo failed!" -ForegroundColor Red
        exit 1
    }

    $text = $result.Output

    $hasPrivilegedMessage = $text -match "privileged containers are not allowed"
    $hasOwnerMessage = $text -match "owner label is required"
    $hasResourceMessage = $text -match "resource requests and limits are\s+required"

    if ($hasPrivilegedMessage -and $hasOwnerMessage -and $hasResourceMessage) {
        Write-Host "Result:" -ForegroundColor Green
        Write-Host "The platform guardrail blocked the unsafe change before it reached production." -ForegroundColor Green
        exit 0
    }

    Write-Host "ERROR: Kubernetes blocked the workload, but expected Kyverno messages were missing." -ForegroundColor Red

    if (-not $hasPrivilegedMessage) {
        Write-Host "- Missing: privileged containers are not allowed" -ForegroundColor Yellow
    }

    if (-not $hasOwnerMessage) {
        Write-Host "- Missing: owner label is required" -ForegroundColor Yellow
    }

    if (-not $hasResourceMessage) {
        Write-Host "- Missing: resource requests and limits are required" -ForegroundColor Yellow
    }

    exit 1
}

if ($Scenario -eq "good") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Kubernetes Guardrail Demo: Good Workload" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Expected result: This deployment passes policies and applies successfully." -ForegroundColor Yellow
    Write-Host ""

    $result = Invoke-KubectlApply -ManifestPath "k8s/good"

    Write-Host $result.Output
    Write-Host ""

    if ($result.ExitCode -eq 0) {
        Write-Host "Result:" -ForegroundColor Green
        Write-Host "The safe change passed the platform guardrails." -ForegroundColor Green
        exit 0
    }

    Write-Host "ERROR: Good deployment unexpectedly failed. Demo failed!" -ForegroundColor Red
    exit 1
}
