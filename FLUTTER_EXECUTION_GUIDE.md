# 🚀 Guía de Ejecución: Flutter Login Test

**Objetivo:** Probar el login desde Flutter conectando con backend Rust  
**Tiempo estimado:** 15 minutos  
**Requisitos:** Docker corriendo, Android Emulator, Flutter SDK

---

## ⚡ INICIO RÁPIDO (5 Pasos)

### Paso 1: Verificar Backend está corriendo
```powershell
# Abre PowerShell y ejecuta:
docker-compose ps

# Debería mostrar:
# NAME          STATUS
# sme_postgres  Up (healthy)
# sme_backend   Up (healthy)

# Si no está corriendo:
docker-compose up -d
```

### Paso 2: Verificar conectividad al backend
```powershell
# Test rápido:
Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" -Method Post `
  -Body (@{email="admin@sweetmodels.com"; password="sweet123"} | ConvertTo-Json) `
  -ContentType "application/json" | ConvertTo-Json

# Debe retornar un JSON con campo "token"
```

### Paso 3: Abrir Android Emulator
```bash
# Opción 1: Desde Android Studio
# Tools → AVD Manager → Selecciona dispositivo → Play

# Opción 2: Desde línea de comandos
emulator -avd Pixel_4_API_30 -netdelay none -netspeed full

# Espera a que el emulator termine de cargar (2-3 minutos)
```

### Paso 4: Compilar y ejecutar Flutter
```bash
# Abre terminal en la carpeta mobile_app
cd "c:\Users\Sweet\OneDrive\Desktop\Sweet Models Enterprise\mobile_app"

# Limpiar y obtener dependencias
flutter clean
flutter pub get

# Ejecutar en el emulator
flutter run

# Espera a que compile (5-10 minutos la primera vez)
```

### Paso 5: Probar login manualmente
```
1. La aplicación Flutter se abrirá en el Android Emulator
2. Verás la pantalla de Login
3. Ingresa:
   Email: admin@sweetmodels.com
   Password: sweet123
4. Presiona el botón "Login" o "Iniciar Sesión"
5. Espera 2-3 segundos mientras se conecta
6. Si todo funciona, deberías ver:
   ✅ Pantalla de carga se muestra
   ✅ Token se guarda (silenciosamente)
   ✅ Navegas a la pantalla de Dashboard
   ✅ Se muestra información del usuario (nombre, rol, etc.)
```

---

## 🔍 VALIDACIÓN PASO A PASO

### Verificación 1: Backend Operacional
```powershell
Write-Host "Verificando backend..."

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
    -Method Post `
    -Body (@{
        email = "admin@sweetmodels.com"
        password = "sweet123"
    } | ConvertTo-Json) `
    -ContentType "application/json"

Write-Host "✅ Token recibido:" $response.token.Substring(0, 50) "..."
Write-Host "✅ Role: " $response.role
Write-Host "✅ User ID: " $response.user_id
```

**Resultado esperado:**
```
✅ Token recibido: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJz...
✅ Role: admin
✅ User ID: d27e1bd0-9543-49d0-9ca0-502e143985b3
```

### Verificación 2: Flutter Config
```bash
cd mobile_app/lib
grep -n "10.0.2.2:3000" api_service.dart  # Debe encontrar la línea
grep -n "/api/auth/login" api_service.dart  # Debe encontrar la línea
grep -n "final String token" api_service.dart  # Debe encontrar la línea
```

**Resultado esperado:**
```
✅ baseUrl configurada: http://10.0.2.2:3000
✅ Endpoint configurado: /api/auth/login
✅ Model tiene campo: token
```

### Verificación 3: Android Emulator Conectado
```bash
# Verificar que el emulador está corriendo y conectado a Flutter
flutter devices

# Debe mostrar algo como:
# Android SDK built for x86 • emulator-5554 • android • Android 11 (API 30)
```

---

## 🧪 ESCENARIOS DE PRUEBA

