# ========================================
# Sweet Models Enterprise
# Configuración de firma para Android
# Version: 2.0 - Actualizado 2025-12-06
# ========================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  🔐 Configuración de Firma Android        " -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

# Verificar Java/keytool
Write-Host "🔍 Verificando keytool..." -ForegroundColor Cyan
try {
    keytool -help 2>&1 | Out-Null
    Write-Host "✅ keytool encontrado" -ForegroundColor Green
} catch {
    Write-Host "❌ keytool no encontrado" -ForegroundColor Red
    Write-Host "   Instala Java JDK desde: https://adoptium.net/" -ForegroundColor Yellow
    exit 1
}

# Verificar si ya existe keystore
$keystorePath = "android\app\upload-keystore.jks"
$keyPropsPath = "android\key.properties"

if (Test-Path $keystorePath) {
    Write-Host ""
    Write-Host "⚠️  ADVERTENCIA: Ya existe un keystore en:" -ForegroundColor Yellow
    Write-Host "   $keystorePath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Si lo regeneras, NO PODRÁS actualizar la app en Google Play" -ForegroundColor Red
    Write-Host "   con tu keystore anterior." -ForegroundColor Red
    Write-Host ""
    $continue = Read-Host "¿Continuar y sobrescribir? (S/N)"
    if ($continue -ne "S" -and $continue -ne "s") {
        Write-Host "❌ Cancelado por el usuario" -ForegroundColor Yellow
        exit 0
    }
}

# Solicitar información para el certificado
Write-Host ""
Write-Host "📝 Ingresa la información para el certificado:" -ForegroundColor Cyan
Write-Host ""

$storePassword = Read-Host "Password del keystore (mínimo 6 caracteres)" -AsSecureString
$keyPassword = Read-Host "Password de la key (puede ser el mismo)" -AsSecureString
$alias = Read-Host "Alias de la key (ej: upload)"
$name = Read-Host "Tu nombre completo (ej: Juan Perez)"
$orgUnit = Read-Host "Unidad organizacional (ej: Development)"
$org = Read-Host "Organización (ej: Sweet Models Enterprise)"
$city = Read-Host "Ciudad (ej: Bogotá)"
$state = Read-Host "Departamento/Estado (ej: Cundinamarca)"
$country = Read-Host "Código de país (2 letras, ej: CO)"

# Convertir SecureString a texto plano para keytool
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword)
$storePasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword)
$keyPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)

# Crear directorio si no existe
New-Item -ItemType Directory -Path "android\app" -Force | Out-Null

# Generar keystore
Write-Host ""
Write-Host "🔨 Generando keystore..." -ForegroundColor Cyan
Write-Host ""

$dname = "CN=$name, OU=$orgUnit, O=$org, L=$city, ST=$state, C=$country"

