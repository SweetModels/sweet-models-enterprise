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

    ,
    [Parameter(Mandatory=$false)]
    [switch]$UseStagingDir = $false,

    [Parameter(Mandatory=$false)]
    [string]$StagingDir = "C:\dev\sweet_models_build\mobile_app"
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

# Always run from the project root (script directory)
$OriginalRoot = $PSScriptRoot
Set-Location $OriginalRoot

$isOneDrivePath = $OriginalRoot -match "\\OneDrive\\"
if (-not $UseStagingDir -and $isOneDrivePath) {
    Write-Warning "⚠️  Proyecto dentro de OneDrive detectado: se usará un staging fuera de OneDrive para evitar locks."
    $UseStagingDir = $true
}

# Use a dedicated local Pub cache to avoid file locks/corruption (common on Windows with AV/OneDrive)
$defaultPubCache = "C:\dev\sweet_models_pub_cache"
if ($UseStagingDir) {
    $defaultPubCache = Join-Path $StagingDir ".pub-cache"
}
if (-not $env:PUB_CACHE -or [string]::IsNullOrWhiteSpace($env:PUB_CACHE)) {
    $env:PUB_CACHE = $defaultPubCache
}
New-Item -ItemType Directory -Force -Path $env:PUB_CACHE | Out-Null
Write-Info "📦 PUB_CACHE: $env:PUB_CACHE"

function Initialize-Staging {
    param(
        [Parameter(Mandatory=$true)][string]$SourceDir,
        [Parameter(Mandatory=$true)][string]$TargetDir
    )

    Write-Info "🧰 Preparando staging en: $TargetDir"
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

    $excludedDirs = @(
        (Join-Path $SourceDir "build"),
        (Join-Path $SourceDir ".dart_tool"),
        (Join-Path $SourceDir ".git"),
        (Join-Path $SourceDir ".idea"),
        (Join-Path $SourceDir ".vscode"),
        (Join-Path $SourceDir "windows\flutter\ephemeral"),
        (Join-Path $SourceDir "linux\flutter\ephemeral"),
        (Join-Path $SourceDir "android\.gradle"),
        (Join-Path $SourceDir "android\.cxx"),
        (Join-Path $SourceDir "android\app\build")
    )

    $robocopyArgs = @(
        $SourceDir,
        $TargetDir,
        "/MIR",
        "/R:2",
        "/W:1",
        "/NFL",
        "/NDL",
        "/NJH",
        "/NJS",
        "/NP",
        "/XD"
    ) + $excludedDirs

    & robocopy @robocopyArgs | Out-Null
    $rc = $LASTEXITCODE
    if ($rc -gt 7) {
        Write-Error "❌ Robocopy falló (código $rc)"
        exit 1
    }

    Set-Location $TargetDir
    Write-Success "✅ Staging listo"
}

function Copy-ArtifactsBack {
    param(
        [Parameter(Mandatory=$true)][string]$FromPath,
        [Parameter(Mandatory=$true)][string]$ToPath
    )

    if (-not $UseStagingDir) { return }
    if (-not (Test-Path $FromPath)) { return }

    $destDir = Split-Path -Parent $ToPath
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Copy-Item -Path $FromPath -Destination $ToPath -Force
}

function Copy-ArtifactsBackFolder {
    param(
        [Parameter(Mandatory=$true)][string]$FromGlob,
        [Parameter(Mandatory=$true)][string]$ToDir
    )

    if (-not $UseStagingDir) { return }
    New-Item -ItemType Directory -Force -Path $ToDir | Out-Null
    Get-ChildItem $FromGlob -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination (Join-Path $ToDir $_.Name) -Force
    }
}

function Get-VSInstallPath {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) { return $null }
    try {
        $path = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ([string]::IsNullOrWhiteSpace($path)) { return $null }
        return $path.Trim()
    } catch {
        return $null
    }
}

function Ensure-WindowsTooling {
    $cmake = Get-Command cmake -ErrorAction SilentlyContinue
    $ninja = Get-Command ninja -ErrorAction SilentlyContinue

    if ($cmake -and $ninja) { return }

    $vs = Get-VSInstallPath
    if (-not $vs) {
        Write-Warning "⚠️  No se encontró Visual Studio via vswhere; si falla Windows build, instala CMake o agrega cmake.exe al PATH."
        return
    }

    $vsCMakeBin = Join-Path $vs "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
    $vsNinjaBin = Join-Path $vs "Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja"

    if (-not $cmake -and (Test-Path (Join-Path $vsCMakeBin "cmake.exe"))) {
        $env:Path = "$vsCMakeBin;$env:Path"
        Write-Info "🧰 Agregado CMake de Visual Studio al PATH"
    }
    if (-not $ninja -and (Test-Path (Join-Path $vsNinjaBin "ninja.exe"))) {
        $env:Path = "$vsNinjaBin;$env:Path"
        Write-Info "🧰 Agregado Ninja de Visual Studio al PATH"
    }
}

