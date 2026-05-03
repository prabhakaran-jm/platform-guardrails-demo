Write-Host "Checking Prerequisites..." -ForegroundColor Cyan

$tools = @("docker", "kind", "kubectl", "helm", "terraform", "conftest", "git")

foreach ($tool in $tools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: $tool is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Please install $tool to run this demo." -ForegroundColor Yellow
        exit 1
    } else {
        $version = (& $tool --version 2>&1 | Select-Object -First 1)
        Write-Host " - $tool found ($version)" -ForegroundColor Green
    }
}

try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Docker not running" }
} catch {
    Write-Host "ERROR: Docker daemon is not running." -ForegroundColor Red
    exit 1
}

Write-Host "All prerequisites met." -ForegroundColor Green
