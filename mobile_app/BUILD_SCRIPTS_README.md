# 🚀 Scripts de Build y Release

Herramientas automatizadas para compilar y distribuir Sweet Models Enterprise.

## 📜 Scripts Disponibles

### 1️⃣ `setup_android_signing.ps1`
**Configuración inicial de firma para Android**

Genera el keystore necesario para firmar APKs/AABs de producción.

```powershell
.\setup_android_signing.ps1
```

**Lo que hace:**
- ✅ Verifica que keytool esté instalado
- ✅ Genera keystore RSA 2048-bit válido por 27 años
- ✅ Crea `android/key.properties` con credenciales
- ✅ Guarda backup de credenciales en `android/keystore_backup/`
- ✅ Actualiza `.gitignore` para proteger archivos sensibles
- ✅ Muestra instrucciones para modificar `build.gradle`

**⚠️ IMPORTANTE:** 
- Solo ejecuta UNA VEZ (al inicio del proyecto)
- Guarda el keystore en 3 lugares seguros
- Sin el keystore NO podrás actualizar la app en Google Play

---

### 2️⃣ `build_release.ps1`
**Compilador principal de releases**

Compila APKs, AABs, EXEs y MSIXs para distribución.

```powershell
# Compilar todo (Android + Windows)
.\build_release.ps1 -Platform all

# Solo Android
.\build_release.ps1 -Platform android

# Solo Windows
.\build_release.ps1 -Platform windows

# Con limpieza previa
.\build_release.ps1 -Platform all -Clean

# Sin ejecutar tests
.\build_release.ps1 -Platform all -SkipTests
```

**Parámetros:**
- `-Platform`: `android` | `windows` | `all` (default: `all`)
- `-Clean`: Limpia builds anteriores con `flutter clean`
- `-SkipTests`: Omite ejecución de tests

**Genera:**
- 📱 **Android:**
  - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~16-18 MB)
  - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (~15-17 MB)
  - `build/app/outputs/flutter-apk/app-x86_64-release.apk` (~17-19 MB)
  - `build/app/outputs/bundle/release/app-release.aab` (~17-20 MB)

- 🪟 **Windows:**
  - `build/windows/x64/runner/Release/sweet_models_mobile.exe`
  - `build/windows/runner/Release/sweet_models_mobile.msix` (~35-45 MB)
  - `build/windows/installer/SweetModelsEnterprise-Setup-1.0.0.exe` (~40-60 MB)

---

### 3️⃣ `bump_version.ps1`
**Actualizador de versiones**

Incrementa versión siguiendo Semantic Versioning (SemVer).

```powershell
# Incrementar build number (1.0.0+1 → 1.0.0+2)
.\bump_version.ps1 -BumpType build

# Incrementar patch (1.0.0 → 1.0.1) - Bug fixes
.\bump_version.ps1 -BumpType patch

# Incrementar minor (1.0.0 → 1.1.0) - Nuevas features
.\bump_version.ps1 -BumpType minor

# Incrementar major (1.0.0 → 2.0.0) - Breaking changes
.\bump_version.ps1 -BumpType major
```

**Lo que hace:**
- ✅ Lee versión actual de `pubspec.yaml`
- ✅ Incrementa según tipo especificado
- ✅ Actualiza `pubspec.yaml` e `installer_setup.iss`
- ✅ Crea tag de Git (`v1.0.1`)
- ✅ Muestra changelog sugerido

**Tipos de versión (SemVer):**
- `build`: Cambios internos, mismo código público
- `patch`: Correcciones de bugs (1.0.0 → 1.0.1)
- `minor`: Nuevas funcionalidades compatibles (1.0.0 → 1.1.0)
- `major`: Cambios incompatibles en API (1.0.0 → 2.0.0)

---

## 🔄 Workflow Completo

### Primera vez (Setup inicial):

```powershell
# 1. Configurar firma de Android (solo una vez)
.\setup_android_signing.ps1

# 2. Modificar android/app/build.gradle según instrucciones
code android\app\build.gradle

# 3. Compilar primera versión
.\build_release.ps1 -Platform all
```

### Releases subsecuentes:

```powershell
# 1. Hacer cambios en el código...
# 2. Incrementar versión
.\bump_version.ps1 -BumpType patch  # o minor/major

# 3. Commitear cambios
git add .
git commit -m "Bump version to 1.0.1"
git push origin main
git push origin v1.0.1

# 4. Compilar release
.\build_release.ps1 -Platform all

# 5. Crear GitHub Release con los archivos compilados
```

---

## 📁 Estructura de Archivos Generados

