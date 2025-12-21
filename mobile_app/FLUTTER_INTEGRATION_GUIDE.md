# 📱 Integración de Nuevas Funcionalidades - Flutter App

## 🆕 Funcionalidades Disponibles en el Backend

La app móvil ya puede integrar estos 3 nuevos sistemas:

---


## 1️⃣ **VERIFICACIÓN POR OTP (SMS)**

### **Flujo de Registro con OTP**

```dart
// 1. Usuario ingresa teléfono en RegisterModelScreen
final phone = "+573001234567";

// 2. Llamar endpoint send-otp
final response = await ApiService().sendOtp(phone);
if (response['success']) {
  print('OTP enviado a $phone');
  // Mostrar pantalla de ingreso de código
}

// 3. Usuario ingresa código (simulado en consola del servidor)
final otpCode = "244045"; // Ver logs: "ENVIO SMS A [+57...]: CÓDIGO OTP = 244045"

// 4. Verificar OTP
final verifyResponse = await ApiService().verifyOtp(phone, otpCode);
if (verifyResponse['phone_verified']) {
  print('✅ Teléfono verificado');
  // Continuar con registro
}

```

### **Actualizar ApiService para OTP**

```dart
// Agregar a lib/api_service.dart

Future<Map<String, dynamic>> sendOtp(String phone) async {
  try {
    final response = await _dio.post(
      '/auth/send-otp',
      data: {
        'phone': phone,
      },
    );

    print('✅ OTP enviado: ${response.data}');
    return response.data;
  } on DioException catch (e) {
    if (e.response != null) {
      throw Exception(e.response?.data.toString() ?? 'Error al enviar OTP');
    } else {
      throw Exception('Error de conexión: ${e.message}');
    }
  }
}

Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
  try {
    final response = await _dio.post(
      '/auth/verify-otp',
      data: {
        'phone': phone,
        'code': code,
      },
    );

    print('✅ OTP verificado: ${response.data}');
    return response.data;
  } on DioException catch (e) {
    if (e.response != null) {
      throw Exception(e.response?.data.toString() ?? 'Error al verificar OTP');
    } else {
      throw Exception('Error de conexión: ${e.message}');
    }
  }
}

```

---


## 2️⃣ **GESTIÓN DE CÁMARAS CCTV**

### **Implementación en Flutter**

```dart
// lib/camera_monitor_screen.dart - ACTUALIZADO

import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraMonitorScreen extends StatefulWidget {
  const CameraMonitorScreen({Key? key}) : super(key: key);

  @override
  State<CameraMonitorScreen> createState() => _CameraMonitorScreenState();
}

class _CameraMonitorScreenState extends State<CameraMonitorScreen> {
  late Future<Map<String, dynamic>> _camerasFuture;
  String _userRole = '';
  bool _hasAccess = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _camerasFuture = _loadCameras();
  }

  Future<void> _checkAdminAccess() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('user_role') ?? '';

    if (_userRole != 'admin') {
      setState(() => _hasAccess = false);
      return;
    }
  }

  Future<Map<String, dynamic>> _loadCameras() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No authentication token');
      }

      // El header Authorization se agrega automáticamente en ApiService
      final camerasData = await ApiService().getCameras();
      return camerasData;
    } catch (e) {
      print('Error loading cameras: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cámaras de Seguridad')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Acceso Denegado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Solo administradores pueden ver las cámaras'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cámaras en Vivo'),
        backgroundColor: const Color(0xFF1D1E33),
      ),
      backgroundColor: const Color(0xFF0A0E27),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _camerasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data ?? {};
          final cameras = List.from(data['cameras'] ?? []);
          final totalActive = data['total_active'] ?? 0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: true,
                backgroundColor: const Color(0xFF1A1F3A),
                title: Text(
                  '📹 $totalActive Cámaras Activas',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 16 / 9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final camera = cameras[index];
                    return _buildCameraCard(camera);
                  },
                  childCount: cameras.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraCard(Map<String, dynamic> camera) {
    return GestureDetector(
      onTap: () => _showCameraDetails(camera),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: camera['is_active'] ? Colors.green : Colors.grey,
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder para video RTSP
            Container(
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.videocam, size: 48, color: Colors.grey),
              ),
            ),
            // Overlay con información
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Info
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    camera['name'] ?? 'Camera',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    camera['platform'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Badge EN VIVO
            if (camera['is_active'])
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EN VIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCameraDetails(Map<String, dynamic> camera) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(camera['name'] ?? 'Camera Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('ID', camera['id'].toString()),
            _detailRow('Nombre', camera['name'] ?? 'N/A'),
            _detailRow('Plataforma', camera['platform'] ?? 'N/A'),
            _detailRow('Estado', camera['is_active'] ? '🟢 Activa' : '🔴 Inactiva'),
            _detailRow('URL RTSP', camera['stream_url'] ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

```

