# 🚀 Guía de Integración Flutter + Backend Rust

## ✅ Estado Actual

El backend Rust y la aplicación Flutter están completamente configurados para comunicarse:

### Backend (Rust/Axum)
- ✅ Ejecutándose en Docker en `http://localhost:3000`
- ✅ Endpoint de login: `POST /api/auth/login`
- ✅ Base de datos PostgreSQL con usuario ADMIN creado
- ✅ Autenticación con JWT (24 horas de expiración)

### Flutter Mobile App
- ✅ Configurado para Android Emulator (`10.0.2.2:3000`)
- ✅ ApiService actualizado con endpoint correcto
- ✅ LoginResponse model sincronizado con respuesta del backend
- ✅ Token storage en SharedPreferences

---

## 🔐 Credenciales de Prueba

```
Email: admin@sweetmodels.com
Contraseña: sweet123
```

---

## 🛠️ Cambios Realizados en Flutter

### 1. **api_service.dart**
```dart
// ✅ baseUrl corregida para Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000';

// ✅ Endpoint de login correcto
_dio.post('/api/auth/login', ...)

// ✅ LoginResponse refactorizado
class LoginResponse {
  final String token; // Cambio de accessToken
  final String? refreshToken;
  final String role;
  final String userId;
  // ...
}
```

### 2. **login_screen.dart**
```dart
// ✅ Usando el campo 'token' correcto
final token = response.token;
```

### 3. **lib/services/api_service.dart** (backup)
- También actualizado para consistencia

---

## 📱 Pasos para Probar

### Paso 1: Verificar que el Backend está Corriendo
```powershell
# En PowerShell
Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" -Method Post `
  -Body (@{email="admin@sweetmodels.com"; password="sweet123"} | ConvertTo-Json) `
  -ContentType "application/json"
```

Respuesta esperada:
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "role": "ADMIN",
  "user_id": "...",
  "name": "Admin User"
}
```

### Paso 2: Ejecutar Flutter en Android Emulator
```bash
# En VSCode o terminal, desde la carpeta mobile_app
flutter run
```

**Requisitos:**
- Android Emulator debe estar ejecutándose
- Flutter SDK debe estar instalado
- Dependencias de pubspec.yaml instaladas (`flutter pub get`)

### Paso 3: Probar Login desde la App
1. Abre la aplicación Flutter
2. Ingresa las credenciales:
   - Email: `admin@sweetmodels.com`
   - Contraseña: `sweet123`
3. Presiona "Login"

**Resultados esperados:**
- ✅ Pantalla de carga aparece brevemente
- ✅ Token se guarda en SharedPreferences
- ✅ Navega a la pantalla de Dashboard
- ✅ Los datos del usuario aparecen en el Dashboard

---

## 🔍 Debugging

### Si la conexión falla:

#### Error: "Connection refused"
```
Problema: El backend no está ejecutándose
Solución: 
  docker-compose up -d
  docker logs sme_backend
```

#### Error: "404 Not Found"
```
Problema: Endpoint path incorrecto
Solución: Verificar que sea '/api/auth/login' (no '/login')
```

#### Error: "Invalid credentials"
```
Problema: Email/contraseña incorrectos
Solución: Crear nuevo usuario con:
  SQL: INSERT INTO users (email, password_hash, role) 
       VALUES ('test@test.com', '<hash>', 'MODEL')
```

#### Error en Emulator: "Network unreachable"
```
Problema: Usando localhost en lugar de 10.0.2.2
Solución: Verificar baseUrl = 'http://10.0.2.2:3000'
         (No usar 'localhost' en Android Emulator)
```

---

## 📊 Flujo de Autenticación

```
Flutter App
    ↓
[Login Screen]
    ↓
email + password (admin@sweetmodels.com, sweet123)
    ↓
POST http://10.0.2.2:3000/api/auth/login
    ↓
Backend Rust/Axum
    ├─ Valida email existe
    ├─ Verifica Argon2 hash
    └─ Genera JWT token (24h expiration)
    ↓
Respuesta JSON con token
    ↓
Flutter almacena en SharedPreferences
    ↓
[Dashboard Screen]
    ↓
Todas las siguientes requests incluyen:
Authorization: Bearer <token>
```

---

## 🧪 Crear Usuarios de Prueba Adicionales

Si necesitas crear más usuarios con diferentes roles:

### Opción 1: Desde PowerShell
```powershell
# Usar el binario gen_hash del backend
.\backend_api\target\release\gen_hash.exe "password123"
```

Esto genera un hash Argon2 válido.

### Opción 2: Directamente en SQL
```sql
INSERT INTO users (id, email, password_hash, role, full_name, is_active, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'model@sweetmodels.com',
  '$argon2id$v=19$m=19456,t=2,p=1$<salt>$<hash>',
  'MODEL',
  'Test Model',
  true,
  NOW(),
  NOW()
);
```

---

## 🚀 Próximos Pasos

Después de validar el login:

1. **Implementar Refresh Token**
   - Endpoint: `POST /api/auth/refresh`
   - Actualizar Flutter interceptor

2. **Crear Usuarios por Rol**
   - MODEL: Acceso a panel de modelo
   - MODERATOR: Acceso a consola moderador
   - ADMIN: Acceso administrativo

3. **Pruebas de Endpoints**
   - Dashboard: `GET /api/dashboard`
   - Profile: `GET /api/profile`
   - KYC: `POST /api/kyc/upload`

4. **UI/UX Improvements**
   - Manejo de errores más detallado
   - Loading states mejorados
   - Validaciones en tiempo real

---

## 📝 Notas Técnicas

### Magic IP para Android Emulator
- `10.0.2.2` es la dirección IP especial que el emulador de Android usa para referirse al host (tu máquina)
- En dispositivo físico, usar `192.168.X.X` o la IP local real

### Token Storage
- SharedPreferences almacena en el dispositivo/emulador
- No es 100% seguro; considerar flutter_secure_storage para producción

### JWT Expiration
- Tokens expiran en 24 horas
- Implementar refresh token para sesiones largas

---

## ✨ Estado de Confirmación

```
[✅] Backend corriendo en Docker
[✅] Base de datos inicializada
[✅] Usuario admin creado
[✅] Flutter app compilada y lista
[✅] API client configurado correctamente
[✅] Endpoint paths sincronizados
[✅] Response models actualizados
[✅] Token storage configurado
[✅] Documentación completa
```

**Próximo Paso:** Ejecutar `flutter run` en Android Emulator y probar login con credenciales admin.

---

*Última actualización: 2025-01-17*
*Sistema: Sweet Models Enterprise*
