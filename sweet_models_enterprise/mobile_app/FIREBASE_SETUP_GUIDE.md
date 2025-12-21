# 📱 GUÍA COMPLETA: Firebase Cloud Messaging en Flutter

## 📋 Tabla de Contenidos
1. [Configuración Inicial](#configuración-inicial)
2. [Dependencias](#dependencias)
3. [Setup Android](#setup-android)
4. [Setup iOS](#setup-ios)
5. [Integración en el Código](#integración-en-el-código)
6. [Tipos de Notificaciones](#tipos-de-notificaciones)
7. [Ejemplos de Uso](#ejemplos-de-uso)
8. [Troubleshooting](#troubleshooting)

---

## 🚀 Configuración Inicial

### Paso 1: Crear Proyecto Firebase

```bash
# Ir a Firebase Console
https://console.firebase.google.com

# Crear nuevo proyecto:
1. Click "Crear Proyecto"
2. Nombre: "Sweet Models Enterprise"
3. Habilitar Google Analytics (opcional)
4. Crear

# Anotar Project ID (lo necesitarás después)
```

### Paso 2: Descargar FlutterFire CLI

```bash
# Instalar FlutterFire CLI globalmente
dart pub global activate flutterfire_cli

# Configurar Firebase automáticamente
flutterfire configure

# Seleccionar:
# - Project: Sweet Models Enterprise
# - Android: Sí
# - iOS: Sí
# - Platforms: android, ios
```

**Esto genera automáticamente:**
- `firebase_options.dart` (ya creado)
- Configuración en `android/build.gradle`
- Configuración en `ios/Podfile`

---

## 📦 Dependencias

### ✅ Ya Instaladas en `pubspec.yaml`

```yaml
firebase_core: ^3.11.0              # 🔥 Core Firebase
firebase_messaging: ^15.2.10        # 📬 FCM
flutter_local_notifications: ^17.0.0 # 🔔 Notificaciones locales
provider: ^6.0.0                    # 📊 State management
http: ^1.6.0                        # 🌐 HTTP client
shared_preferences: ^2.2.0          # 💾 Almacenamiento local
```

**No necesitas agregar nada más.**

---

## 🤖 Setup Android

### 1. Agregar google-services.json

**Descargar:**
1. Firebase Console → Project Settings → Applications
2. Selecciona tu app Android
3. Click "Download google-services.json"
4. Coloca en: `mobile_app/android/app/google-services.json`

**Archivo esperado en:**
```
mobile_app/
├── android/
│   └── app/
│       ├── google-services.json  ← Aquí
│       └── build.gradle
```

### 2. Verificar android/build.gradle

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    
    dependencies {
        // Google services plugin
        classpath 'com.google.gms:google-services:4.3.15'  // ← Verificar versión
    }
}
```

### 3. Verificar android/app/build.gradle

```gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.google.gms.google-services'  // ← Importante!
}

android {
    namespace "com.sweetmodels.enterprise"
    compileSdk 34  // Mínimo 33
    
    defaultConfig {
        applicationId "com.sweetmodels.enterprise"
        minSdkVersion 21  // Mínimo para FCM
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }
}

dependencies {
    // Firebase
    implementation platform('com.google.firebase:firebase-bom:32.8.1')
    implementation 'com.google.firebase:firebase-messaging'
}
```

### 4. Permisos en AndroidManifest.xml

**`mobile_app/android/app/src/main/AndroidManifest.xml`**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.sweetmodels.enterprise">

    <!-- Permisos FCM -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

---

## 🍎 Setup iOS

### 1. Agregar GoogleService-Info.plist

**Descargar:**
1. Firebase Console → Project Settings → Applications
2. Selecciona tu app iOS
3. Click "Download GoogleService-Info.plist"
4. Arrastra a Xcode (en `Runner` → `Runner`)

**Asegúrate de:**
- ✅ "Copy items if needed" está marcado
- ✅ "Add to targets" es "Runner"

**Ubicación esperada:**
```
mobile_app/ios/Runner/GoogleService-Info.plist
```

### 2. Abrir Xcode

```bash
cd mobile_app/ios
open Runner.xcworkspace  # ⚠️ IMPORTANTE: .xcworkspace, NO .xcodeproj
```

### 3. Habilitar Push Notifications

En Xcode:
1. Selecciona `Runner` (proyecto)
2. Targets → `Runner`
3. Tab "Signing & Capabilities"
4. Click "+ Capability"
5. Busca "Push Notifications"
6. Haz click para agregar
7. ✅ Debe decir "Push Notifications"

### 4. Configurar APNs en Firebase

1. Ir a Firebase Console
2. Configuración del proyecto → Cloud Messaging → iOS app configuration
3. Subir certificado APNs (lo necesitas de Apple Developer Account)

---

## 💻 Integración en el Código

### 1. Inicializar en main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### 2. Inicializar PushNotificationService

**En tu MainScreen o navegación principal:**

```dart
import 'services/push_notification_service.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    
    // Inicializar notificaciones cuando el widget está listo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tu contenido aquí
    );
  }
}
```

### 3. Usar Provider (opcional)

```dart
// En tus providers
final pushNotificationProvider = ChangeNotifierProvider<PushNotificationService>((ref) {
  return PushNotificationService.instance;
});

// En tu widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(pushNotificationProvider);
    
    return Column(
      children: [
        Text('FCM Token: ${notifications.fcmToken}'),
        Text('Inicializado: ${notifications.isInitialized}'),
      ],
    );
  }
}
```

---

## 📬 Tipos de Notificaciones

### 1️⃣ Chat Privado

**Desde Backend (Rust):**
```rust
let payload = NotificationPayload {
    title: "Nuevo mensaje".to_string(),
    body: "Juan: Hola! ¿Cómo estás?".to_string(),
    action: Some("open_chat".to_string()),
    from_user_id: Some("user_123".to_string()),
    from_user_name: Some("Juan".to_string()),
    chat_id: Some("chat_456".to_string()),
};

notification_service.send_alert("user_789", payload, NotificationType::Chat).await?;
```

**En Flutter:**
```dart
// Automáticamente manejado en PushNotificationService
// Navega a /chat con argumentos
```

### 2️⃣ Chat Grupal

```rust
let payload = NotificationPayload {
    title: "Nuevo mensaje en Trabajo".to_string(),
    body: "María: Vamos a grabar mañana".to_string(),
    action: Some("open_group_chat".to_string()),
    group_id: Some("group_789".to_string()),
    group_name: Some("Trabajo".to_string()),
};
```

### 3️⃣ Llamada Entrante

```rust
let payload = NotificationPayload {
    title: "Llamada de Laura".to_string(),
    body: "Tienes una llamada entrante".to_string(),
    action: Some("answer_call".to_string()),
    from_user_id: Some("user_456".to_string()),
    from_user_name: Some("Laura".to_string()),
    call_id: Some("call_123".to_string()),
};
```

### 4️⃣ Notificación de Pago

```rust
let payload = NotificationPayload {
    title: "Pago Recibido".to_string(),
    body: "Recibiste $100 USD por una sesión".to_string(),
    action: Some("show_payment".to_string()),
    amount: Some("100".to_string()),
    currency: Some("USD".to_string()),
};
```

### 5️⃣ Alerta de Seguridad

```rust
let payload = NotificationPayload {
    title: "⚠️ Actividad Sospechosa".to_string(),
    body: "Se intentó acceder a tu cuenta desde una ubicación desconocida".to_string(),
    action: Some("show_security_alert".to_string()),
    alert_type: Some("unauthorized_access".to_string()),
};
```

---

## 🧪 Ejemplos de Uso

### Ejemplo 1: Enviar notificación desde Backend

**Endpoint REST:**
```bash
curl -X POST http://localhost:3000/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Nuevo mensaje",
    "body": "Tienes un nuevo mensaje de Juan",
    "action": "open_chat",
    "from_user_id": "123",
    "from_user_name": "Juan"
  }'
