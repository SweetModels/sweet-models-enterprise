# GUÍA DE INSTALACIÓN - Sweet Models Enterprise
# Ejecutar después de reiniciar el PC

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║        Sweet Models Enterprise - Instalación Completa         ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`nEste script instalará TODO lo necesario para ejecutar el proyecto.`n" -ForegroundColor Yellow

# Paso 1: Verificar herramientas
Write-Host "═══ PASO 1: Verificando herramientas instaladas ═══`n" -ForegroundColor Green

$herramientasFaltantes = @()

# Rust/Cargo
if (!(Test-Path "$env:USERPROFILE\.cargo\bin\cargo.exe")) {
    $herramientasFaltantes += "Rust/Cargo"
    Write-Host "  ✗ Rust/Cargo no encontrado" -ForegroundColor Red
} else {
    Write-Host "  ✓ Rust/Cargo instalado" -ForegroundColor Green
}

# Flutter
if (!(Test-Path "C:\flutter\bin\flutter.bat")) {
    $herramientasFaltantes += "Flutter"
    Write-Host "  ✗ Flutter no encontrado" -ForegroundColor Red
} else {
    Write-Host "  ✓ Flutter instalado" -ForegroundColor Green
}

# Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "  ⚠ Docker no encontrado (opcional)" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ Docker instalado" -ForegroundColor Green
}

# Instalar herramientas faltantes
if ($herramientasFaltantes.Count -gt 0) {
    Write-Host "`n❌ Faltan herramientas esenciales:" -ForegroundColor Red
    $herramientasFaltantes | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    
    Write-Host "`n¿Deseas instalar las herramientas faltantes ahora? (S/N): " -ForegroundColor Yellow -NoNewline
    $respuesta = Read-Host
    
    if ($respuesta -eq 'S' -or $respuesta -eq 's') {
        if ("Rust/Cargo" -in $herramientasFaltantes) {
            Write-Host "`nInstalando Rust..." -ForegroundColor Cyan
            $rustupPath = "$env:TEMP\rustup-init.exe"
            Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile $rustupPath
            Start-Process -FilePath $rustupPath -ArgumentList "-y" -Wait -NoNewWindow
            Write-Host "✓ Rust instalado" -ForegroundColor Green
        }
        
        if ("Flutter" -in $herramientasFaltantes) {
            Write-Host "`nInstalando Flutter..." -ForegroundColor Cyan
            $flutterZip = "$env:TEMP\flutter.zip"
            Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip" -OutFile $flutterZip
            Expand-Archive -Path $flutterZip -DestinationPath "C:\" -Force
            Remove-Item $flutterZip
            Write-Host "✓ Flutter instalado en C:\flutter" -ForegroundColor Green
        }
        
        # Actualizar PATH
        $currentUserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentUserPath -notlike "*\.cargo\bin*") {
            [System.Environment]::SetEnvironmentVariable("Path", "$currentUserPath;$env:USERPROFILE\.cargo\bin", "User")
        }
        if ($currentUserPath -notlike "*C:\flutter\bin*") {
            $newUserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
            [System.Environment]::SetEnvironmentVariable("Path", "$newUserPath;C:\flutter\bin", "User")
        }
        
        Write-Host "`n✓ Herramientas instaladas. Reinicia PowerShell y ejecuta este script de nuevo.`n" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n❌ No se pueden instalar dependencias sin las herramientas base.`n" -ForegroundColor Red
        exit 1
    }
}

# Actualizar PATH para esta sesión
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Paso 2: Instalar dependencias del Backend
Write-Host "`n═══ PASO 2: Instalando dependencias del Backend (Rust) ═══`n" -ForegroundColor Green
Write-Host "  📍 Ubicación: backend_api" -ForegroundColor Gray
Write-Host "  ⏱  Esto puede tardar 5-10 minutos...`n" -ForegroundColor Yellow

Set-Location "$PSScriptRoot\backend_api"
cargo build --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n  ✓ Backend compilado exitosamente`n" -ForegroundColor Green
} else {
    Write-Host "`n  ✗ Error al compilar el backend`n" -ForegroundColor Red
}

# Paso 3: Instalar dependencias de Flutter
Write-Host "═══ PASO 3: Instalando dependencias de Flutter ═══`n" -ForegroundColor Green
Write-Host "  📍 Ubicación: mobile_app" -ForegroundColor Gray

Set-Location "$PSScriptRoot\mobile_app"

# Deshabilitar analytics
C:\flutter\bin\flutter.bat config --no-analytics | Out-Null

# Descargar paquetes
C:\flutter\bin\flutter.bat pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n  ✓ Dependencias de Flutter descargadas`n" -ForegroundColor Green
} else {
    Write-Host "`n  ✗ Error al descargar dependencias`n" -ForegroundColor Red
}

# Diagnóstico de Flutter
Write-Host "═══ Diagnóstico de Flutter ═══`n" -ForegroundColor Green
C:\flutter\bin\flutter.bat doctor

# Paso 4: Verificar Docker (opcional)
Write-Host "`n═══ PASO 4: Verificando Docker ═══`n" -ForegroundColor Green

docker info 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Docker está funcionando`n" -ForegroundColor Green
    
    Set-Location $PSScriptRoot
    if (Test-Path "docker-compose.yml") {
        Write-Host "  ¿Deseas iniciar los servicios de Docker? (S/N): " -ForegroundColor Yellow -NoNewline
        $respuesta = Read-Host
        
        if ($respuesta -eq 'S' -or $respuesta -eq 's') {
            docker-compose up -d
            Write-Host "`n  ✓ Servicios iniciados`n" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  ⚠ Docker no está ejecutándose" -ForegroundColor Yellow
    Write-Host "  Si necesitas Docker, abre Docker Desktop`n" -ForegroundColor Gray
}

# Resumen final
Set-Location $PSScriptRoot

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║                  ✓ INSTALACIÓN COMPLETADA                     ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green

Write-Host "`nCOMandos útiles:" -ForegroundColor Cyan
Write-Host "  • Ejecutar backend:  " -NoNewline; Write-Host "cd backend_api && cargo run" -ForegroundColor White
Write-Host "  • Ejecutar app:      " -NoNewline; Write-Host "cd mobile_app && flutter run -d windows" -ForegroundColor White
Write-Host "  • Ver servicios:     " -NoNewline; Write-Host "docker-compose ps" -ForegroundColor White
Write-Host "  • Logs del backend:  " -NoNewline; Write-Host "docker-compose logs -f backend" -ForegroundColor White
Write-Host "`n"
