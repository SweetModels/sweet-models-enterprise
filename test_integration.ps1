# Test Flutter + Backend Integration
# Verificar que la integración está lista

Write-Host "`n=== Flutter + Backend Integration Test ===" -ForegroundColor Cyan

# Test 1: Verificar Backend
Write-Host "`n[1] Checking Backend Connection..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
        -Method Post `
        -Body (@{
            email = "admin@sweetmodels.com"
            password = "sweet123"
        } | ConvertTo-Json) `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    Write-Host "[OK] Backend is responding correctly" -ForegroundColor Green
    Write-Host "     Token: $($response.token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host "     Role: $($response.role)" -ForegroundColor Gray
    Write-Host "     User ID: $($response.user_id)" -ForegroundColor Gray
    
    $backendOK = $true
} catch {
    Write-Host "[ERROR] Backend connection failed" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "     Solution: Run: docker-compose up -d" -ForegroundColor Yellow
    
    $backendOK = $false
}

# Test 2: Verificar Flutter Config
Write-Host "`n[2] Checking Flutter Configuration..." -ForegroundColor Yellow
$apiServicePath = ".\mobile_app\lib\api_service.dart"

if (-Not (Test-Path $apiServicePath)) {
    Write-Host "[ERROR] File not found: $apiServicePath" -ForegroundColor Red
} else {
    $content = Get-Content $apiServicePath -Raw
    
    # Check baseUrl
    if ($content -match "baseUrl.*10\.0\.2\.2:3000") {
        Write-Host "[OK] baseUrl configured correctly for Android Emulator (10.0.2.2:3000)" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] baseUrl not configured for Android Emulator" -ForegroundColor Red
    }
    
    # Check endpoint
    if ($content -match "post\('/api/auth/login'") {
        Write-Host "[OK] Login endpoint correct: /api/auth/login" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Login endpoint incorrect" -ForegroundColor Red
    }
    
    # Check LoginResponse
    if ($content -match "final String token;") {
        Write-Host "[OK] LoginResponse uses correct 'token' field" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] LoginResponse not using 'token' field" -ForegroundColor Red
    }
}

# Test 3: Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($backendOK) {
    Write-Host "[OK] All systems ready for Flutter login testing" -ForegroundColor Green
    Write-Host "`nTest Credentials:" -ForegroundColor Yellow
    Write-Host "  Email: admin@sweetmodels.com" -ForegroundColor Gray
    Write-Host "  Password: sweet123" -ForegroundColor Gray
    Write-Host "`nNext Step: Run 'flutter run' on Android Emulator" -ForegroundColor Yellow
} else {
    Write-Host "[ERROR] Backend not ready. Fix issues and try again." -ForegroundColor Red
}

Write-Host "`n=== Documentation ===" -ForegroundColor Cyan
Write-Host "See: FLUTTER_BACKEND_INTEGRATION_GUIDE.md" -ForegroundColor Gray
Write-Host "See: FLUTTER_INTEGRATION_CHANGES_SUMMARY.md" -ForegroundColor Gray

Write-Host ""
