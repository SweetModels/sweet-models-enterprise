# Bootstrap runner: detects tools, runs backend locally or via Docker
$ErrorActionPreference = "Stop"

function Has-Command($name) { Get-Command $name -ErrorAction SilentlyContinue | ForEach-Object { $true } ; if (-not $?) { return $false } }

$root = "$PSScriptRoot"
Write-Host "Root: $root"

$dockerOk = (Has-Command docker)
$cargoOk = (Has-Command cargo)

if (-not $cargoOk) {
  Write-Host "Rust toolchain not found. Opening installer..." -ForegroundColor Yellow
  Start-Process "https://rustup.rs/" -WindowStyle Normal
  Write-Host "Install Rust, then re-run run.ps1" -ForegroundColor Yellow
  exit 1
}

# If Docker is available, use compose, else run locally
if ($dockerOk) {
  Write-Host "Docker found. Building and starting services..." -ForegroundColor Cyan
  Push-Location "$root/.."
  docker compose build
  docker compose up -d
  Pop-Location
  Start-Sleep -Seconds 2
  Write-Host "Testing endpoint via container..." -ForegroundColor Cyan
  try {
    $resp = Invoke-WebRequest -Uri http://localhost:8080/ -TimeoutSec 10
    Write-Host "Response: $($resp.Content)" -ForegroundColor Green
  } catch {
    Write-Host "Could not reach backend on :8080 yet. Check 'docker ps'." -ForegroundColor Yellow
  }
} else {
  Write-Host "Docker not found. Running backend locally..." -ForegroundColor Yellow
  Push-Location "$root/backend_api"
  cargo build
  Start-Process powershell -ArgumentList 'cargo run' -WorkingDirectory "$root/backend_api"
  Start-Sleep -Seconds 2
  try {
    $resp = Invoke-WebRequest -Uri http://localhost:8080/ -TimeoutSec 10
    Write-Host "Response: $($resp.Content)" -ForegroundColor Green
  } catch {
    Write-Host "Server starting... If port not ready, wait and retry: 'Invoke-WebRequest http://localhost:8080/'" -ForegroundColor Yellow
  }
  Pop-Location
}
