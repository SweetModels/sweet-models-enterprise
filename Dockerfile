# ============================================================================
# Sweet Models Enterprise - Production Dockerfile
# ============================================================================
# Multi-stage build para optimizar tamaño de imagen final
# Railway detectará automáticamente este archivo en la raíz del proyecto

# ============================================================================
# STAGE 1: Builder - Compilar la aplicación Rust
# ============================================================================
FROM rust:1.75-bookworm as builder

# Instalar dependencias de sistema necesarias para compilación
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración de Cargo primero (para cachear dependencias)
COPY backend_api/Cargo.toml backend_api/Cargo.lock ./

# Crear proyecto dummy para cachear dependencias
RUN mkdir src && \
    echo "fn main() {println!(\"dummy\")}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copiar todo el código fuente del backend
COPY backend_api/ .

# Compilar en modo release (optimizado para producción)
RUN cargo build --release

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

# Copiar binario compilado desde el builder
COPY --from=builder /app/target/release/backend_api /app/backend_api

# Copiar migraciones de base de datos (si existen)
COPY --from=builder /app/migrations /app/migrations

# Cambiar ownership al usuario no-root
RUN chown -R appuser:appuser /app

# Cambiar a usuario no-root
USER appuser

# Exponer puerto (Railway puede override con la variable PORT)
EXPOSE 8080

# Variables de entorno por defecto (Railway las overrideará)
ENV RUST_LOG=info
ENV PORT=8080

# Comando de inicio
CMD ["/app/backend_api"]
