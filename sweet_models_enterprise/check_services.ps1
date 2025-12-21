# Check Services Status
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Sweet Models Enterprise - Services Status" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker containers
Write-Host "Docker Containers:" -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host ""

# Check Redis
Write-Host "Redis Connection:" -ForegroundColor Yellow
try {
    docker exec sme_redis redis-cli ping
    Write-Host "  ✓ Redis OK" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Redis failed: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Check PostgreSQL
Write-Host "PostgreSQL Connection:" -ForegroundColor Yellow
try {
    docker exec sme_postgres pg_isready -U sme_user
    Write-Host "  ✓ PostgreSQL OK" -ForegroundColor Green
} catch {
    Write-Host "  ✗ PostgreSQL failed: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Check NATS
Write-Host "NATS Connection:" -ForegroundColor Yellow
Write-Host "  Container: sme_nats on port 4222" -ForegroundColor Gray
Write-Host ""

# Check Backend API
Write-Host "Backend API:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -Method GET -UseBasicParsing -TimeoutSec 2
    Write-Host "  ✓ Backend API OK - Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Backend API not responding: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "================================================" -ForegroundColor Cyan
