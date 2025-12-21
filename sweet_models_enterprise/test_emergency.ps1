# Test Emergency Stop Endpoints
# Usage: .\test_emergency.ps1

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Testing Sweet Models Enterprise - Emergency Stop" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:3000"

# Test 1: Health Check
Write-Host "[1] Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/health" -Method GET -UseBasicParsing
    Write-Host "  ✓ Health check OK - Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Get Emergency Status (before freeze)
Write-Host "[2] Getting Emergency Status (should be inactive)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/admin/emergency/status" -Method GET -UseBasicParsing
    Write-Host "  ✓ Status retrieved - Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Failed to get status: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Try to freeze WITHOUT authentication (should fail)
Write-Host "[3] Attempting freeze without auth (should fail 401)..." -ForegroundColor Yellow
try {
    $body = @{
        active = $true
        message = "Test freeze without auth"
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "$baseUrl/api/admin/emergency/freeze" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
    Write-Host "  ✗ Unexpected success - should have failed!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "  ✓ Correctly rejected - Status: 401 Unauthorized" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Wrong error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Host ""

# Test 4: Test regular endpoint (should work before freeze)
Write-Host "[4] Testing regular endpoint before freeze..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/finance/balance" -Method GET -UseBasicParsing
    Write-Host "  ✓ Endpoint accessible - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "  ⚠ Requires auth (expected) - Status: 401" -ForegroundColor Yellow
    } else {
        Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Note: To test SUPER ADMIN freeze, you need a valid JWT token" -ForegroundColor Cyan
Write-Host "with role='SUPER_ADMIN' in the Authorization header" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
