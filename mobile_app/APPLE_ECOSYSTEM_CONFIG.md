# 🍎 Apple Ecosystem Configuration Guide
## Sweet Models Enterprise - iOS, iPadOS & macOS

**Versión:** 1.0  
**Fecha:** Diciembre 2025  
**Compatibilidad:** Flutter 3.x, iOS 13+, macOS 11+

---

## 📋 Tabla de Contenidos

1. [macOS Desktop Setup](#macos-desktop-setup)
2. [iOS/iPadOS Permissions](#iosipados-permissions)
3. [Adaptive UI Implementation](#adaptive-ui-implementation)
4. [Deployment Checklist](#deployment-checklist)

---

## 🖥️ macOS Desktop Setup

### 1.1 Activar Soporte macOS en Flutter

```bash
# Habilitar soporte de escritorio macOS
flutter config --enable-macos-desktop

# Crear el proyecto macOS (si no existe)
flutter create --platforms=macos .

# Verificar que se creó la carpeta /macos
ls -la macos/
```

**Output esperado:**
```
macos/
├── Runner.xcworkspace
├── Runner.xcodeproj
├── Runner/
│   ├── Assets.xcassets
│   ├── DebugProfile.entitlements  ✅
│   ├── GeneratedPluginRegistrant.swift
│   ├── Info.plist
│   └── Release.entitlements
└── Podfile
```

### 1.2 Configurar Entitlements de macOS

**Archivo:** `macos/Runner/DebugProfile.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- 📱 Sandbox Security (Obligatorio para macOS App Store) -->
	<key>com.apple.security.app-sandbox</key>
	<true/>
	
	<!-- 🔧 Development Features (Solo en Debug) -->
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	
	<!-- 🌐 NETWORK ACCESS - Cliente (Saliente) 
	     Permite que la app se conecte a servidores externos
	     Necesario para: API calls, Web3, Auth servers -->
	<key>com.apple.security.network.client</key>
	<true/>
	
	<!-- 🌐 NETWORK ACCESS - Servidor (Entrante)
	     Permite que la app reciba conexiones entrantes
	     Necesario para: WebSockets, real-time updates -->
	<key>com.apple.security.network.server</key>
	<true/>
	
	<!-- 📁 FILE ACCESS - Lectura/Escritura
	     Permite acceso a archivos seleccionados por el usuario
	     Necesario para: Subir documentos, guardar PDFs -->
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
	
	<!-- 📁 DOCUMENTS FOLDER ACCESS (macOS 11+)
	     Acceso a la carpeta ~/Documents
	     Necesario para: Descargas, exportación de datos -->
	<key>com.apple.security.files.downloads.read-write</key>
	<true/>
	
	<!-- 🎥 CAMERA ACCESS
	     Necesario para: KYC (Know Your Customer), videollamadas -->
	<key>com.apple.security.device.camera</key>
	<true/>
	
	<!-- 🎤 MICROPHONE ACCESS
	     Necesario para: Videollamadas, conferencias -->
	<key>com.apple.security.device.microphone</key>
	<true/>
	
	<!-- 🌐 INTERNET ACCESS (Explícito)
	     Combina cliente y servidor
	     Equivalente a NSBonjourServices en iOS -->
	<key>com.apple.security.network.incoming</key>
	<true/>
	<key>com.apple.security.network.outgoing</key>
	<true/>
</dict>
</plist>
```

**También configurar:** `macos/Runner/Release.entitlements` (igual al anterior)

### 1.3 Verificar la Configuración en Xcode

```bash
# Abrir Xcode para verificar entitlements
open macos/Runner.xcworkspace

# O compilar desde terminal
flutter build macos --debug
```

**En Xcode (si abres el .workspace):**
1. Selecciona el proyecto "Runner"
2. Target "Runner" → Signing & Capabilities
3. Verifica que los entitlements aparezcan bajo "Capabilities"

---

## 📱 iOS/iPadOS Permissions

### 2.1 Archivo de Configuración

**Archivo:** `ios/Runner/Info.plist`

```xml
<!-- 📷 CAMERA PERMISSION
     Descripción que aparece en el popup del usuario
     Usado para: KYC (verificación de identidad), Videollamadas
     Mínimo iOS: 10.0+ -->
<key>NSCameraUsageDescription</key>
<string>Sweet Models necesita acceso a tu cámara para verificación de identidad (KYC) y videollamadas profesionales.</string>

<!-- 🖼️ PHOTO LIBRARY - Lectura
     Necesario para: Subir fotos de perfil, documentos de verificación
     Mínimo iOS: 6.0+
     Nota: iOS 14+ muestra popup pidiendo permiso -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Sweet Models necesita acceso a tu galería para subir fotos de perfil, portafolios y documentos de verificación.</string>

<!-- 📸 PHOTO LIBRARY - Escritura (iOS 14+)
     Necesario para: Guardar screenshots, exportar archivos
     Solo aparece en iOS 14+, en versiones anteriores se ignora -->
<key>NSPhotoLibraryAddOnlyUsageDescription</key>
<string>Sweet Models necesita permiso para guardar fotos y documentos en tu galería.</string>

<!-- 🔐 FACE ID / BIOMETRIC AUTHENTICATION
     Necesario para: Autenticación local, acceso seguro a wallet
     Mínimo iOS: 11.0 (Face ID)
     Nota: Touch ID se detecta automáticamente si el dispositivo lo tiene -->
<key>NSFaceIDUsageDescription</key>
<string>Sweet Models usa Face ID para acceso seguro a tu cuenta y wallet Web3. Puedes cambiar esta configuración en Configuración > Sweet Models.</string>

<!-- 🎤 MICROPHONE PERMISSION
     Necesario para: Videollamadas, conferencias en vivo
     Mínimo iOS: 10.0+ -->
<key>NSMicrophoneUsageDescription</key>
<string>Sweet Models necesita acceso a tu micrófono para videollamadas y sesiones de tutoría.</string>

<!-- 📍 LOCATION - When in Use (Opcional)
     Descomenta si necesitas localización futura
     Mínimo iOS: 8.0+ -->
<!-- <key>NSLocationWhenInUseUsageDescription</key> -->
<!-- <string>Sweet Models necesita tu ubicación para servicios localizados.</string> -->

<!-- 📍 LOCATION - Always (Muy invasivo - NO recomendado)
     Solo para apps como GPS, maps, tracking continuo
     Rara vez necesario para Sweet Models -->
<!-- <key>NSLocationAlwaysAndWhenInUseUsageDescription</key> -->
<!-- <string>...</string> -->
```

### 2.2 Permisos Recomendados por Feature

| Feature | iOS Permissions | Behavior |
|---------|-----------------|----------|
| **Login** | Ninguno | Works without permissions |
| **KYC/Identity Verification** | `NSCameraUsageDescription` | Popup aparece cuando se intenta usar la cámara |
| **Profile Photo Upload** | `NSPhotoLibraryUsageDescription` | Popup en primer acceso a galería |
| **Video Calls** | `NSCameraUsageDescription` + `NSMicrophoneUsageDescription` | Popup para cada permiso |
| **Web3 Biometric Auth** | `NSFaceIDUsageDescription` | Silencioso (no popup si ya está autorizado) |
| **Save Receipt/Invoice** | `NSPhotoLibraryAddOnlyUsageDescription` | iOS 14+ requerido |

### 2.3 Testing Permissions en iOS

```bash
# Compilar para iOS
flutter build ios

# O ejecutar directamente
flutter run -d ios

# En el simulador, simular solicitud de permiso:
# Settings > Sweet Models > Camera: Allow
# Settings > Sweet Models > Photos: Allow
# Settings > Sweet Models > Microphone: Allow
```

---

## 📲 Adaptive UI Implementation

### 3.1 Responsive Breakpoints

```dart
// lib/utils/responsive_helper.dart

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;     // < 600px = Mobile
  static const double tabletBreakpoint = 900;     // 600-900px = Tablet
  static const double desktopBreakpoint = 1200;   // > 1200px = Desktop

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
}
```

### 3.2 Adaptive Dashboard Implementation

**Archivo:** `lib/screens/adaptive_scaffold.dart` ✅ (Ya creado)

**Características:**
- ✅ **iPhone (<600px):** BottomNavigationBar (5 items)
- ✅ **iPad/Mac (>600px):** NavigationRail expandido (barra lateral)
- ✅ **Detección automática** de orientación
- ✅ **Responde a cambios de tamaño** (rotación)

**Uso en main.dart:**

```dart
routes: {
  '/': (context) => const LoginScreenShadcn(),
  '/login': (context) => const LoginScreen(),
  '/dashboard': (context) => const AdaptiveDashboardScreen(),  // ← Usar esta
  // ... resto de rutas
}
```

### 3.3 Componentes Adaptativos Adicionales

```dart
// lib/widgets/adaptive_dialog.dart

class AdaptiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const AdaptiveDialog({
    required this.title,
    required this.content,
    required this.actions,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // En móvil: usar BottomSheet
      return Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(title: Text(title)),
            Flexible(child: SingleChildScrollView(child: content)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: actions),
            ),
          ],
        ),
      );
    } else {
      // En tablet/desktop: usar AlertDialog tradicional
      return AlertDialog(
        title: Text(title),
        content: content,
        actions: actions,
      );
    }
  }
}
```

---

## ✅ Deployment Checklist

### Pre-Deployment (Antes de compilar)

- [ ] `flutter config --enable-macos-desktop` ejecutado
- [ ] `macos/Runner/DebugProfile.entitlements` actualizado
- [ ] `macos/Runner/Release.entitlements` actualizado
- [ ] `ios/Runner/Info.plist` con permisos configurados
- [ ] `ios/Runner/GeneralInfo.plist` (si existe) actualizado
- [ ] Tested en simulador iOS
- [ ] Tested en simulador macOS
- [ ] Tested en dispositivo físico (si posible)

### macOS Build

```bash
# Limpiar builds anteriores
flutter clean
rm -rf build/ macos/Pods macos/Podfile.lock

# Compilar release
flutter build macos --release

# Output: build/macos/Build/Products/Release/sweet_models_mobile.app
```

### iOS Build

```bash
# Limpiar
flutter clean
rm -rf build/ ios/Pods ios/Podfile.lock

# Compilar (iOS 13.0+)
flutter build ios --release

# Para App Store, necesitas certificados y provisioning profiles
# Ver: https://docs.flutter.dev/deployment/ios
```

### Verificar Permisos (iOS)

```bash
# Abrir Info.plist en Xcode
open ios/Runner.xcworkspace

# Verificar que los NSxxxUsageDescription aparezcan
# Xcode > Runner > Info > Custom iOS Target Properties
```

### Firma de Código (macOS)

```bash
# En Xcode UI:
# 1. Runner Project > Targets > Runner
# 2. Signing & Capabilities
# 3. Team: Selecciona tu Apple Developer Account
# 4. Bundle Identifier: com.sweetmodels.enterprise
```

---

## 🚀 Comandos Útiles

```bash
# Ver dispositivos disponibles
flutter devices

# Correr en simulador iOS específico
flutter run -d "iPhone 14"
flutter run -d "iPad Air"
flutter run -d "macOS"

# Ver logs de iOS
flutter logs

# Profiling macOS
flutter run -d macos --profile

# Compilar solo el binary (sin instalar)
flutter build macos --debug
flutter build ios --debug

# Verificar dependencias
flutter pub get
flutter pub audit

# Update permisos de macOS
git add macos/Runner/*.entitlements
git commit -m "🍎 Update macOS entitlements for network and camera access"
```

---

## 📚 Referencias Oficiales

- **Flutter macOS:** https://docs.flutter.dev/platform-integration/macos
- **Apple Entitlements:** https://developer.apple.com/documentation/bundleresources/entitlements
- **iOS Permissions:** https://developer.apple.dev/design/human-interface-guidelines/ios/patterns/protecting-the-users-privacy/
- **App Store Guidelines:** https://developer.apple.com/app-store/review/guidelines/

---

## 🆘 Troubleshooting

### "Pod install failed on macOS"
```bash
cd macos
rm -rf Pods Podfile.lock
pod install
cd ..
```

### "NSCameraUsageDescription not found"
Verifica que `ios/Runner/Info.plist` está formateado correctamente como XML.

### "Entitlements not applied"
Limpia y reconstruye:
```bash
flutter clean
rm -rf build/
flutter run
```

### "File size too large for App Store"
Usa `flutter build ios --release --split-per-abi` para versiones más pequeñas.

---

**Última actualización:** Diciembre 8, 2025  
**Autor:** Release Engineering Team  
**Status:** ✅ Listo para producción
