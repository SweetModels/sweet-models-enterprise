# 🚀 Installation & Testing Guide - Advanced Flutter Screens

## ✅ Pre-requisitos

- Flutter 3.5.4 o superior
- Dart 3.3.0 o superior
- Device o emulador con Android/iOS/Windows
- Backend en ejecución (`http://localhost:3000`)
---


## 📦 Instalación de Dependencias

### Paso 1: Actualizar pubspec.yaml

```bash
cd mobile_app
flutter pub get

```

### Paso 2: Limpiar caché (si es necesario)

```bash
flutter clean
flutter pub get

```

### Paso 3: Instalar paquetes específicos

```bash
flutter pub add pin_code_fields
flutter pub add camera
flutter pub add image_picker
flutter pub add media_kit
flutter pub add media_kit_video

```

---


## 🔧 Configuración por Plataforma

### Windows

```

✓ Soporte nativo de cámara (requiere permisos)
✓ media_kit funciona sin configuración adicional
✓ Ejecutar: flutter run -d windows

```

### Android

**1. AndroidManifest.xml:**


```xml
<!-- android/app/src/main/AndroidManifest.xml -->

<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<application
    android:label="Sweet Models Enterprise"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true">
    <!-- ... -->
</application>

```

**2. build.gradle (app):**


```gradle
android {
    compileSdk 34

    defaultConfig {
        targetSdk 34
        minSdk 21
    }
}

```

**3. Solicitar permisos en tiempo de ejecución:**


Agregar a `pubspec.yaml`:

```yaml
permission_handler: ^11.4.0

```

Usar en código:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> _requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (status.isDenied) {
    print('Camera permission denied');
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
  }
}

```

### iOS

**1. Info.plist:**


```xml
<!-- ios/Runner/Info.plist -->

<dict>
  <key>NSCameraUsageDescription</key>
  <string>Se requiere acceso a la cámara para capturar documentos KYC</string>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Se requiere ubicación para validar identidad</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>Se requiere acceso a galería para seleccionar fotos</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>Se requiere micrófono para comunicación</string>
</dict>

```

**2. Podfile:**


```ruby
post_install do |installer|

  installer.pods_project.targets.each do |target|

    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|

      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end

```

---


## 🧪 Testing

### Unit Tests

**test/otp_screen_test.dart:**


```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_models_mobile/otp_verification_screen.dart';

void main() {
  group('OTP Verification Screen', () {
    testWidgets('Renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '+573001234567',
            onVerificationComplete: () {},
          ),
        ),
      );

      expect(find.text('Verificación de Identidad'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
    });

    testWidgets('Countdown timer works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '+573001234567',
            onVerificationComplete: () {},
          ),
        ),
      );

      // Esperar 1 segundo
      await tester.pump(const Duration(seconds: 1));

      // Verificar que el contador cambió
      expect(find.text('segundos'), findsOneWidget);
    });
  });
}

```

### Widget Tests

**test/identity_camera_test.dart:**


```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_models_mobile/identity_camera_screen.dart';

void main() {
  group('Identity Camera Screen', () {
    testWidgets('Shows camera overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdentityCameraScreen(
            documentType: 'national_id_front',
            userId: 'test-user',
            onDocumentUploaded: () {},
          ),
        ),
      );

      // Verificar elementos
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.text('Capturar: Frente de la Cédula'), findsOneWidget);
    });
  });
}

```

**test/cctv_grid_test.dart:**


```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_models_mobile/cctv_grid_screen.dart';

void main() {
  group('CCTV Grid Screen', () {
    testWidgets('Displays cameras grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CctvGridScreen(),
        ),
      );

      // Esperar a que cargue
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.videocam), findsWidgets);
    });
  });
}

```

### Ejecutar Tests:

```bash

# Todos los tests

flutter test

# Test específico

flutter test test/otp_screen_test.dart

# Con cobertura

flutter test --coverage

```

---


## 🚀 Ejecución

### Windows

```bash
flutter run -d windows

```

### Android

```bash

# Device conectado

flutter run

# Emulador

flutter run -d emulator-5554

```

### iOS

```bash
flutter run -d all

```

### Web (con soporte limitado)

```bash
flutter run -d chrome

# Nota: Cámara no funciona en web

