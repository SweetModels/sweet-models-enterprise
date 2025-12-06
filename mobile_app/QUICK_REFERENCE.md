# 🚀 Quick Reference - Ejemplos de Uso

## 1️⃣ OTP Verification Screen

### Usar desde cualquier pantalla:
```dart
// Opción A: Navegar con argumentos
Navigator.pushNamed(
  context,
  '/otp_verify',
  arguments: {
    'phone': '+573001234567',
    'onComplete': () {
      print('Verificación exitosa');
      Navigator.pop(context);
    },
  },
);

// Opción B: Navegar directo
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OtpVerificationScreen(
      phone: '+573001234567',
      onVerificationComplete: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Verificado')),
        );
      },
    ),
  ),
);
```

### En RegisterModelScreen:
```dart
Future<void> _verifyPhoneWithOtp() async {
  final phone = '+57${_phoneController.text}';
  
  // Enviar código
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
            print('✅ Phone verified');
            _proceedToNextStep();
          },
        },
      );
    }
  }
}
```

---

## 2️⃣ Identity Camera Screen

### Capturar documento:
```dart
// Abrir cámara para capturar DNI
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => IdentityCameraScreen(
      documentType: 'national_id_front',
      userId: userId,  // Obtenido del login
      onDocumentUploaded: () {
        print('✅ Documento subido');
        setState(() => _documentsUploaded['national_id_front'] = true);
      },
    ),
  ),
);
```

### En RegisterModelScreen con loop:
```dart
Future<void> _captureAllDocuments() async {
  final documents = [
    'national_id_front',
    'national_id_back',
    'selfie',
    'proof_address',
  ];
  
  for (String docType in documents) {
    if (!mounted) return;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdentityCameraScreen(
          documentType: docType,
          userId: userId,
          onDocumentUploaded: () {
            setState(() => _documentsUploaded[docType] = true);
          },
        ),
      ),
    );
  }
  
  print('✅ Todos los documentos capturados');
}
```

### Tipos de documentos:
```dart
const documentTypes = {
  'national_id_front': '📄 Frente de la Cédula',
  'national_id_back': '📄 Dorso de la Cédula',
  'selfie': '🤳 Foto de Rostro',
  'proof_address': '📮 Comprobante de Domicilio',
};
```

---

## 3️⃣ CCTV Grid Screen

### Navegar a monitoreo:
```dart
// Navegar simple
Navigator.pushNamed(context, '/cctv_grid');

// Con argumentos (si es necesario)
Navigator.pushNamed(
  context,
  '/cctv_grid',
  arguments: {
    'filterPlatform': 'Studio', // Opcional
  },
);
```

### En Dashboard agregando botón:
```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.pushNamed(context, '/cctv_grid');
  },
  icon: const Icon(Icons.videocam),
  label: const Text('Monitoreo en Vivo'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFEB1555),
  ),
),
```

### Mostrar cámaras con estado:
```dart
// El CctvGridScreen ya maneja:
// - Carga de cámaras desde backend
// - Grid 2x2 automático
// - Estadísticas
// - Fullscreen al tocar
```

---

## 4️⃣ RegisterModelScreenAdvanced

### Reemplazar en main.dart:
```dart
// ANTES:
routes: {
  '/register_model': (context) => const RegisterModelScreen(),
}

// DESPUÉS:
routes: {
  '/register_model': (context) => const RegisterModelScreenAdvanced(),
}
```

### Uso completo:
```dart
// En Dashboard o MainScreen
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/register_model');
  },
  child: const Text('Registrarse como Modelo'),
),
```

### Componentes internos:
```dart
// Step 1: Información básica
_buildStep1BasicInfo()

// Step 2: Verificación OTP
_buildStep2OtpVerification()

// Step 3: Captura de documentos
_buildStep3KycDocuments()

// Step 4: Resumen y confirmación
_buildStep4Summary()
```

---

## 🎯 Casos de Uso Comunes

### Caso 1: Verificar teléfono después de login
```dart
Future<void> _verifyPhone() async {
  final prefs = await SharedPreferences.getInstance();
  final phone = prefs.getString('user_phone');
  
  if (phone != null && !phone.contains('+')) {
    phone = '+57$phone';
  }
  
  Navigator.pushNamed(
    context,
    '/otp_verify',
    arguments: {
      'phone': phone,
      'onComplete': () {
        // Actualizar estado
        _markPhoneAsVerified();
      },
    },
  );
}
```

### Caso 2: Capturar documento específico
```dart
Future<void> _captureDocumentForApproval(String docId) async {
  final userId = await _getUserId();
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => IdentityCameraScreen(
        documentType: 'national_id_front',
        userId: userId,
        onDocumentUploaded: () {
          // Notificar al admin
          _notifyAdminOfNewDocument(docId);
        },
      ),
    ),
  );
}
```

### Caso 3: Monitorear cámaras específicas
```dart
// Ver solo cámaras del "Studio"
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CctvGridScreen(
      // El filtro se puede agregar en próxima versión
    ),
  ),
);
```

---

## 💾 Estado Local

