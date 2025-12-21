# ✅ PRODUCTION SECURITY CHECKLIST

## 🔐 ANTES DE DESPLEGAR EN RAILWAY

### 1. Auditoría de Código

- [ ] Ejecutar `.\security-audit.ps1` - Debe mostrar ✅ sin problemas
- [ ] `git log --all -p | grep -i "secret\|password\|AKIA"` - Debe estar vacío
- [ ] Revisar que NO hay comentarios con credenciales de prueba
- [ ] Verificar `backend_api/src/main.rs` - NO debe tener `const JWT_SECRET`
- [ ] Verificar `backend_api/src/services/jwt.rs` - Debe leer desde `std::env::var("JWT_SECRET")`

### 2. Archivo .env

- [ ] `.env` existe con valores de DESARROLLO
- [ ] `.env` está en `.gitignore`
- [ ] Crear `.env.example` con placeholders (ya existe)
- [ ] `.env` nunca se pushea a GitHub

### 3. Variables de Entorno Requeridas

**Obtener estos valores ANTES de desplegar:**

```bash
# JWT_SECRET - Generar uno fuerte
openssl rand -base64 48
# Copiar el resultado a Railway variables

# DATABASE_URL - Railway crea automáticamente
# Esperar a que PostgreSQL esté disponible

# AWS credentials
# Obtener de AWS IAM console:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_REGION (ej: us-east-1)
# - S3_BUCKET_NAME

# RUST_LOG
# Recomendado: "info,sqlx=warn,hyper=info"
```

- [ ] JWT_SECRET configurado en Railway (min 32 chars)
- [ ] DATABASE_URL configurado en Railway (con contraseña fuerte)
- [ ] AWS_ACCESS_KEY_ID configurado en Railway
- [ ] AWS_SECRET_ACCESS_KEY configurado en Railway
- [ ] AWS_REGION configurado en Railway
- [ ] S3_BUCKET_NAME configurado en Railway
- [ ] RUST_LOG configurado en Railway

### 4. Código Rust

- [ ] JWT_SECRET se lee desde `std::env::var("JWT_SECRET")`
- [ ] DATABASE_URL se lee desde `std::env::var("DATABASE_URL")`
- [ ] AWS credentials se leen desde variables de entorno
- [ ] S3_BUCKET_NAME intenta leer de `S3_BUCKET_NAME` primero, luego `AWS_BUCKET_NAME`
- [ ] RUST_LOG se configura en `main.rs`
- [ ] No hay hardcoded secrets en comentarios o strings

### 5. Git Repository

- [ ] `.env` está en `.gitignore` ✓
- [ ] No hay `.env` en el repositorio
- [ ] No hay archivos `.env.local` o `.env.production` en el repositorio
- [ ] Histórico limpio: `git log --all | grep -i "secret\|password"` está vacío

### 6. Dockerfile (Opcional pero Recomendado)

- [ ] `backend_api/Dockerfile` existe
- [ ] NO instala `dotenvy` en la imagen (solo en desarrollo)
- [ ] Variables de entorno se pasan en tiempo de ejecución, no en build
- [ ] Base image es slim (ej: `debian:bookworm-slim`)
- [ ] Healthcheck configurado

### 7. Railway Configuration

- [ ] Proyecto creado en Railway
- [ ] PostgreSQL plugin agregado
- [ ] Todas las variables configuradas
- [ ] Dockerfile especificado en railway.json (si aplica)

### 8. Seguridad Extra

- [ ] JWT_SECRET tiene al menos 32 caracteres
- [ ] DATABASE_URL no tiene contraseña débil
- [ ] AWS keys tienen permisos mínimos (least privilege en IAM)
- [ ] CORS_ALLOWED_ORIGINS está configurado para dominios específicos
- [ ] Logs NO exponen tokens o credenciales

### 9. Testing Pre-Deployment

```bash
# Test local con variables de entorno
$env:RUST_LOG="info"
$env:JWT_SECRET="test-secret-minimum-32-characters-required-12345"
$env:DATABASE_URL="postgresql://localhost:5432/test"
cargo run

# Verificar health endpoint
curl http://localhost:3000/health
```

- [ ] Servidor inicia correctamente
- [ ] Health endpoint responde
- [ ] Logs muestran nivel correcto (RUST_LOG)
- [ ] No hay panics o errores de variables no configuradas

### 10. Post-Deployment en Railway

```bash
# Conectar a Railway
railway login

# Ver logs
railway logs --tail 100

# Verificar que no hay "not set" o "missing" para variables
railway logs | grep -i "not set\|missing\|error"

# Test del endpoint
curl https://<your-railway-url>/health
```

- [ ] Servicio arrancó correctamente
- [ ] No hay errores en logs sobre variables no configuradas
- [ ] Health endpoint responde
- [ ] Logs muestran nivel RUST_LOG correcto

## 🚨 PROBLEMAS COMUNES

### "JWT_SECRET not set"
→ Agrega la variable en Railway Dashboard → Variables

### "DATABASE_URL not set"
→ Agrega PostgreSQL plugin y espera a que se inicialice

### "Logs vacíos"
→ Verifica que RUST_LOG está configurado: `railway variables | grep RUST_LOG`

### "Secretos en histórico de Git"
→ Usar `git-secret` o `BFG Repo-Cleaner` para limpiar histórico

## ✅ COMANDO FINAL DE AUDITORÍA

Antes de hacer `git push`:

```powershell
# 1. Ejecutar auditoría
.\security-audit.ps1

# 2. Revisar cambios
git status

# 3. Verificar que .env NO se está pusheando
git diff --cached | grep -i "database_url\|jwt_secret\|aws_" || echo "✅ Clean"

# 4. Push
git push
```

## 📚 Referencias

- Rust Secrets Management: https://docs.rs/dotenvy/
- Railway Docs: https://railway.app/docs
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- JWT Security: https://tools.ietf.org/html/rfc7519
