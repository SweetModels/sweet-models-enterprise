# 📱 Advanced Flutter Screens Implementation Guide

## ✅ Pantallas Implementadas

### 1️⃣ **OtpVerificationScreen** (`otp_verification_screen.dart`)

#### Características:

- 🎨 Diseño estilo Banco (profesional y seguro)
- 📱 6 campos de PIN individuales con PinCodeFields
- ⏰ Cuenta regresiva de 30 segundos para reenvío
- ✨ Animación de éxito al verificar
- 🔄 Auto-verificación al completar los 6 dígitos
- 📞 Número de teléfono enmascarado (+57 300****567)


#### Uso:

```dart
// Navegar a pantalla de OTP
Navigator.pushNamed(
  context,
  '/otp_verify',
  arguments: {
    'phone': '+573001234567',
    'onComplete': () {
      print('Verificación completada');
      Navigator.pop(context);
    },
  },
);

```

#### Parámetros:

| Parámetro | Tipo | Descripción |

|-----------|------|-------------|

| phone | String | Número de teléfono con código país (+57...) |

| onVerificationComplete | VoidCallback | Función a ejecutar tras verificación exitosa |

#### API Calls:

- `ApiService().sendOtp(phone)` - Enviar código OTP
- `ApiService().verifyOtp(phone, code)` - Verificar código
---


### 2️⃣ **IdentityCameraScreen** (`identity_camera_screen.dart`)

#### Características:

- 📸 Captura con cámara del dispositivo
- 🎯 Overlay con marco guía (rectángulo con esquinas destacadas)
- 🌫️ Fondo oscurecido alrededor del marco
- ✅ Preview de foto antes de subir
- 🚀 Upload automático a backend
- 📄 Soporta 4 tipos de documentos:
  - `national_id_front` - Frente de cédula
  - `national_id_back` - Dorso de cédula
  - `selfie` - Foto de rostro
  - `proof_address` - Comprobante de domicilio


#### Uso:

```dart
// Navegar a captura de documento
Navigator.pushNamed(
  context,
  '/identity_camera',
  arguments: {
    'documentType': 'national_id_front',
    'userId': '550e8400-e29b-41d4-a716-446655440000',
    'onComplete': () {
      print('Documento subido');
      Navigator.pop(context);
    },
  },
);

```

#### Parámetros:

| Parámetro | Tipo | Descripción |

|-----------|------|-------------|

| documentType | String | Tipo de documento a capturar |

| userId | String | UUID del usuario (obtenido al login) |

| onDocumentUploaded | VoidCallback | Callback tras upload exitoso |

#### Flujo:

1. 📸 Mostrar preview en vivo con overlay
2. 🎯 Usuario alinea documento en marco
3. 📷 Captura foto (botón rojo circular)
4. 👀 Mostrar preview de captura
5. ✓/✗ Usuario confirma o retoma
6. 🚀 Upload automático con indicador de progreso
7. ✅ Animación de éxito con document_id


#### API Calls:

- `ApiService().uploadKycDocument(userId, documentType, imageFile)`
---


### 3️⃣ **CctvGridScreen** (`cctv_grid_screen.dart`)

#### Características:

- 📹 Cuadrícula 2x2 de reproductores de video RTSP
- 🟢 Indicador de estado "EN VIVO" para cámaras activas
- 🔴 Badge "Sin Señal" para cámaras inactivas
- 📊 Estadísticas de cámaras (activas, inactivas, ubicaciones)
- 🖥️ Vista fullscreen al tapping en tarjeta
- 🎬 Soporte para URLs RTSP en tiempo real


#### Uso:

```dart
// Navegar a monitoreo en vivo
Navigator.pushNamed(context, '/cctv_grid');

```

#### Parámetros:

No requiere parámetros. Carga automáticamente desde el endpoint `/admin/cameras`

#### Estructura de Datos (desde Backend):

```json
{
  "cameras": [
    {
      "id": 1,
      "name": "Main Studio Cam 1",
      "stream_url": "rtsp://192.168.1.100:554/stream1",
      "platform": "Studio",
      "is_active": true
    }
  ],
  "total_active": 4
}

```

#### Componentes:

- **Header con estadísticas**: Muestra cámaras activas
- **Grid de tarjetas**: Cada una representa una cámara
- **Video Player**: Reproducción de stream RTSP
- **Fullscreen Modal**: Al tocar una tarjeta
- **Información detallada**: URL, estado, ubicación


#### API Calls:

- `ApiService().getCameras()` - Obtener lista de cámaras (requiere JWT admin)
---


## 🚀 Instalación de Dependencias

### 1. Actualizar pubspec.yaml:

```yaml
dependencies:
  pin_code_fields: ^8.0.1
  camera: ^0.10.5+5
  image_picker: ^0.8.9
  media_kit: ^1.3.0
  media_kit_video: ^1.3.0
  image: ^4.3.0
  http_parser: ^4.0.2

```

### 2. Ejecutar pub get:

```bash
flutter pub get

```

### 3. Configurar permisos (Android):

**android/app/src/main/AndroidManifest.xml:**


```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

```

### 4. Configurar permisos (iOS):

**ios/Runner/Info.plist:**


```xml
<key>NSCameraUsageDescription</key>
<string>Se requiere acceso a la cámara para capturar documentos KYC</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Se requiere ubicación para asociar con cámaras</string>

```

### 5. Configurar permisos (Windows):

En la mayoría de casos, Windows permite acceso a cámara automáticamente.

---