```

---


## 📱 Testing Manual

### Prueba 1: OTP Screen

**Pasos:**
1. Ir a `/otp_verify` con parámetros `phone=+573001234567`
2. Ver que aparece pantalla OTP
3. Esperar 30 segundos a que aparezca "Reenviar"
4. Ingresar código manualmente
5. Verificar que auto-verifica al completar 6 dígitos
**Esperado:**
- ✅ Campos PIN aparecen
- ✅ Countdown inicia en 30s
- ✅ Auto-verifica al ingresar 6 dígitos
- ✅ Animación de éxito tras verificación


### Prueba 2: Identity Camera

**Pasos:**
1. Ir a `/identity_camera` con `documentType=national_id_front`
2. Permitir acceso a cámara
3. Ver preview en vivo con overlay
4. Capturar foto (botón rojo)
5. Confirmar foto
6. Ver progreso de upload
**Esperado:**
- ✅ Cámara inicia
- ✅ Overlay visible (marco rosa)
- ✅ Preview después de capturar
- ✅ Upload muestra indicador
- ✅ Éxito con document_id


### Prueba 3: CCTV Grid

**Pasos:**
1. Ir a `/cctv_grid`
2. Esperar carga de cámaras
3. Ver grid 2x2
4. Tocar tarjeta
5. Ver fullscreen
**Esperado:**
- ✅ Grid carga correctamente
- ✅ Estadísticas mostradas (4 activas)
- ✅ Badges "EN VIVO" visibles
- ✅ Fullscreen modal abre
- ✅ Información detallada en modal


### Prueba 4: RegisterModelScreenAdvanced

**Pasos:**
1. Ir a `/register_model`
2. Completar datos básicos
3. Verificar OTP
4. Capturar 4 documentos
5. Revisar resumen
6. Completar registro
**Esperado:**
- ✅ Progress bar actualiza
- ✅ Validaciones funcionan
- ✅ Cada paso verifica requisitos
- ✅ Resumen muestra todos los datos
- ✅ Registro crea usuario
---


## 🐛 Troubleshooting

### Error: "Camera not initialized"

**Solución:**


```bash

# Limpiar y reconstruir

flutter clean
flutter pub get
flutter run --release

```

### Error: "pin_code_fields not found"

**Solución:**


```bash
flutter pub add pin_code_fields
flutter pub get
flutter run

```

### Error: "media_kit not working"

**Solución (Windows):**


```bash

# Desinstalar y reinstalar

flutter clean
flutter pub remove media_kit media_kit_video
flutter pub add media_kit media_kit_video
flutter run -d windows

```

### Error: "Network timeout on /admin/cameras"

**Verificar:**
1. Backend corriendo: `http://localhost:3000` ✅
2. JWT token válido ✅
3. Role = admin ✅
4. Red conectada ✅


```bash

# Testar endpoint manualmente

$token = "tu_jwt_token"
$headers = @{"Authorization"="Bearer $token"}
Invoke-WebRequest -Uri "`http://localhost:3000/admin/cameras`" -Headers $headers

```

### Error: "Segmentation fault en Android"

**Solución:**


```bash

# Actualizar gradle

flutter pub upgrade

# Limpiar caché

flutter clean
flutter pub get

# Reconstruir

flutter run --verbose

```

---


## 📊 Performance

### Optimizaciones implementadas:

1. **Lazy Loading**: Las cámaras se cargan bajo demanda
2. **Caching**: Tokens guardados en SharedPreferences
3. **IndexedStack**: Cambios rápidos entre pasos de registro
4. **Async/Await**: No bloquea UI durante uploads


### Benchmarks esperados:

| Operación | Tiempo |

|-----------|--------|

| Cargar OTP Screen | ~200ms |

| Capturar foto | ~500ms |

| Upload documento (5MB) | ~3-5s |

| Cargar grid CCTV | ~1-2s |

| Completar registro | ~10-15s |

---


## 📝 Checklist de Implementación

- [ ] Actualizar pubspec.yaml
- [ ] `flutter pub get`
- [ ] Crear otp_verification_screen.dart
- [ ] Crear identity_camera_screen.dart
- [ ] Crear cctv_grid_screen.dart
- [ ] Crear register_model_screen_advanced.dart
- [ ] Actualizar main.dart con rutas
- [ ] Configurar permisos (Android/iOS)
- [ ] Testar en device
- [ ] Testar flows de registro
- [ ] Documentar cambios
- [ ] Crear PR/MR
---


## 🎯 Próximas Fases

### Fase 2: Analytics

- [ ] Eventos de usuario (OTP sent, document captured)
- [ ] Tiempo promedio de registro
- [ ] Tasa de abandono por paso


### Fase 3: Notificaciones

- [ ] Push cuando KYC es aprobado
- [ ] Alerta cuando cámara se desconecta
- [ ] Recordatorio de documentos pendientes


### Fase 4: OCR

- [ ] Extraer datos de DNI automáticamente
- [ ] Validar que nombre coincida con selfie
- [ ] Detectar documentos falsificados
---


## 📞 Soporte

Para reportar issues:
1. Describe el problema
2. Incluye pasos para reproducir
3. Adjunta logs: `flutter logs`
4. Versión de Flutter: `flutter --version`
