# ========================================
# Sweet Models Enterprise
# Pre-Build Checker
# ========================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  🔍 Pre-Build Verification               " -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

$issues = 0
$warnings = 0

# Función para verificar comandos
function Test-Command {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# 1. Verificar Flutter
Write-Host "🔍 Verificando Flutter..." -ForegroundColor Cyan
if (Test-Command "flutter") {
    $flutterVersion = flutter --version | Select-String "Flutter" | Select-Object -First 1
    Write-Host "   ✅ Flutter encontrado" -ForegroundColor Green
    Write-Host "      $flutterVersion" -ForegroundColor Gray
} else {
    Write-Host "   ❌ Flutter NO encontrado" -ForegroundColor Red
    Write-Host "      Instala desde: https://flutter.dev" -ForegroundColor Yellow
    $issues++
}

# 2. Verificar Java/keytool
Write-Host ""
Write-Host "🔍 Verificando Java (keytool)..." -ForegroundColor Cyan
if (Test-Command "keytool") {
    Write-Host "   ✅ keytool encontrado" -ForegroundColor Green
    try {
        $javaVersion = java -version 2>&1 | Select-String "version" | Select-Object -First 1
        Write-Host "      $javaVersion" -ForegroundColor Gray
    } catch {
        Write-Host "      (Java JDK instalado)" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ keytool NO encontrado" -ForegroundColor Red
    Write-Host "      Instala Java JDK: https://adoptium.net/" -ForegroundColor Yellow
    $issues++
}

# 3. Verificar Git
Write-Host ""
Write-Host "🔍 Verificando Git..." -ForegroundColor Cyan
if (Test-Command "git") {
    $gitVersion = git --version
    Write-Host "   ✅ Git encontrado: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Git NO encontrado" -ForegroundColor Yellow
    Write-Host "      Recomendado para control de versiones" -ForegroundColor Gray
    $warnings++
}

# 4. Verificar pubspec.yaml
Write-Host ""
Write-Host "🔍 Verificando pubspec.yaml..." -ForegroundColor Cyan
if (Test-Path "pubspec.yaml") {
    $pubspec = Get-Content "pubspec.yaml" -Raw
    
    # Verificar versión
    if ($pubspec -match 'version:\s+(\d+\.\d+\.\d+\+\d+)') {
        $version = $matches[1]
        Write-Host "   ✅ Versión válida: $version" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Versión no válida o no encontrada" -ForegroundColor Red
        $issues++
    }
    
    # Verificar dependencias críticas
    $requiredDeps = @('dio', 'shared_preferences', 'flutter_riverpod')
    foreach ($dep in $requiredDeps) {
        if ($pubspec -match $dep) {
            Write-Host "   ✅ Dependencia '$dep' presente" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Dependencia '$dep' no encontrada" -ForegroundColor Yellow
            $warnings++
        }
    }
} else {
    Write-Host "   ❌ pubspec.yaml NO encontrado" -ForegroundColor Red
    Write-Host "      ¿Estás en el directorio mobile_app?" -ForegroundColor Yellow
    $issues++
}

# 5. Verificar estructura Android
Write-Host ""
Write-Host "🔍 Verificando configuración Android..." -ForegroundColor Cyan

if (Test-Path "android\app\build.gradle") {
    Write-Host "   ✅ build.gradle encontrado" -ForegroundColor Green
    
    $buildGradle = Get-Content "android\app\build.gradle" -Raw
    
    # Verificar applicationId
    if ($buildGradle -match 'applicationId\s+"([^"]+)"') {
        $appId = $matches[1]
        Write-Host "   ✅ Application ID: $appId" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Application ID no encontrado" -ForegroundColor Yellow
        $warnings++
    }
    
    # Verificar configuración de firma
    if ($buildGradle -match 'signingConfigs') {
        Write-Host "   ✅ Configuración de firma presente" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Configuración de firma NO encontrada" -ForegroundColor Yellow
        Write-Host "      Ejecuta: .\setup_android_signing.ps1" -ForegroundColor Gray
        $warnings++
    }
} else {
    Write-Host "   ❌ build.gradle NO encontrado" -ForegroundColor Red
    $issues++
}

# Verificar keystore
if (Test-Path "android\app\upload-keystore.jks") {
    Write-Host "   ✅ Keystore presente" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Keystore NO encontrado" -ForegroundColor Yellow
    Write-Host "      Ejecuta: .\setup_android_signing.ps1" -ForegroundColor Gray
    $warnings++
}

# Verificar key.properties
if (Test-Path "android\key.properties") {
    Write-Host "   ✅ key.properties presente" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  key.properties NO encontrado" -ForegroundColor Yellow
    Write-Host "      Ejecuta: .\setup_android_signing.ps1" -ForegroundColor Gray
    $warnings++
}

# 6. Verificar estructura Windows
Write-Host ""
Write-Host "🔍 Verificando configuración Windows..." -ForegroundColor Cyan

if (Test-Path "windows\runner\main.cpp") {
    Write-Host "   ✅ Proyecto Windows encontrado" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Proyecto Windows NO encontrado" -ForegroundColor Yellow
    Write-Host "      Ejecuta: flutter create --platforms=windows ." -ForegroundColor Gray
    $warnings++
}

# Verificar Inno Setup (opcional)
if (Test-Path "C:\Program Files (x86)\Inno Setup 6\ISCC.exe") {
    Write-Host "   ✅ Inno Setup instalado" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Inno Setup NO instalado (opcional)" -ForegroundColor Yellow
    Write-Host "      Para crear instalador EXE: winget install --id JRSoftware.InnoSetup" -ForegroundColor Gray
    $warnings++
}

# Verificar installer_setup.iss
if (Test-Path "installer_setup.iss") {
    Write-Host "   ✅ installer_setup.iss presente" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  installer_setup.iss NO encontrado" -ForegroundColor Yellow
    $warnings++
}

# 7. Verificar dependencias Flutter
Write-Host ""
Write-Host "🔍 Verificando dependencias Flutter..." -ForegroundColor Cyan
try {
    flutter pub get 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Dependencias resueltas correctamente" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Advertencias en dependencias" -ForegroundColor Yellow
        $warnings++
    }
} catch {
    Write-Host "   ❌ Error al obtener dependencias" -ForegroundColor Red
    $issues++
}

# 8. Verificar conectividad backend (opcional)
Write-Host ""
Write-Host "🔍 Verificando configuración de backend..." -ForegroundColor Cyan

$libFiles = Get-ChildItem "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue
$backendUrls = $libFiles | Select-String -Pattern "http:|https:" | Select-Object -First 5

if ($backendUrls) {
    Write-Host "   ℹ️  URLs encontradas en el código:" -ForegroundColor Cyan
    foreach ($urlLine in $backendUrls) {
        $line = $urlLine.Line
        if ($line -match '(https?://[^\s''\"]+)') {
            $urlFound = $matches[1]
            if ($urlFound -match 'localhost|127\.0\.0\.1') {
                Write-Host "      ⚠️  $urlFound (localhost - es correcto para produccion?)" -ForegroundColor Yellow
                $warnings++
            } else {
                Write-Host "      ✅ $urlFound" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "   ℹ️  No se encontraron URLs en el código" -ForegroundColor Gray
}

# 9. Verificar .gitignore
Write-Host ""
Write-Host "🔍 Verificando .gitignore..." -ForegroundColor Cyan

if (Test-Path ".gitignore") {
    $gitignore = Get-Content ".gitignore" -Raw
    
    $criticalEntries = @('upload-keystore.jks', 'key.properties')
    $allPresent = $true
    
    foreach ($entry in $criticalEntries) {
        if ($gitignore -match $entry) {
            Write-Host "   ✅ '$entry' excluido de Git" -ForegroundColor Green
        } else {
            Write-Host "   ❌ '$entry' NO excluido de Git" -ForegroundColor Red
            Write-Host "      ¡RIESGO DE SEGURIDAD!" -ForegroundColor Red
            $issues++
            $allPresent = $false
        }
    }
} else {
    Write-Host "   ⚠️  .gitignore NO encontrado" -ForegroundColor Yellow
    $warnings++
}

# 10. Verificar scripts de build
Write-Host ""
Write-Host "🔍 Verificando scripts de build..." -ForegroundColor Cyan

$scripts = @('build_release.ps1', 'setup_android_signing.ps1', 'bump_version.ps1')
foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "   ✅ $script presente" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  $script NO encontrado" -ForegroundColor Yellow
        $warnings++
    }
}

# Resumen final
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  📊 RESUMEN DE VERIFICACIÓN" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

if ($issues -eq 0 -and $warnings -eq 0) {
    Write-Host "✅ TODO OK - Listo para compilar!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Siguiente paso:" -ForegroundColor Cyan
    Write-Host "   .\build_release.ps1 -Platform all" -ForegroundColor Yellow
    exit 0
} elseif ($issues -eq 0) {
    Write-Host "⚠️  $warnings advertencia(s) encontrada(s)" -ForegroundColor Yellow
    Write-Host "   Puedes compilar, pero revisa las advertencias" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📝 Para compilar:" -ForegroundColor Cyan
    Write-Host "   .\build_release.ps1 -Platform all" -ForegroundColor Gray
    exit 0
} else {
    Write-Host "❌ $issues error(es) crítico(s) encontrado(s)" -ForegroundColor Red
    Write-Host "   $warnings advertencia(s) adicional(es)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Corrige los errores antes de compilar" -ForegroundColor Red
    Write-Host ""
    Write-Host "📝 Ayuda:" -ForegroundColor Cyan
    Write-Host "   • Revisa BUILD_RELEASE_GUIDE.md" -ForegroundColor Gray
    Write-Host "   • Ejecuta: .\setup_android_signing.ps1" -ForegroundColor Gray
    Write-Host "   • Verifica que estes en el directorio mobile_app/" -ForegroundColor Gray
    exit 1
}