$keytoolCommand = "keytool -genkey -v -keystore `"$keystorePath`" " +
                  "-keyalg RSA -keysize 2048 -validity 10000 " +
                  "-alias `"$alias`" " +
                  "-dname `"$dname`" " +
                  "-storepass `"$storePasswordPlain`" " +
                  "-keypass `"$keyPasswordPlain`""

try {
    Invoke-Expression $keytoolCommand 2>&1 | Out-Null
    
    if (Test-Path $keystorePath) {
        Write-Host "✅ Keystore generado exitosamente" -ForegroundColor Green
    } else {
        throw "No se generó el archivo keystore"
    }
} catch {
    Write-Host "❌ Error al generar keystore: $_" -ForegroundColor Red
    exit 1
}

# Crear key.properties
Write-Host ""
Write-Host "📝 Creando key.properties..." -ForegroundColor Cyan

$keyPropsContent = @"
storePassword=$storePasswordPlain
keyPassword=$keyPasswordPlain
keyAlias=$alias
storeFile=../app/upload-keystore.jks
"@

New-Item -ItemType Directory -Path "android" -Force | Out-Null
Set-Content -Path $keyPropsPath -Value $keyPropsContent -Encoding UTF8

Write-Host "✅ key.properties creado" -ForegroundColor Green

# Verificar/Modificar build.gradle
Write-Host ""
Write-Host "🔧 Configurando build.gradle..." -ForegroundColor Cyan

$buildGradlePath = "android\app\build.gradle"
$buildGradleContent = Get-Content $buildGradlePath -Raw

# Verificar si ya tiene la configuración
if ($buildGradleContent -match "keystoreProperties") {
    Write-Host "✅ build.gradle ya está configurado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Necesitas modificar manualmente build.gradle" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Agrega ANTES de 'android {' esto:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   def keystoreProperties = new Properties()" -ForegroundColor Gray
    Write-Host "   def keystorePropertiesFile = rootProject.file('key.properties')" -ForegroundColor Gray
    Write-Host "   if (keystorePropertiesFile.exists()) {" -ForegroundColor Gray
    Write-Host "       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))" -ForegroundColor Gray
    Write-Host "   }" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Y dentro de 'buildTypes {' cambia 'release {' a:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   release {" -ForegroundColor Gray
    Write-Host "       signingConfig signingConfigs.release" -ForegroundColor Gray
    Write-Host "   }" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Y agrega DESPUÉS de 'buildTypes {' pero dentro de 'android {' esto:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   signingConfigs {" -ForegroundColor Gray
    Write-Host "       release {" -ForegroundColor Gray
    Write-Host "           keyAlias keystoreProperties['keyAlias']" -ForegroundColor Gray
    Write-Host "           keyPassword keystoreProperties['keyPassword']" -ForegroundColor Gray
    Write-Host "           storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null" -ForegroundColor Gray
    Write-Host "           storePassword keystoreProperties['storePassword']" -ForegroundColor Gray
    Write-Host "       }" -ForegroundColor Gray
    Write-Host "   }" -ForegroundColor Gray
    Write-Host ""
}

# Guardar credenciales de forma segura
Write-Host ""
Write-Host "💾 Guardando backup de credenciales..." -ForegroundColor Cyan

$backupDir = "android\keystore_backup"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$credentialsContent = @"
==================================================
SWEET MODELS ENTERPRISE - CREDENCIALES DE FIRMA
==================================================

⚠️  GUARDA ESTE ARCHIVO EN UN LUGAR SEGURO ⚠️
   Sin estas credenciales NO podrás actualizar la app en Google Play

Fecha de creación: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

INFORMACIÓN DE LA KEY:
----------------------
Keystore Password: $storePasswordPlain
Key Password: $keyPasswordPlain
Alias: $alias
Validity: 10000 días (~27 años)

UBICACIÓN DEL KEYSTORE:
-----------------------
$keystorePath

INFORMACIÓN DEL CERTIFICADO:
----------------------------
CN (Common Name): $name
OU (Organizational Unit): $orgUnit
O (Organization): $org
L (Locality): $city
ST (State): $state
C (Country): $country

BACKUPS RECOMENDADOS:
---------------------
1. Copia upload-keystore.jks a 3 lugares seguros:
   - USB externo
   - Cloud privado (Google Drive/Dropbox)
   - Password manager (1Password/Bitwarden)

2. Guarda este archivo de credenciales junto con el keystore

3. NO subas el keystore ni este archivo a Git/GitHub

VERIFICACIÓN:
-------------
Para verificar el keystore:
keytool -list -v -keystore android\app\upload-keystore.jks -alias $alias

==================================================
"@

$credentialsFile = Join-Path $backupDir "CREDENTIALS_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Set-Content -Path $credentialsFile -Value $credentialsContent -Encoding UTF8

Write-Host "✅ Credenciales guardadas en:" -ForegroundColor Green
Write-Host "   $credentialsFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "   ⚠️  CÓPIALO A UN LUGAR SEGURO AHORA ⚠️" -ForegroundColor Red
Write-Host ""

# Agregar al .gitignore
Write-Host "🔒 Actualizando .gitignore..." -ForegroundColor Cyan

$gitignorePath = ".gitignore"
$gitignoreContent = if (Test-Path $gitignorePath) { Get-Content $gitignorePath -Raw } else { "" }

$linesToAdd = @"

# Android Signing
android/key.properties
android/app/upload-keystore.jks
android/keystore_backup/
*.jks
*.keystore
"@

if ($gitignoreContent -notmatch "upload-keystore.jks") {
    Add-Content -Path $gitignorePath -Value $linesToAdd -Encoding UTF8
    Write-Host "✅ .gitignore actualizado" -ForegroundColor Green
} else {
    Write-Host "✅ .gitignore ya contiene las exclusiones" -ForegroundColor Green
}

# Resumen final
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  ✅ CONFIGURACIÓN COMPLETADA" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "📁 Archivos creados:" -ForegroundColor Cyan
Write-Host "   ✅ $keystorePath" -ForegroundColor Green
Write-Host "   ✅ $keyPropsPath" -ForegroundColor Green
Write-Host "   ✅ $credentialsFile" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Siguiente paso:" -ForegroundColor Cyan
Write-Host "   1. Modifica android\app\build.gradle (ver instrucciones arriba)" -ForegroundColor Yellow
Write-Host "   2. Ejecuta: .\build_release.ps1 -Platform android" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔒 IMPORTANTE:" -ForegroundColor Red
Write-Host "   • Copia el keystore a 3 lugares seguros AHORA" -ForegroundColor Red
Write-Host "   • Guarda las credenciales en un password manager" -ForegroundColor Red
Write-Host "   • NUNCA subas el keystore a Git/GitHub" -ForegroundColor Red
Write-Host ""