### Guardar progreso de verificación:
```dart
Future<void> _saveVerificationProgress() async {
  final prefs = await SharedPreferences.getInstance();
  
  await prefs.setBool('phone_verified', _phoneVerified);
  await prefs.setStringList(
    'documents_uploaded',
    _documentsUploaded.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList(),
  );
  await prefs.setInt('registration_step', _currentStep);
}
```

### Recuperar progreso:
```dart
Future<void> _loadVerificationProgress() async {
  final prefs = await SharedPreferences.getInstance();
  
  _phoneVerified = prefs.getBool('phone_verified') ?? false;
  final uploaded = prefs.getStringList('documents_uploaded') ?? [];
  _currentStep = prefs.getInt('registration_step') ?? 0;
  
  // Restaurar estado
  for (String doc in uploaded) {
    _documentsUploaded[doc] = true;
  }
}
```

---

## 🔄 Flujos de Navegación

### Flujo 1: Login → Verificar → Dashboard
```
LoginScreen
    ↓
    [Éxito]
    ↓
OtpVerificationScreen (auto)
    ↓
    [Verificado]
    ↓
DashboardScreen
```

### Flujo 2: Registro completo
```
RegisterModelScreenAdvanced
    ↓
[Paso 1: Datos básicos]
    ↓
[Paso 2: OTP → OtpVerificationScreen]
    ↓
[Paso 3: KYC → IdentityCameraScreen × 4]
    ↓
[Paso 4: Resumen]
    ↓
[Éxito → LoginScreen]
```

### Flujo 3: Admin monitoreo
```
DashboardScreen
    ↓
[Botón "Monitoreo"]
    ↓
CctvGridScreen
    ↓
[Tap cámara]
    ↓
CctvGridScreen (fullscreen modal)
```

---

## 🧪 Testing Rápido

### Test OTP:
```bash
# 1. En browser/postman:
POST http://localhost:3000/auth/send-otp
{ "phone": "+573001234567" }

# 2. Ver código en logs
docker logs sme_backend | grep "ENVIO SMS"

# 3. En app, navegar a /otp_verify y ingresar código
```

### Test Camera:
```bash
# 1. Permitir permisos de cámara en device
# 2. Navegar a /identity_camera?documentType=national_id_front
# 3. Capturar foto
# 4. Esperar upload
```

### Test CCTV:
```bash
# 1. Login como admin
# 2. Navegar a /cctv_grid
# 3. Ver grid con 4 cámaras
# 4. Tocar tarjeta para fullscreen
```

---

## 📱 Ejemplos de Valores

### Teléfonos válidos:
```
+573001234567    ✅
+573055551234    ✅
+571234567890    ✅
573001234567     ❌ (falta +57)
+1234567890      ❌ (no es Colombia)
```

### Documentos válidos:
```
'national_id_front'    ✅
'national_id_back'     ✅
'selfie'               ✅
'proof_address'        ✅
'passport'             ❌ (no soportado)
```

### Estados de cámara:
```
{
  "id": 1,
  "name": "Main Studio Cam 1",
  "stream_url": "rtsp://192.168.1.100:554/stream1",
  "platform": "Studio",
  "is_active": true
}
```

---

## ⚡ Tips de Performance

### Optimizar carga de cámaras:
```dart
// Usar StreamBuilder para actualizaciones en tiempo real
StreamBuilder<List<Camera>>(
  stream: camerasStream,
  builder: (context, snapshot) {
    // Rebuild solo cuando hay nuevos datos
  },
)
```

### Caché de imágenes:
```dart
// Precarga de fotos en background
precacheImage(AssetImage('assets/icon.png'), context);
```

### Lazy load documentos:
```dart
// Solo cargar documento cuando es necesario
_documentsUploaded.putIfAbsent(docType, () => false);
```

---

## 🎨 Personalización

### Cambiar colores:
```dart
// En main.dart theme:
const Color(0xFFEB1555)  // Principal (cambiar aquí)
const Color(0xFF0A0E27)  // Background
const Color(0xFF1D1E33)  // Surface
```

### Cambiar textos:
```dart
// En cada Screen:
const String kVerificationTitle = 'Verificación de Identidad';
const String kOtpSent = 'Hemos enviado un código a:';
```

### Cambiar duraciones:
```dart
// En otp_verification_screen.dart:
_countdownSeconds = 30;  // Cambiar aquí

// En identity_camera_screen.dart:
await Future.delayed(const Duration(seconds: 1));  // Cambiar aquí
```

---

## 📞 API Reference

### Métodos en ApiService que usar:

```dart
// Login
await ApiService().login(email, password)
// → {access_token, user_id, role, name}

// Send OTP
await ApiService().sendOtp(phone)
// → {success, message, expires_in_minutes}

// Verify OTP
await ApiService().verifyOtp(phone, code)
// → {success, phone_verified}

// Upload KYC
await ApiService().uploadKycDocument(userId, type, file)
// → {success, document_id, file_path}

// Get Cameras
await ApiService().getCameras()
// → {cameras: [...], total_active: 4}
```

---

## ✨ Esto es TODO lo que necesitas para empezar

¡Copia, pega y personaliza! 🚀
