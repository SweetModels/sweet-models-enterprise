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

# MAGIA: Buscar Cargo.toml, encontrar su directorio, y compilar desde ahí
RUN cd $(dirname $(find . -name Cargo.toml -maxdepth 2 | head -n 1)) && cargo build --release

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

# Buscar y copiar el binario compilado, sin importar en qué subcarpeta esté
# El binario se llama 'backend_api' según Cargo.toml [[bin]] name="backend_api"
COPY --from=builder /app/*/target/release/backend_api /app/backend_api

# Permisos de ejecución
RUN chmod +x /app/backend_api

# Variables de entorno por defecto (Railway las overrideará)
ENV RUST_LOG=info
ENV PORT=8080

# Exponer puerto
EXPOSE 8080

# Comando de inicio - Ejecutar el binario con su nombre correcto
CMD ["/app/backend_api"]
