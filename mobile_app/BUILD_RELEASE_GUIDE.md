# 🚀 Guía de Release - Sweet Models Enterprise

## 📌 Versión Actual: 1.0.0+1

---

## 1️⃣ PREPARACIÓN PRE-BUILD

### Actualizar versión en `pubspec.yaml`

**Ubicación:** Línea 19 del archivo `pubspec.yaml`

```yaml
version: 1.0.0+1
# Formato: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

**Reglas de versionado semántico:**
- **MAJOR (1.x.x)**: Cambios incompatibles con versiones anteriores
- **MINOR (x.1.x)**: Nuevas funcionalidades compatibles
- **PATCH (x.x.1)**: Correcciones de bugs
- **BUILD (+1)**: Incrementa en cada compilación

**Ejemplos:**
- Primera release pública: `1.0.0+1`
- Hotfix: `1.0.1+2`
- Nueva funcionalidad: `1.1.0+3`
- Breaking changes: `2.0.0+10`

---

## 2️⃣ BUILD ANDROID (APK/AAB)

### Paso 1: Generar Keystore (Solo primera vez)

**⚠️ IMPORTANTE: Guarda el keystore y las contraseñas de forma segura. Sin ellos NO podrás actualizar la app en Google Play.**

```powershell
# Navegar al directorio del proyecto
cd "C:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app\android\app"

# Generar keystore (Java keytool)
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Te pedirá:
# 1. Contraseña del keystore (mínimo 6 caracteres) - GUÁRDALA
# 2. Nombre y apellido (puede ser el nombre de tu empresa)
# 3. Unidad organizativa (opcional)
# 4. Organización: Sweet Models Enterprise
# 5. Ciudad: Bogotá (o tu ciudad)
# 6. Departamento: Cundinamarca (o tu región)
# 7. Código país: CO
# 8. Contraseña de la key (puede ser la misma) - GUÁRDALA
```

**Resultado esperado:**
```
Generando par de claves RSA de 2048 bits y certificado autofirmado (SHA256withRSA) con una validez de 10000 días
        para: CN=Sweet Models Enterprise, OU=Development, O=Sweet Models, L=Bogotá, ST=Cundinamarca, C=CO
[Storing upload-keystore.jks]
```

### Paso 2: Crear `key.properties`

```powershell
# Crear archivo key.properties en android/
cd "C:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app\android"

# Crear archivo (PowerShell)
@"
storePassword=TU_CONTRASEÑA_KEYSTORE
keyPassword=TU_CONTRASEÑA_KEY
keyAlias=upload
storeFile=../app/upload-keystore.jks
"@ | Out-File -FilePath key.properties -Encoding UTF8
```

**⚠️ NUNCA subas `key.properties` ni `upload-keystore.jks` a Git.**

Verifica que estén en `.gitignore`:
```
android/key.properties
android/app/upload-keystore.jks
```

### Paso 3: Configurar `build.gradle` (Android signing)

Edita `android/app/build.gradle`:

```gradle
// ANTES de android { ... }, agrega:
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... código existente ...
    
    // Agrega esta sección ANTES de buildTypes
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release  // 👈 AGREGAR ESTA LÍNEA
            // ... resto del código ...
        }
    }
}
```

### Paso 4: Compilar APK Release

```powershell
# Navegar a mobile_app
cd "C:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app"

# Limpiar builds anteriores
flutter clean
flutter pub get

# Compilar APK (ARM + ARM64 + x86_64)
flutter build apk --release

# O compilar APK por arquitectura (más ligero)
flutter build apk --release --split-per-abi
```

**Salida esperada:**
```
✓ Built build\app\outputs\flutter-apk\app-release.apk (18.5MB)
```

**Si usaste --split-per-abi:**
```
✓ Built build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk (15.2MB)
✓ Built build\app\outputs\flutter-apk\app-arm64-v8a-release.apk (16.8MB)
✓ Built build\app\outputs\flutter-apk\app-x86_64-release.apk (17.1MB)
```

### Paso 5: Compilar AAB (Google Play Store)

```powershell
# AAB (Android App Bundle) - RECOMENDADO para Play Store
flutter build appbundle --release

# Salida: build\app\outputs\bundle\release\app-release.aab
```

**Ventajas del AAB:**
- Google Play genera APKs optimizados por dispositivo
- Reduce tamaño de descarga (~35% menos)
- Requerido para apps nuevas en Play Store desde 2021

---

## 3️⃣ BUILD WINDOWS (EXE/MSIX)

### Opción A: MSIX (Recomendado - Microsoft Store)

#### Paso 1: Instalar herramientas

```powershell
# Verificar que tengas el SDK de Windows
flutter doctor -v