function Get-VSGeneratorName {
    try {
        $help = & cmake --help 2>$null
        $line = $help | Select-String -Pattern "^\s*\*\s+Visual Studio\s+18" -CaseSensitive:$false | Select-Object -First 1
        if ($line) {
            $raw = ($line.Line -replace '^\s*\*\s+', '').Trim()
            # Typical format: "Visual Studio 18 2026        = Generates Visual Studio 2026 project files."
            if ($raw -match '^(Visual Studio\s+\d+\s+\d+)\b') {
                return $matches[1]
            }
            if ($raw -match '^(.*?)\s*=') {
                return $matches[1].Trim()
            }
            return $raw
        }
    } catch {
        # ignore
    }
    return $null
}

function Ensure-NuGet {
    $nuget = Get-Command nuget -ErrorAction SilentlyContinue
    if ($nuget) { return }

    $toolsRoot = Join-Path (Get-Location) ".tools"
    $nugetDir = Join-Path $toolsRoot "nuget"
    $nugetExe = Join-Path $nugetDir "nuget.exe"

    if (-not (Test-Path $nugetExe)) {
        New-Item -ItemType Directory -Force -Path $nugetDir | Out-Null
        $url = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
        Write-Info "⬇️  Descargando nuget.exe (necesario para algunos plugins Windows)..."
        try {
            Invoke-WebRequest -Uri $url -OutFile $nugetExe -UseBasicParsing -ErrorAction Stop
        } catch {
            Write-Warning "⚠️  No se pudo descargar nuget.exe automáticamente. Si falla CMake, instala NuGet o permite acceso a dist.nuget.org."
            return
        }
    }

    if (Test-Path $nugetExe) {
        $env:Path = "$nugetDir;$env:Path"
        Write-Info "🧰 Agregado nuget.exe al PATH"
    }
}

function Get-InnoSetupCompilerPath {
    $cmd = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
        return $cmd.Source
    }

    $candidates = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe"
    )

    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }

    # Try to discover installation path via registry (covers non-standard installs)
    $uninstallRoots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    foreach ($root in $uninstallRoots) {
        if (-not (Test-Path $root)) { continue }
        foreach ($key in (Get-ChildItem $root -ErrorAction SilentlyContinue)) {
            try {
                $p = Get-ItemProperty $key.PSPath -ErrorAction Stop
            } catch {
                continue
            }

            if (-not $p.DisplayName) { continue }
            if ($p.DisplayName -notlike "Inno Setup*") { continue }

            if ($p.InstallLocation) {
                $iscc = Join-Path $p.InstallLocation "ISCC.exe"
                if (Test-Path $iscc) { return $iscc }
            }

            if ($p.UninstallString -and ($p.UninstallString -match '"?([^"\r\n]+\\unins\d+\.exe)"?')) {
                $dir = Split-Path $matches[1] -Parent
                $iscc = Join-Path $dir "ISCC.exe"
                if (Test-Path $iscc) { return $iscc }
            }
        }
    }

    return $null
}

function Convert-ToInnoVersionInfo {
    param(
        [Parameter(Mandatory=$true)][string]$Version
    )

    # Inno Setup VersionInfoVersion must be numeric dotted, e.g. 1.2.3.4
    if ($Version -match '^(\d+)\.(\d+)\.(\d+)\+(\d+)$') {
        return "$($matches[1]).$($matches[2]).$($matches[3]).$($matches[4])"
    }
    if ($Version -match '^(\d+)\.(\d+)\.(\d+)$') {
        return "$($matches[1]).$($matches[2]).$($matches[3]).0"
    }

    # Fallback for unexpected version formats
    return "1.0.0.0"
}

function Patch-PrintingCMakeGenerator {
    param(
        [Parameter(Mandatory=$true)][string]$Generator
    )

    $file = "windows\flutter\ephemeral\.plugin_symlinks\printing\windows\DownloadProject.cmake"
    if (-not (Test-Path $file)) { return }

    $content = Get-Content $file -Raw
    $updated = $content
    $updated = $updated -replace "Visual Studio 17 2022", $Generator
    $updated = $updated -replace "Visual Studio 16 2019", $Generator
    $updated = $updated -replace "Visual Studio 15 2017", $Generator

    if ($updated -ne $content) {
        Set-Content -Path $file -Value $updated -Encoding UTF8
        Write-Success "✅ printing/windows: CMake generator actualizado a '$Generator'"
    }
}

