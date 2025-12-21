# Test penalty system end-to-end
Write-Host "`n=== SWEET MODELS PENALTY SYSTEM TEST ===" -ForegroundColor Magenta

# 1. Login as admin
Write-Host "`n[1/5] Logging in as admin..." -ForegroundColor Cyan
$loginPayload = @{ email = 'admin@sweetmodels.com'; password = 'Admin123!' } | ConvertTo-Json
try {
    $adminResp = Invoke-RestMethod -Uri 'http://localhost:3000/login' -Method Post -Body $loginPayload -ContentType 'application/json'
    $adminToken = $adminResp.access_token
    Write-Host "✅ Admin logged in (User ID: $($adminResp.user_id))" -ForegroundColor Green
} catch {
    Write-Host "❌ Admin login failed: $_" -ForegroundColor Red
    exit 1
}

# 2. Apply penalty
Write-Host "`n[2/5] Applying penalty to modelo@sweet.com..." -ForegroundColor Cyan
$penaltyPayload = @{
    model_email = 'modelo@sweet.com'
    reason = 'Llegada Tarde'
    xp_penalty = 500
} | ConvertTo-Json

$headers = @{ Authorization = "Bearer $adminToken" }
try {
    $penaltyResp = Invoke-RestMethod -Uri 'http://localhost:3000/api/admin/penalize' -Method Post -Body $penaltyPayload -ContentType 'application/json' -Headers $headers
    Write-Host "✅ Penalty applied successfully!" -ForegroundColor Green
    Write-Host "   Message: $($penaltyResp.message)" -ForegroundColor Yellow
    Write-Host "   New XP: $($penaltyResp.new_xp)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Penalty application failed: $_" -ForegroundColor Red
    Write-Host "   Response: $($_.Exception.Response)" -ForegroundColor Gray
    exit 1
}

# 3. Login as model
Write-Host "`n[3/5] Logging in as modelo..." -ForegroundColor Cyan
$modelLogin = @{ email = 'modelo@sweet.com'; password = 'Modelo123!' } | ConvertTo-Json
try {
    $modelResp = Invoke-RestMethod -Uri 'http://localhost:3000/login' -Method Post -Body $modelLogin -ContentType 'application/json'
    $modelToken = $modelResp.access_token
    Write-Host "✅ Model logged in (User ID: $($modelResp.user_id))" -ForegroundColor Green
} catch {
    Write-Host "❌ Model login failed: $_" -ForegroundColor Red
    exit 1
}

# 4. Check model stats
Write-Host "`n[4/5] Fetching model stats..." -ForegroundColor Cyan
$modelHeaders = @{ Authorization = "Bearer $modelToken" }
try {
    $statsResp = Invoke-RestMethod -Uri 'http://localhost:3000/api/model/stats' -Method Get -Headers $modelHeaders
    Write-Host "✅ Stats retrieved successfully!" -ForegroundColor Green
    Write-Host "   XP: $($statsResp.xp)" -ForegroundColor Cyan
    Write-Host "   Rank: $($statsResp.rank) $($statsResp.icon)" -ForegroundColor Yellow
    Write-Host "   Progress: $([math]::Round($statsResp.progress * 100, 1))%" -ForegroundColor Magenta
} catch {
    Write-Host "❌ Stats retrieval failed: $_" -ForegroundColor Red
}

# 5. Check recent penalties
Write-Host "`n[5/5] Fetching recent penalties..." -ForegroundColor Cyan
try {
    $penaltiesResp = Invoke-RestMethod -Uri 'http://localhost:3000/api/model/penalties/recent' -Method Get -Headers $modelHeaders
    $penalties = $penaltiesResp.penalties
    Write-Host "✅ Found $($penalties.Count) recent penalties:" -ForegroundColor Green
    foreach ($p in $penalties) {
        Write-Host "   - $($p.reason) ($($p.xp_deduction) XP) on $($p.created_at.Substring(0,10))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Penalties retrieval failed: $_" -ForegroundColor Red
}

Write-Host "`n=== TEST COMPLETE ===" -ForegroundColor Magenta