### Scenario 1: Login Exitoso (ADMIN)
```
Input:
  Email: admin@sweetmodels.com
  Password: sweet123

Expected Output:
  ✅ Token guardado en SharedPreferences
  ✅ Navegación a Dashboard
  ✅ Rol mostrado: ADMIN
  ✅ Nombre mostrado: Admin User

Status: 🟢 PASS
```

### Scenario 2: Credenciales Incorrectas
```
Input:
  Email: admin@sweetmodels.com
  Password: contraseñaIncorrecta

Expected Output:
  ✅ Mensaje de error: "Credenciales inválidas"
  ✅ Se mantiene en pantalla de Login
  ✅ Campo de contraseña se limpia
  ✅ Campo de email conserva el valor

Status: 🟢 PASS
```

### Scenario 3: Email no existe
```
Input:
  Email: noexiste@test.com
  Password: cualquiera

Expected Output:
  ✅ Mensaje de error: "Usuario no encontrado" o similar
  ✅ Se mantiene en pantalla de Login

Status: 🟢 PASS
```

### Scenario 4: Backend no disponible
```
Input:
  - Detener backend: docker-compose down
  - Intentar login

Expected Output:
  ✅ Mensaje de error: "No se pudo conectar al servidor"
  ✅ Opción para reintentar

Status: 🟢 PASS
```

---

## 🐛 DEBUGGING EN VIVO

### Ver logs detallados de Flutter
```bash
# Ejecutar con logs verbose
flutter run -v

# Buscar líneas importantes:
# "I/flutter" - Logs de la app
# "POST /api/auth/login" - Request HTTP
# "token" - Mención de token
# "error" o "Exception" - Errores
```

### Ver logs del backend
```bash
docker logs sme_backend -f

# Buscar líneas:
# "POST /api/auth/login" - Request recibida
# "Valid password" o "Invalid password" - Verificación
# "Generating JWT" - Token generado
# "Response" - Respuesta enviada
```

### Ver logs de base de datos
```bash
docker logs sme_postgres -f

# Buscar queries de SELECT en tabla users
```

### Ver almacenamiento de SharedPreferences
```dart
// Dentro de la app, después de login:
import 'package:shared_preferences/shared_preferences.dart';

void debugTokenStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  final role = prefs.getString('user_role');
  final userId = prefs.getString('user_id');
  final email = prefs.getString('user_email');
  
  print('🔍 SharedPreferences Debug:');
  print('  access_token: ${token?.substring(0, 50)}...');
  print('  user_role: $role');
  print('  user_id: $userId');
  print('  user_email: $email');
}

// Llamar después de login exitoso
debugTokenStorage();
```

---

## ⚙️ CHECKLIST PRE-PRUEBA

Antes de ejecutar `flutter run`, verifica:

- [ ] Docker está corriendo: `docker-compose ps`
- [ ] Backend responde: `Invoke-RestMethod` test exitoso
- [ ] Android Emulator está abierto y cargado completamente
- [ ] Flutter SDK instalado: `flutter --version`
- [ ] Dependencias instaladas: `cd mobile_app && flutter pub get`
- [ ] No hay errores de compilación: `flutter analyze`
- [ ] Archivo api_service.dart tiene `10.0.2.2:3000`
- [ ] Archivo api_service.dart tiene `/api/auth/login`
- [ ] LoginResponse tiene campo `token` (no `accessToken`)

---

## 📊 RESULTADO ESPERADO

### Pantalla de Login (Inicial)
```
┌─────────────────────────────────┐
│   Sweet Models Enterprise       │
│                                 │
│   Email: [_________________]    │
│   Password: [________________]  │
│                                 │
│   [    LOGIN    ]               │
│   [  Sign Up    ]               │
│                                 │
│   Remember me: [ ]              │
│   Forgot password?              │
└─────────────────────────────────┘
```

### Ingresando Credenciales
```
Email: admin@sweetmodels.com
Password: sweet123
```

