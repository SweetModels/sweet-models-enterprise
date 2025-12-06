# ========================================
# Sweet Models Enterprise - Build Script
# Automatización de compilación de releases
# Version: 2.0 - Actualizado 2025-12-06
# ========================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('android', 'windows', 'all')]
    [string]$Platform = 'all',
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests = $false
)

$ErrorActionPreference = "Stop"

# Colores para output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

# Banner
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Sweet Models Enterprise - Builder    " -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# Obtener versión del pubspec.yaml
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match 'version:\s+(\d+\.\d+\.\d+\+\d+)') {
    $version = $matches[1]
    Write-Info "📦 Versión detectada: $version"
} else {
    Write-Error "❌ No se pudo detectar la versión en pubspec.yaml"
    exit 1
}

# Verificar Flutter
Write-Info "🔍 Verificando Flutter..."
try {
    $flutterVersion = flutter --version | Select-String "Flutter" | Select-Object -First 1
    Write-Success "✅ Flutter encontrado: $flutterVersion"
} catch {
    Write-Error "❌ Flutter no encontrado. Instálalo desde https://flutter.dev"
    exit 1
}

# Limpiar builds anteriores
if ($Clean) {
    Write-Info "🧹 Limpiando builds anteriores..."
    flutter clean
    Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Success "✅ Limpieza completada"
}

# Obtener dependencias
Write-Info "📦 Obteniendo dependencias..."
flutter pub get
Write-Success "✅ Dependencias actualizadas"

# Ejecutar tests (opcional)
if (-not $SkipTests) {
    Write-Info "🧪 Ejecutando tests..."
    flutter test
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "⚠️  Algunos tests fallaron. ¿Continuar? (S/N)"
        $continue = Read-Host
        if ($continue -ne "S" -and $continue -ne "s") {
            exit 1
        }
    } else {
        Write-Success "✅ Todos los tests pasaron"
    }
}

# Función para compilar Android
function Invoke-AndroidBuild {
    Write-Info ""
    Write-Info "============================================"
    Write-Info "📱 COMPILANDO ANDROID"
    Write-Info "============================================"
    
    # Verificar keystore
    $keystoreExists = Test-Path "android\app\upload-keystore.jks"
    $keyPropsExists = Test-Path "android\key.properties"
    
    if (-not $keystoreExists -or -not $keyPropsExists) {
        Write-Warning "⚠️  Keystore o key.properties no encontrados"
        Write-Info "📝 Sigue las instrucciones en BUILD_RELEASE_GUIDE.md para crear el keystore"
        Write-Warning "⚠️  Compilando APK sin firma (solo para testing)..."
    }
    
    # Compilar APK (split per ABI para archivos más pequeños)
    Write-Info "🔨 Compilando APK split-per-abi..."
    flutter build apk --release --split-per-abi
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ APK compilado exitosamente"
        Write-Info ""
        Write-Info "📁 Archivos generados:"
        Get-ChildItem "build\app\outputs\flutter-apk\" -Filter "*.apk" | ForEach-Object {
            $size = [math]::Round($_.Length / 1MB, 2)
            Write-Success "   • $($_.Name) ($size MB)"
        }
    } else {
        Write-Error "❌ Error al compilar APK"
        exit 1
    }
    
    # Compilar AAB (Google Play)
    Write-Info ""
    Write-Info "🔨 Compilando AAB (Google Play Store)..."
    flutter build appbundle --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ AAB compilado exitosamente"
        $aabFile = Get-Item "build\app\outputs\bundle\release\app-release.aab"
        $size = [math]::Round($aabFile.Length / 1MB, 2)
        Write-Success "   • app-release.aab ($size MB)"
    } else {
        Write-Warning "⚠️  Error al compilar AAB (puede ser por falta de keystore)"
    }
}

# Función para compilar Windows
function Invoke-WindowsBuild {
    Write-Info ""
    Write-Info "============================================"
    Write-Info "🪟 COMPILANDO WINDOWS"
    Write-Info "============================================"
    
    # Compilar Windows Release
    Write-Info "🔨 Compilando Windows release..."
    flutter build windows --release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Error al compilar Windows release"
        exit 1
    }
    
    Write-Success "✅ Windows release compilado"
    
    # Verificar archivos
    $exePath = "build\windows\x64\runner\Release\sweet_models_mobile.exe"
    if (Test-Path $exePath) {
        $exeSize = [math]::Round((Get-Item $exePath).Length / 1MB, 2)
        Write-Success "   • sweet_models_mobile.exe ($exeSize MB)"
    }
    
    # Intentar compilar MSIX
    Write-Info ""
    Write-Info "🔨 Compilando MSIX (Microsoft Store)..."
    try {
        flutter pub run msix:create
        if ($LASTEXITCODE -eq 0) {
            Write-Success "✅ MSIX compilado exitosamente"
            if (Test-Path "build\windows\runner\Release\sweet_models_mobile.msix") {
                $msixSize = [math]::Round((Get-Item "build\windows\runner\Release\sweet_models_mobile.msix").Length / 1MB, 2)
                Write-Success "   • sweet_models_mobile.msix ($msixSize MB)"
            }
        }
    } catch {
        Write-Warning "⚠️  No se pudo compilar MSIX (requiere configuración adicional)"
    }
    
    # Intentar compilar instalador con Inno Setup
    Write-Info ""
    Write-Info "🔨 Compilando instalador EXE (Inno Setup)..."
    $innoPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    
    if (Test-Path $innoPath) {
        try {
            & $innoPath "installer_setup.iss"
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✅ Instalador EXE compilado exitosamente"
                $installerFiles = Get-ChildItem "build\windows\installer\" -Filter "*.exe"
                foreach ($file in $installerFiles) {
                    $size = [math]::Round($file.Length / 1MB, 2)
                    Write-Success "   • $($file.Name) ($size MB)"
                }
            }
        } catch {
            Write-Warning "⚠️  Error al compilar con Inno Setup"
        }
    } else {
        Write-Warning "⚠️  Inno Setup no encontrado"
        Write-Info "   Instálalo desde: https://jrsoftware.org/isdl.php"
        Write-Info "   O ejecuta: winget install --id JRSoftware.InnoSetup"
    }
}

# Ejecutar builds según plataforma seleccionada
switch ($Platform) {
    'android' {
        Invoke-AndroidBuild
    }
    'windows' {
        Invoke-WindowsBuild
    }
    'all' {
        Invoke-AndroidBuild
        Invoke-WindowsBuild
    }
}

# Resumen final
Write-Info ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  ✅ BUILD COMPLETADO" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Info ""
Write-Info "📦 Versión: $version"
Write-Info "📁 Archivos en:"

if ($Platform -eq 'android' -or $Platform -eq 'all') {
    Write-Info "   • Android APK: build\app\outputs\flutter-apk\"
    Write-Info "   • Android AAB: build\app\outputs\bundle\release\"
}

if ($Platform -eq 'windows' -or $Platform -eq 'all') {
    Write-Info "   • Windows EXE: build\windows\x64\runner\Release\"
    Write-Info "   • Windows MSIX: build\windows\runner\Release\"
    Write-Info "   • Instalador: build\windows\installer\"
}

Write-Info ""
Write-Success "🎉 ¡Listo para distribución!"
Write-Info ""
Write-Info "📝 Siguiente paso:"
Write-Info "   1. Prueba los archivos compilados"
Write-Info "   2. Crea tag de Git: git tag v$version"
Write-Info "   3. Sube a GitHub: git push origin v$version"
Write-Info "   4. Crea GitHub Release con los archivos"
Write-Info ""
