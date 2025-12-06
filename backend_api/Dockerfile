# ============================================
# ETAPA 1: BUILDER - Compilación con Rust
# ============================================
FROM rust:latest AS builder

WORKDIR /app

# Copiar manifiestos para cachear dependencias
COPY Cargo.toml Cargo.lock ./

# Crear estructura dummy para cachear dependencias
RUN mkdir src && \
    echo "fn main() {println!(\"dummy\");}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copiar código real y migraciones
COPY src ./src
COPY migrations ./migrations

# Compilar aplicación en modo release (optimizado)
RUN cargo build --release

# ============================================
# ETAPA 2: RUNNER - Imagen final ultraligera
# ============================================
FROM debian:bullseye-slim

WORKDIR /app

# Instalar dependencias mínimas necesarias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copiar solo el binario compilado desde builder
COPY --from=builder /app/target/release/backend_api /app/backend_api

# Copiar migraciones (necesarias en runtime)
COPY --from=builder /app/migrations /app/migrations

# Railway asigna PORT dinámicamente, usar variable de entorno
ENV PORT=3000
ENV RUST_LOG=info

EXPOSE ${PORT}

# Ejecutar aplicación
CMD ["/app/backend_api"]
