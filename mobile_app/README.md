# 📱 Sweet Models Enterprise - Mobile App

Aplicación móvil multiplataforma (Android/iOS/Windows) para la gestión de modelos webcam, moderadores, producción diaria y administración empresarial.

## ✨ Características

### 🔐 Autenticación

- Login/Logout con JWT (access tokens 24h + refresh tokens 30 días)
- Renovación automática de tokens antes de expiración
- Gestión de sesiones con revocación de tokens
- Modo offline con caché local


### 👥 Gestión de Usuarios

- Roles: Model, Moderador, Administrador
- Perfiles personalizados con gamificación
- Sistema de puntos y niveles
- Top performers con rankings


### 📊 Operaciones Diarias

- Registro de producción por modelo
- Cálculo automático de tokens/comisiones
- Logs de auditoría detallados
- Sincronización en background cada 15 minutos


### 🔔 Notificaciones

- In-app notifications con caché offline
- Push notifications (Firebase Cloud Messaging)
- Preferencias personalizables (push/email/in-app)
- Quiet hours configuration
- Prioridades (info, success, warning, error)


### 📈 Admin Dashboard

- Métricas en tiempo real (modelos activos, ingresos, tokens)
- Gráficas de ingresos (30 días con FL Chart)
- Top 10 performers
- Exportación de datos (CSV/Excel/PDF)


### 🌍 Internacionalización (i18n)

- 3 idiomas: Inglés (EN-US), Español (ES-CO), Portugués (PT-BR)
- 340+ traducciones
- Cambio dinámico de idioma


### 🔄 Background Tasks

- WorkManager para tareas periódicas
- Sincronización automática de producción (15 min)
- Verificación de notificaciones (30 min)
- Persistencia de tareas pendientes


### 🧪 Testing

- Unit tests para lógica de negocio
- Widget tests para UI components
- Cobertura de código >80%


## 🚀 Quick Start

### Desarrollo (Debug)

```powershell

# Clonar repositorio

git clone https://github.com/SweetModels/sweet-models-enterprise.git
cd sweet-models-enterprise/mobile_app

# Instalar dependencias

flutter pub get

# Ejecutar en emulador/dispositivo

flutter run

# Ejecutar tests

flutter test

```

### Producción (Release)

```powershell

# 1. Verificar que todo esté listo

.\check_build_readiness.ps1

# 2. Configurar firma Android (solo primera vez)

.\setup_android_signing.ps1

# 3. Compilar releases

.\build_release.ps1 -Platform all

# 4. Archivos generados:

# - Android APK: build/app/outputs/flutter-apk/

# - Android AAB: build/app/outputs/bundle/release/

# - Windows EXE: build/windows/x64/runner/Release/

# - Windows MSIX: build/windows/runner/Release/

# - Instalador Windows: build/windows/installer/

```

## 📚 Documentación

- **[BUILD_SCRIPTS_README.md](BUILD_SCRIPTS_README.md)**: Guía de scripts de compilación
- **[BUILD_RELEASE_GUIDE.md](BUILD_RELEASE_GUIDE.md)**: Documentación completa de release engineering
- **[NUEVAS_FUNCIONALIDADES.md](../NUEVAS_FUNCIONALIDADES.md)**: Changelog detallado de features


## 🛠️ Scripts Disponibles

| Script | Descripción | Uso |

|--------|-------------|-----|

| `check_build_readiness.ps1` | Verifica requisitos pre-build | `.\check_build_readiness.ps1` |

| `setup_android_signing.ps1` | Genera keystore para Android | `.\setup_android_signing.ps1` |

| `build_release.ps1` | Compila releases (APK/AAB/EXE/MSIX) | `.\build_release.ps1 -Platform all` |

| `bump_version.ps1` | Incrementa versión (SemVer) | `.\bump_version.ps1 -BumpType patch` |

## 🏗️ Arquitectura

### State Management

- **Riverpod 2.6+** para gestión de estado
- Providers para services (Auth, Notifications, Background Sync)
- StateNotifier para estados complejos


### Networking

- **Dio** para peticiones HTTP con interceptors
- Automatic token injection/refresh
- Retry logic con exponential backoff
- Offline detection con caché fallback


### Persistencia Local

- **SharedPreferences** para settings y tokens
- **WorkManager** para background tasks
- Caché de notificaciones para modo offline


### Backend API

- **Base URL**: `http://localhost:3000` (desarrollo)
- **Producción**: Configurar en `lib/services/api_service.dart`
- **Endpoints**: 25+ REST APIs (auth, users, production, notifications, admin)