### **Actualizar ApiService**

```dart
// Agregar a lib/api_service.dart

Future<Map<String, dynamic>> getCameras() async {
  try {
    final response = await _dio.get('/admin/cameras');
    print('✅ Cameras fetched: ${response.data}');
    return response.data;
  } on DioException catch (e) {
    if (e.response != null) {
      throw Exception(e.response?.data.toString() ?? 'Error fetching cameras');
    } else {
      throw Exception('Error de conexión: ${e.message}');
    }
  }
}

```

---


## 3️⃣ **UPLOAD DE DOCUMENTOS KYC**

### **Implementación en Flutter**

```dart
// Agregar a lib/api_service.dart

Future<Map<String, dynamic>> uploadKycDocument({
  required String userId,
  required String documentType, // 'national_id_front', 'national_id_back', 'selfie', 'proof_address'
  required File imageFile,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/kyc'),
    );

    // Agregar fields
    request.fields['user_id'] = userId;
    request.fields['document_type'] = documentType;

    // Agregar archivo
    var file = await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    );
    request.files.add(file);

    // Enviar
    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      print('✅ Document uploaded: $responseData');
      return jsonDecode(responseData);
    } else {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error uploading KYC: $e');
    rethrow;
  }
}

```

### **Pantalla de Upload en RegisterModelScreen**

```dart
// Agregar a lib/register_model_screen.dart

Future<void> _uploadDocument(String documentType) async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.camera);

  if (image == null) return;

  final file = File(image.path);

  try {
    setState(() => _isLoading = true);

    final response = await ApiService().uploadKycDocument(
      userId: userId, // Obtenido del login
      documentType: documentType,
      imageFile: file,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${documentType} subido exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

```

---


## 📝 ACTUALIZACIÓN DE PUBSPEC.YAML

```yaml
dependencies:
  image_picker: ^0.8.9
  http_parser: ^4.0.2
  # ... otros

```

Instalar:

```bash
flutter pub add image_picker http_parser

```

---


## 🔄 FLUJO COMPLETO DE REGISTRO CON OTP Y KYC

```

┌─ REGISTRO MODELO ─┐
│                  │
├─ Datos básicos   │
│ (email, nombre)  │
│                  │
├─ Verificación    │
│ de teléfono (OTP)│
│  ↓               │
│ /auth/send-otp   │
│ /auth/verify-otp │
│                  │
├─ Documentos KYC  │
│ (fotos)          │
│  ↓               │
│ /upload/kyc      │
│                  │
└─ ✅ Registro OK  │

```

---


## 🧪 TESTS EN FLUTTER

```dart
// test/api_service_test.dart

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('New Security Features', () {
    test('Send OTP', () async {
      final response = await ApiService().sendOtp('+573001234567');
      expect(response['success'], true);
      expect(response['expires_in_minutes'], 10);
    });

    test('Verify OTP', () async {
      // Primero enviar OTP
      await ApiService().sendOtp('+573001234567');

      // Luego verificar (usar código real del servidor)
      final response = await ApiService().verifyOtp('+573001234567', '244045');
      expect(response['phone_verified'], true);
    });

    test('Get Cameras (requires admin token)', () async {
      // Hacer login como admin
      final loginResponse = await ApiService().login(
        'karber.pacheco007`@gmail.com`',
        'Isaias..20-26',
      );

      // Obtener cámaras
      final camerasResponse = await ApiService().getCameras();
      expect(camerasResponse['total_active'], greaterThan(0));
    });
  });
}

```

---


## 🚀 PRÓXIMOS PASOS

1. **Integrar OTP en RegisterModelScreen**
   - Agregar campo de teléfono
   - Botón "Enviar OTP"
   - Pantalla para ingresar código
2. **Mejorar CameraMonitorScreen**
   - Integrar flutter_vlc_player para video RTSP
   - Mostrar stream en vivo
   - Controles de play/pause
3. **Sistema de KYC completo**
   - Cámara para fotografías
   - Galería de documentos
   - Estado de aprobación
4. **Notificaciones**
   - When KYC approved/rejected
   - When camera goes offline
   - New security alerts
---
**¡App y Backend están listos para integración completa! 🎉**