```

### Ejemplo 2: Registrar dispositivo del usuario

**En Flutter:**
```dart
// Automático en initialize()
// El servicio hace POST a:
// POST /api/notifications/devices/:user_id

// Con payload:
{
  "fcm_token": "eR1...",
  "platform": "ANDROID",
  "device_name": "Samsung Galaxy S23"
}
```

### Ejemplo 3: Notificación cuando app está abierta

**Automático - el snackbar se muestra:**
```dart
// El servicio detecta que la app está abierta y muestra:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('💬 Juan: Hola!'),
    // Estilos cyan del proyecto
  ),
);
```

### Ejemplo 4: Notificación cuando app está cerrada

**Automático:**
1. Sistema recibe notificación
2. Muestra notificación del sistema
3. Usuario toca → App se abre
4. `onMessageOpenedApp` listener navega al chat

---

## 🐛 Troubleshooting

### ❌ Token no se obtiene

**Causas comunes:**
- Firebase no inicializado en main.dart
- google-services.json no en la ubicación correcta
- Internet deshabilitado

**Solución:**
```dart
// Verificar en debug console
PushNotificationService.instance.debugPrintTokens();

// Verifica:
// [FCM] FCM Token: null  ← Problema
// [FCM] Is Initialized: false ← Problema
```

### ❌ Permisos no otorgados

**Android:**
- Ve a Settings → Apps → Tu App → Permissions → Notifications
- Habilitar "Allow notifications"

**iOS:**
- Ir a Settings → Tu App → Notifications
- Habilitar "Allow Notifications"

### ❌ Notificaciones no llegan

**Verificar:**
1. ¿Token está registrado en backend?
   ```bash
   SELECT * FROM device_tokens WHERE user_id = 'tu_user_id';
   ```

2. ¿Google Play Services está instalado? (solo Android)
   ```bash
   adb shell pm list packages | grep gms
   ```

3. ¿Firebase proyecto tiene billing habilitado?
   - Firebase Console → Billing (algunos países requieren tarjeta)

4. ¿google-services.json es del proyecto correcto?
   - Verificar `project_id` en el archivo

### ❌ App se crashea al inicializar

**Causas:**
- firebase_options.dart tiene valores incorrectos
- Firebase no se inicializó en main.dart

**Solución:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // ← IMPORTANTE
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Error: $e');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## 📊 Monitoreo

### Ver logs en Firebase Console

1. Firebase Console → Cloud Messaging
2. Ir a "Analytics"
3. Ver:
   - Mensajes enviados
   - Tasas de entrega
   - Errores

### Verificar tokens en BD

```sql
-- En PostgreSQL
SELECT 
    id,
    user_id,
    fcm_token,
    platform,
    device_name,
    is_active,
    created_at,
    last_used_at
FROM device_tokens
ORDER BY created_at DESC
LIMIT 10;
```

---

## ✅ Checklist de Configuración

- [ ] Firebase proyecto creado
- [ ] FlutterFire CLI ejecutado
- [ ] `google-services.json` en `android/app/`
- [ ] `GoogleService-Info.plist` en `ios/Runner/`
- [ ] Push Notifications capability en Xcode
- [ ] `firebase_options.dart` generado
- [ ] Firebase inicializado en `main.dart`
- [ ] `PushNotificationService` inicializado
- [ ] Token se obtiene correctamente
- [ ] Backend registra tokens
- [ ] Permisos otorgados en dispositivo
- [ ] Notificaciones recibidas en foreground/background

---

## 🔗 Referencias

- [Firebase Flutter Documentation](https://firebase.flutter.dev)
- [FCM Messaging Guide](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [APNs Certificate Setup](https://firebase.google.com/docs/cloud-messaging/ios/certs)

---

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs: `flutter logs`
2. Ejecuta `flutter doctor -v`
3. Limpia caché: `flutter clean && flutter pub get`
4. Recompila: `flutter run -v`
