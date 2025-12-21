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

# Compilar en modo release (optimizado para producción)
RUN cargo build --release

# DEBUG: Listar artefactos para ver el nombre real del binario
RUN ls -la /app/backend_api/target/release/

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

# Copiar binario compilado desde el builder (entrypoint servidor)
COPY --from=builder /app/backend_api/target/release/backend_api /app/server

# Copiar migraciones de base de datos (si existen)
COPY --from=builder /app/backend_api/migrations /app/migrations

# Cambiar ownership al usuario no-root
RUN chmod +x /app/server && chown -R appuser:appuser /app

# Cambiar a usuario no-root
USER appuser

# Exponer puerto (Railway puede override con la variable PORT)
EXPOSE 8080

# Variables de entorno por defecto (Railway las overrideará)
ENV RUST_LOG=info
ENV PORT=8080

# Comando de inicio
CMD ["/app/server"]
