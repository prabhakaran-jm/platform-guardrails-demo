param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("bad", "good")]
    [string]$Scenario
)

$ErrorActionPreference = "Stop"
$Scenario = $Scenario.Trim().ToLowerInvariant()

git rev-parse --show-toplevel 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    $Root = (git rev-parse --show-toplevel)
} else {
    $Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

Set-Location $Root

if (-not (Test-Path (Join-Path $Root "scripts"))) {
    Write-Host "ERROR: scripts/ not found — run from the repository root." -ForegroundColor Red
    exit 2
}

kubectl get namespace argocd *>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: namespace argocd not found. Run: .\demo.ps1 setup" -ForegroundColor Red
    exit 2
}

# Fork reachability precheck — Argo can only sync a repoURL it can clone.
$Repo = $env:DEMO_GITOPS_REPO_URL
if ([string]::IsNullOrWhiteSpace($Repo)) {
    $remote = git -C $Root remote get-url origin 2>$null
    if ($LASTEXITCODE -eq 0 -and $remote) {
        if ($remote -match '^https://') {
            $Repo = $remote -replace '\.git$', ''
        } elseif ($remote -match '^git@') {
            $stripped = $remote -replace '^git@', ''
            $hostPart, $pathPart = $stripped -split ':', 2
            $pathPart = $pathPart -replace '\.git$', ''
            $Repo = "https://$hostPart/$pathPart"
        }
    }
}
if ([string]::IsNullOrWhiteSpace($Repo) -or -not ($Repo -match '^https://')) {
    Write-Host "ERROR: GitOps demo requires a public HTTPS fork URL." -ForegroundColor Red
    Write-Host "  Set DEMO_GITOPS_REPO_URL or push your fork as 'origin' over HTTPS." -ForegroundColor Yellow
    Write-Host "  For the recording, prefer .\demo.ps1 k8s-bad / k8s-good (no remote needed)." -ForegroundColor Yellow
    exit 2
}
$Revision = if ($env:DEMO_GITOPS_REVISION) { $env:DEMO_GITOPS_REVISION } else { "main" }
Write-Host "Checking fork reachability: $Repo" -ForegroundColor Cyan
git ls-remote $Repo $Revision *>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Cannot reach $Repo@$Revision." -ForegroundColor Red
    Write-Host "  Push your fork (with the latest manifests) before running gitops-* demos." -ForegroundColor Yellow
    exit 2
}

function Remove-DemoApplications {
    kubectl delete applications.argoproj.io demo-gitops-good demo-gitops-bad -n argocd --ignore-not-found | Out-Null
}

function Wait-GoodScenario {
    Write-Host "Waiting for Argo CD to sync the healthy application (up to ~3 minutes)..." -ForegroundColor Yellow

    for ($attempt = 1; $attempt -le 90; $attempt++) {
        $sync = kubectl get applications.argoproj.io demo-gitops-good -n argocd -o jsonpath="{.status.sync.status}" 2>$null
        $health = kubectl get applications.argoproj.io demo-gitops-good -n argocd -o jsonpath="{.status.health.status}" 2>$null

        if ($sync -eq "Synced" -and $health -eq "Healthy") {
            Write-Host "Application reports Synced / Healthy." -ForegroundColor Green
            kubectl rollout status deployment/demo-app-good -n default --timeout=120s
            return $true
        }

        $syncSet = -not [string]::IsNullOrWhiteSpace($sync)
        $healthSet = -not [string]::IsNullOrWhiteSpace($health)
        if ($syncSet -or $healthSet -or $attempt -ge 5) {
            $syncOut = if ($syncSet) { $sync } else { "?" }
            $healthOut = if ($healthSet) { $health } else { "?" }
            Write-Host ("[{0:D2}/{1:D2}] sync={2} health={3}" -f $attempt, 90, $syncOut, $healthOut) -ForegroundColor DarkGray
        }

        Start-Sleep -Seconds 2
    }

    Write-Host "ERROR: Timed out waiting for demo-gitops-good to become Healthy." -ForegroundColor Red
    kubectl get applications.argoproj.io demo-gitops-good -n argocd -o yaml | Select-Object -Last 40 | Write-Host
    return $false
}

function Wait-BadScenarioBlocked {
    Write-Host "Waiting for Kyverno to block admission during Argo sync (up to ~3 minutes)..." -ForegroundColor Yellow

    for ($attempt = 1; $attempt -le 90; $attempt++) {
        $msg = kubectl get applications.argoproj.io demo-gitops-bad -n argocd -o jsonpath="{.status.operationState.message}" 2>$null
        $phase = kubectl get applications.argoproj.io demo-gitops-bad -n argocd -o jsonpath="{.status.operationState.phase}" 2>$null

        $hasPrivileged = ($msg -match "privileged containers are not allowed")
        $hasOwner = ($msg -match "owner label is required")
        $hasLimits = ($msg -match "resource requests and limits are required")

        if ($hasPrivileged -and $hasOwner -and $hasLimits) {
            Write-Host ("[{0:D2}/{1:D2}] phase={2}" -f $attempt, 90, $phase) -ForegroundColor Green
            Write-Host ""
            Write-Host $msg
            Write-Host ""
            Write-Host "Result:"
            Write-Host "Argo CD applied Git state, but admission control prevented the unsafe Pods from scheduling." -ForegroundColor Green
            return $true
        }

        Write-Host ("[{0:D2}/{1:D2}] phase={2} sniffing kyverno output..." -f $attempt, 90, $phase) -ForegroundColor DarkGray
        Start-Sleep -Seconds 2
    }

    Write-Host "ERROR: Timed out without Kyverno enforcement markers on the Application." -ForegroundColor Red
    kubectl get applications.argoproj.io demo-gitops-bad -n argocd -o yaml | Select-Object -Last 60 | Write-Host
    return $false
}

Write-Host "========================================" -ForegroundColor Cyan

if ($Scenario -eq "bad") {
    Write-Host "GitOps Guardrail Demo: Unsafe manifest via Argo CD" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Expected result: Admission blocks Pods while Argo reports a failed sync." -ForegroundColor Yellow
    Write-Host ""

    Remove-DemoApplications

    & .\scripts\render-gitops-applications.ps1 -KubectlApply "demo-gitops-bad.yaml.in"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    if (-not (Wait-BadScenarioBlocked)) { exit 1 }
    exit 0
}

Write-Host "GitOps Guardrail Demo: Healthy manifest via Argo CD" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Expected result: Sync succeeds and the Deployment becomes ready." -ForegroundColor Yellow
Write-Host ""

Remove-DemoApplications

& .\scripts\render-gitops-applications.ps1 -KubectlApply "demo-gitops-good.yaml.in"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not (Wait-GoodScenario)) { exit 1 }

Write-Host "Result:" -ForegroundColor Green
Write-Host "GitOps synced a compliant workload past admission control successfully." -ForegroundColor Green
exit 0
