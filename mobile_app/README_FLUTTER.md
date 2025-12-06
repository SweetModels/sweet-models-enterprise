# Sweet Models Enterprise - Frontend

Aplicación móvil Flutter para Sweet Models Enterprise, conectada al backend en Rust.

## Requisitos

- Flutter 3.24.5 o superior (stable channel)
- Dart 3.5.4 o superior
- Android Studio / Xcode (para emuladores)
- Backend ejecutándose en `http://localhost:3000`

## Instalación

### 1. Instalar dependencias

```bash
cd mobile_app
flutter pub get --no-precompile
```

### 2. Asegurar conexión al backend

El backend debe estar ejecutándose en `http://localhost:3000`. Para verificar:

```bash
curl http://localhost:3000/health
# Respuesta esperada: 200 OK
```

Si está en Windows y el backend está en WSL o Docker:
- Para WSL: Cambia `localhost` en `lib/services/api_service.dart` por la IP de WSL (`wsl.exe hostname -I`)
- Para Docker Desktop: `localhost` funciona directamente

### 3. Ejecutar la aplicación

```bash
# Ejecutar en emulador Android
flutter run

# Ejecutar en device iOS
flutter run -d ios

# Ejecutar específicamente
flutter run -d <device_id>

# Listar dispositivos disponibles
flutter devices
```

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada, configuración de tema
├── models/
│   ├── user_model.dart      # Modelo de Usuario
│   └── group_model.dart     # Modelo de Grupo
├── services/
│   └── api_service.dart     # Cliente HTTP para comunicarse con el backend
├── screens/
│   ├── splash_screen.dart   # Pantalla de carga / verificación de servidor
│   ├── home_screen.dart     # Pantalla principal (ejemplo)
│   ├── login_screen.dart    # [Pendiente] Autenticación
│   └── register_screen.dart # [Pendiente] Registro
├── providers/
│   └── auth_provider.dart   # Proveedores Riverpod para estado de autenticación
├── widgets/
│   └── custom_widgets.dart  # Componentes reutilizables (botones, campos de texto, etc.)
└── pubspec.yaml             # Dependencias del proyecto
```

## Características Implementadas

✅ **Conexión al backend**: Cliente HTTP funcional
✅ **Modelo de datos**: User y Group
✅ **Estado con Riverpod**: Autenticación y almacenamiento de usuario
✅ **UI atractiva**: Tema oscuro con Google Fonts
✅ **Validación**: Análisis de código sin errores
✅ **Seguridad**: Flutter Secure Storage para credenciales

## Características Pendientes

- [ ] Login screen con validación
- [ ] Registro de usuarios
- [ ] Navegación con Go Router
- [ ] CRUD de grupos
- [ ] Perfil de usuario
- [ ] Configuración de aplicación
- [ ] Recuperación de contraseña
- [ ] Autenticación de dos factores

## Troubleshooting

### "Failed to connect to localhost:3000"

**Problema**: El emulador no puede alcanzar el backend.

**Soluciones**:
1. Asegúrate que el backend está ejecutándose: `cargo run` en la carpeta `backend_api`
2. En Android Emulator, usa `10.0.2.2` en lugar de `localhost`
3. En iOS Simulator, necesitas exponer el puerto si el backend está en WSL/Docker

### "The value isn't used" warning

**Problema**: Warnings de análisis estático.

**Solución**: Ya han sido corregidos. Ejecuta `flutter analyze` para verificar.

### "Conexión rechazada"

**Problema**: El backend no está disponible.

**Solución**:
```bash
# Verifica el estado del servidor
curl http://localhost:3000/health

# Si no responde, inicia el backend:
cd backend_api
cargo run
```

## Comandos Útiles

```bash
# Analizar código
flutter analyze

# Formatar código
flutter format .

# Limpiar build
flutter clean

# Ejecutar tests
flutter test

# Compilar APK (Android)
flutter build apk --release

# Compilar IPA (iOS)
flutter build ios --release

# Generar código (si usas JSON serialization)
flutter pub run build_runner build
```

## API Endpoints Usados

- `GET /health` - Verificar estado del servidor
- `POST /setup_admin` - Crear usuario admin (solo para pruebas)
- Más endpoints por implementar en el backend

## Dependencias Principales

- **flutter_riverpod**: Estado management
- **go_router**: Navegación
- **http**: Cliente HTTP
- **flutter_secure_storage**: Almacenamiento seguro
- **google_fonts**: Tipografía personalizada
- **provider**: State management alternativo

## Contribuciones

Para agregar nuevas pantallas o funcionalidades:

1. Crea el modelo en `models/` si es necesario
2. Crea el servicio en `services/` si necesita conectarse a la API
3. Crea el provider en `providers/` para el estado
4. Crea la pantalla en `screens/`
5. Agrega widgets reutilizables en `widgets/`
6. Ejecuta `flutter analyze` y corrige cualquier warning
7. Prueba la aplicación

## Licencia

Privado - Sweet Models Enterprise 2024
