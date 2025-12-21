# ============================================
# ETAPA 1: BUILDER - Compilación con Rust
# ============================================
FROM rust:1.92-alpine AS builder

WORKDIR /app

# Instalar dependencias de compilación para Alpine
RUN apk add --no-cache musl-dev openssl-dev pkgconfig

# Copiar manifiestos para cachear dependencias
COPY Cargo.toml Cargo.lock ./

# Crear estructura mínima para cachear dependencias con versión de Cargo compatible
# Nota: Evitamos compilar dependencias con toolchains viejas que fallen por edition2024
RUN mkdir -p src && echo "fn main() {}" > src/main.rs && cargo fetch

# Copiar código real y migraciones
COPY src ./src
COPY migrations ./migrations

# Compilar aplicación en modo release (optimizado)
RUN cargo build --release

# ============================================
# ETAPA 2: RUNNER - Imagen final ultraligera
# ============================================
FROM gcr.io/distroless/base-debian12:nonroot

WORKDIR /app

# Copiar solo el binario compilado desde builder
COPY --from=builder /app/target/release/backend_api /app/backend_api

# Copiar migraciones (necesarias en runtime)
COPY --from=builder /app/migrations /app/migrations

# Copiar certificados SSL necesarios
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Railway asigna PORT dinámicamente, usar variable de entorno
ENV PORT=3000
ENV RUST_LOG=info
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

EXPOSE ${PORT}

# Ejecutar aplicación (distroless ya es seguro)
CMD ["/app/backend_api"]
