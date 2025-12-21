# 📱 Guía de Publicación - Sweet Models Enterprise

Esta guía te ayudará a publicar la app en Google Play Store y Apple App Store.

## 🔐 Paso 1: Generar Keystore para Android (Google Play)

### Crear el archivo keystore

Ejecuta este comando en PowerShell (desde la carpeta `mobile_app`):

```powershell
keytool -genkey -v -keystore c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app\android\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Información que debes proporcionar:**
- **Password del keystore**: Crea una contraseña segura (ej: `SweetModels2025!`)
- **Password del key alias**: Usa la misma contraseña
- **Nombre y apellidos**: Sweet Models Enterprise
- **Unidad organizativa**: Development Team
- **Organización**: Sweet Models
- **Ciudad**: [Tu ciudad]
- **Estado**: [Tu estado/provincia]
- **Código de país**: CO (o tu país)

### Crear el archivo key.properties

Crea el archivo `android/key.properties` con este contenido:

```properties
storePassword=TU_PASSWORD_AQUÍ
keyPassword=TU_PASSWORD_AQUÍ
keyAlias=upload
storeFile=upload-keystore.jks
```

**⚠️ IMPORTANTE:** Guarda este archivo en un lugar seguro y NO lo subas a Git.

---

## 🍎 Paso 2: Configurar iOS (Apple App Store)

### Requisitos previos:
1. **Mac con Xcode instalado** (versión 15+)
2. **Apple Developer Account** ($99 USD/año)
3. **Certificados y Provisioning Profiles**

### Pasos en Xcode:

1. Abre el proyecto iOS:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. En Xcode:
   - **Signing & Capabilities** → Selecciona tu equipo de desarrollo
   - **Bundle Identifier**: `com.sweetmodels.enterprise`
   - **Version**: 1.0.0
   - **Build**: 1

3. Configura los permisos necesarios en `Info.plist`:
   - Camera (ya configurado)
   - Microphone (ya configurado)
   - Photo Library (ya configurado)

---

## 🎨 Paso 3: Generar Íconos y Splash Screens

### Opción A: Usar flutter_launcher_icons

Ya tienes `flutter_launcher_icons` en el proyecto. Solo necesitas:

1. Crea una imagen de **1024x1024px** para el ícono (formato PNG)
2. Guárdala en: `assets/icon/app_icon.png`
3. Ejecuta:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

### Opción B: Crear manualmente

**Android:**
- Coloca los íconos en `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Tamaños: hdpi (72x72), mdpi (48x48), xhdpi (96x96), xxhdpi (144x144), xxxhdpi (192x192)

**iOS:**
- Usa Xcode para agregar los íconos en `Assets.xcassets/AppIcon.appiconset`

---

## 📦 Paso 4: Build de Producción

### Android (AAB para Google Play)

```bash
flutter build appbundle --release
```

El archivo AAB estará en: `build/app/outputs/bundle/release/app-release.aab`

### Android (APK para pruebas)

```bash
flutter build apk --release
```

El archivo APK estará en: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (IPA para App Store)

**En Mac con Xcode:**

```bash
flutter build ios --release
```

Luego en Xcode:
1. **Product** → **Archive**
2. **Distribute App** → **App Store Connect**
3. Sigue el asistente de publicación

---

## 📝 Paso 5: Preparar Assets para las Tiendas

### Google Play Store necesita:

1. **Screenshots** (mínimo 2, máximo 8):
   - Formato: JPEG o PNG de 24 bits
   - Dimensiones: Entre 320px y 3840px
   - Aspecto: Mínimo 16:9, máximo 2:1

2. **Ícono de alta resolución**:
   - 512x512px PNG
   - 32 bits con alpha

3. **Feature graphic**:
   - 1024x500px
   - JPEG o PNG de 24 bits

4. **Descripción corta**: Máximo 80 caracteres
   ```
   Platform for model management, earnings tracking, and secure payments
   ```