```
mobile_app/
├── build/
│   ├── app/outputs/
│   │   ├── flutter-apk/          # APKs split per ABI
│   │   └── bundle/release/       # AAB para Google Play
│   └── windows/
│       ├── x64/runner/Release/   # EXE sin instalador
│       ├── runner/Release/       # MSIX para Microsoft Store
│       └── installer/            # Instalador EXE con Inno Setup
│
├── android/
│   ├── app/upload-keystore.jks   # ⚠️ NO subir a Git
│   ├── key.properties            # ⚠️ NO subir a Git
│   └── keystore_backup/          # Backup de credenciales
│
├── build_release.ps1             # Script principal de build
├── setup_android_signing.ps1     # Generador de keystore
├── bump_version.ps1              # Actualizador de versiones
└── BUILD_RELEASE_GUIDE.md        # Documentación detallada
```

---

## ⚙️ Requisitos Previos

### Para Android:
- ✅ Flutter 3.24.5+ (`flutter --version`)
- ✅ Java JDK 11+ con keytool (`keytool -help`)
- ✅ Android SDK (`flutter doctor`)

### Para Windows:
- ✅ Flutter con soporte Windows (`flutter config --enable-windows-desktop`)
- ✅ Visual Studio 2022 con C++ desktop development
- ✅ (Opcional) Inno Setup 6 para instalador EXE:
  ```powershell
  winget install --id JRSoftware.InnoSetup
  ```

---

## 🐛 Troubleshooting

### "keytool: command not found"
```powershell
# Instalar Java JDK
winget install --id EclipseAdoptium.Temurin.11.JDK

# O descargar desde: https://adoptium.net/
```

### "Execution of scripts is disabled"
```powershell
# Permitir ejecución de scripts en PowerShell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### "Gradle task assembleRelease failed"
- Verifica que `android/key.properties` exista
- Verifica que `build.gradle` tenga la configuración de firma
- Revisa `BUILD_RELEASE_GUIDE.md` sección de troubleshooting

### "MSIX packaging failed"
- Verifica que `msix` esté en `pubspec.yaml` (dev_dependencies)
- Ejecuta `flutter pub get`
- Revisa configuración de `msix_config` en pubspec.yaml

### APK muy grande (>30MB)
- El script compila con `--split-per-abi` (genera 3 APKs separados)
- Cada APK es ~15-18MB (solo una arquitectura)
- El AAB automáticamente optimiza por dispositivo en Google Play

---

## 🔒 Seguridad

### ⚠️ NUNCA subir a Git:
- ❌ `android/app/upload-keystore.jks`
- ❌ `android/key.properties`
- ❌ `android/keystore_backup/CREDENTIALS_*.txt`

### ✅ Hacer backups en:
1. USB externo (físico, fuera de línea)
2. Cloud privado (Google Drive con 2FA)
3. Password manager (1Password/Bitwarden)

### 🔑 Si pierdes el keystore:
- ❌ **NO podrás actualizar la app en Google Play**
- ✅ Tendrás que publicar como nueva app (nuevo package name)
- ✅ Usuarios perderán datos si desinstalan

---

## 📊 Checklist de Release

Antes de distribuir, verifica:

- [ ] ✅ Tests pasan (`flutter test`)
- [ ] ✅ Versión incrementada en `pubspec.yaml`
- [ ] ✅ Git tag creado (`v1.0.1`)
- [ ] ✅ Changelog actualizado
- [ ] ✅ APKs firmados correctamente
- [ ] ✅ Builds probados en dispositivos reales
- [ ] ✅ URLs apuntan a producción (no localhost)
- [ ] ✅ Firebase configurado (si se usan notificaciones)
- [ ] ✅ Backups de keystore en 3 lugares
- [ ] ✅ GitHub Release creado con archivos
- [ ] ✅ Documentación actualizada

---

## 📚 Documentación Adicional

- **BUILD_RELEASE_GUIDE.md**: Guía completa paso a paso
- **NUEVAS_FUNCIONALIDADES.md**: Características implementadas
- **README.md**: Documentación principal del proyecto

---

## 💡 Tips

### Compilación rápida (solo debug):
```powershell
flutter build apk --debug
```

### Ver tamaño de APK:
```powershell
flutter build apk --analyze-size
```

### Probar en dispositivo conectado:
```powershell
flutter install
```

### Limpiar completamente (si hay problemas):
```powershell
flutter clean
flutter pub get
cd android
.\gradlew clean
cd ..
```

---

¿Dudas? Revisa **BUILD_RELEASE_GUIDE.md** para instrucciones detalladas.
