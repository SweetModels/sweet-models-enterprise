# 🚀 Guía de Despliegue Railway - Monorepo

## ✅ Archivos Creados

Se han creado los siguientes archivos en la **raíz del proyecto**:

- ✅ `Dockerfile` - Instrucciones de construcción optimizadas
- ✅ `.dockerignore` - Exclusiones para build más rápido
- ✅ `railway.json` - Configuración de Railway

## 📋 Pasos para Desplegar

### 1. Subir a GitHub

```bash
git add .
git commit -m "feat: Add production Dockerfile for Railway deployment"
git push
```

### 2. Configurar Railway

1. Ve a https://railway.app
2. Crea un nuevo proyecto: **New Project → Deploy from GitHub**
3. Selecciona tu repositorio: `sweet-models-enterprise`
4. Railway detectará automáticamente el `Dockerfile` en la raíz

### 3. Configurar Variables de Entorno

En Railway, ve a **Variables** y agrega:

```bash
# OBLIGATORIAS
JWT_SECRET=tu_super_secret_key_min_32_caracteres_aqui
DATABASE_URL=postgresql://user:password@host:port/database
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxx

# Firebase (si usas notificaciones)
FCM_PROJECT_ID=tu-proyecto-firebase
FCM_API_KEY=tu-api-key-firebase

# Opcionales
RUST_LOG=info
PORT=8080
```

### 4. Agregar PostgreSQL

En Railway:
1. Click en **New** → **Database** → **PostgreSQL**
2. Railway automáticamente configurará `DATABASE_URL`
3. Ejecuta las migraciones:

```bash
# Railway ejecutará automáticamente si tienes migrations/
# O puedes hacerlo manualmente con sqlx-cli
```

### 5. Verificar Despliegue

Railway te dará una URL pública como:
```
https://tu-app.railway.app
```

Prueba:
```bash
curl https://tu-app.railway.app/health
```

## 🏗️ Cómo Funciona el Dockerfile

### Stage 1: Builder
- Usa `rust:1.75-bookworm` para compilar
- Instala dependencias de sistema (OpenSSL, PostgreSQL)
- Cachea dependencias de Cargo para builds más rápidos
- Compila en modo `--release` (optimizado)

### Stage 2: Runtime
- Usa `debian:bookworm-slim` (imagen ligera)
- Solo incluye binario compilado + dependencias runtime
- Usuario no-root para seguridad
- Tamaño final: ~100-150 MB vs ~2 GB del builder

## 🔍 Troubleshooting

### Railway no encuentra el Dockerfile
```bash
# Asegúrate de que esté en la raíz:
ls -la Dockerfile  # Debe estar en la raíz, no en backend_api/
```

### Error de compilación
```bash
# Verifica que Cargo.toml tenga todas las dependencias:
cd backend_api
cargo build --release
```

### Error de migraciones
```bash
# Railway necesita ejecutar migraciones
# Opción 1: Agregar comando en railway.json
# Opción 2: Usar railway CLI
railway run sqlx migrate run
```

### Puerto incorrecto
Railway asigna dinámicamente el puerto a través de la variable `PORT`.
El Dockerfile ya está configurado para leerla.

## 📊 Métricas Esperadas

- **Build time**: 5-10 minutos (primera vez, luego 1-2 min con cache)
- **Image size**: 100-150 MB
- **Memory usage**: 50-200 MB en idle
- **Cold start**: 2-5 segundos

## 🎯 Próximos Pasos

1. ✅ Subir Dockerfile a GitHub
2. ⏳ Conectar Railway con GitHub
3. ⏳ Configurar variables de entorno
4. ⏳ Agregar PostgreSQL
5. ⏳ Verificar deployment exitoso

## 📚 Recursos Adicionales

- [Railway Documentation](https://docs.railway.app)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Rust on Railway](https://railway.app/template/rust)
