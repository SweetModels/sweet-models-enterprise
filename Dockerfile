# ============================================================================
# Sweet Models Enterprise - Production Dockerfile
# ============================================================================
# Dockerfile para monorepo - El código de Rust está en backend_api/
# Railway detectará automáticamente este archivo en la raíz del proyecto

# ============================================================================
# STAGE 1: Builder - Compilar la aplicación Rust
# ============================================================================
FROM rust:latest as builder

# Instalar dependencias de sistema necesarias para compilación
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar TODO el proyecto (monorepo completo)
COPY . .

# Cambiar al directorio donde está el Cargo.toml
WORKDIR /app/backend_api

# CACHE BUSTER: Forzar rebuild completo
RUN echo "CacheBuster: $(date)"

# Compilar en modo release (optimizado para producción)
RUN cargo build --release

# SMART COPY: Buscar ejecutable compilado y copiarlo como /tmp/server
RUN find ./target/release -maxdepth 1 -type f -executable -exec cp {} /tmp/server \;

# ============================================================================
# STAGE 2: Runtime - Imagen final ligera
# ============================================================================
FROM debian:bookworm-slim

# Instalar dependencias runtime mínimas
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario no-root para seguridad
RUN useradd -m -u 1001 -s /bin/bash appuser

# Crear directorio de trabajo
WORKDIR /app

# Copiar binario renombrado "server" desde la etapa builder
COPY --from=builder /tmp/server /app/server

# Copiar migraciones de base de datos (si existen)
COPY --from=builder /app/backend_api/migrations /app/migrations

# DUAL NAMING: Crear symlink para que /app/backend_api apunte a /app/server
RUN ln -s /app/server /app/backend_api

# Permisos y ownership para ambos archivos
RUN chmod +x /app/server /app/backend_api && chown -R appuser:appuser /app

# Cambiar a usuario no-root
USER appuser

# Exponer puerto (Railway puede override con la variable PORT)
EXPOSE 8080

# Variables de entorno por defecto (Railway las overrideará)
ENV RUST_LOG=info
ENV PORT=8080

# Comando de inicio
CMD ["/app/server"]
