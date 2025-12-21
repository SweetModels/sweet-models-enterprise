# 🚀 Guía Rápida de Publicación

## Pasos para Publicar en Google Play Store

### 1️⃣ Configurar Keystore (Solo la primera vez)

```powershell
.\setup-keystore.ps1
```

Sigue las instrucciones y guarda las contraseñas de forma segura.

### 2️⃣ Crear Íconos de la App

1. Crea dos imágenes PNG de 1024x1024:
   - `assets/icon/app_icon.png` (logo con fondo)
   - `assets/icon/app_icon_foreground.png` (logo sin fondo)

2. Genera los íconos en todos los tamaños:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

Ver **ICONOS.md** para más detalles.

### 3️⃣ Generar Build de Producción

**Para Google Play (AAB):**
```powershell
.\build-release.ps1 -Platform android -BuildType appbundle
```

**Para pruebas (APK):**
```powershell
.\build-release.ps1 -Platform android -BuildType apk
```

### 4️⃣ Subir a Google Play Console

1. Ve a [Google Play Console](https://play.google.com/console)
2. Crea una nueva aplicación
3. Completa la información básica:
   - Nombre: Sweet Models Enterprise
   - Descripción corta: "Platform for model management and earnings tracking"
   - Categoría: Business
   - Contacto: Tu email
4. Ve a **Producción** → **Crear nueva versión**
5. Sube el archivo `app-release.aab`
6. Completa el cuestionario de contenido
7. **Enviar para revisión**

**Tiempo de revisión**: 1-7 días

---

## Pasos para Publicar en Apple App Store

### 1️⃣ Requisitos

- ✅ Mac con Xcode 15+
- ✅ Apple Developer Account ($99/año)
- ✅ Certificados y Provisioning Profiles configurados

### 2️⃣ Generar Build de iOS

```bash
flutter build ios --release
```

### 3️⃣ Archivar y Subir desde Xcode

1. Abre el proyecto en Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Product** → **Archive**

3. **Distribute App** → **App Store Connect**

4. Sigue el asistente

### 4️⃣ Completar en App Store Connect

1. Ve a [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → **+** → **New App**
3. Completa la información:
   - Name: Sweet Models Enterprise
   - Bundle ID: com.sweetmodels.enterprise
   - SKU: sweetmodels001
4. Sube screenshots (ver PUBLICACION.md)
5. Agrega la descripción
6. Configura precios (gratis o de pago)
7. **Submit for Review**

**Tiempo de revisión**: 24-48 horas

---

## 📋 Checklist de Publicación

### Antes de Publicar:

- [ ] ✅ Keystore configurado (Android)
- [ ] ✅ Bundle ID actualizado (iOS)
- [ ] ✅ Íconos generados
- [ ] ✅ Versión correcta en `pubspec.yaml`
- [ ] ✅ Build de producción generado
- [ ] ✅ App probada en dispositivos reales
- [ ] 📝 Screenshots tomados
- [ ] 📝 Descripción escrita
- [ ] 📝 Política de privacidad publicada
- [ ] 📝 URL de soporte configurada

### Assets Necesarios:

**Google Play:**
- Screenshots: 2-8 imágenes (JPEG/PNG, entre 320-3840px)
- Ícono: 512x512px PNG
- Feature graphic: 1024x500px

**App Store:**
- Screenshots: Varios tamaños (iPhone, iPad)
- Ícono: 1024x1024px (sin transparencia)
- Privacy Policy URL
- Support URL

---

## 📱 Información de la App

```yaml
Nombre: Sweet Models Enterprise
Package: com.sweetmodels.enterprise
Versión: 1.0.0
Build: 1
```

### Descripción Corta (80 caracteres):
```
Platform for model management, earnings tracking, and secure payments
```

### Descripción Completa:
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
```

### Keywords (App Store):
```
model,management,earnings,payments,blockchain,admin,finance
```

---

## 🔄 Actualizar la App

Para publicar una actualización:

1. Actualiza la versión en `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # 1.0.1 = versión visible, 2 = build number
   ```

2. Genera el nuevo build:
   ```powershell
   .\build-release.ps1 -Platform android -BuildType appbundle
   ```

3. Sube a las tiendas siguiendo el mismo proceso

---

## 📞 Ayuda

- 📖 Guía completa: **PUBLICACION.md**
- 🎨 Guía de íconos: **ICONOS.md**
- 🔐 Script de keystore: `.\setup-keystore.ps1`
- 📦 Script de build: `.\build-release.ps1`

---

## 💡 Consejos

1. **Testing**: Usa Internal Testing en Play Console antes de publicar
2. **Crashlytics**: Integra Firebase para monitorear errores
3. **ASO**: Optimiza el título y descripción para búsquedas
4. **Updates**: Planifica actualizaciones cada 2-4 semanas
5. **Feedback**: Responde a las reseñas de usuarios

**¡Buena suerte! 🚀**
