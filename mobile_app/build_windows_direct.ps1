# Compilador directo de Windows para Flutter sin usar flutter run

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║         Compilación Directa de App Flutter - Windows          ║
║                (Evitando problemas de CMake)                  ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

$projectPath = Get-Location
$mobilePath = $projectPath

Write-Host "`n📁 Proyecto: $mobilePath" -ForegroundColor Yellow
Write-Host "🔧 Compilador: Visual Studio 2026 (v18)`n" -ForegroundColor Yellow

# Paso 1: Limpiar build anterior
Write-Host "Step 1️⃣  - Limpiando build anterior..." -ForegroundColor Green
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Write-Host "✓ Build eliminado`n" -ForegroundColor Green

# Paso 2: Generar Dart Files
Write-Host "Step 2️⃣  - Generando archivos Dart..." -ForegroundColor Green
C:\flutter\bin\dart.bat pub get
Write-Host "✓ Dependencias de Dart descargadas`n" -ForegroundColor Green

# Paso 3: Generar archivos de Windows
Write-Host "Step 3️⃣  - Generando estructura de Windows..." -ForegroundColor Green
C:\flutter\bin\flutter.bat create . --platforms windows 2>&1 | Out-Null
Write-Host "✓ Archivos de Windows generados`n" -ForegroundColor Green

# Paso 4: Compilar con CMake y Visual Studio
Write-Host "Step 4️⃣  - Compilando con CMake..." -ForegroundColor Green

$cmakeArgs = @(
    "-B", "build",
    "-G", "Visual Studio 18 2024",
    "-A", "x64",
    "-DCMAKE_BUILD_TYPE=Debug",
    "-S", "windows"
)

Write-Host "  Ejecutando CMake..." -ForegroundColor Cyan
Write-Host "  cmake $($cmakeArgs -join ' ')" -ForegroundColor Gray

# Encontrar CMake
$cmake = "cmake"
if (!(Get-Command cmake -ErrorAction SilentlyContinue)) {
    # Buscar en Visual Studio
    $vsPath = "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
    if (Test-Path $vsPath) {
        $cmake = $vsPath
    } else {
        Write-Host "❌ CMake no encontrado!" -ForegroundColor Red
        Write-Host "Asegúrate de tener Visual Studio 2026 con CMake instalado" -ForegroundColor Yellow
        exit 1
    }
}

& $cmake @cmakeArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ CMake configurado`n" -ForegroundColor Green
    
    # Paso 5: Compilar con MSBuild
    Write-Host "Step 5️⃣  - Compilando con MSBuild..." -ForegroundColor Green
    
    $msbuild = "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"
    if (!(Test-Path $msbuild)) {
        Write-Host "Missing MSBuild" -ForegroundColor Red
        Exit 1
    }

    Write-Host "  Compilando..." -ForegroundColor Cyan
    & $msbuild "build\sweet_models_mobile.sln" /p:Configuration=Debug /p:Platform=x64 /verbosity:minimal
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nCompilation successful!`n" -ForegroundColor Green

        $appExe = "build\windows\Release\sweet_models_mobile.exe"
        $appDebugExe = "build\windows\Debug\sweet_models_mobile.exe"
        
        if (Test-Path $appDebugExe) {
            Write-Host "Step 6 - Running application..." -ForegroundColor Green
            Write-Host "  Starting: $appDebugExe`n" -ForegroundColor Cyan

            & $appDebugExe
        } elseif (Test-Path $appExe) {
            & $appExe
        } else {
            Write-Host "Warning: Application compiled but not found" -ForegroundColor Yellow
            Write-Host "Searching for executable..." -ForegroundColor Yellow
            Get-ChildItem "build" -Recurse -Filter "*.exe" | Select-Object -First 1 | ForEach-Object {
                Write-Host "Found: $_" -ForegroundColor Green
                & $_.FullName
            }
        }
    } else {
        Write-Host "`nMSBuild error" -ForegroundColor Red
        Write-Host "Verify Visual Studio 2026 installation" -ForegroundColor Yellow
        Exit 1
    }
} else {
    Write-Host "`nCMake error" -ForegroundColor Red
    Write-Host "Verify Visual Studio 2026 installation" -ForegroundColor Yellow
    Exit 1
}

Write-Host "`n════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
