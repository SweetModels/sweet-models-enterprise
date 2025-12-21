# 🎯 QUICK REFERENCE CARD - Flutter Backend Integration

**Imprime esto o mantén abierto en tu pantalla durante las pruebas**

---

## 📋 CHECKLIST PRE-EJECUCIÓN

```
☐ Docker corriendo:              docker-compose ps
☐ Backend responde:              Invoke-RestMethod (ver abajo)
☐ Android Emulator abierto:      Ver lista de dispositivos
☐ Flutter instalado:             flutter --version
☐ Dependencias actualizadas:     cd mobile_app && flutter pub get
```

---

## 🚀 COMANDOS RÁPIDOS

### Backend
```powershell
# Verificar backend
docker-compose ps

# Ver logs backend
docker logs sme_backend -f

# Test endpoint
Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
  -Method Post `
  -Body (@{email="admin@sweetmodels.com"; password="sweet123"} | ConvertTo-Json) `
  -ContentType "application/json"
```

### Flutter
```bash
# Limpiar proyecto
flutter clean

# Obtener dependencias
flutter pub get

# Ejecutar con logs
flutter run -v

# Ejecutar en dispositivo específico
flutter run -d emulator-5554
```

### Emulator
```bash
# Listar dispositivos
flutter devices

# Abrir emulator (desde Android Studio)
# Tools → AVD Manager → Play
```

---

## 🔐 CREDENCIALES

```
Email:    admin@sweetmodels.com
Password: sweet123
```

---

## 🌐 ENDPOINTS

```
POST /api/auth/login
  Input:  { email, password }
  Output: { token, role, user_id, expires_in, ... }
  
GET /api/profile
  Header: Authorization: Bearer <token>
  
GET /api/dashboard
  Header: Authorization: Bearer <token>
```

---

## 📱 DIRECCIONES IP

```
Backend en Host:           http://localhost:3000
Flutter en Android Emu:    http://10.0.2.2:3000
Flutter en iOS Simulator:  http://localhost:3000
Flutter en Dispositivo:    http://<local-ip>:3000
```

---

## 🔍 DEBUGGING RÁPIDO

| Problema | Comando Debug |
|----------|---|
| Backend no responde | `docker logs sme_backend` |
| Error de conexión | `flutter run -v` (ver network logs) |
| Error de parsing | `flutter run -v` (ver JSON response) |
| Token no se guarda | Ver SharedPreferences en logs |
| Crash en UI | `flutter run -v` y buscar "Exception" |

---

## ✅ SIGNOS DE ÉXITO

```
✅ Backend responde con token
✅ No hay "Connection refused"
✅ No hay errores de parsing JSON
✅ App navega a Dashboard
✅ Token guardado en SharedPreferences
✅ Rol mostrado correctamente
```

---

## ❌ SIGNOS DE PROBLEMAS

```
❌ "Connection refused" → Backend no corre
❌ "Invalid credentials" → Email/password incorrecto
❌ "404 Not Found" → Endpoint path incorrecto
❌ "JSON Parse error" → Model desincronizado
❌ "Network unreachable" → IP incorrecta
```

---

## 📂 ARCHIVOS MODIFICADOS

```
✅ mobile_app/lib/api_service.dart
✅ mobile_app/lib/login_screen.dart
✅ mobile_app/lib/services/api_service.dart
```

---

## 🔑 CONFIGURACIONES IMPORTANTES

### Base URL
```dart
// Correcto para Android Emulator:
static const String baseUrl = 'http://10.0.2.2:3000';

// NO usar localhost en Android Emulator
```

### Endpoint
```dart
// Correcto:
_dio.post('/api/auth/login', ...)

// NO es /login
```

### LoginResponse
```dart
// Correcto:
final String token;

// NO es accessToken
```

---

## 📖 DOCUMENTOS

| Documento | Cuando |
|-----------|--------|
| INTEGRATION_COMPLETE.md | Overview rápido |
| FLUTTER_EXECUTION_GUIDE.md | Pasos detallados |
| FLUTTER_BACKEND_INTEGRATION_GUIDE.md | Referencia técnica |
| FINAL_VALIDATION_CHECKLIST.md | Validar todo |
| test_integration.ps1 | Ejecutar tests |

---

## ⏱️ TIEMPOS ESTIMADOS

```
Setup (preparación):        5 min
Compilación (primera vez):  10 min
Ejecución (en emulator):    2 min
Prueba manual (login):      2 min
Total:                      ~20 min
```

---

## 🆘 EMERGENCIES

### Backend no inicia
```powershell
docker-compose down
docker-compose up -d
docker logs sme_backend
```

### Flutter no compila
```bash
flutter clean
rm -r pubspec.lock
flutter pub get
flutter run
```

### Emulator no responde
```bash
# Cerrar y abrir nuevamente
adb kill-server
adb start-server
# O simplemente reiniciar desde Android Studio
```

### Token token inválido
```
Solución: Volver a loguear con credenciales correctas
Email: admin@sweetmodels.com
Password: sweet123
```

---

## 📊 RESPUESTA ESPERADA

```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "role": "admin",
  "user_id": "d27e1bd0-9543-49d0-9ca0-502e143985b3",
  "name": "Admin User"
}
```

---

## 🎬 FLUJO SIMPLIFICADO

```
1. Abrir Emulator
   ↓
2. Ejecutar: flutter run
   ↓
3. Esperar compilación
   ↓
4. Ingrese: admin@sweetmodels.com / sweet123
   ↓
5. Presionar: Login
   ↓
6. Ver: Dashboard ✅
```

---

## 🔗 REFERENCIAS RÁPIDAS

- Flutter Docs: https://flutter.dev/docs
- Dio Package: https://pub.dev/packages/dio
- JWT Decode: https://jwt.io
- Docker Docs: https://docs.docker.com

---

## 💾 GUARDAR EN PANTALLA

**Próximas acciones:**
1. Lee INTEGRATION_COMPLETE.md (5 min)
2. Sigue FLUTTER_EXECUTION_GUIDE.md (15 min)
3. Ejecuta flutter run
4. Prueba login

---

**Última actualización:** 2025-01-17  
**Versión:** 1.0  
**Sistema:** Sweet Models Enterprise

✅ LISTO PARA USAR

