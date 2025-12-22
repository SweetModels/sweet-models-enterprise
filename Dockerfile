# ============================================================================
# Sweet Models Enterprise - Production Dockerfile (Debian Bookworm Unified)
# ============================================================================
# Construcción con Rust Nightly (soporta edition2024)
# Ejecución con Debian Bookworm Slim (GLIBC compatible)

# ============================================================================
# STAGE 1: Construcción (Build) - Rust Nightly + Debian Bookworm
# ============================================================================
# Rust nightly para soportar edition2024 (requerido por home v0.5.12)
FROM rustlang/rust:nightly-bookworm as builder

WORKDIR /app

# Copiar TODO el proyecto (monorepo completo)
COPY . .

# Compilar en modo release (optimizado para producción)
RUN cargo build --release

# ============================================================================
# STAGE 2: Ejecución (Runtime) - Debian Bookworm Slim
# ============================================================================
FROM debian:bookworm-slim

WORKDIR /app

# Instalar dependencias del sistema (OpenSSL y Certificados para AWS/DB)
RUN apt-get update && apt-get install -y \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copiar el binario compilado de la etapa builder
# El binario se llama 'backend_api' según Cargo.toml [[bin]] name="backend_api"
COPY --from=builder /app/backend_api/target/release/backend_api /app/backend_api

# Permisos de ejecución
RUN chmod +x /app/backend_api

# Variables de entorno por defecto (Railway las overrideará)
ENV RUST_LOG=info
ENV PORT=8080

# Exponer puerto
EXPOSE 8080

# Comando de inicio - Ejecutar el binario con su nombre correcto
CMD ["/app/backend_api"]
