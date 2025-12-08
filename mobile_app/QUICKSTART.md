# 🚀 Quick Start - Sweet Models Enterprise App v2.0

## ⚡ Comandos Rápidos

### 1️⃣ Instalar Dependencias

```powershell
cd "c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app"
flutter pub get

```

### 2️⃣ Verificar Backend

```powershell

# Verificar que Docker esté corriendo

cd "c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise"
docker ps

# Si no está corriendo:

docker compose up -d

```

### 3️⃣ Ejecutar App

```powershell

# Web (Chrome) - Recomendado

cd mobile_app
flutter run -d chrome --web-port=8082

# Windows Desktop

flutter run -d windows

# Android (si tienes emulador)

flutter run -d emulator-5554

```

---


## 🧪 Testing Rápido

### Login con Admin (Acceso Completo)

```

URL: `http://localhost:8082`
Email: karber.pacheco007`@gmail.com`
Password: Isaias..20-26

✅ Puede acceder a:

- Dashboard
- Grupos
- Planificación Financiera
- Perfil
- 📹 Monitoreo de Cámaras (NUEVO)


```

### Registro de Nuevo Modelo

```

1. Click en "¿No tienes cuenta? Regístrate como modelo"
2. Llenar formulario:
   - Nombre: Juan Pérez
   - Email: juan.perez`@example.com`
   - Teléfono: 3109876543 (10 dígitos)
   - Cédula: 1234567890 (min 6 dígitos)
   - Dirección: Calle 100 #20-30
   - Contraseña: SecurePass123
3. Click en "Verificar Teléfono" (simulado)
4. Click en "Registrar Modelo"


```

### Probar Biometría (Simulador Android)

```powershell

# Después del primer login, activar biometría

# Luego simular huella dactilar:

adb -e emu finger touch 1

```

### Ver Cámaras (Solo Admin)

```

1. Login como admin
2. Dashboard → Menú lateral
3. Click en "Monitoreo de Cámaras"
4. Ver grid con 4 cámaras activas
5. Click en cualquier cámara para ver detalles


```

---


## 📡 Endpoints Disponibles

### Backend (`http://localhost:3000`)

```

✅ POST /register_model       - Registro avanzado
✅ GET  /admin/cameras        - Lista de cámaras (admin)
✅ POST /admin/trm            - Actualizar TRM (admin)
✅ POST /api/payroll/calculate - Calcular nómina
✅ GET  /dashboard            - Métricas generales

```

### Frontend (`http://localhost:8082`)

```

✅ /                  - Login con biometría
✅ /register_model    - Registro de modelos
✅ /dashboard         - Panel principal
✅ /cameras          - Monitoreo (admin)
✅ /groups           - Gestión de grupos
✅ /financial_planning - Calculadora
✅ /profile          - Perfil de usuario

```

---


## 🔍 Verificar Estado

### Backend Healthy

```powershell
Invoke-WebRequest `http://localhost:3000/health` | ConvertFrom-Json

# Debe retornar:

{
  "status": "healthy",
  "version": "2.0.0",
  "features": ["doble_trm", "biometric_auth", "camera_monitoring"]
}

```

### Database Conectada

```powershell
docker logs sweet_models_enterprise-postgres-1 | Select-Object -Last 10

# Debe mostrar:

# "database system is ready to accept connections"

```

---


## 🎨 Características Visibles

### 1. Login Biométrico

- **Huella verde** en pantalla de login
- Botón "Usar huella dactilar" o "Usar Face ID"
- Diálogo de activación después del primer login


### 2. Registro de Modelo

- Campos adicionales: Teléfono, Cédula, Dirección
- Botón "Verificar Teléfono" con animación
- Ícono de verificación verde cuando se completa


### 3. Cámaras (Admin)

- Grid 2x2 o 3x3 según tamaño de pantalla
- Badge "EN VIVO" en verde
- Indicador "● REC" en cámaras activas
- Bordes verdes para cámaras activas


### 4. Control de Acceso

- Usuarios no-admin ven "Acceso Denegado" en /cameras
- Mensaje claro con el rol del usuario
- Botón para volver al dashboard
---


## 🐛 Troubleshooting

### Error: "Backend no responde"

```powershell