function Patch-PrintingDownloadProjectGenerator {
    param(
        [Parameter(Mandatory=$true)][string]$Generator
    )

    $candidates = @()

    # Preferred: patch in PUB_CACHE so it applies before plugin symlinks are generated
    if ($env:PUB_CACHE) {
        $hosted = Join-Path $env:PUB_CACHE "hosted\pub.dev"
        if (Test-Path $hosted) {
            $printingDir = Get-ChildItem $hosted -Directory -Filter "printing-*" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($printingDir) {
                $candidates += Join-Path $printingDir.FullName "windows\DownloadProject.cmake"
            }
        }
    }

    # Also patch the ephemeral plugin symlink if it exists
    $candidates += "windows\flutter\ephemeral\.plugin_symlinks\printing\windows\DownloadProject.cmake"

    foreach ($file in $candidates | Select-Object -Unique) {
        if (-not (Test-Path $file)) { continue }

        $content = Get-Content $file -Raw
        $updated = $content

        # Force the nested download project's generator explicitly.
        $pattern = 'execute_process\(COMMAND \$\{CMAKE_COMMAND\} -G "\$\{CMAKE_GENERATOR\}"'
        $replacement = 'execute_process(COMMAND ${CMAKE_COMMAND} -G "' + $Generator + '"'
        $updated = $updated -replace $pattern, $replacement

        if ($updated -ne $content) {
            Set-Content -Path $file -Value $updated -Encoding UTF8
            Write-Success "✅ printing/windows: DownloadProject generator fijado a '$Generator'"
        }
    }
}

function New-WindowsPortableZip {
    param(
        [Parameter(Mandatory=$true)][string]$Version
    )

    $releaseDir = "build\windows\x64\runner\Release"
    if (-not (Test-Path $releaseDir)) {
        Write-Warning "⚠️  No se encontró el directorio Release de Windows para empaquetar ZIP portable: $releaseDir"
        return
    }

    $versionSafe = $Version -replace "\+", "_"
    $outDir = "build\windows\portable"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    $zipName = "sweet_models_mobile-windows-x64-v$versionSafe.zip"
    $zipPath = Join-Path $outDir $zipName

    if (Test-Path $zipPath) {
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
    }

    Write-Info "📦 Creando ZIP portable..."
    Compress-Archive -Path (Join-Path $releaseDir "*") -DestinationPath $zipPath -Force

    if (Test-Path $zipPath) {
        $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
        Write-Success "✅ Portable ZIP listo: $zipName ($zipSize MB)"

        # Copy artifact back to original workspace if building in staging
        Copy-ArtifactsBack -FromPath $zipPath -ToPath (Join-Path $OriginalRoot $zipPath)
    }
}

# Obtener versión del pubspec.yaml
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match 'version:\s+(\d+\.\d+\.\d+\+\d+)') {
    $version = $matches[1]
    Write-Info "📦 Versión detectada: $version"
} else {
    Write-Error "❌ No se pudo detectar la versión en pubspec.yaml"
    exit 1
}

