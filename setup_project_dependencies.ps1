# Script para instalar dependencias específicas del proyecto
# Ejecuta esto DESPUÉS de instalar las herramientas base

Write-Host "=== Sweet Models Enterprise - Configuración del Proyecto ===" -ForegroundColor Cyan
Write-Host ""

$projectRoot = "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise"

# Actualizar PATH con las rutas necesarias
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path += ";$env:USERPROFILE\.cargo\bin"
$env:Path += ";C:\flutter\bin"

Write-Host "Verificando herramientas instaladas..." -ForegroundColor Cyan

# Verificar que las herramientas estén instaladas
$missingTools = @()

$cargoPath = "$env:USERPROFILE\.cargo\bin\cargo.exe"
$flutterPath = "C:\flutter\bin\flutter.bat"

if (!(Test-Path $cargoPath)) {
    $missingTools += "Rust/Cargo (no encontrado en $cargoPath)"
}
if (!(Test-Path $flutterPath)) {
    $missingTools += "Flutter (no encontrado en $flutterPath)"
}

if ($missingTools.Count -gt 0) {
    Write-Host "ERROR: Faltan las siguientes herramientas:" -ForegroundColor Red
    $missingTools | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host "`nPor favor ejecuta primero: .\install_dependencies.ps1" -ForegroundColor Yellow
    Write-Host "Y luego CIERRA y REABRE PowerShell antes de ejecutar este script" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[1/3] Instalando dependencias del Backend API (Rust)..." -ForegroundColor Green
Set-Location "$projectRoot\backend_api"

Write-Host "  Descargando y compilando dependencias de Rust..." -ForegroundColor Yellow
Write-Host "  (Esto puede tomar varios minutos la primera vez)" -ForegroundColor Yellow

& "$env:USERPROFILE\.cargo\bin\cargo.exe" build --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Dependencias del backend instaladas correctamente" -ForegroundColor Green
}
else {
    Write-Host "  ✗ Error al instalar dependencias del backend" -ForegroundColor Red
    Write-Host "  Puedes intentar ejecutar manualmente:" -ForegroundColor Yellow
    Write-Host "  cd backend_api && cargo build --release" -ForegroundColor White
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Dependencias del backend instaladas correctamente" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Error al instalar dependencias del backend" -ForegroundColor Red
    }

    # 2. Mobile App (Flutter)
    Write-Host "`n[2/3] Instalando dependencias de la App Móvil (Flutter)..." -ForegroundColor Green
    & "C:\flutter\bin\flutter.bat" pub get

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Dependencias de Flutter instaladas correctamente" -ForegroundColor Green
    
        # Verificar configuración de Flutter
        Write-Host "  Verificando configuración de Flutter..." -ForegroundColor Yellow
        & "C:\flutter\bin\flutter.bat" doctor
    }
    else {
        Write-Host "  ✗ Error al instalar dependencias de Flutter" -ForegroundColor Red
        Write-Host "  Puedes intentar ejecutar manualmente:" -ForegroundColor Yellow
        Write-Host "  cd mobile_app && flutter pub get" -ForegroundColor White
        flutter doctor
    }
    else {
        Write-Host "  ✗ Error al instalar dependencias de Flutter" -ForegroundColor Red
    }

    # 3. Configurar Docker
    Write-Host "`n[3/3] Verificando Docker..." -ForegroundColor Green
    Set-Location $projectRoot

    Write-Host "  Verificando que Docker Desktop esté ejecutándose..." -ForegroundColor Yellow
    docker info 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Docker está funcionando correctamente" -ForegroundColor Green
    
        Write-Host "`n  ¿Deseas iniciar los servicios de Docker ahora? (S/N)" -ForegroundColor Yellow
        $response = Read-Host
    
        if ($response -eq 'S' -or $response -eq 's') {
            Write-Host "  Iniciando servicios con Docker Compose..." -ForegroundColor Yellow
            docker-compose up -d
        
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Servicios de Docker iniciados" -ForegroundColor Green
            }
            else {
                Write-Host "  ✗ Error al iniciar servicios de Docker" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "  ✗ Docker no está ejecutándose" -ForegroundColor Red
        Write-Host "  Abre Docker Desktop e inténtalo de nuevo" -ForegroundColor Yellow
    }

    # Volver al directorio raíz
    Set-Location $projectRoot

    Write-Host "`n=== Configuración del:" -ForegroundColor Yellow

    try {
        $rustVersion = & "$env:USERPROFILE\.cargo\bin\rustc.exe" --version 2>&1
        Write-Host "- Rust: $rustVersion" -ForegroundColor White
    }
    catch {
        Write-Host "- Rust: No disponible" -ForegroundColor Red
    }

    try {
        $cargoVersion = & "$env:USERPROFILE\.cargo\bin\cargo.exe" --version 2>&1
        Write-Host "- Cargo: $cargoVersion" -ForegroundColor White
    }
    catch {
        Write-Host "- Cargo: No disponible" -ForegroundColor Red
    }

    try {
        $flutterVersion = & "C:\flutter\bin\flutter.bat" --version 2>&1 | Select-Object -First 1
        Write-Host "- Flutter: $flutterVersion" -ForegroundColor White
    }
    catch {
        Write-Host "- Flutter: No disponible" -ForegroundColor Red
    }

    Write-Host "- Flutter version: $(flutter --version --machine | ConvertFrom-Json | Select-Object -ExpandProperty frameworkVersion)" -ForegroundColor White
    Write-Host "- Docker version: $(docker --version)" -ForegroundColor White
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor Yellow
    Write-Host "1. Para iniciar el backend: cd backend_api && cargo run" -ForegroundColor White
    Write-Host "2. Para iniciar la app móvil: cd mobile_app && flutter run -d windows" -ForegroundColor White
    Write-Host "3. Para ver servicios Docker: docker-compose ps" -ForegroundColor White
    Write-Host ""
