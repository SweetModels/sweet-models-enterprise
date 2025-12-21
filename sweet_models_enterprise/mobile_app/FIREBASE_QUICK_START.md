# ⚡ INICIO RÁPIDO - Push Notifications en 5 Minutos

## 📋 Lo que ya está hecho ✅

```
✅ PushNotificationService.dart - Servicio completo
✅ firebase_options.dart - Configuración base
✅ push_notification_example_screen.dart - Pantalla de demo
✅ main.dart - Firebase inicializado
✅ Documentación completa (FIREBASE_SETUP_GUIDE.md)
✅ Ejemplos de notificaciones (FIREBASE_NOTIFICATION_EXAMPLES.md)
```

---

## 🚀 Pasos para Activar (Solo 3 pasos!)

### PASO 1: Descargar Archivos de Configuración

#### Android

```bash
# 1. Ve a: https://console.firebase.google.com
# 2. Proyecto → Configuración → Descargar google-services.json
# 3. Guarda en: mobile_app/android/app/google-services.json
```

#### iOS

```bash
# 1. Ve a: https://console.firebase.google.com
# 2. Proyecto → Configuración → Descargar GoogleService-Info.plist
# 3. En Xcode:
#    - Abre: mobile_app/ios/Runner.xcworkspace
#    - Arrastra el .plist a Runner → Runner
#    - ✅ "Copy items if needed"
```

### PASO 2: Agregar a tu MainScreen

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
    
    // Esto inicializa las notificaciones
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

### PASO 3: Reemplazar User ID Real

En `push_notification_service.dart`, línea ~135:

```dart
// ANTES:
const String backendUrl = 'http://localhost:3000/api/notifications/devices';
final response = await http.post(
  Uri.parse('$backendUrl/550e8400-e29b-41d4-a716-446655440000'), // ← DUMMY
  
// DESPUÉS:
const String backendUrl = 'http://localhost:3000/api/notifications/devices';
String userId = await _getCurrentUserId(); // O desde SharedPreferences
final response = await http.post(
  Uri.parse('$backendUrl/$userId'),
```

---

## 🧪 Probar Rápidamente

### Opción A: Con Pantalla de Demo

```dart
// En tu router/navigation
routes: {
  '/notifications-demo': (context) => const PushNotificationExampleScreen(),
}

// Luego accede a: localhost:8080/#/notifications-demo
```

### Opción B: Con cURL desde Terminal

```bash
# Registrar dispositivo
curl -X POST http://localhost:3000/api/notifications/devices/550e8400-e29b-41d4-a716-446655440000 \
  -H "Content-Type: application/json" \
  -d '{
    "fcm_token": "test_token_123",
    "platform": "ANDROID",
    "device_name": "My Device"
  }'

# Enviar notificación
curl -X POST http://localhost:3000/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "¡Hola!",
    "body": "Primera notificación",
    "action": "open_chat"
  }'
```

---

## 📱 Qué Pasa Después

### Cuando App Está ABIERTA 🟢

```
1. Recibe notificación
2. Muestra SnackBar elegante (cyan)
3. Usuario puede tocar para navegar
```

### Cuando App Está CERRADA 🔴

```
1. Recibe notificación del sistema
2. Muestra en bandeja de notificaciones
3. Usuario toca → App se abre
4. Navega automáticamente al destino
```

---

## 🔧 Ajustes Comunes

### Cambiar Backend URL

**En:** `push_notification_service.dart` línea ~130

```dart
const String backendUrl = 'http://localhost:3000/api/notifications/devices';
                         // ↑ Cambiar aquí
```

### Cambiar URL en Producción

```dart
const String backendUrl = Platform.isDebug 
  ? 'http://localhost:3000/api/notifications/devices'
  : 'https://api.sweetmodels.com/api/notifications/devices';
```

### Cambiar Sonido de Notificación

**En:** `push_notification_service.dart` línea ~200

```dart
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'sweet_models_channel',
  'Sweet Models',
  sound: RawResourceAndroidNotificationSound('notification'), // ← Cambiar
);
```

Debe existir en: `android/app/src/main/res/raw/notification.mp3`

### Cambiar Color del LED

```dart
color: Color.fromARGB(255, 0, 245, 255), // ← Cambiar a tu color
```

### Cambiar Color del Snackbar

**En:** `push_notification_service.dart` línea ~280

```dart
backgroundColor: const Color(0xFF09090B), // ← Fondo
// y
side: const BorderSide(
  color: Color(0xFF00F5FF), // ← Borde
  width: 1.5,
),
```

---

## 🛠️ Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| ❌ Token es null | Verificar que Firebase inicializado en main.dart |
| ❌ No llega notificación | Token debe estar en BD: `SELECT * FROM device_tokens` |
| ❌ App se crashea | Revisar google-services.json está correcto |
| ❌ Permisos denegados | Settings → Tu App → Notifications → Habilitar |
| ❌ Sin sonido | Verificar archivo `notification.mp3` existe en android/app/src/main/res/raw/ |

---

## 📚 Documentación Completa

**Lee estos archivos para más detalles:**

1. **FIREBASE_SETUP_GUIDE.md** - Configuración paso a paso
2. **FIREBASE_NOTIFICATION_EXAMPLES.md** - Ejemplos de notificaciones
3. **push_notification_service.dart** - Código comentado

---

## 🎯 Próximos Pasos

1. **Ejecutar la app:**

   ```bash
   cd mobile_app
   flutter pub get
   flutter run
   ```

2. **Ver logs:**

   ```bash
   flutter logs | grep FCM
   ```

3. **Enviar primer notificación:**

   ```bash
   # Desde terminal con cURL (ver arriba)
   ```

4. **Navega a chat/llamada/pago** cuando tapes la notificación

---

## 📞 Contacto

Si algo no funciona:

- Revisa `flutter logs` para errores
- Ejecuta `flutter doctor -v`
- Limpia: `flutter clean && flutter pub get`

¡Listo! 🎉
