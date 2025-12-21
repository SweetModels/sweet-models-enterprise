# Sweet Models Enterprise - Guía de Publicación Android

## ✅ Configuración Completada

### 1. Package Name
- **ID de aplicación**: `com.sweetmodels.app`
- **Namespace**: `com.sweetmodels.app`
- **MainActivity**: `com/sweetmodels/app/MainActivity.kt`

### 2. Firebase Configurado
- `firebase_core`, `firebase_auth`, `firebase_database`, `cloud_firestore`, `firebase_messaging`
- Inicialización automática en Android
- Permisos de notificaciones solicitados

### 3. Gradle Actualizado
- **Android Gradle Plugin**: 8.7.2
- **Gradle**: 8.9
- **Kotlin**: 2.0.21
- **Google Services Plugin**: 4.4.0

### 4. ProGuard Rules
- Reglas creadas en `android/app/proguard-rules.pro`
- Configurado para minificación y shrinkResources en Release

### 5. Keystore (Firma)
- Archivo: `android/app/keystore.properties`
- Credenciales configuradas (cambiar para producción)

---

## ⚠️ Pasos Pendientes ANTES de Publicar

### 1. **Aceptar Licencias de Android SDK**

El build falló porque necesitas aceptar las licencias del NDK. Ejecuta:

```powershell
# Buscar sdkmanager
$sdkPath = "C:\Users\Sweet\AppData\Local\Android\Sdk"
$sdkManager = Get-ChildItem "$sdkPath" -Recurse -Filter "sdkmanager.bat" | Select-Object -First 1

# Aceptar licencias
if ($sdkManager) {
    & $sdkManager.FullName --licenses
    # Presiona 'y' para cada licencia
} else {
    Write-Host "Instala Android Studio y acepta licencias desde SDK Manager"
}
```

**Alternativa**: Abre Android Studio → Settings → SDK Manager → SDK Tools → Acepta licencias.

### 2. **Generar Keystore de Producción**

El keystore actual usa credenciales temporales. Para producción:

```powershell
cd "android\app"

# Generar keystore de producción (guardar contraseñas en lugar seguro!)
keytool -genkey -v -keystore upload-keystore.jks `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias upload `
  -storepass TU_CONTRASEÑA_SEGURA `
  -keypass TU_CONTRASEÑA_SEGURA `
  -dname "CN=Sweet Models Enterprise, OU=Mobile, O=Sweet Models, L=Ciudad, ST=Estado, C=MX"

# Actualizar android/app/keystore.properties:
# storePassword=TU_CONTRASEÑA_SEGURA
# keyPassword=TU_CONTRASEÑA_SEGURA
# keyAlias=upload
# storeFile=upload-keystore.jks
```

⚠️ **IMPORTANTE**: Guarda el keystore y contraseñas en un lugar seguro. Si lo pierdes, NO podrás actualizar la app en Play Store.

### 3. **Configurar Firebase con Package Correcto**

En Firebase Console:
1. Actualiza/agrega la app Android con package `com.sweetmodels.app`
2. Descarga el nuevo `google-services.json`
3. Colócalo en `android/app/google-services.json`

### 4. **Actualizar App Icons y Name**

```powershell
# Cambiar nombre en AndroidManifest.xml
# android:label="Sweet Models"

# Generar iconos para Android (usa https://appicon.co/)
# Coloca en: android/app/src/main/res/mipmap-*/ic_launcher.png
```

### 5. **Build de Prueba**

```powershell
cd "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise\mobile_app"

# Limpiar
flutter clean
flutter pub get

# Build Debug APK
flutter build apk --debug

# Build Release APK (para pruebas)
flutter build apk --release

# Build App Bundle (para publicar en Play Store)
flutter build appbundle --release
```

El AAB (Android App Bundle) estará en:
`build/app/outputs/bundle/release/app-release.aab`

---

## 📱 Publicar en Google Play Store

### 1. **Crear Cuenta de Desarrollador**
- Ve a [Google Play Console](https://play.google.com/console)
- Pago único de $25 USD

### 2. **Crear Nueva Aplicación**
1. Click "Crear app"
2. Nombre: **Sweet Models Enterprise**
3. Idioma predeterminado: **Español**
4. Tipo: **App** o **Juego**
5. Gratis o de pago: **Gratis**

### 3. **Configurar Store Listing**
- **Título**: Sweet Models Enterprise
- **Descripción corta**: Plataforma de gestión para modelos webcam
- **Descripción completa**: (Ver sección abajo)
- **Capturas de pantalla**: Mínimo 2 (formato 16:9 o 9:16)
- **Ícono**: 512x512 px
- **Gráfico de función**: 1024x500 px

#### Descripción Completa Sugerida:
```
Sweet Models Enterprise - Gestión Profesional para Modelos

Características principales:
✅ Panel de estadísticas en tiempo real
✅ Sistema de pagos y comisiones automatizado
✅ Monitoreo de transmisiones en vivo
✅ Notificaciones push de eventos importantes
✅ Autenticación biométrica segura
✅ Gestión de contratos digitales
✅ Reportes financieros detallados
✅ Soporte multiplataforma (Android, Windows, iOS)

Ideal para agencias y modelos que buscan profesionalizar su gestión.
```

### 4. **Configurar Contenido**
- **Categoría**: Negocios
- **Clasificación de contenido**: Completar cuestionario
- **Política de privacidad**: URL requerida (crear en tu sitio web)
- **Datos de contacto**: Email del desarrollador

### 5. **Subir AAB**
1. Panel izquierdo → **Producción**
2. Click **Crear nueva versión**
3. Subir `app-release.aab`
4. Notas de la versión:
```
Versión 1.0.0
- Lanzamiento inicial
- Dashboard completo
- Sistema de pagos
- Notificaciones push
- Autenticación segura
```

### 6. **Revisión y Publicación**
- Completar todos los campos obligatorios
- Enviar a revisión (puede tardar 1-3 días)
- Google revisará la app para verificar políticas

---

## 🔧 Solución de Problemas Actuales

### Error: NDK License Not Accepted
**Solución**: Ejecuta `sdkmanager --licenses` y acepta todo con `y`.

### Error: Keystore No Funciona
**Solución**: Regenera keystore con contraseñas seguras y actualiza `keystore.properties`.

### Error: google-services.json No Encontrado
**Solución**: Descarga desde Firebase Console con package `com.sweetmodels.app`.

---

## 📋 Checklist Pre-Publicación

- [ ] Licencias Android SDK aceptadas
- [ ] Keystore de producción generado
- [ ] google-services.json con package correcto
- [ ] App icons generados (todos los tamaños)
- [ ] Nombre de app actualizado en AndroidManifest
- [ ] Build exitoso de AAB release
- [ ] Prueba de app en dispositivo físico
- [ ] Cuenta Google Play Console creada
- [ ] Capturas de pantalla preparadas
- [ ] Descripción y textos escritos
- [ ] Política de privacidad publicada
- [ ] Clasificación de contenido completada

---

## 🚀 Comandos Rápidos

```powershell
# Build Debug
flutter build apk --debug

# Build Release APK
flutter build apk --release

# Build App Bundle (para Play Store)
flutter build appbundle --release

# Instalar en dispositivo conectado
flutter install

# Ver logs en tiempo real
flutter logs

# Limpiar y rebuild
flutter clean && flutter pub get && flutter build appbundle --release
```

---

**Fecha**: 14 de Diciembre 2025  
**Estado**: Configuración completa, pendiente aceptar licencias SDK y generar keystore de producción