### Durante Login
```
┌─────────────────────────────────┐
│                                 │
│         Loading...              │
│                                 │
│      (círculo animado)          │
│                                 │
│    Conectando al servidor...    │
│                                 │
└─────────────────────────────────┘
```

### Después de Login Exitoso
```
┌─────────────────────────────────┐
│   DASHBOARD - Sweet Models      │
│                                 │
│   👤 Admin User                 │
│   📧 admin@sweetmodels.com      │
│   👔 Role: ADMIN                │
│                                 │
│   Balance: $0.00                │
│   Models: 0                     │
│                                 │
│   [Menu] [Profile] [Settings]   │
│                                 │
└─────────────────────────────────┘
```

---

## ✅ SIGNOS DE ÉXITO

Sabrás que todo está bien si:

1. ✅ **Conexión Establece**
   - No hay "Connection refused"
   - No hay "Network unreachable"

2. ✅ **Login Procesa**
   - Se muestra loading durante 2-3 segundos
   - No hay errores de parsing

3. ✅ **Token se Guarda**
   - El JWT se almacena correctamente
   - Aparece en SharedPreferences

4. ✅ **Navegación Funciona**
   - Cambias de LoginScreen a Dashboard
   - No hay crashes o excepciones

5. ✅ **Datos se Muestran**
   - Ves el nombre del usuario
   - Se muestra el rol (ADMIN)
   - Se muestra el user ID

---

## ❌ SIGNOS DE PROBLEMAS

Si ves esto, hay un issue:

| Síntoma | Causa Probable | Solución |
|---------|---|---|
| "Connection refused" | Backend no corre | `docker-compose up -d` |
| "Invalid credentials" | Credenciales incorrectas | Usar `admin@sweetmodels.com / sweet123` |
| "404 Not Found" | Endpoint path incorrecto | Verificar `/api/auth/login` |
| "JSON Parse error" | Model desincronizado | Verificar campo `token` no `accessToken` |
| "Network unreachable" | IP incorrecta en emulator | Cambiar a `10.0.2.2:3000` |
| App se crashea | Error no capturado | Ver `flutter run -v` logs |

---

## 🔄 CICLO DE PRUEBA COMPLETO

```
1. Verificar Backend
   ↓
2. Abrir Emulator
   ↓
3. Ejecutar Flutter
   ↓
4. Ingresar Credenciales
   ↓
5. Presionar Login
   ↓
6. Esperar Respuesta
   ↓
7. Verificar Dashboard
   ↓
8. Validar Token
   ↓
✅ ÉXITO o ❌ DEBUG
```

---

## 📞 RECURSOS DE AYUDA

| Documento | Propósito |
|-----------|-----------|
| `FLUTTER_BACKEND_INTEGRATION_GUIDE.md` | Guía completa |
| `FINAL_VALIDATION_CHECKLIST.md` | Checklist de validación |
| `test_integration.ps1` | Script de prueba automática |
| `docker logs sme_backend` | Logs del backend |
| `flutter run -v` | Logs verbose de Flutter |

---

## 🎯 PRÓXIMOS PASOS DESPUÉS DEL LOGIN

Después de validar el login exitoso:

1. **Crear Usuarios Adicionales**
   - MODEL user para pruebas
   - MODERATOR user para pruebas

2. **Probar Otros Endpoints**
   - GET /api/profile
   - GET /api/dashboard
   - POST /api/kyc/upload

3. **Validar Seguridad**
   - Token expiration
   - Token refresh
   - Logout functionality

4. **Implementar UI Completa**
   - Formularios de registro
   - Pantalla de perfil
   - Dashboard con datos reales

---

**Documento:** Guía de Ejecución Flutter Login Test  
**Versión:** 1.0  
**Última actualización:** 2025-01-17  
**Sistema:** Sweet Models Enterprise

✅ **LISTO PARA EJECUTAR**

