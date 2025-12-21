# 🚀 GUÍA FINAL DE DEPLOYMENT - Sweet Models Enterprise

**Fecha**: 9 de Diciembre 2025  
**Status**: ✅ Completado - Listo para producción  
**Commit**: b2ce784 (Gamificación completa)

---

## 📋 Checklist de Compilación

### Backend Rust ✅
```bash
cd backend_api
cargo check          # ✅ Sin errores, solo warnings redis/sqlx-postgres (future-compat)
cargo build --release  # ✅ Compilado exitosamente
```

### Frontend Flutter ✅
```bash
cd mobile_app
flutter analyze --no-fatal-infos  # ✅ 10 infos de estilo, sin errores críticos
flutter build web    # ✅ Salida en mobile_app/build/web
flutter build apk    # ✅ APK en mobile_app/build/app/outputs/flutter-apk/app-release.apk (51 MB)
```

---

## 📦 Artefactos Generados

### Backend
- **Binario release**: `backend_api/target/release/backend_api`
- **Dockerfile**: `backend_api/Dockerfile` (listo para Docker/Kubernetes)

### Frontend
- **Web bundle**: `mobile_app/build/web/` (estático, listo para Firebase Hosting)
- **APK release**: `mobile_app/build/app/outputs/flutter-apk/app-release.apk` (51 MB)
- **IPA** (requiere macOS/Xcode)

---

## 🔧 Pasos de Deployment

### 1️⃣ Backend (Rust/Docker)

#### Opción A: Docker Compose
```bash
cd docker
docker-compose -f docker-compose.yml up -d
```

#### Opción B: Kubernetes
```bash
# Buildear imagen
docker build -t sweetmodels/backend_api:latest backend_api/

# Push a registry
docker push sweetmodels/backend_api:latest

# Deploy en K8s
kubectl apply -f k8s/backend-api-deployment.yaml
```

#### Opción C: Bare Metal
```bash
cd backend_api
cargo build --release
./target/release/backend_api  # Escucha en 0.0.0.0:3000
```

### 2️⃣ Base de Datos (PostgreSQL)

```bash
# Migrar gamificación
sqlx migrate run --database-url "postgresql://user:pass@localhost:5432/sweet_models"

# O ejecutar manualmente
psql -U sweet_models_user -d sweet_models -f migrations/001_gamification.sql
```

### 3️⃣ Frontend Web (Hosting Estático)

#### Firebase Hosting
```bash
cd mobile_app
flutter build web --release
firebase login
firebase init hosting  # Seleccionar proyecto existente
firebase deploy --only hosting
```

#### Nginx
```bash
# Copiar build
rsync -avz mobile_app/build/web/ /var/www/sweetmodels/

# Configurar nginx.conf
server {
    listen 80;
    server_name app.sweetmodels.com;
    root /var/www/sweetmodels;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}

nginx -t && systemctl reload nginx
```

#### Cloudflare Pages
```bash
# Conectar repositorio GitHub
# Seleccionar rama: master
# Build command: flutter build web
# Output directory: build/web
```

### 4️⃣ Mobile Apps

#### Android Play Store
```bash
cd mobile_app

# Firmar APK
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore keystore.jks \
  build/app/outputs/flutter-apk/app-release.apk key_alias

# Zip align
zipalign -v 4 app-release.apk app-release-aligned.apk

# Subir a Play Store Console
# - Internal testing track primero
# - Gradual rollout (25% → 50% → 100%)
```

#### iOS TestFlight (requiere macOS)
```bash
cd mobile_app/ios
pod install
cd ..
flutter build ios --release

# En Xcode
# - Product → Archive
# - Organizer → Validate
# - Upload to App Store
# - Enviar a TestFlight
```

---

## 🔐 Configuración de Seguridad

### Variables de Entorno

```bash
# .env (Backend)
DATABASE_URL=postgresql://user:pass@db:5432/sweet_models
REDIS_URL=redis://cache:6379
JWT_SECRET=your_secret_key_here
AWS_REGION=us-east-1
MINIO_ENDPOINT=http://minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
FCM_PROJECT_ID=sweet-models-prod
OPENAI_API_KEY=sk-...
```

### Firebase Configuration

**Android** (`android/app/google-services.json`):
```json
{
  "project_id": "sweet-models-prod",
  "api_key": "AIzaSy...",
  "auth_domain": "sweet-models-prod.firebaseapp.com",
  ...
}
```

