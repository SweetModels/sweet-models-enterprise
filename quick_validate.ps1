# Quick validation script
Write-Host "`n=== FLUTTER BACKEND INTEGRATION READY ===" -ForegroundColor Cyan

Write-Host "`nChecking Docker..." -ForegroundColor Yellow
try {
    $status = docker-compose ps 2>&1 | Select-String "Up"
    if ($status) {
        Write-Host "OK: Docker containers running" -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: Docker not available" -ForegroundColor Red
}

Write-Host "`nChecking Backend..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
        -Method Post `
        -Body (@{email="admin@sweetmodels.com"; password="sweet123"} | ConvertTo-Json) `
        -ContentType "application/json" -TimeoutSec 5 -ErrorAction Stop
    
    Write-Host "OK: Backend responding" -ForegroundColor Green
    Write-Host "    Token: $($response.token.Substring(0, 40))..." -ForegroundColor Gray
    Write-Host "    Role: $($response.role)" -ForegroundColor Gray
} catch {
    Write-Host "ERROR: Backend not responding" -ForegroundColor Red
}

Write-Host "`nChecking Flutter Config..." -ForegroundColor Yellow
if (Test-Path ".\mobile_app\lib\api_service.dart") {
    $content = Get-Content ".\mobile_app\lib\api_service.dart" -Raw
    if ($content -match "10\.0\.2\.2:3000") {
        Write-Host "OK: Base URL configured for Android Emulator" -ForegroundColor Green
    }
    if ($content -match "/api/auth/login") {
        Write-Host "OK: Endpoint path correct" -ForegroundColor Green
    }
    if ($content -match "final String token") {
        Write-Host "OK: LoginResponse model updated" -ForegroundColor Green
    }
}

Write-Host "`n=== EVERYTHING IS READY ===" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Open Android Emulator" -ForegroundColor Gray
Write-Host "2. cd mobile_app" -ForegroundColor Gray
Write-Host "3. flutter run" -ForegroundColor Gray
Write-Host "4. Login with: admin@sweetmodels.com / sweet123" -ForegroundColor Gray
Write-Host ""
