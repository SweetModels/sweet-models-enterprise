# Script para instalar todas las dependencias necesarias
# Sweet Models Enterprise - Instalación completa

Write-Host "=== Sweet Models Enterprise - Instalación de Dependencias ===" -ForegroundColor Cyan
Write-Host ""

# Actualizar PATH con las rutas comunes
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
$env:Path += ";$env:USERPROFILE\.cargo\bin"
$env:Path += ";C:\flutter\bin"

# 1. Verificar winget
Write-Host "[1/5] Verificando winget..." -ForegroundColor Green
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  ERROR: winget no está disponible. Necesitas Windows 10/11 actualizado" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  ✓ winget está disponible" -ForegroundColor Green
}

# 2. Instalar Rust y Cargo
Write-Host "`n[2/5] Verificando Rust/Cargo..." -ForegroundColor Green
$cargoPath = "$env:USERPROFILE\.cargo\bin\cargo.exe"
if (!(Test-Path $cargoPath)) {
    Write-Host "  Instalando Rust con winget..." -ForegroundColor Yellow
    winget install --id Rustlang.Rust.MSVC --accept-source-agreements --accept-package-agreements --silent
    
    # Actualizar PATH
    $env:Path += ";$env:USERPROFILE\.cargo\bin"
    
    Write-Host "  ✓ Rust/Cargo instalado" -ForegroundColor Green
} else {
    Write-Host "  ✓ Rust/Cargo ya está instalado" -ForegroundColor Green
    $env:Path += ";$env:USERPROFILE\.cargo\bin"
}

# 3. Instalar Flutter
Write-Host "`n[3/5] Verificando Flutter..." -ForegroundColor Green
$flutterPath = "C:\flutter\bin\flutter.bat"
if (!(Test-Path $flutterPath)) {
    Write-Host "  Descargando Flutter SDK..." -ForegroundColor Yellow
    $flutterZip = "$env:TEMP\flutter.zip"
    Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip" -OutFile $flutterZip
    
    Write-Host "  Extrayendo Flutter..." -ForegroundColor Yellow
    Expand-Archive -Path $flutterZip -DestinationPath "C:\" -Force
    Remove-Item $flutterZip
    
    # Actualizar PATH
    $env:Path += ";C:\flutter\bin"
    
    Write-Host "  ✓ Flutter instalado en C:\flutter" -ForegroundColor Green
} else {
    Write-Host "  ✓ Flutter ya está instalado" -ForegroundColor Green
    $env:Path += ";C:\flutter\bin"
}

# 4. Instalar Docker Desktop
Write-Host "`n[4/5] Verificando Docker..." -ForegroundColor Green
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "  Instalando Docker Desktop con winget..." -ForegroundColor Yellow
    winget install --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
    Write-Host "  ✓ Docker Desktop instalado" -ForegroundColor Green
    Write-Host "  IMPORTANTE: Necesitarás reiniciar tu PC y abrir Docker Desktop" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ Docker ya está instalado" -ForegroundColor Green
}

# 5. Instalar Git
Write-Host "`n[5/5] Verificando Git..." -ForegroundColor Green
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  Instalando Git con winget..." -ForegroundColor Yellow
    winget install --id Git.Git --accept-source-agreements --accept-package-agreements
    Write-Host "  ✓ Git instalado" -ForegroundColor Green
} else {
    Write-Host "  ✓ Git ya está instalado" -ForegroundColor Green
}

# Guardar PATH permanentemente
Write-Host "`n=== Guardando configuración del PATH ===" -ForegroundColor Cyan
$currentUserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

if ($currentUserPath -notlike "*\.cargo\bin*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$currentUserPath;$env:USERPROFILE\.cargo\bin", "User")
    Write-Host "  ✓ Cargo agregado al PATH del usuario" -ForegroundColor Green
}

if ($currentUserPath -notlike "*C:\flutter\bin*") {
    $newUserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    [System.Environment]::SetEnvironmentVariable("Path", "$newUserPath;C:\flutter\bin", "User")
    Write-Host "  ✓ Flutter agregado al PATH del usuario" -ForegroundColor Green
}

Write-Host "`n=== Instalación de herramientas completada ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. Cierra y reabre PowerShell (IMPORTANTE)" -ForegroundColor White
Write-Host "2. Ejecuta: .\setup_project_dependencies.ps1" -ForegroundColor White
Write-Host "3. Si instalaste Docker Desktop, abre la aplicación Docker Desktop" -ForegroundColor White
Write-Host ""
