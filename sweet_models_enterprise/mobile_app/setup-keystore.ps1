# Script de Configuración de Keystore para Android
# Sweet Models Enterprise

Write-Host "🔐 Configuración de Keystore para Google Play Store" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "android\app\upload-keystore.jks"
$keyPropertiesPath = "android\key.properties"

# Verificar si ya existe el keystore
if (Test-Path $keystorePath) {
    Write-Host "⚠️  Ya existe un keystore en: $keystorePath" -ForegroundColor Yellow
    $response = Read-Host "¿Deseas crear uno nuevo? (s/N)"
    if ($response -ne "s" -and $response -ne "S") {
        Write-Host "❌ Operación cancelada" -ForegroundColor Red
        exit 0
    }
    Remove-Item $keystorePath -Force
    Write-Host "✅ Keystore anterior eliminado" -ForegroundColor Green
}

Write-Host ""
Write-Host "📝 Por favor, proporciona la siguiente información:" -ForegroundColor Yellow
Write-Host ""

# Solicitar información
$storePassword = Read-Host "Password del keystore (guárdalo en un lugar seguro)" -AsSecureString
$storePasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword)
)

$keyPassword = Read-Host "Password del key alias (usa el mismo que arriba)" -AsSecureString
$keyPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword)
)

$nombre = Read-Host "Nombre completo (ej: Sweet Models Enterprise)"
$unidad = Read-Host "Unidad organizativa (ej: Development Team)"
$organizacion = Read-Host "Organización (ej: Sweet Models)"
$ciudad = Read-Host "Ciudad"
$estado = Read-Host "Estado/Provincia"
$pais = Read-Host "Código de país (ej: CO, US, ES)"

Write-Host ""
Write-Host "🔨 Generando keystore..." -ForegroundColor Yellow

# Generar el keystore
$dname = "CN=$nombre, OU=$unidad, O=$organizacion, L=$ciudad, ST=$estado, C=$pais"

$keytoolCmd = "keytool -genkey -v -keystore `"$keystorePath`" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload -dname `"$dname`" -storepass `"$storePasswordPlain`" -keypass `"$keyPasswordPlain`""

try {
    Invoke-Expression $keytoolCmd | Out-Null
    
    if (Test-Path $keystorePath) {
        Write-Host "✅ Keystore generado exitosamente: $keystorePath" -ForegroundColor Green
    } else {
        throw "No se pudo generar el keystore"
    }
} catch {
    Write-Host "❌ Error al generar el keystore: $_" -ForegroundColor Red
    exit 1
}

# Crear el archivo key.properties
Write-Host ""
Write-Host "📝 Creando archivo key.properties..." -ForegroundColor Yellow

$keyPropertiesContent = @"
storePassword=$storePasswordPlain
keyPassword=$keyPasswordPlain
keyAlias=upload
storeFile=upload-keystore.jks
"@

try {
    $keyPropertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding ASCII
    Write-Host "✅ Archivo key.properties creado: $keyPropertiesPath" -ForegroundColor Green
} catch {
    Write-Host "❌ Error al crear key.properties: $_" -ForegroundColor Red
    exit 1
}

# Agregar al .gitignore si no está
$gitignorePath = "android\.gitignore"
if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath
    if ($gitignoreContent -notcontains "key.properties") {
        Add-Content -Path $gitignorePath -Value "`nkey.properties"
        Write-Host "✅ key.properties agregado a .gitignore" -ForegroundColor Green
    }
    if ($gitignoreContent -notcontains "*.jks") {
        Add-Content -Path $gitignorePath -Value "*.jks"
        Write-Host "✅ *.jks agregado a .gitignore" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "✅ CONFIGURACIÓN COMPLETADA" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  IMPORTANTE: Guarda estos archivos de forma segura:" -ForegroundColor Yellow
Write-Host "   - $keystorePath" -ForegroundColor White
Write-Host "   - $keyPropertiesPath" -ForegroundColor White
Write-Host ""
Write-Host "🔒 Passwords configurados:" -ForegroundColor Yellow
Write-Host "   Store Password: $storePasswordPlain" -ForegroundColor White
Write-Host "   Key Password: $keyPasswordPlain" -ForegroundColor White
Write-Host ""
Write-Host "📝 Guarda esta información en un lugar seguro (1Password, LastPass, etc.)" -ForegroundColor Yellow
Write-Host ""
Write-Host "🚀 Siguiente paso: Generar el build de producción" -ForegroundColor Cyan
Write-Host "   flutter build appbundle --release" -ForegroundColor White
Write-Host ""
