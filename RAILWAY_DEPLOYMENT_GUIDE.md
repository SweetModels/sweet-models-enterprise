# 🚂 RAILWAY DEPLOYMENT GUIDE - Rust Backend

Este documento te guía paso a paso para desplegar tu backend Rust en Railway de forma SEGURA sin exponer secretos.

## ⚠️ SEGURIDAD CRÍTICA

**NUNCA incluyas credenciales en el código.** Todas las variables sensibles deben estar en Railway variables, no en el repositorio Git.

### Credenciales que se leen desde variables de entorno:
- ✅ `JWT_SECRET` - Token signing secret
- ✅ `DATABASE_URL` - PostgreSQL connection with password
- ✅ `AWS_ACCESS_KEY_ID` - AWS credentials
- ✅ `AWS_SECRET_ACCESS_KEY` - AWS credentials
- ✅ `AWS_REGION` - AWS region
- ✅ `S3_BUCKET_NAME` - S3 bucket name
- ✅ `RUST_LOG` - Logging level

## 🚀 Pasos para Desplegar en Railway

### Paso 1: Preparar el Repositorio

```bash
# 1. Asegúrate que tu .env NO está en git
git status

# 2. Verifica que .env esté en .gitignore
cat .gitignore | grep ".env"

# 3. Si .env estaba antes, elimínalo del historio
git rm --cached backend_api/.env
git commit -m "Remove .env from tracking"

# 4. Verificar que no hay secretos en el código
git log --all -p -- backend_api/src | grep -i "secret\|password\|AKIA" || echo "✅ No secrets found"
```

### Paso 2: Crear Proyecto en Railway

```bash
# 1. Instalar Railway CLI
npm install -g @railway/cli
# o para PowerShell
choco install railway
# o descarga desde https://railway.app/

# 2. Loguear en Railway
railway login

# 3. Crear nuevo proyecto
railway init

# 4. Seleccionar: "Create a new project"
```

### Paso 3: Configurar Base de Datos PostgreSQL

Railway proporciona PostgreSQL automáticamente:

```bash
# 1. En el panel de Railway, agregar PostgreSQL plugin
# Ve a https://railway.app y abre tu proyecto

# 2. Click en "Plugins" → "+ Add" → "PostgreSQL"

# 3. Railway crea automáticamente DATABASE_URL
# (Se mostrará en Variables cuando esté listo)
```

### Paso 4: Configurar Variables de Entorno en Railway

**Via Railway Dashboard Web (RECOMENDADO):**

1. Ve a https://railway.app/dashboard
2. Abre tu proyecto
3. Selecciona tu servicio backend
4. Tab "Variables"
5. Agrega cada variable:

```
JWT_SECRET=<tu-secret-fuerte-aqui-min-32-chars>
AWS_ACCESS_KEY_ID=<tu-aws-key>
AWS_SECRET_ACCESS_KEY=<tu-aws-secret>
AWS_REGION=us-east-1
S3_BUCKET_NAME=sweet-models-media
RUST_LOG=info,sqlx=warn,hyper=info
```

**Vía Railway CLI:**

```bash
# Navegar al directorio del backend
cd backend_api

# Configurar variables
railway variables set JWT_SECRET="tu-secret-key-aqui-minimo-32-caracteres"
railway variables set AWS_ACCESS_KEY_ID="tu-aws-key"
railway variables set AWS_SECRET_ACCESS_KEY="tu-aws-secret"
railway variables set AWS_REGION="us-east-1"
railway variables set S3_BUCKET_NAME="sweet-models-media"
railway variables set RUST_LOG="info,sqlx=warn,hyper=info"

# Ver todas las variables
railway variables

# Ver variables en archivo
railway variables export > .env.production
```

### Paso 5: Configurar el Dockerfile (Recomendado)

Crea un optimizado `Dockerfile` en la raíz de `backend_api/`:

```dockerfile
# Stage 1: Build
FROM rust:1.75-slim as builder

WORKDIR /app

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copiar código
COPY . .

# Build optimizado
RUN cargo build --release --bin backend_api

# Stage 2: Runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar binary desde builder
COPY --from=builder /app/target/release/backend_api /app/backend_api

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT:-3000}/health || exit 1

# Puerto (Railway inyecta PORT variable)
EXPOSE ${PORT:-3000}

# Ejecutar
CMD ["./backend_api"]
```

