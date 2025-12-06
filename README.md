# 🚀 Sweet Models Enterprise

**Plataforma completa de gestión empresarial** con backend de alto rendimiento en Rust, aplicación móvil nativa en Flutter y sistema de moderación con gamificación.

## ⚡ Stack Tecnológico

| Capa | Tecnología | Características |
|------|-----------|-----------------|
| **Backend** | Rust + Axum 0.7 | API REST con JWT, Argon2, SQLx |
| **Frontend** | Flutter 3.24.5+ | Multi-plataforma (Android, iOS, Windows) |
| **Base de Datos** | PostgreSQL 15-alpine | Migraciones automáticas, JSONB, índices optimizados |
| **Infraestructura** | Docker Compose | Orquestación multi-servicio |
| **State Management** | Riverpod 2.6+ | State management reactivo |
| **Autenticación** | JWT + Argon2id | Tokens seguros, hash de contraseñas |

## ✨ Características Principales

### 🔐 Sistema de Autenticación
- ✅ JWT con roles (admin, moderator, model, user)
- ✅ Hash de contraseñas con Argon2id
- ✅ Validación de tokens en todos los endpoints protegidos
- ✅ Login persistente en SharedPreferences

### 👥 Módulos de Usuario

#### 📊 Consola de Moderadores
- ✅ Dashboard de grupos asignados
- ✅ Registro de producción diaria (tokens)
- ✅ Gamificación: Meta de 10,000 tokens/día con feedback visual
- ✅ Borde dorado animado al alcanzar meta
- ✅ Modo offline: cola de reintentos automáticos
- ✅ Barra de progreso en tiempo real

#### 🌟 Espacio de Modelos
- ✅ Dashboard con puntos acumulados
- ✅ Desglose de ganancias (hoy, semana, mes) en COP
- ✅ Firma de contratos con captura de firma digital
- ✅ Animaciones de confetti al firmar
- ✅ Sistema de gamificación con logros

### 🔧 Backend API Endpoints

#### Autenticación
- `POST /login` - Login con email/password
- `POST /register` - Registro de usuarios
- `POST /api/model/register` - Registro avanzado de modelos

#### Operaciones de Moderador
- `GET /api/mod/groups` - Obtener grupos asignados
- `POST /api/mod/production` - Registrar producción diaria
- Auto-generación de audit trail en cada registro
- Detección automática de metas diarias

#### Modelos
- `GET /api/model/dashboard` - Dashboard de puntos y ganancias
- `POST /api/model/sign-contract` - Firma digital de contratos

### 🗄️ Base de Datos

#### Tablas Principales
- **users** - Usuarios con roles, KYC, verificación biométrica
- **groups** - Grupos de trabajo con plataforma, tokens, miembros
- **points_ledger** - Ledger de puntos con razón y timestamps
- **contracts** - Contratos firmados con ruta de imagen
- **production_logs** - Logs de producción diaria por grupo
- **audit_trail** - Auditoría completa con JSONB (old_value, new_value)
- **social_links** - Links de redes sociales por usuario

### 🎨 UI/UX
- ✅ Dark theme personalizado (Material 3)
- ✅ Google Fonts (Inter)
- ✅ Animaciones fluidas (confetti, shimmer, bordes brillantes)
- ✅ Responsive design
- ✅ Feedback visual inmediato

## 🚀 Inicio Rápido

### Opción 1: Script Automático (Recomendado)

```powershell
# En PowerShell (Windows)
cd sweet_models_enterprise

# Iniciar todo automáticamente
.\dev.ps1 -action all

# O componentes individuales
.\dev.ps1 -action docker    # Inicia PostgreSQL
.\dev.ps1 -action backend   # Inicia servidor Rust
.\dev.ps1 -action frontend  # Inicia Flutter
```

### Opción 2: Manual

**Terminal 1 - Docker:**
```bash
cd docker
docker-compose up
```

**Terminal 2 - Backend:**
```bash
cd backend_api
cargo run
```

**Terminal 3 - Frontend:**
```bash
cd mobile_app
flutter run
```

## 📊 Verificación de Servicios

```bash
# Script de estado
.\dev.ps1 -action status

# O manualmente:

# Backend health
curl http://localhost:3000/health

# Base de datos (Puerto 8081)
open http://localhost:8081
# Usuario: admin
# Contraseña: admin
# Base de datos: sme_db
```

## 📁 Estructura del Proyecto

