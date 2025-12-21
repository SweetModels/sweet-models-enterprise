# Script de Build de Producción
# Sweet Models Enterprise

param(
    [string]$Platform = "android",
    [string]$BuildType = "appbundle"
)

Write-Host "🚀 Sweet Models Enterprise - Build de Producción" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar Flutter
Write-Host "🔍 Verificando instalación de Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Host "✅ $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter no está instalado o no está en PATH" -ForegroundColor Red
    exit 1
}

# Limpiar builds anteriores
Write-Host ""
Write-Host "🧹 Limpiando builds anteriores..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Build anterior limpiado" -ForegroundColor Green

# Obtener dependencias
Write-Host ""
Write-Host "📦 Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get
Write-Host "✅ Dependencias obtenidas" -ForegroundColor Green

# Verificar configuración
Write-Host ""
Write-Host "🔍 Verificando configuración..." -ForegroundColor Yellow

if ($Platform -eq "android") {
    # Verificar keystore
    $keystorePath = "android\app\upload-keystore.jks"
    $keyPropertiesPath = "android\key.properties"
    
    if (!(Test-Path $keystorePath)) {
        Write-Host "❌ No se encontró el keystore: $keystorePath" -ForegroundColor Red
        Write-Host "   Ejecuta: .\setup-keystore.ps1" -ForegroundColor Yellow
        exit 1
    }
    
    if (!(Test-Path $keyPropertiesPath)) {
        Write-Host "❌ No se encontró key.properties: $keyPropertiesPath" -ForegroundColor Red
        Write-Host "   Ejecuta: .\setup-keystore.ps1" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✅ Keystore configurado correctamente" -ForegroundColor Green
}

# Build
Write-Host ""
Write-Host "🔨 Iniciando build de producción..." -ForegroundColor Yellow
Write-Host "   Plataforma: $Platform" -ForegroundColor White
Write-Host "   Tipo: $BuildType" -ForegroundColor White
Write-Host ""

$buildSuccess = $false

try {
    switch ($Platform) {
        "android" {
            switch ($BuildType) {
                "appbundle" {
                    Write-Host "📱 Generando Android App Bundle (AAB)..." -ForegroundColor Cyan
                    flutter build appbundle --release
                    $outputPath = "build\app\outputs\bundle\release\app-release.aab"
                }
                "apk" {
                    Write-Host "📱 Generando Android APK..." -ForegroundColor Cyan
                    flutter build apk --release
                    $outputPath = "build\app\outputs\flutter-apk\app-release.apk"
                }
                "apk-split" {
                    Write-Host "📱 Generando Android APK (split por ABI)..." -ForegroundColor Cyan
                    flutter build apk --release --split-per-abi
                    $outputPath = "build\app\outputs\flutter-apk\"
                }
                default {
                    Write-Host "❌ Tipo de build no válido: $BuildType" -ForegroundColor Red
                    Write-Host "   Opciones: appbundle, apk, apk-split" -ForegroundColor Yellow
                    exit 1
                }
            }
        }
        "ios" {
            Write-Host "🍎 Generando iOS IPA..." -ForegroundColor Cyan
            Write-Host "⚠️  Este build requiere un Mac con Xcode" -ForegroundColor Yellow
            flutter build ios --release
            $outputPath = "build\ios\iphoneos\Runner.app"
        }
        "windows" {
            Write-Host "🪟 Generando Windows EXE..." -ForegroundColor Cyan
            flutter build windows --release
            $outputPath = "build\windows\x64\runner\Release\"
        }
        default {
            Write-Host "❌ Plataforma no válida: $Platform" -ForegroundColor Red
            Write-Host "   Opciones: android, ios, windows" -ForegroundColor Yellow
            exit 1
        }
    }
    
    $buildSuccess = $true
    
} catch {
    Write-Host "❌ Error durante el build: $_" -ForegroundColor Red
    exit 1
}

# Verificar que el build se generó
Write-Host ""
if ($buildSuccess) {
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "✅ BUILD COMPLETADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Path $outputPath) {
        Write-Host "📦 Archivo de salida:" -ForegroundColor Yellow
        Write-Host "   $outputPath" -ForegroundColor White
        Write-Host ""
        
        # Obtener tamaño del archivo
        if ($BuildType -ne "apk-split") {
            $fileSize = (Get-Item $outputPath).Length / 1MB
            Write-Host "📊 Tamaño: $([math]::Round($fileSize, 2)) MB" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "🚀 Próximos pasos:" -ForegroundColor Cyan
        
        if ($Platform -eq "android") {
            if ($BuildType -eq "appbundle") {
                Write-Host "   1. Ve a Google Play Console" -ForegroundColor White
                Write-Host "   2. Crea una nueva versión en Producción" -ForegroundColor White
                Write-Host "   3. Sube el archivo AAB" -ForegroundColor White
                Write-Host "   4. Completa la información de la versión" -ForegroundColor White
                Write-Host "   5. Envía para revisión" -ForegroundColor White
            } else {
                Write-Host "   1. Instala el APK en un dispositivo para probar" -ForegroundColor White
                Write-Host "   2. Si todo funciona, genera un AAB para subir a Play Store" -ForegroundColor White
                Write-Host "      .\build-release.ps1 -Platform android -BuildType appbundle" -ForegroundColor Yellow
            }
        } elseif ($Platform -eq "ios") {
            Write-Host "   1. Abre Xcode en un Mac" -ForegroundColor White
            Write-Host "   2. Product → Archive" -ForegroundColor White
            Write-Host "   3. Distribute App → App Store Connect" -ForegroundColor White
            Write-Host "   4. Sigue el asistente de publicación" -ForegroundColor White
        }
        
    } else {
        Write-Host "⚠️  No se encontró el archivo de salida en: $outputPath" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "📖 Para más información, lee: PUBLICACION.md" -ForegroundColor Cyan
    Write-Host ""
}
