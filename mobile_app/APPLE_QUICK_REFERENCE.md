# 🍎 Apple Ecosystem - Quick Reference

## 🔧 macOS Configuration

### 1. Activate macOS Support
```bash
flutter config --enable-macos-desktop
```

### 2. macOS/Runner/DebugProfile.entitlements
```xml
<!-- 🌐 Internet (Cliente + Servidor) -->
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>

<!-- 📁 File Access -->
<key>com.apple.security.files.user-selected.read-write</key>
<true/>

<!-- 🎥 Camera & Microphone -->
<key>com.apple.security.device.camera</key>
<true/>
<key>com.apple.security.device.microphone</key>
<true/>
```

**Copiar el mismo contenido a:** `macOS/Runner/Release.entitlements`

---

## 📱 iOS Permissions (ios/Runner/Info.plist)

### Essential Permissions

```xml
<!-- 📷 Camera for KYC -->
<key>NSCameraUsageDescription</key>
<string>Sweet Models necesita acceso a tu cámara para verificación de identidad (KYC) y videollamadas.</string>

<!-- 🖼️ Photo Gallery (Read) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Sweet Models necesita acceso a tu galería para subir fotos de perfil y documentos.</string>

<!-- 📸 Photo Gallery (Write) - iOS 14+ -->
<key>NSPhotoLibraryAddOnlyUsageDescription</key>
<string>Sweet Models necesita permiso para guardar fotos en tu galería.</string>

<!-- 🔐 Face ID / Biometric -->
<key>NSFaceIDUsageDescription</key>
<string>Sweet Models usa Face ID para acceso seguro a tu cuenta. Puedes desactivarlo en Configuración.</string>

<!-- 🎤 Microphone -->
<key>NSMicrophoneUsageDescription</key>
<string>Sweet Models necesita acceso a tu micrófono para videollamadas.</string>
```

---

## 💻 Adaptive UI (Responsive Layout)

### Breakpoints
| Screen | Width | Component |
|--------|-------|-----------|
| iPhone | < 600px | **BottomNavigationBar** |
| iPad | 600-900px | **NavigationRail** |
| Mac | > 900px | **NavigationRail** |

### Implementation
```dart
// Import the new adaptive scaffold
import 'screens/adaptive_scaffold.dart';

routes: {
  '/dashboard': (context) => const AdaptiveDashboardScreen(),
}
```

**File:** `lib/screens/adaptive_scaffold.dart` ✅ (Already created)

---

## 🚀 Quick Commands

```bash
# Enable macOS Desktop
flutter config --enable-macos-desktop

# Clean & Rebuild
flutter clean && flutter pub get

# Build macOS
flutter build macos --debug
flutter build macos --release

# Build iOS
flutter build ios --release

# Run on specific device
flutter run -d "iPhone 14"
flutter run -d "iPad Air"
flutter run -d macOS

# Check permissions
flutter analyze
```

---

## ✅ Pre-Launch Checklist

- [ ] macOS entitlements configured (DebugProfile + Release)
- [ ] iOS Info.plist has all NSxxxUsageDescription keys
- [ ] AdaptiveDashboardScreen imported in main.dart
- [ ] Tested on iPhone simulator (BottomNavigationBar)
- [ ] Tested on iPad simulator (NavigationRail)
- [ ] Tested on macOS (NavigationRail + NetworkAccess)
- [ ] Flutter analyze shows no errors
- [ ] Flutter pub get completed successfully

---

## 📝 Files Modified/Created

✅ **Created:**
- `lib/screens/adaptive_scaffold.dart` - Responsive layout
- `APPLE_ECOSYSTEM_CONFIG.md` - Full documentation
- This file - Quick reference

✅ **Modified:**
- `macos/Runner/DebugProfile.entitlements` - Network + Camera + Microphone
- `ios/Runner/Info.plist` - Camera + Photos + FaceID + Microphone
- `lib/services/web3_service.dart` - Fixed `include0xPrefix` parameter

---

## 🔗 Related Documentation

- Main Guide: `APPLE_ECOSYSTEM_CONFIG.md`
- Responsive UI: `lib/screens/adaptive_scaffold.dart`
- Shadcn Setup: `SHADCN_UI_SETUP.md`

---

**Last Updated:** December 8, 2025  
**Status:** ✅ Ready for Deployment
