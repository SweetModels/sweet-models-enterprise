#!/usr/bin/env pwsh
# safe-push.ps1
# Script para hacer un push seguro sin exponer secretos

Write-Host "`n🔒 SAFE GIT PUSH - Verificando Seguridad Antes de Hacer Push`n" -ForegroundColor Cyan

# 1. Ejecutar auditoría de seguridad
Write-Host "1️⃣  Ejecutando auditoría de seguridad..." -ForegroundColor Yellow
& ".\security-audit.ps1"

# 2. Ver cambios pendientes
Write-Host "`n2️⃣  Cambios pendientes:" -ForegroundColor Yellow
git status

# 3. Verificar que no hay secretos en cambios
Write-Host "`n3️⃣  Verificando que no hay secretos en cambios preparados..." -ForegroundColor Yellow
$secrets_in_staged = git diff --cached | Select-String -Pattern "DATABASE_URL|JWT_SECRET|AWS_ACCESS_KEY|password" -ErrorAction SilentlyContinue

if ($secrets_in_staged) {
    Write-Host "❌ ¡ERROR! Se encontraron secretos en los cambios preparados:" -ForegroundColor Red
    $secrets_in_staged | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    Write-Host "`nNo se puede hacer push con secretos expuestos." -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ No hay secretos en los cambios preparados" -ForegroundColor Green
}

# 4. Mostrar resumen de cambios
Write-Host "`n4️⃣  Resumen de cambios a hacer push:" -ForegroundColor Yellow
git diff --cached --stat

# 5. Pedir confirmación
Write-Host "`n5️⃣  ¿Estás seguro de que quieres hacer push?" -ForegroundColor Cyan
$confirm = Read-Host "Escribe 'yes' para continuar"

if ($confirm -ne "yes") {
    Write-Host "❌ Push cancelado" -ForegroundColor Red
    exit 0
}

# 6. Hacer push
Write-Host "`n6️⃣  Haciendo push..." -ForegroundColor Green
git push

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Push exitoso - Tu código está en GitHub" -ForegroundColor Green
    Write-Host "📚 Próximo paso: Ver RAILWAY_DEPLOYMENT_GUIDE.md para desplegar en Railway`n" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Error al hacer push" -ForegroundColor Red
    exit 1
}
