# Configuración de Firebase para Android

## Checklist de Configuración

### ✅ Pasos Completados
- [x] Gradle actualizado con plugin de Google Services
- [x] AndroidManifest.xml con permisos necesarios
- [x] firebase_core en pubspec.yaml

### ⚠️ Pasos Pendientes (Manuales)

#### 1. **Crear Proyecto Firebase**
```
1. Ve a https://console.firebase.google.com/
2. Click "Crear proyecto"
3. Nombre: sweet-models-enterprise
4. Desactiva Google Analytics
5. Click "Crear proyecto"
```

#### 2. **Registrar App Android**
```
1. En Firebase Console → Agregar app → Android
2. Nombre del paquete: com.example.sweet_models_mobile
3. SHA-1 fingerprint (opcional):
   - En PowerShell:
   keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### 3. **Descargar google-services.json**
```
1. En Firebase Console, click "Descargar google-services.json"
2. Coloca el archivo en:
   mobile_app/android/app/google-services.json
```

#### 4. **Habilitar Servicios**
En Firebase Console, activa:
- ☐ Cloud Messaging (FCM)
- ☐ Realtime Database (o Firestore)
- ☐ Authentication
- ☐ Storage (para fotos)

#### 5. **Configurar Authentication**
```
En Firebase Console → Authentication:
- Email/Password: Habilitar
- Phone: Habilitar (opcional)
- Custom Claims (para roles)
```

#### 6. **Crear Reglas de Realtime Database**
```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "models": {
      ".read": "auth != null",
      ".write": "auth != null && root.child('users').child(auth.uid).child('role').val() === 'admin'"
    }
  }
}
```

### 📱 Configuración de API_SERVICE

El archivo `lib/api_service.dart` debe usar FirebaseAuth:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // Generado por flutterfire CLI

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// En login:
final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

### 🔧 Generar FirebaseOptions (Firebase CLI)

```powershell
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar Firebase para el proyecto
flutterfire configure --project=sweet-models-enterprise

# Esto genera:
# - lib/firebase_options.dart
# - Actualiza android/build.gradle
# - Actualiza android/app/build.gradle
```

### 🧪 Probar Conexión

```dart
// En main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const ProviderScope(child: MyApp()));
}

// En login_screen.dart, verificar:
try {
  final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  print('✅ Login Firebase exitoso: ${userCredential.user?.email}');
} catch (e) {
  print('❌ Error Firebase: $e');
}
```

### 📋 Dependencias Necesarias

```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_auth: ^4.12.0
  firebase_database: ^10.2.0
  firebase_messaging: ^14.6.0
  cloud_firestore: ^4.13.0  # Opcional
```

### 🚀 Compilar y Ejecutar

```powershell
cd "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise\mobile_app"

# Limpiar y obtener dependencias
flutter clean
flutter pub get

# Compilar para Android
flutter build apk --release

# O ejecutar en emulador/dispositivo
flutter run -d <device-id>
```

### 🔐 Variables de Entorno (Opcional)

Crear archivo `.env`:
```
FIREBASE_PROJECT_ID=sweet-models-enterprise
FIREBASE_API_KEY=your_api_key_here
FIREBASE_SENDER_ID=your_sender_id_here
```

---

**Última actualización**: 14 Diciembre 2025  
**Estado**: Listo para configurar manualmente en Firebase Console
