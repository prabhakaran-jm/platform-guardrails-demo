$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir
$InDir = Join-Path $Root "gitops/argocd-applications"

$Rev = $env:DEMO_GITOPS_REVISION
if ([string]::IsNullOrWhiteSpace($Rev)) { $Rev = "main" }

$Repo = $env:DEMO_GITOPS_REPO_URL
if ([string]::IsNullOrWhiteSpace($Repo)) {
    Push-Location $Root
    try {
        $remote = (git remote get-url origin 2>$null)
        if (-not [string]::IsNullOrWhiteSpace($remote)) {
            if ($remote -match '^https://') {
                $Repo = ($remote.TrimEnd('/') -replace '\.git$', '')
            }
            elseif ($remote.StartsWith('git@')) {
                $stripped = $remote.Substring(4)
                $colon = $stripped.IndexOf(':')
                $hostName = $stripped.Substring(0, $colon)
                $pathPart = $stripped.Substring($colon + 1).TrimEnd('/')
                if ($pathPart.EndsWith('.git')) {
                    $pathPart = $pathPart.Substring(0, $pathPart.Length - 4)
                }
                $Repo = "https://$hostName/$pathPart"
            }
        }
    }
    finally {
        Pop-Location
    }
}

if ([string]::IsNullOrWhiteSpace($Repo)) {
    Write-Host "ERROR: DEMO_GITOPS_REPO_URL is unset and could not be inferred from git remote." -ForegroundColor Red
    Write-Host "Set DEMO_GITOPS_REPO_URL to a Git HTTPS URL Argo CD can clone (typically your fork on GitHub)." -ForegroundColor Red
    exit 2
}

function Render-One {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )
    return ((Get-Content -LiteralPath $SourcePath -Raw)
        .Replace("__DEMO_REPO_URL__", $Repo)
        .Replace("__DEMO_REVISION__", $Rev))
}

$mode = $args[0]

if (-not $mode) {
    Write-Host "Usage: render-gitops-applications.ps1 -KubectlApply <file.yaml.in> | -KubectlApplyAll" -ForegroundColor Yellow
    exit 2
}

if ($mode -eq "-KubectlApply") {
    $fname = $args[1]
    if (-not $fname) {
        Write-Host "Missing filename after -KubectlApply." -ForegroundColor Red
        exit 2
    }
    $srcPath = Join-Path $InDir $fname
    (Render-One -SourcePath $srcPath) | kubectl apply -f -
    exit $LASTEXITCODE
}

if ($mode -eq "-KubectlApplyAll") {
    $tmpdir = Join-Path ([System.IO.Path]::GetTempPath()) ("plat-guardrails-gitops-{0}" -f [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmpdir | Out-Null
    try {
        Get-ChildItem -LiteralPath $InDir -Filter "*.yaml.in" | ForEach-Object {
            $yamlName = $_.Name.Substring(0, $_.Name.Length - 3) # .yaml.in -> .yaml
            $dest = Join-Path $tmpdir $yamlName
            Render-One -SourcePath $_.FullName | Set-Content -LiteralPath $dest -Encoding Utf8
        }
        kubectl apply -f $tmpdir
        exit $LASTEXITCODE
    }
    finally {
        Remove-Item -LiteralPath $tmpdir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Unknown mode '$mode'" -ForegroundColor Red
exit 2
