# Diagnóstico automático de backend Axum + SQLx
$ErrorActionPreference = "Stop"

function Test-Url($url) {
  try {
    $resp = Invoke-WebRequest -Uri $url -TimeoutSec 5
    return $resp.Content
  } catch {
    return "ERROR: $($_.Exception.Message)"
  }
}

Write-Host "== Paso 1: Compilar =="
Set-Location "$PSScriptRoot"
cargo build

Write-Host "== Paso 2: Levantar servidor (en segundo plano) =="
$env:RUST_LOG = "info,sqlx=info,hyper=info"
$job = Start-Job -ScriptBlock { Set-Location $using:PSScriptRoot; cargo run }
Start-Sleep -Seconds 3

Write-Host "== Paso 3: Probar endpoints =="
$root = "http://localhost:8080"
$hello = Test-Url "$root/"
$health = Test-Url "$root/health"
$dbhealth = Test-Url "$root/db/health"

Write-Host "Resultado /            : $hello"
Write-Host "Resultado /health      : $health"
Write-Host "Resultado /db/health   : $dbhealth"

Write-Host "== Paso 4: Detener servidor =="
Stop-Job -Job $job | Out-Null
Receive-Job -Job $job | Out-String | Write-Host

Write-Host "Diagnóstico completado."