# Instalar dependencia MSIX
flutter pub add msix
flutter pub get
```

#### Paso 2: Configurar `pubspec.yaml`

Ya tienes `msix: ^3.16.12` instalado. Agrega configuración:

```yaml
msix_config:
  display_name: Sweet Models Enterprise
  publisher_display_name: Sweet Models
  identity_name: com.sweetmodels.enterprise
  msix_version: 1.0.0.0  # Debe ser X.X.X.X
  logo_path: assets\images\logo.png  # Icono 256x256 PNG
  capabilities: internetClient
  languages: en-us, es-co, pt-br
  publisher: CN=Sweet Models Enterprise  # Certificado de firma
```

#### Paso 3: Compilar MSIX

```powershell
# Navegar a mobile_app
cd "C:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app"

# Limpiar y compilar
flutter clean
flutter pub get

# Compilar Windows Release
flutter build windows --release

# Generar MSIX (instalador Microsoft Store)
flutter pub run msix:create

# Salida: build\windows\runner\Release\sweet_models_mobile.msix
```

**Características del MSIX:**
- ✅ Instalación con un clic
- ✅ Actualizaciones automáticas
- ✅ Desinstalación limpia
- ✅ Compatible con Microsoft Store
- ✅ Firma digital automática (desarrollo)

### Opción B: Inno Setup (EXE tradicional con asistente)

#### Paso 1: Instalar Inno Setup

```powershell
# Descargar desde: https://jrsoftware.org/isdl.php
# O con winget:
winget install --id JRSoftware.InnoSetup

# Verificar instalación
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" /? 
```

#### Paso 2: Compilar Flutter Windows

```powershell
cd "C:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app"

flutter clean
flutter pub get

# Compilar release
flutter build windows --release

# Archivos en: build\windows\x64\runner\Release\
```

#### Paso 3: Crear script Inno Setup

Crea `installer_setup.iss` en la raíz de `mobile_app`:

```ini
[Setup]
AppName=Sweet Models Enterprise
AppVersion=1.0.0
AppPublisher=Sweet Models
AppPublisherURL=https://github.com/SweetModels/sweet-models-enterprise
DefaultDirName={autopf}\Sweet Models Enterprise
DefaultGroupName=Sweet Models Enterprise
OutputDir=build\windows\installer
OutputBaseFilename=SweetModelsEnterprise-Setup-1.0.0
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
SetupIconFile=assets\images\icon.ico
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "portuguesebrazilian"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Sweet Models Enterprise"; Filename: "{app}\sweet_models_mobile.exe"
Name: "{autodesktop}\Sweet Models Enterprise"; Filename: "{app}\sweet_models_mobile.exe"; Tasks: desktopicon
Name: "{group}\Uninstall Sweet Models Enterprise"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\sweet_models_mobile.exe"; Description: "Launch Sweet Models Enterprise"; Flags: nowait postinstall skipifsilent
```

#### Paso 4: Compilar instalador

```powershell
# Ejecutar compilador Inno Setup
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer_setup.iss

# Salida: build\windows\installer\SweetModelsEnterprise-Setup-1.0.0.exe (40-60 MB)
```

**Características del EXE (Inno Setup):**
- ✅ Asistente de instalación profesional
- ✅ Multi-idioma (EN, ES, PT)
- ✅ Opción de icono en escritorio
- ✅ Desinstalador incluido
- ✅ Instalación en Program Files
- ✅ Detección de versión previa
- ✅ Compresión LZMA2 (~50% reducción)

---

## 4️⃣ COMANDOS RÁPIDOS (CHEAT SHEET)

### Android APK
```powershell
cd mobile_app
flutter clean && flutter pub get
flutter build apk --release --split-per-abi
# Salida: build\app\outputs\flutter-apk\
```

### Android AAB (Google Play)
```powershell
cd mobile_app
flutter clean && flutter pub get
flutter build appbundle --release
# Salida: build\app\outputs\bundle\release\app-release.aab
```

### Windows MSIX
```powershell
cd mobile_app
flutter clean && flutter pub get
flutter build windows --release
flutter pub run msix:create
# Salida: build\windows\runner\Release\*.msix
```

### Windows EXE (Inno Setup)
```powershell
cd mobile_app
flutter clean && flutter pub get
flutter build windows --release
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer_setup.iss
# Salida: build\windows\installer\*.exe
```

---

## 5️⃣ VERIFICACIÓN DE BUILDS

### Android
```powershell
# Verificar firma del APK
keytool -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk

# Ver información del APK
# Instala APK Analyzer o usa Android Studio > Build > Analyze APK
```

### Windows
```powershell
# Verificar archivos compilados
dir build\windows\x64\runner\Release\

