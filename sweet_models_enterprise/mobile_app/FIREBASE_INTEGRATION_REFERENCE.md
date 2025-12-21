# 📱 INTEGRACIÓN FIREBASE - CHECKLIST Y REFERENCIAS

## ✅ Archivos Creados

```
mobile_app/
├── lib/
│   ├── services/
│   │   └── push_notification_service.dart        ✅ (520 líneas)
│   ├── screens/
│   │   └── push_notification_example_screen.dart ✅ (350 líneas)
│   ├── main.dart                                  ✅ (Modificado)
│   └── firebase_options.dart                      ✅ (80 líneas)
│
├── FIREBASE_SETUP_GUIDE.md                        ✅ (Guía completa)
├── FIREBASE_NOTIFICATION_EXAMPLES.md              ✅ (7 ejemplos)
├── FIREBASE_QUICK_START.md                        ✅ (5 min start)
└── FIREBASE_INTEGRATION_REFERENCE.md              ✅ (Este archivo)
```

---

## 🔑 Características Implementadas

### PushNotificationService
```dart
✅ initialize(context)              - Iniciar FCM
✅ Solicitar permisos              - iOS + Android
✅ Obtener token FCM               - Automático
✅ Registrar en backend            - HTTP POST
✅ onMessage listener              - App abierta
✅ onBackgroundMessage             - App cerrada
✅ onMessageOpenedApp              - Notificación tocada
✅ Deep linking                    - Navegar según acción
✅ Snackbar personalizado          - Estilo cyan
✅ Notificaciones locales          - Sonido + vibración
✅ Token refresh automático        - Mantener sincronizado
✅ Debugging utilities             - debugPrintTokens()
```

---

## 🔄 Flujos de Notificaciones

### Flujo 1: App Abierta (Foreground)
```
1. Backend envía notificación FCM
2. Firebase Cloud Messaging recibe
3. onMessage listener captura
4. showLocalNotification() muestra
5. ScaffoldMessenger muestra SnackBar
6. Usuario puede tocar → _handleNotificationTap
7. Navega según acción
```

### Flujo 2: App Cerrada (Background)
```
1. Backend envía notificación FCM
2. Sistema recibe (no hay app abierta)
3. _firebaseMessagingBackgroundHandler ejecuta
4. showLocalNotification() muestra en bandeja
5. Usuario toca notificación del sistema
6. App abre
7. onMessageOpenedApp captura
8. _handleNotificationTap navega
```

### Flujo 3: Token Registration
```
1. App abre
2. PushNotificationService.initialize()
3. _getFCMToken() obtiene token
4. _registerTokenOnBackend() guarda en BD
5. Backend almacena en device_tokens
6. onTokenRefresh() vigila cambios
7. Si cambia: registra nuevo token
```

---

## 📡 Comunicación Backend ↔ Frontend

### 1. Registrar Dispositivo

**Request:**
```http
POST /api/notifications/devices/:user_id
Content-Type: application/json

{
  "fcm_token": "eRl_Np2gRhyXm...",
  "platform": "ANDROID",
  "device_name": "Samsung Galaxy S23"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Token registrado exitosamente",
  "data": {
    "id": "550e8401-...",
    "platform": "ANDROID",
    "is_active": true,
    "created_at": "2024-12-10T15:30:00Z"
  }
}
```

### 2. Enviar Notificación

**Request:**
```http
POST /api/notifications/send
Content-Type: application/json

{
  "user_id": "550e8400-...",
  "title": "Nuevo mensaje",
  "body": "Juan te escribió",
  "action": "open_chat",
  "from_user_id": "user_123",
  "from_user_name": "Juan",
  "chat_id": "chat_456"
}
```

**Manejo en Flutter:**
- `action: "open_chat"` → Navigator a `/chat` con `chat_id`
- `from_user_name: "Juan"` → Mostrar en UI
- Demás campos → Guardar en payload para contexto

---

## 🎨 Estructura de Notificaciones

### Payload Completo

```dart
class NotificationPayload {
  // Base
  String title              // Título de notificación
  String body               // Descripción
  String? action            // open_chat, answer_call, etc.
  
  // Chat
  String? chat_id           // ID de conversación
  String? from_user_id      // Quién envía
  String? from_user_name    // Nombre del remitente
  String? group_id          // Para chats grupales
  String? group_name        // Nombre del grupo
  
  // Llamadas
  String? call_id           // ID de llamada
  String? call_type         // video_session, audio_call
  
  // Pagos
  String? amount            // Monto
  String? currency          // USD, COP, etc.
  String? payment_method    // stripe, paypal, etc.
  String? reference_id      // ID de transacción
  
  // Seguridad
  String? alert_type        // unauthorized_login, etc.
  String? ip_address        // Para alertas
  String? location          // Ubicación
  
  // Social
  String? post_id           // Para posts
  String? likes_count       // Número de likes
  String? comments_count    // Número de comentarios
  String? profile_image_url // URL de avatar
}
```

---

## 🎯 Acciones (Actions)

| Acción | Resultado | Ruta |
|--------|-----------|------|
| `open_chat` | Abre chat privado | `/chat?chat_id=xxx` |
| `open_group_chat` | Abre chat grupal | `/group-chat?group_id=xxx` |
| `answer_call` | Muestra pantalla de llamada | `/call?call_id=xxx` |
| `show_payment` | Abre historial de pagos | `/payments` |
| `show_security_alert` | Muestra alertas de seguridad | `/security-alerts` |
| `open_profile` | Abre perfil de usuario | `/profile?user_id=xxx` |
| `open_post` | Abre post | `/feed?post_id=xxx` |

---

## 🔐 Configuración de Firebase

### firebase_options.dart

