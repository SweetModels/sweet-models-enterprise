# Script rápido para instalar dependencias del proyecto
# Este script funciona sin cerrar/reabrir PowerShell

Write-Host "=== Instalando Dependencias del Proyecto ===" -ForegroundColor Cyan
Write-Host ""

$projectRoot = "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise"

# Actualizar PATH para esta sesión
$env:Path += ";$env:USERPROFILE\.cargo\bin"
$env:Path += ";C:\flutter\bin"

# 1. Backend API (Rust)
Write-Host "[1/2] Instalando dependencias del Backend (Rust)..." -ForegroundColor Green
Write-Host "  Ubicación: $projectRoot\backend_api" -ForegroundColor Gray
Write-Host "  Esto puede tardar 5-10 minutos la primera vez..." -ForegroundColor Yellow
Write-Host ""

cd "$projectRoot\backend_api"
& "$env:USERPROFILE\.cargo\bin\cargo.exe" build --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n  ✓ Backend compilado exitosamente" -ForegroundColor Green
} else {
    Write-Host "`n  ✗ Error al compilar el backend" -ForegroundColor Red
    Write-Host "  Verifica que Rust esté instalado correctamente" -ForegroundColor Yellow
}

# 2. Mobile App (Flutter)
Write-Host "`n[2/2] Instalando dependencias de Flutter..." -ForegroundColor Green
Write-Host "  Ubicación: $projectRoot\mobile_app" -ForegroundColor Gray
Write-Host ""

cd "$projectRoot\mobile_app"
& "C:\flutter\bin\flutter.bat" pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n  ✓ Dependencias de Flutter descargadas" -ForegroundColor Green
    
    Write-Host "`n  Ejecutando flutter doctor..." -ForegroundColor Yellow
    & "C:\flutter\bin\flutter.bat" doctor
} else {
    Write-Host "`n  ✗ Error al descargar dependencias de Flutter" -ForegroundColor Red
}

cd $projectRoot

Write-Host "`n=== ¡Instalación Completada! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "El proyecto está listo. Puedes:" -ForegroundColor Yellow
Write-Host "• Ejecutar el backend: cd backend_api && cargo run" -ForegroundColor White
Write-Host "• Ejecutar la app: cd mobile_app && flutter run -d windows" -ForegroundColor White
Write-Host "• Ver los servicios: docker-compose ps" -ForegroundColor White
Write-Host ""