**iOS** (`ios/Runner/GoogleService-Info.plist`):
- Descargar desde Firebase Console
- Agregar al Xcode project
- Build Phases → Copy Bundle Resources

### TLS/HTTPS

Backend automáticamente genera certificados en `backend_api/tls/`. Para producción:

```bash
# Usar Let's Encrypt
certbot certonly --standalone -d api.sweetmodels.com
cp /etc/letsencrypt/live/api.sweetmodels.com/{fullchain,privkey}.pem backend_api/tls/
```

---

## 📊 Verificación Post-Deployment

### Health Checks

```bash
# Backend
curl https://api.sweetmodels.com/health

# Respuesta esperada
{
  "status": "ok",
  "version": "0.1.0",
  "uptime": "3600s"
}
```

### Endpoints Gamificación

```bash
# Obtener nivel de usuario
curl https://api.sweetmodels.com/gamification/users/550e8400-e29b-41d4-a716-446655440000/level

# Leaderboard
curl https://api.sweetmodels.com/gamification/leaderboard
```

### Firebase Notifications

```bash
# Test FCM
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=$FCM_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "device_token",
    "notification": {
      "title": "Test",
      "body": "¡Level Up!"
    },
    "data": {
      "action": "level_up",
      "old_rank": "ELITE",
      "new_rank": "QUEEN"
    }
  }'
```

---

## 📱 Testing en Dispositivos

### Android
```bash
# Conectar dispositivo
adb devices

# Instalar APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Ver logs
adb logcat
```

### iOS
```bash
# Usar Xcode
open ios/Runner.xcworkspace

# O desde CLI
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -derivedDataPath build/ios_build
```

---

## 🐛 Troubleshooting

### Backend no inicia
```bash
# Ver logs detallados
RUST_LOG=debug ./target/release/backend_api

# Verificar puerto 3000
netstat -tulpn | grep 3000

# Verificar DB
psql -U sweet_models_user -d sweet_models -c "SELECT 1"
```

### Flutter app no compila
```bash
# Limpiar cache
flutter clean
rm -rf build/ pubspec.lock

# Actualizar dependencias
flutter pub get

# Análisis detallado
flutter analyze -v
```

### FCM no funciona
1. Verificar `google-services.json` y `GoogleService-Info.plist` colocados correctamente
2. Confirmar FCM proyecto habilitado en Firebase Console
3. Revisar `logcat` (Android) o console de Xcode (iOS)
4. Verificar permisos en `AndroidManifest.xml`

---

## 📈 Monitoreo y Logs

### Backend (Structured Logging)
```rust
// Los logs van a stdout en formato JSON
// Integrar con ELK/DataDog/NewRelic para análisis

RUST_LOG=backend_api=debug cargo run --release
```

### Frontend (Crashlytics)
```dart
// Firebase Crashlytics está integrado en PushNotificationService
FirebaseCrashlytics.instance.recordError(error, stackTrace);
```

### Métricas
```bash
# Prometheus metrics en /metrics
curl https://api.sweetmodels.com/metrics
```

---

## 📞 Contacto y Soporte

- **GitHub**: [SweetModels/sweet-models-enterprise](https://github.com/SweetModels/sweet-models-enterprise)
- **Issues**: [GitHub Issues](https://github.com/SweetModels/sweet-models-enterprise/issues)
- **Documentación**: Ver archivos `.md` en raíz del proyecto

---

## ✅ Checklist Final

- [ ] Backend compilado y probado
- [ ] DB migrada (gamificación)
- [ ] Firebase configs colocadas (Android/iOS)
- [ ] Variables de entorno configuradas
- [ ] TLS/HTTPS habilitado
- [ ] Web bundle deployado
- [ ] APK firmado y subido (internal testing)
- [ ] iOS build en TestFlight (si aplica)
- [ ] Health checks pasando
- [ ] Logs monitoreados
- [ ] Backups configurados
- [ ] DNS apuntando a servidores

---

## 🎉 Estado Final

**Sweet Models Enterprise está listo para producción.**

✅ **Backend**: Motor Rust con gamificación, notificaciones, billetera  
✅ **Frontend**: Flutter app con UI moderna, animaciones, Firebase  
✅ **Base de Datos**: PostgreSQL con rangos, XP, logros  
✅ **DevOps**: Docker, Kubernetes, CI/CD ready  

**Próximas iteraciones**: Analytics, IA para recomendaciones, marketplace avanzado