5. **Descripción completa**: Máximo 4000 caracteres
   ```
   Sweet Models Enterprise is a comprehensive platform designed for professional model management.
   
   ✨ Key Features:
   • Real-time earnings tracking
   • Secure blockchain-based payments
   • Group management and coordination
   • Financial planning tools
   • Video call capabilities
   • Admin dashboard with analytics
   • Multi-currency support (COP, USD, ETH)
   
   🔒 Security:
   • End-to-end encryption
   • Biometric authentication
   • Zero-knowledge proofs
   • Decentralized identity verification
   
   💼 For Models:
   Track your earnings, manage contracts, and receive payments securely.
   
   👥 For Administrators:
   Comprehensive dashboard for managing models, groups, and financial operations.
   
   🌐 Built with cutting-edge technology including blockchain integration and modern UI design.
   ```

### Apple App Store necesita:

1. **Screenshots**:
   - iPhone 6.7": 1290x2796px
   - iPhone 6.5": 1242x2688px
   - iPhone 5.5": 1242x2208px
   - iPad Pro 12.9": 2048x2732px

2. **App Icon**: 1024x1024px (sin transparency)

3. **Privacy Policy URL**: Debes crear una política de privacidad

4. **Support URL**: URL de soporte/contacto

5. **Marketing URL** (opcional)

6. **Descripción**:
   ```
   Professional model management platform with earnings tracking, secure payments, and comprehensive admin tools.
   ```

7. **Keywords**: Máximo 100 caracteres
   ```
   model,management,earnings,payments,blockchain,admin,finance
   ```

8. **Promotional Text**: Máximo 170 caracteres
   ```
   Manage your modeling career with ease. Track earnings, receive secure payments, and coordinate with your team—all in one powerful app.
   ```

---

## 🚀 Paso 6: Subir a las Tiendas

### Google Play Console:

1. Ve a [Google Play Console](https://play.google.com/console)
2. **Crear aplicación**
3. Completa la información básica
4. **Producción** → **Crear nueva versión**
5. Sube el archivo AAB
6. Completa el cuestionario de contenido
7. **Enviar para revisión**

**Tiempo de revisión**: 1-7 días

### App Store Connect:

1. Ve a [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → **+** → **New App**
3. Completa la información
4. Sube el build desde Xcode Organizer
5. Completa la información de la versión
6. **Submit for Review**

**Tiempo de revisión**: 24-48 horas (generalmente)

---

## ✅ Checklist Final

### Antes de publicar:

- [ ] Keystore generado y guardado de forma segura
- [ ] key.properties configurado
- [ ] Bundle ID/Application ID únicos configurados
- [ ] Versión y build number correctos
- [ ] Íconos en todos los tamaños
- [ ] Screenshots tomados
- [ ] Descripción y textos preparados
- [ ] Política de privacidad creada y publicada
- [ ] URL de soporte configurada
- [ ] Build de producción generado y probado
- [ ] Permisos verificados (cámara, micrófono, etc.)

### Testing antes de publicar:

```bash
# Test en modo release
flutter run --release -d android
flutter run --release -d ios

# Verificar que no hay errores
flutter analyze
```

---

## 📞 Soporte

Si tienes problemas:

1. **Android**: Revisa los logs en Play Console
2. **iOS**: Revisa los logs en App Store Connect
3. **Flutter**: `flutter doctor` para verificar el setup

---

## 🔄 Actualizaciones Futuras

Para publicar actualizaciones:

1. Incrementa el número de versión en `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # 1.0.1 es la versión, 2 es el build number
   ```

2. Genera el nuevo build:
   ```bash
   flutter build appbundle --release  # Android
   flutter build ios --release         # iOS
   ```

3. Sube a las tiendas siguiendo el mismo proceso

---

## 💡 Consejos Finales

- **Testing**: Usa **Internal Testing** en Play Console antes de publicar
- **Crash Reports**: Integra Firebase Crashlytics para monitorear errores
- **Analytics**: Usa Firebase Analytics o Google Analytics
- **Marketing**: Prepara estrategia de ASO (App Store Optimization)
- **Updates**: Planifica actualizaciones cada 2-4 semanas

**¡Buena suerte con tu publicación! 🚀**