# If enabled, move all build work to a staging directory outside OneDrive.
if ($UseStagingDir) {
    Initialize-Staging -SourceDir $OriginalRoot -TargetDir $StagingDir
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
    $keyPropsExists = Test-Path "android\app\keystore.properties"
    
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

        # Copy artifacts back to original workspace if building in staging
        Copy-ArtifactsBackFolder -FromGlob "build\app\outputs\flutter-apk\*.apk" -ToDir (Join-Path $OriginalRoot "build\app\outputs\flutter-apk")
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

        # Copy artifact back to original workspace if building in staging
        Copy-ArtifactsBack -FromPath "build\app\outputs\bundle\release\app-release.aab" -ToPath (Join-Path $OriginalRoot "build\app\outputs\bundle\release\app-release.aab")
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
    
    Ensure-WindowsTooling
    Ensure-NuGet

    # Force generator for new Visual Studio versions (avoids invalid generator like 'Visual Studio 18 2024')
    $vsGenerator = Get-VSGeneratorName
    if ($vsGenerator) {
        $env:CMAKE_GENERATOR = $vsGenerator
        $env:CMAKE_GENERATOR_PLATFORM = "x64"
        Write-Info "🧰 Usando CMAKE_GENERATOR='$vsGenerator'"
        Patch-PrintingDownloadProjectGenerator -Generator $vsGenerator
    }

    # Generar configuración primero (crea windows/flutter/ephemeral) para poder aplicar parches antes del build real
    Write-Info "🧩 Generando configuración (config-only)..."
    flutter build windows --release --config-only
    if ($LASTEXITCODE -ne 0) {
        # Workaround for CMake 4.x: Firebase C++ SDK still declares cmake_minimum_required(VERSION 3.1)
        $firebaseCMake = "build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"
        if (-not (Test-Path $firebaseCMake)) {
            $candidate = Get-ChildItem "build\windows" -Recurse -Filter "CMakeLists.txt" -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match "firebase_cpp_sdk_windows" } |
                Select-Object -First 1
            if ($candidate) { $firebaseCMake = $candidate.FullName }
        }

        if (Test-Path $firebaseCMake) {
            $raw = Get-Content $firebaseCMake -Raw
            if ($raw -match "cmake_minimum_required\(VERSION 3\.1\)") {
                Write-Warning "⚠️  Detectado Firebase C++ SDK con cmake_minimum_required(VERSION 3.1). Aplicando workaround para CMake 4.x..."
                $fixed = $raw -replace "cmake_minimum_required\(VERSION 3\.1\)", "cmake_minimum_required(VERSION 3.5)"
                Set-Content -Path $firebaseCMake -Value $fixed -Encoding UTF8

                Write-Info "🔁 Reintentando configuración (config-only)..."
                flutter build windows --release --config-only
            }
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Error "❌ Error al generar configuración de Windows"
            exit 1
        }
    }

    if ($vsGenerator) {
        Patch-PrintingCMakeGenerator -Generator $vsGenerator
    }

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

        # Copy artifact back to original workspace if building in staging
        Copy-ArtifactsBack -FromPath $exePath -ToPath (Join-Path $OriginalRoot $exePath)
    }

    # Empaquetado portable (ZIP) para distribución directa
    New-WindowsPortableZip -Version $version
    
    # Intentar compilar MSIX
    Write-Info ""
    Write-Info "🔨 Compilando MSIX (Microsoft Store)..."
    try {
        flutter pub run msix:create
        if ($LASTEXITCODE -eq 0) {
            Write-Success "✅ MSIX compilado exitosamente"
            if (Test-Path "build\windows\x64\runner\Release\sweet_models_mobile.msix") {
                $msixSize = [math]::Round((Get-Item "build\windows\x64\runner\Release\sweet_models_mobile.msix").Length / 1MB, 2)
                Write-Success "   • sweet_models_mobile.msix ($msixSize MB)"

                # Copy artifact back to original workspace if building in staging
                Copy-ArtifactsBack -FromPath "build\windows\x64\runner\Release\sweet_models_mobile.msix" -ToPath (Join-Path $OriginalRoot "build\windows\x64\runner\Release\sweet_models_mobile.msix")
            }
        }
    } catch {
        Write-Warning "⚠️  No se pudo compilar MSIX (requiere configuración adicional)"
    }
    
    # Intentar compilar instalador con Inno Setup
    Write-Info ""
    Write-Info "🔨 Compilando instalador EXE (Inno Setup)..."
    $innoPath = Get-InnoSetupCompilerPath
    
    if ($innoPath -and (Test-Path $innoPath)) {
        try {
            $innoVersionInfo = Convert-ToInnoVersionInfo -Version $version
            & $innoPath "/DMyAppVersion=$version" "/DMyAppVersionInfo=$innoVersionInfo" "installer_setup.iss"
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✅ Instalador EXE compilado exitosamente"
                $installerFiles = Get-ChildItem "build\windows\installer\" -Filter "*.exe"
                foreach ($file in $installerFiles) {
                    $size = [math]::Round($file.Length / 1MB, 2)
                    Write-Success "   • $($file.Name) ($size MB)"
                }

                # Copy artifacts back to original workspace if building in staging
                Copy-ArtifactsBackFolder -FromGlob "build\windows\installer\*.exe" -ToDir (Join-Path $OriginalRoot "build\windows\installer")
            } else {
                Write-Warning "⚠️  Inno Setup terminó con error (código $LASTEXITCODE). Revisa la salida arriba."
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
    Write-Info "   • Windows MSIX: build\windows\x64\runner\Release\"
    Write-Info "   • Windows Portable ZIP: build\windows\portable\"
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
