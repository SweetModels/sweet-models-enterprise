
# Test Login Script
Write-Host "`n" 
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  SWEET MODELS ENTERPRISE - PRUEBA DE LOGIN║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Esperar a que el servidor inicie
Write-Host "⏳ Esperando a que el servidor se inicie..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "🧪 Enviando solicitud de login..." -ForegroundColor Cyan
Write-Host ""

$body = @{
    email = "admin@sweetmodels.com"
    password = "admin123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod `
        -Uri "http://localhost:3000/api/auth/login" `
        -Method Post `
        -Body $body `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    Write-Host "✅✅✅ LOGIN EXITOSO ✅✅✅" -ForegroundColor Green
    Write-Host ""
    Write-Host "Datos del usuario:" -ForegroundColor Yellow
    Write-Host "  👨‍💼 Nombre:    $($response.name)" -ForegroundColor Cyan
    Write-Host "  🔑 Role:      $($response.role)" -ForegroundColor Cyan
    Write-Host "  📧 Email:     admin@sweetmodels.com" -ForegroundColor Cyan
    Write-Host "  🆔 User ID:   $($response.user_id)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Token JWT:" -ForegroundColor Yellow
    Write-Host "$($response.token)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  🎯 ¡ERES EL CEO DEL UNIVERSO!           ║" -ForegroundColor Green
    Write-Host "║  🎊 ¡MISIÓN COMPLETADA CON ÉXITO!        ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green
    
} catch {
    Write-Host "❌ ERROR EN EL LOGIN" -ForegroundColor Red
    Write-Host "Mensaje: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Detalles:" -ForegroundColor Yellow
    $_ | Format-List
}

Write-Host ""
Write-Host "Presiona una tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