## 🔌 Integración en RegisterModelScreen

### Ejemplo de flujo completo:

```dart
// 1. Solicitar teléfono
TextFormField(
  controller: _phoneController,
  decoration: InputDecoration(
    labelText: 'Teléfono',
    prefixText: '+57 ',
  ),
  keyboardType: TextInputType.phone,
  validator: (value) {
    if (value == null || value.isEmpty) return 'Requerido';

    if (value.length != 10) return '10 dígitos';
    return null;
  },
),

// 2. Botón para enviar OTP
ElevatedButton(
  onPressed: () async {
    // Primero enviar OTP
    final phone = '+57${_phoneController.text}';
    final response = await ApiService().sendOtp(phone);

    if (response['success']) {
      // Ir a pantalla de verificación
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/otp_verify',
          arguments: {
            'phone': phone,
            'onComplete': () {
              // Proceder con captura de documentos
              _goToIdentityCapture();
            },
          },
        );
      }
    }
  },
  child: const Text('Verificar Teléfono'),
),

// 3. Iniciar captura de documentos KYC
Future<void> _goToIdentityCapture() async {
  final userId = _getUserIdFromStorage(); // Del login

  final documents = [
    'national_id_front',
    'national_id_back',
    'selfie',
    'proof_address',
  ];

  for (String docType in documents) {
    if (!mounted) return;

    await Navigator.pushNamed(
      context,
      '/identity_camera',
      arguments: {
        'documentType': docType,
        'userId': userId,
        'onComplete': () {
          print('Documento $docType subido');
        },
      },
    );
  }

  // Todos los documentos capturados
  print('✅ Registro KYC completado');
  Navigator.pushReplacementNamed(context, '/dashboard');
}

```

---


## 🧪 Testing

### Unit Tests:

```dart
// test/otp_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_models_mobile/otp_verification_screen.dart';

void main() {
  testWidgets('OTP Screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OtpVerificationScreen(
          phone: '+573001234567',
          onVerificationComplete: () {},
        ),
      ),
    );

    expect(find.byType(PinCodeTextField), findsOneWidget);
    expect(find.text('Verificación de Identidad'), findsOneWidget);
  });

  testWidgets('OTP auto-verifies on 6 digits', (WidgetTester tester) async {
    bool verified = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OtpVerificationScreen(
          phone: '+573001234567',
          onVerificationComplete: () => verified = true,
        ),
      ),
    );

    // Simular ingreso de 6 dígitos
    await tester.enterText(find.byType(PinCodeTextField), '123456');
    await tester.pumpAndSettle();

    // Verificaría automáticamente
    expect(verified, true);
  });
}

```

### Widget Tests:

```dart
// test/camera_screen_test.dart
testWidgets('Camera overlay displays correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: IdentityCameraScreen(
        documentType: 'national_id_front',
        userId: 'test-user-id',
        onDocumentUploaded: () {},
      ),
    ),
  );

  expect(find.byIcon(Icons.videocam), findsWidgets);
  expect(find.byIcon(Icons.camera_alt), findsOneWidget);
});

```

---


## 🛠️ Troubleshooting

### Problema: "Camera not initialized"

**Solución:**
- Verificar permisos de cámara en AndroidManifest.xml
- En iOS, revisar Info.plist
- Usar device real (simulador puede tener limitaciones)


### Problema: "RTSP stream no funciona"

**Solución:**
- Verificar que URL RTSP sea válida
- Usar media_kit correctamente para streams
- En desarrollo local, validar conectividad de red


### Problema: "PinCodeTextField no aparece"

**Solución:**
- Ejecutar `flutter pub get`
- Clean build: `flutter clean && flutter pub get`
- Verificar que pin_code_fields está en pubspec.yaml


### Problema: "Upload falla"

**Solución:**
- Verificar que ApiService tiene método uploadKycDocument
- Validar JWT token en SharedPreferences
- Comprobar que backend está en línea
---


## 📊 Estados de Carga

### OTP Screen:

```

Inicial → Esperando entrada → Auto-verificando → Éxito ✅
                ↓ (error)
            Mostrar error (3s)

```

### Identity Camera:

```

Inicializando → Preview en vivo → Captura → Preview foto → Upload → Éxito ✅
                                              ↓ (rechazar)
                                           Reintentar

```

### CCTV Grid:

```

Cargando → Grid 2x2 → Tap tarjeta → Fullscreen → Info detallada

```

---


## 🎨 Paleta de Colores

| Elemento | Color | Código |

|----------|-------|--------|

| Primary | Rosa | #EB1555 |

| Background | Oscuro | #0A0E27 |

| Surface | Gris Oscuro | #1D1E33 |

| Surface Alt | Gris | #1A1F3A |

| Error | Rojo | #FF3B30 |

| Success | Verde | #34C759 |

---


## 📞 Contacto & Soporte

Para preguntas sobre la implementación, consultar:

- Backend API docs: `backend_api/SECURITY_FEATURES.md`
- Flutter Integration: `mobile_app/FLUTTER_INTEGRATION_GUIDE.md`
---


## ✨ Próximas Mejoras

- [ ] OCR para extraer datos de DNI automáticamente
- [ ] Reconocimiento facial en tiempo real
- [ ] Descarga de videos RTSP localmente
- [ ] Notificaciones push para alertas de cámaras
- [ ] Recorder de sesión CCTV de 7 días
- [ ] Exportación de videos en MP4
- [ ] Zoom y Pan en vista de cámara fullscreen
- [ ] Detector de movimiento en feeds