Este archivo contiene las credenciales de Firebase. Se genera automáticamente con:

```bash
flutterfire configure
```

**Contiene:**
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSy...',                    // De google-services.json
  appId: '1:123456:android:abc123...',
  messagingSenderId: '123456',
  projectId: 'your-project-id',
  storageBucket: 'your-project.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSy...',
  appId: '1:123456:ios:def456...',
  messagingSenderId: '123456',
  projectId: 'your-project-id',
  storageBucket: 'your-project.appspot.com',
  iosClientId: '123456-ios.apps.googleusercontent.com',
  iosBundleId: 'com.example.sweetModels',
);
```

---

## 📲 Permisos Requeridos

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS (Info.plist)
```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

---

## 🧪 Testing

### Test 1: Token se obtiene correctamente

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final service = PushNotificationService.instance;
  await service.initialize(context);
  
  expect(service.fcmToken, isNotNull);
  expect(service.isInitialized, isTrue);
}
```

### Test 2: Notificación se muestra

```dart
test('Notificación local se muestra', () async {
  PushNotificationService.instance.showLocalNotification(
    title: 'Test',
    body: 'Prueba',
    payload: {'action': 'test'},
  );
  
  // Verificar en logs
  // [FCM] 🔔 Notificación local mostrada: Test
});
```

### Test 3: Deep linking funciona

```dart
test('Deep linking navega correctamente', () {
  final remoteMessage = RemoteMessage(
    notification: RemoteNotification(
      title: 'Chat',
      body: 'Test',
    ),
    data: {
      'action': 'open_chat',
      'chat_id': 'chat_123',
    },
  );
  
  // Simular tap
  _handleNotificationTap(context, remoteMessage);
  
  // Verificar navegación
});
```

---

## 🚀 Deployment

### Pre-Deployment Checklist

```
[ ] firebase_options.dart tiene credenciales correctas
[ ] google-services.json en android/app/
[ ] GoogleService-Info.plist en ios/Runner/
[ ] Push Notifications capability agregada en Xcode
[ ] Permisos en AndroidManifest.xml
[ ] PushNotificationService.initialize() en main screen
[ ] Token se registra en backend (verificar DB)
[ ] Notificación de prueba se recibe
[ ] Navegación funciona al tocar notificación
[ ] Prodbe ambas plataformas (Android + iOS)
[ ] Prueba con app abierta y cerrada
```

### Environment URLs

```dart
// Development
const String API_URL = 'http://localhost:3000';

// Staging
const String API_URL = 'https://staging-api.sweetmodels.com';

// Production
const String API_URL = 'https://api.sweetmodels.com';
```

---

## 📊 Base de Datos

### Tabla: device_tokens

```sql
CREATE TABLE device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL UNIQUE,
  platform VARCHAR(50) NOT NULL CHECK (platform IN ('ANDROID', 'IOS')),
  device_name TEXT,
  is_active BOOLEAN DEFAULT true,
  last_used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Verificar tokens registrados
SELECT user_id, COUNT(*) as device_count
FROM device_tokens
WHERE is_active = true
GROUP BY user_id;

-- Buscar tokens de un usuario
SELECT * FROM device_tokens
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'
AND is_active = true;
```

---

## 🔗 Referencias de Archivos

```
Backend (Rust):
  src/notifications/mod.rs              (548 líneas)
  src/notifications/handlers.rs         (121 líneas)
  src/social/chat_notifications.rs      (170 líneas)
  migrations/20251209000002_*            (SQL schema)

Frontend (Flutter):
  lib/services/push_notification_service.dart        (520 líneas)
  lib/screens/push_notification_example_screen.dart  (350 líneas)
  lib/firebase_options.dart                           (80 líneas)
  lib/main.dart                                       (modificado)

Documentación:
  FIREBASE_SETUP_GUIDE.md               (Guía completa)
  FIREBASE_NOTIFICATION_EXAMPLES.md     (7 ejemplos)
  FIREBASE_QUICK_START.md               (5 min start)
  FIREBASE_INTEGRATION_REFERENCE.md     (Este archivo)
```

---

## 🛠️ Troubleshooting Matrix

| Síntoma | Causa Probable | Solución |
|---------|----------------|----------|
| Token es null después de init | Firebase no está inicializado | Verificar `Firebase.initializeApp()` en main |
| App se crashea al iniciar | Credenciales incorrectas en firebase_options | Ejecutar `flutterfire configure` |
| No llega notificación al backend | Token no registrado en BD | Ver logs: `[FCM] ✅ Token registrado...` |
| Snackbar no aparece | onMessage listener no funcionando | Verificar que la app está en foreground |
| No recibe cuando app cerrada | Background handler no registrado | Ver logs de background |
| Navegación no funciona | Action desconocida o mal mapeada | Ver switch en `_navigateToCorrectScreen()` |
| Sin sonido | Archivo de audio no existe | Agregar a `android/app/src/main/res/raw/` |
| Permisos denegados | Usuario rechazó en diálogo | Ir a Settings → Notifications → Enable |

---

## 📞 Contacto y Soporte

**Archivos de referencia rápida:**
- `FIREBASE_QUICK_START.md` - Para empezar en 5 minutos
- `FIREBASE_SETUP_GUIDE.md` - Para configuración paso a paso
- `FIREBASE_NOTIFICATION_EXAMPLES.md` - Para ver ejemplos reales

**Si algo no funciona:**
1. Revisar logs: `flutter logs | grep FCM`
2. Ejecutar: `flutter doctor -v`
3. Limpiar: `flutter clean && flutter pub get`
4. Recompilar: `flutter run -v`

---

**Última actualización:** 2024-12-10
**Versión:** 1.0 (Producción)
**Estado:** ✅ Listo para deploy
