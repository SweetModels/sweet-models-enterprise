# Script para instalar lucide-react
$projectPath = "C:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise\sweet-models-web"

# Obtener la ruta de npm desde node.js
$nodePath = (Get-Command node -ErrorAction SilentlyContinue).Source
if (-not $nodePath) {
    Write-Host "Node.js no encontrado. Buscando en Program Files..." -ForegroundColor Yellow
    $nodePath = "C:\Program Files\nodejs\node.exe"
}

# Obtener directorio de npm
$npmPath = $nodePath.Replace("node.exe", "npm")
if ($npmPath -like "*node.exe*") {
    $npmPath = $npmPath.Replace("node.exe", "npm.cmd")
}

Write-Host "Ruta de npm: $npmPath" -ForegroundColor Cyan

# Cambiar al directorio del proyecto
Set-Location $projectPath
Write-Host "Directorio: $(Get-Location)" -ForegroundColor Cyan

# Instalar lucide-react
Write-Host "Instalando lucide-react..." -ForegroundColor Green
& $npmPath install lucide-react

Write-Host "✅ Instalación completada" -ForegroundColor Green
Write-Host "Los iconos de lucide-react ya están disponibles en tu proyecto" -ForegroundColor Green