# Debe contener:
# - sweet_models_mobile.exe
# - data\*
# - flutter_windows.dll
# - Archivos .dll de plugins
```

---

## 6️⃣ TAMAÑOS ESPERADOS

| Build | Tamaño aproximado |
|-------|-------------------|
| APK (universal) | 18-25 MB |
| APK (arm64-v8a) | 16-18 MB |
| APK (armeabi-v7a) | 15-17 MB |
| AAB | 17-20 MB |
| Windows MSIX | 35-45 MB |
| Windows EXE (Inno) | 40-60 MB |
| Windows portable | 50-70 MB |

---

## 7️⃣ DISTRIBUCIÓN

### Android
- **APK directo**: Subir a servidor web o enviar por email
- **Google Play Store**: Subir AAB a Play Console
- **Firebase App Distribution**: Para beta testers
- **APKPure/APKMirror**: Distribución alternativa

### Windows
- **MSIX**: Microsoft Store o instalación local
- **EXE**: Hosting en web, GitHub Releases, OneDrive
- **Portable**: Carpeta Release\ zipeada (sin instalador)

---

## 8️⃣ SEGURIDAD Y BACKUPS

### ⚠️ CRÍTICO - GUARDAR DE FORMA SEGURA:

```
📁 BACKUPS OBLIGATORIOS:
├── android/app/upload-keystore.jks  (archivo binario)
├── android/key.properties            (contraseñas)
├── keystore_credentials.txt          (backup de contraseñas)
└── signing_certificate.pem           (para Windows firmado)

🔒 ALMACENAMIENTO RECOMENDADO:
- Password manager (1Password, Bitwarden)
- Bóveda cifrada (VeraCrypt)
- USB cifrado (offline backup)
- Azure Key Vault / AWS Secrets Manager (empresas)
```

### Crear backup de credenciales

```powershell
# Crear archivo de backup de credenciales
cd "C:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app"

@"
===============================
SWEET MODELS ENTERPRISE - CREDENTIALS
===============================

ANDROID KEYSTORE:
-----------------
Archivo: upload-keystore.jks
Ubicación: android/app/upload-keystore.jks
Alias: upload
Keystore Password: [TU_CONTRASEÑA_AQUÍ]
Key Password: [TU_CONTRASEÑA_AQUÍ]
Validez: 10000 días (hasta ~2052)
Algoritmo: RSA 2048 bits

WINDOWS SIGNING:
----------------
Certificado: [Si aplica]
Thumbprint: [Si aplica]

NOTAS:
------
- Fecha de creación: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
- Sin estos archivos NO se pueden publicar actualizaciones
- Guardar en 3 lugares seguros diferentes
- No compartir públicamente

===============================
"@ | Out-File -FilePath KEYSTORE_BACKUP_CREDENTIALS.txt -Encoding UTF8

Write-Host "✅ Archivo de backup creado: KEYSTORE_BACKUP_CREDENTIALS.txt"
Write-Host "⚠️  COMPLETA LAS CONTRASEÑAS Y GUÁRDALO DE FORMA SEGURA"
```

---

## 9️⃣ TROUBLESHOOTING

### Error: "keytool no reconocido"
```powershell
# Agregar Java al PATH
$env:Path += ";C:\Program Files\Java\jdk-17\bin"
# O instalar Java JDK desde adoptium.net
```

### Error: "Gradle build failed"
```powershell
cd android
.\gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Error: MSIX firma inválida
```powershell
# En desarrollo, Windows acepta certificados autofirmados
# Para producción, comprar certificado de firma de código
```

### APK muy grande
```powershell
# Usar split-per-abi (reduce ~30%)
flutter build apk --release --split-per-abi

# Analizar qué ocupa espacio
flutter build apk --analyze-size
```

---

## 🎯 CHECKLIST FINAL

Antes de distribuir, verifica:

- [ ] Versión actualizada en `pubspec.yaml`
- [ ] Keystore y credenciales guardados en 3 lugares
- [ ] APK firmado correctamente (verificado con keytool)
- [ ] App probada en dispositivo real (no emulador)
- [ ] Iconos y splash screen configurados
- [ ] Permisos Android configurados en AndroidManifest.xml
- [ ] Nombre de app correcto en todos los idiomas
- [ ] URLs de API apuntan a producción (no localhost)
- [ ] Firebase configurado (si aplica)
- [ ] Logs de debug desactivados
- [ ] Certificados SSL válidos
- [ ] README actualizado con versión
- [ ] CHANGELOG.md creado con cambios
- [ ] Tag de Git creado (`git tag v1.0.0`)
- [ ] Build subido a GitHub Releases

---

**¡Listo para compilar! Ejecuta los comandos según tu plataforma objetivo.** 🚀
