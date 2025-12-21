# Script para ejecutar Flutter en Windows con Visual Studio 2026

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║        Ejecutando App Flutter en Windows - Visual Studio 2026  ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

$projectPath = Split-Path -Parent $PSCommandPath
$mobilePath = Join-Path $projectPath "mobile_app"

Write-Host "`n📁 Directorio del proyecto: $mobilePath`n" -ForegroundColor Yellow

# Verificar que VS 2026 esté instalado
$vsPath = "C:\Program Files\Microsoft Visual Studio\18"
if (-not (Test-Path $vsPath)) {
    Write-Host "❌ Visual Studio 2026 no encontrado en: $vsPath" -ForegroundColor Red
    Write-Host "Por favor instala Visual Studio con soporte para desktop de Windows." -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Visual Studio 2026 encontrado" -ForegroundColor Green

# Cambiar a directorio del proyecto
Set-Location $mobilePath

# Configurar variables de entorno para CMake
Write-Host "`n📝 Configurando variables de entorno..." -ForegroundColor Cyan
$env:CMAKE_GENERATOR = "Visual Studio 18 2024"
$env:CMAKE_GENERATOR_PLATFORM = "x64"
$env:PATH += ";C:\flutter\bin"

Write-Host "  CMAKE_GENERATOR: $env:CMAKE_GENERATOR" -ForegroundColor Green
Write-Host "  CMAKE_GENERATOR_PLATFORM: $env:CMAKE_GENERATOR_PLATFORM`n" -ForegroundColor Green

# Limpiar build anterior si existe
if (Test-Path "build") {
    Write-Host "🧹 Limpiando build anterior..." -ForegroundColor Yellow
    Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Build limpiado`n" -ForegroundColor Green
}

# Ejecutar Flutter con parámetros especiales
Write-Host "🚀 Iniciando compilación de Flutter..." -ForegroundColor Cyan
Write-Host "⏳ Esto puede tardar 3-5 minutos la primera vez...`n" -ForegroundColor Yellow

# Usar cmake directamente con el generador correcto
Write-Host "1️⃣  Configurando CMake..." -ForegroundColor Cyan
& "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" `
    -B build `
    -G "Visual Studio 18 2024" `
    -A x64 `
    -S .

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n⚠️  CMake no encontrado en la ruta esperada, intentando con flutter..." -ForegroundColor Yellow
    # Intentar con Flutter normalmente
    & C:\flutter\bin\flutter.bat run -d windows
} else {
    Write-Host "`n2️⃣  Compilando con Visual Studio..." -ForegroundColor Cyan
    & "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" `
        build/sweet_models_mobile.sln `
        /p:Configuration=Debug `
        /p:Platform=x64
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Compilación exitosa!`n" -ForegroundColor Green
        Write-Host "3️⃣  Ejecutando aplicación..." -ForegroundColor Cyan
        & ".\build\Debug\sweet_models_mobile.exe"
    } else {
        Write-Host "`n❌ Error en la compilación" -ForegroundColor Red
        Write-Host "Intentando con flutter run..." -ForegroundColor Yellow
        & C:\flutter\bin\flutter.bat run -d windows
    }
}