## 📦 Dependencias Principales

```yaml
dependencies:
  flutter_riverpod: ^2.6.1        # State management
  dio: ^5.7.0                     # HTTP client
  shared_preferences: ^2.3.3      # Local storage
  workmanager: ^0.5.2             # Background tasks
  firebase_core: ^3.11.0          # Firebase SDK
  firebase_messaging: ^15.5.2     # Push notifications
  fl_chart: ^0.69.0               # Charts/gráficas
  flutter_localizations: sdk      # i18n support
  intl: ^0.19.0                   # Internationalization

dev_dependencies:
  msix: ^3.16.8                   # Windows MSIX packaging

```

## 🔧 Configuración

### Firebase (Push Notifications)

1. Descarga `google-services.json` de Firebase Console
2. Coloca en `android/app/google-services.json`
3. Para iOS, descarga `GoogleService-Info.plist` y coloca en `ios/Runner/`


### Backend URL

Edita `lib/services/api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'https://tu-dominio.com'; // Cambiar en producción
  // ...
}

```

### Android Signing

Ejecuta `setup_android_signing.ps1` y sigue las instrucciones para:

- Generar keystore con keytool
- Crear `android/key.properties`
- Configurar `android/app/build.gradle`


## 🧪 Ejecutar Tests

```powershell

# Todos los tests

flutter test

# Con cobertura

flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Tests específicos

flutter test test/unit_tests.dart
flutter test test/widget_tests.dart

```

## 🌐 Idiomas Soportados

| Código | Idioma | Estado |

|--------|--------|--------|

| `en` | English (US) | ✅ 100% |

| `es` | Español (Colombia) | ✅ 100% |

| `pt` | Português (Brasil) | ✅ 100% |

Cambiar idioma en la app: **Settings → Language → Seleccionar**

## 📱 Plataformas Soportadas

| Plataforma | Estado | Min Version | Notas |

|------------|--------|-------------|-------|

| Android | ✅ Soportado | API 21 (5.0 Lollipop) | Google Play ready |

| iOS | ⚠️ Pendiente | iOS 12+ | Requiere Mac + Xcode |

| Windows | ✅ Soportado | Windows 10 1809+ | MSIX + Inno Setup |

| Web | ❌ No soportado | - | Backend CORS pendiente |

## 🔐 Seguridad

- ✅ JWT tokens con SHA256 hashing
- ✅ Refresh tokens con rotación automática
- ✅ Passwords con Argon2id (backend)
- ✅ HTTPS only en producción
- ✅ Keystore con RSA 2048-bit
- ⚠️ NUNCA subir `upload-keystore.jks` ni `key.properties` a Git


## 📊 Métricas del Proyecto

- **Líneas de código**: ~15,000 (Flutter) + ~2,300 (Backend Rust)
- **Archivos Dart**: 45+
- **Tests**: 25+ (unit + widget)
- **Cobertura**: >80%
- **Idiomas**: 3 (EN/ES/PT)
- **Traducciones**: 340+
- **Pantallas**: 12+
- **API Endpoints**: 25+


## 🤝 Contribuir

1. Fork el repositorio
2. Crea tu feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la branch (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request


## 📄 Licencia

Proyecto privado - Sweet Models Enterprise © 2024

## 🆘 Soporte

- **Issues**: [GitHub Issues](https://github.com/SweetModels/sweet-models-enterprise/issues)
- **Documentación**: Ver archivos `*_GUIDE.md` y `*_README.md`
- **Email**: <soporte`@sweetmodels.com`>


## 🎯 Roadmap

### ✅ Completado (v1.0.0)

- Autenticación JWT con refresh tokens
- Sistema de notificaciones (in-app + push)
- Admin dashboard con métricas
- Background sync con WorkManager
- Internacionalización (3 idiomas)
- Exportación de datos (CSV/Excel/PDF)
- Tests automatizados


### 🔄 En Progreso

- Builds de producción (Android/Windows)
- Distribución en Google Play / Microsoft Store


### 📋 Próximamente (v1.1.0)

- iOS support (requiere Mac)
- Chat en tiempo real (WebSockets)
- Reportes avanzados con filtros
- Modo oscuro (Dark mode)
- Widgets de Home Screen (Android)
- Soporte para tablets/iPad


### 🔮 Futuro (v2.0.0)

- Machine Learning para predicciones
- Sistema de pagos integrado
- API pública para integraciones
- Web dashboard (React/Vue)
- CI/CD con GitHub Actions

---


Desarrollado con ❤️ usando Flutter, Rust y PostgreSQL