```
sweet_models_enterprise/
├── docker/                    # Orquestación Docker
│   └── docker-compose.yml
├── backend_api/              # Servidor Rust
│   ├── src/main.rs
│   ├── Cargo.toml
│   └── .env
├── mobile_app/               # App Flutter
│   ├── lib/
│   └── pubspec.yaml
├── dev.ps1                   # Script de desarrollo
├── DOCUMENTATION.md          # Documentación técnica
└── README.md                 # Este archivo
```

## 🔑 Endpoints Disponibles

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/` | Información del servidor |
| `GET` | `/health` | Health check |
| `POST` | `/setup_admin` | Crear usuario admin (pruebas) |

### Próximos endpoints:
- `POST /auth/login` - Autenticación
- `POST /auth/register` - Registro de usuarios
- `GET /api/users` - Listar usuarios (admin)
- `GET /api/groups` - Listar grupos

## 🔐 Credenciales

### Base de Datos
- **Host**: localhost
- **Puerto**: 5432
- **Usuario**: `sme_user`
- **Contraseña**: `sme_password`
- **Base de datos**: `sme_db`

### Adminer UI
- **URL**: http://localhost:8081
- **Usuario**: admin
- **Contraseña**: admin

## 🔧 Troubleshooting

### "Conexión rechazada" en backend

```bash
# Verifica que PostgreSQL está corriendo
docker-compose ps

# Verifica la salida del servidor
cargo run
```

### Flutter no encuentra el servidor

```bash
# Si estás en WSL o Docker Desktop:
# 1. En Android Emulator, usa: 10.0.2.2:3000
# 2. En iOS Simulator, usa: localhost:3000

# Edita: mobile_app/lib/services/api_service.dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

### Errores de compilación

```bash
# Limpia y recompila
flutter clean
flutter pub get

cargo clean
cargo build
```

## 📈 Próximas Características

- [ ] Autenticación con JWT
- [ ] Refresh token mechanism
- [ ] Dashboard de administrador
- [ ] Sistema de notificaciones
- [ ] Sincronización en background
- [ ] Exportación de datos
- [ ] Multi-idioma (i18n)
- [ ] Tests automatizados

## 📱 Requisitos de Desarrollo

### Rust Backend
- Rust 1.48.0+
- Cargo

### Flutter Frontend
- Flutter 3.24.5 (stable)
- Dart 3.5.4+
- iOS Xcode (para Mac)
- Android Studio + SDK (para Android)

### Infraestructura
- Docker 25.0.3+
- Docker Compose 2.20+

## ✅ Checklist de Verificación

Después de instalar, verifica que todo funciona:

```bash
# 1. Backend corriendo
curl http://localhost:3000/health
# Respuesta: 200 OK

# 2. Base de datos accesible
docker exec -it sme_db psql -U sme_user -d sme_db
# Debería abrir psql

# 3. Flutter sin errores
cd mobile_app
flutter analyze
# Respuesta: "No issues found!"

# 4. Emulador listo
flutter devices
# Debería listar emuladores/dispositivos
```

## 📚 Documentación Adicional

- **[DOCUMENTATION.md](./DOCUMENTATION.md)** - Documentación técnica detallada
- **[mobile_app/README_FLUTTER.md](./mobile_app/README_FLUTTER.md)** - Guía Flutter específica
- **[backend_api/src/main.rs](./backend_api/src/main.rs)** - Código comentado del backend

## 🤝 Desarrollo

Cuando hagas cambios:

1. **Backend (Rust)**:
   ```bash
   cargo fmt          # Formatea código
   cargo clippy       # Linter
   cargo test         # Tests
   cargo run         # Ejecuta
   ```

2. **Frontend (Flutter)**:
   ```bash
   flutter format .   # Formatea código
   flutter analyze    # Análisis estático
   flutter test       # Tests
   flutter run        # Ejecuta
   ```

## 📞 Ayuda

### Ver logs en tiempo real

```bash
# Backend
cargo run

# Frontend
flutter logs

# Docker
docker-compose logs -f postgres
```

### Reiniciar servicios

```bash
.\dev.ps1 -action clean     # Limpia todo
docker-compose down         # Detiene servicios
docker-compose up -d        # Reinicia servicios
```

## 📄 Licencia

**Privado** - Sweet Models Enterprise 2024

---

**Estado**: ✅ Listo para desarrollo
**Versión**: 1.0.0
**Última actualización**: 2024

Hecho con ❤️ usando Rust y Flutter
