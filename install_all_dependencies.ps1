# Script para instalar todas las dependencias del proyecto
$projectPath = "C:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise\sweet-models-web"
$npmPath = "C:\Program Files\nodejs\npm.cmd"

Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🚀 INSTALADOR DE DEPENDENCIAS - SWEET MODELS" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan

# Cambiar al directorio del proyecto
Write-Host "`n📂 Cambiando al directorio del proyecto..." -ForegroundColor Green
Set-Location $projectPath
Write-Host "✓ Directorio actual: $(Get-Location)" -ForegroundColor Green

# Instalar todas las dependencias
Write-Host "`n📦 Instalando todas las dependencias..." -ForegroundColor Green
Write-Host "   - React, Next.js, TypeScript" -ForegroundColor Yellow
Write-Host "   - Tailwind CSS para estilos" -ForegroundColor Yellow
Write-Host "   - Lucide React para iconos" -ForegroundColor Yellow
Write-Host "   - Dependencias de seguridad y autenticación" -ForegroundColor Yellow

& $npmPath install

Write-Host "`n✅ INSTALACIÓN COMPLETADA" -ForegroundColor Green
Write-Host "`n📚 Próximos pasos:" -ForegroundColor Cyan
Write-Host "  1. Ejecutar dev: npm run dev" -ForegroundColor Yellow
Write-Host "  2. Compilar: npm run build" -ForegroundColor Yellow
Write-Host "  3. Auditoría de seguridad: npm run security-audit" -ForegroundColor Yellow

Write-Host "`n🔐 Características disponibles:" -ForegroundColor Cyan
Write-Host "  ✓ Login con 2FA" -ForegroundColor Green
Write-Host "  ✓ Registro con validación" -ForegroundColor Green
Write-Host "  ✓ Glassmorphism UI" -ForegroundColor Green
Write-Host "  ✓ Iconos Lucide React" -ForegroundColor Green
Write-Host "  ✓ Dark Mode Enterprise" -ForegroundColor Green
Write-Host "  ✓ Seguridad Paranoid Mode" -ForegroundColor Green

Write-Host "`n════════════════════════════════════════════" -ForegroundColor Cyan
