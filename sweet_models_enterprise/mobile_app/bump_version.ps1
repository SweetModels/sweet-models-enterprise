# ========================================
# Sweet Models Enterprise
# Actualizador de versiones
# ========================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('major', 'minor', 'patch', 'build')]
    [string]$BumpType = 'build'
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  📦 Actualizador de Versiones            " -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

# Leer versión actual del pubspec.yaml
$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw

if ($pubspecContent -match 'version:\s+(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $build = [int]$matches[4]
    
    $currentVersion = "$major.$minor.$patch+$build"
    Write-Host "📌 Versión actual: $currentVersion" -ForegroundColor Cyan
} else {
    Write-Host "❌ No se pudo leer la versión en pubspec.yaml" -ForegroundColor Red
    exit 1
}

# Incrementar según tipo
switch ($BumpType) {
    'major' {
        $major++
        $minor = 0
        $patch = 0
        $build++
        $changeType = "MAJOR (incompatible API changes)"
    }
    'minor' {
        $minor++
        $patch = 0
        $build++
        $changeType = "MINOR (new features, backwards compatible)"
    }
    'patch' {
        $patch++
        $build++
        $changeType = "PATCH (bug fixes)"
    }
    'build' {
        $build++
        $changeType = "BUILD (internal changes)"
    }
}

$newVersion = "$major.$minor.$patch+$build"

Write-Host ""
Write-Host "🔄 Tipo de cambio: $changeType" -ForegroundColor Yellow
Write-Host "➡️  Nueva versión: $newVersion" -ForegroundColor Green
Write-Host ""

# Pedir confirmación
$confirm = Read-Host "¿Continuar? (S/N)"
if ($confirm -ne "S" -and $confirm -ne "s") {
    Write-Host "❌ Cancelado por el usuario" -ForegroundColor Yellow
    exit 0
}

# Actualizar pubspec.yaml
Write-Host ""
Write-Host "📝 Actualizando pubspec.yaml..." -ForegroundColor Cyan

$newContent = $pubspecContent -replace "version:\s+\d+\.\d+\.\d+\+\d+", "version: $newVersion"
Set-Content -Path $pubspecPath -Value $newContent -Encoding UTF8

Write-Host "✅ pubspec.yaml actualizado" -ForegroundColor Green

# Actualizar installer_setup.iss (si existe)
$innoSetupPath = "installer_setup.iss"
if (Test-Path $innoSetupPath) {
    Write-Host "📝 Actualizando installer_setup.iss..." -ForegroundColor Cyan
    
    $innoContent = Get-Content $innoSetupPath -Raw
    $versionOnly = "$major.$minor.$patch"
    $newInnoContent = $innoContent -replace '#define MyAppVersion "[\d\.]+"', "#define MyAppVersion `"$versionOnly`""
    Set-Content -Path $innoSetupPath -Value $newInnoContent -Encoding UTF8
    
    Write-Host "✅ installer_setup.iss actualizado" -ForegroundColor Green
}

# Crear tag de Git
Write-Host ""
Write-Host "🏷️  Creando tag de Git..." -ForegroundColor Cyan

$tagName = "v$newVersion"
$tagMessage = "Release $tagName - $changeType"

try {
    git tag -a $tagName -m $tagMessage
    Write-Host "✅ Tag creado: $tagName" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "📤 Para subir a GitHub ejecuta:" -ForegroundColor Yellow
    Write-Host "   git push origin $tagName" -ForegroundColor Gray
} catch {
    Write-Host "⚠️  No se pudo crear tag de Git (repositorio no inicializado?)" -ForegroundColor Yellow
}

# Resumen final
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  ✅ VERSIÓN ACTUALIZADA" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "📦 Nueva versión: $newVersion" -ForegroundColor Cyan
Write-Host "🏷️  Git tag: $tagName" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Siguiente paso:" -ForegroundColor Cyan
Write-Host "   1. Commitea los cambios:" -ForegroundColor Yellow
Write-Host "      git add pubspec.yaml" -ForegroundColor Gray
Write-Host "      git commit -m 'Bump version to $newVersion'" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. Sube el tag a GitHub:" -ForegroundColor Yellow
Write-Host "      git push origin main" -ForegroundColor Gray
Write-Host "      git push origin $tagName" -ForegroundColor Gray
Write-Host ""
Write-Host "   3. Compila el release:" -ForegroundColor Yellow
Write-Host "      .\build_release.ps1 -Platform all" -ForegroundColor Gray
Write-Host ""
Write-Host "   4. Crea GitHub Release en:" -ForegroundColor Yellow
Write-Host "      https://github.com/SweetModels/sweet-models-enterprise/releases/new" -ForegroundColor Gray
Write-Host ""

# Mostrar changelog sugerido
Write-Host "📋 Changelog sugerido:" -ForegroundColor Cyan
Write-Host ""
Write-Host "## [$newVersion] - $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor Gray
Write-Host ""
Write-Host "### Added" -ForegroundColor Gray
Write-Host "- [Describe nuevas funcionalidades]" -ForegroundColor Gray
Write-Host ""
Write-Host "### Changed" -ForegroundColor Gray
Write-Host "- [Describe cambios en funcionalidades existentes]" -ForegroundColor Gray
Write-Host ""
Write-Host "### Fixed" -ForegroundColor Gray
Write-Host "- [Describe bugs corregidos]" -ForegroundColor Gray
Write-Host ""