Guardar como: `backend_api/Dockerfile`

### Paso 6: Configurar railway.json (Opcional)

Crea un archivo `railway.json` en la raíz del proyecto para automatizar:

```json
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfile": "backend_api/Dockerfile"
  },
  "deploy": {
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

### Paso 7: Desplegar

```bash
# Opción 1: Desde la CLI
cd backend_api
railway up

# Opción 2: Desde el Dashboard
# 1. Conectar GitHub repo
# 2. Railway auto-deploya en cada push a main
# 3. Ver logs en https://railway.app/dashboard

# Ver logs en tiempo real
railway logs
```

## 📋 Verificación Post-Deployment

### Verificar que funciona

```bash
# 1. Obtener URL del servicio
railway variables | grep RAILWAY_PUBLIC_DOMAIN

# 2. Test de health
curl https://<tu-railway-url>/health

# 3. Ver logs
railway logs --tail 100

# 4. Verificar variables (sin mostrar valores sensibles)
railway variables | head -20
```

### Checklist de Seguridad

- [ ] `.env` está en `.gitignore`
- [ ] No hay archivos `.env` en el repositorio (`git log --all -p | grep AWS_`)
- [ ] Todas las credenciales están en Railway Variables
- [ ] `JWT_SECRET` tiene al menos 32 caracteres
- [ ] `DATABASE_URL` tiene password fuerte
- [ ] `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` son válidos
- [ ] RUST_LOG está configurado
- [ ] Health check responde correctamente
- [ ] Los logs NO muestran secretos

## 🔧 Troubleshooting

### El servidor no inicia

```bash
# Ver logs detallados
railway logs

# Buscar errores de variable de entorno
railway logs | grep -i "error\|panic\|not set"

# Verificar que JWT_SECRET tiene suficientes caracteres
railway variables | grep JWT_SECRET | wc -c  # Debe ser > 32
```

### Errores de autenticación

```bash
# Verificar que RUST_LOG está seteado
railway variables | grep RUST_LOG

# Cambiar a debug mode
railway variables set RUST_LOG=debug
railway up

# Ver logs detallados
railway logs --tail 200
```

### Errores de base de datos

```bash
# Verificar DATABASE_URL
railway variables | grep DATABASE_URL

# Probar conexión
railway exec psql $DATABASE_URL -c "SELECT 1"
```

## 📚 Variables de Entorno Disponibles en Railway

Railway proporciona automáticamente:

- `PORT` - Puerto asignado (ej: 8080)
- `RAILWAY_PUBLIC_DOMAIN` - URL pública
- `RAILWAY_ENVIRONMENT_NAME` - "production", "staging", etc.
- `RAILWAY_PRIVATE_DOMAIN` - URL interna

Tu código debe usar:

```rust
// Railway inyecta PORT, usa SERVER_PORT como fallback
let port = std::env::var("PORT")
    .or_else(|_| std::env::var("SERVER_PORT"))
    .unwrap_or_else(|_| "3000".to_string());
```

## 🔐 Mejores Prácticas de Seguridad

### 1. Rotación de Secretos

```bash
# Generar nuevo JWT_SECRET cada cierto tiempo
openssl rand -base64 48

# Actualizar en Railway
railway variables set JWT_SECRET="nuevo-secret-aqui"
```

### 2. Auditoría de Logs

```bash
# Descargar logs para auditoría
railway logs --tail 10000 > logs.txt

# Buscar intentos de acceso no autorizados
grep "Unauthorized\|Invalid token" logs.txt
```

### 3. Renovación de Credenciales AWS

- Rotar `AWS_ACCESS_KEY_ID` cada 90 días
- Usar roles IAM con permisos mínimos (least privilege)
- Crear claves específicas por entorno (dev, staging, production)

## 📞 Soporte

- Railway Docs: https://railway.app/docs
- Rust SQLX: https://github.com/launchbadge/sqlx
- JWT Rust: https://github.com/Keats/jsonwebtoken
