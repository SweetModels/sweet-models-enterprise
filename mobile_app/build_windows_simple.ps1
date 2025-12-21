param()

$ErrorActionPreference = 'Continue'

Write-Host "Cleaning build directory..." -ForegroundColor Green
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Getting Dart dependencies..." -ForegroundColor Green
& C:\flutter\bin\dart.bat pub get

Write-Host "Configuring CMake..." -ForegroundColor Green
& cmake -B build -G "Visual Studio 18 2024" -A x64 -S windows

if ($LASTEXITCODE -ne 0) {
    Write-Host "CMake failed" -ForegroundColor Red
    Exit 1
}

Write-Host "Building with MSBuild..." -ForegroundColor Green
$msbuild = "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"

if (!(Test-Path $msbuild)) {
    Write-Host "MSBuild not found" -ForegroundColor Red
    Exit 1
}

& $msbuild build\sweet_models_mobile.sln /p:Configuration=Debug /p:Platform=x64

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful!" -ForegroundColor Green
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    Exit 1
}