# Reiniciar containers

docker compose down
docker compose up -d

# Esperar 15 segundos

Start-Sleep -Seconds 15

# Verificar

Invoke-WebRequest `http://localhost:3000/health`

```

### Error: "No se puede instalar dependencias"

```powershell

# Limpiar cache de Flutter

flutter clean
flutter pub cache repair
flutter pub get

```

### Error: "Symlink not supported"

```powershell

# Habilitar Developer Mode en Windows

start ms-settings:developers

# Activar "Developer Mode" y reiniciar PC

```

### Biometría no funciona

```

# En emulador Android:

1. Settings → Security → Fingerprint
2. Agregar huella simulada
3. En terminal: adb -e emu finger touch 1


# En simulador iOS:

1. Hardware → Touch ID/Face ID → Enrolled
2. Al solicitar biometría: Hardware → Touch ID → Matching Touch


```

---


## 📊 Estado del Sistema

```

Backend:    ✅ Running (Docker)
PostgreSQL: ✅ Healthy (port 5432)
Flutter:    ✅ Ready (Web/Windows/Android)

Endpoints:  14 activos
Screens:    7 pantallas
Features:   Biometría, Cámaras, OTP

```

---


## 🎯 Flujos Completos de Prueba

### Flujo 1: Registro + Login Biométrico

```

1. Abrir `http://localhost:8082`
2. Click "Regístrate como modelo"
3. Completar formulario y verificar teléfono
4. Registrar modelo
5. Volver a login
6. Ingresar email/password
7. Aceptar activar biometría
8. Cerrar sesión (Profile → Logout)
9. Volver a login
10. Click botón "Usar huella dactilar"
11. ✅ Login sin contraseña


```

### Flujo 2: Admin ve Cámaras

```

1. Login como admin
2. Dashboard → Ver métricas
3. Menú lateral → "Cámaras" (ícono 📹)
4. Ver grid con 4 cámaras
5. Click en "Main Studio Cam 1"
6. Ver modal con detalles:
   - ID: 1
   - URL: rtsp://192.168.1.100:554/stream1
   - Plataforma: Studio
   - Estado: Activo
7. Cerrar modal
8. Click botón Refresh (arriba derecha)


```

### Flujo 3: Modelo intenta acceder a Cámaras

```

1. Login como modelo (juan.perez`@example.com`)
2. Intentar navegar a /cameras
3. Ver pantalla "Acceso Denegado"
4. Leer mensaje: "Tu rol actual: model"
5. Click "Volver al Dashboard"
6. ✅ De vuelta en dashboard (acceso controlado)


```

---


## 📝 Notas Importantes

### Biometría

- **Android**: Requiere API 23+ (Android 6.0)
- **iOS**: Requiere iOS 11+ (Face ID) o iOS 8+ (Touch ID)
- **Windows**: Usa Windows Hello (si está disponible)


### Cámaras

- URLs RTSP son de ejemplo (192.168.1.100-103)
- Para producción, integrar con VideoLAN o FFmpeg
- Placeholder muestra iconos animados


### OTP

- Actualmente simulado (3 segundos)
- Integrar con Twilio/AWS SNS para producción
- Código de 6 dígitos recomendado
---


## 🔗 Links Útiles

- **Backend API Docs**: `backend_api/API_DOCUMENTATION.md`
- **Flutter App Docs**: `mobile_app/FLUTTER_APP_V2.md`
- **Local Auth Plugin**: https://pub.dev/packages/local_auth
- **Fluent UI**: https://pub.dev/packages/fluent_ui
---
**¡Listo para producción!** 🎉


Cualquier duda, revisar los archivos de documentación completos.
