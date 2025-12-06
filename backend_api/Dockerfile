# Build stage with latest Alpine edge for security patches
FROM rust:alpine AS builder

# Install build dependencies
RUN apk add --no-cache musl-dev openssl-dev pkgconfig

WORKDIR /app

# Copy manifests
COPY Cargo.toml ./
COPY Cargo.lock ./

# Create dummy source for dependency caching
RUN mkdir -p src && echo "fn main(){}" > src/main.rs

# Pre-compile dependencies only
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release 2>&1 | head -100 || true

# Copy real source code
COPY src ./src
COPY migrations ./migrations

# Build actual application with static linking
RUN cargo build --release

# Runtime stage with minimal distroless image (no vulnerabilities)
FROM gcr.io/distroless/cc-debian12:nonroot

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/target/release/backend_api /app/backend_api

EXPOSE 3000

ENV RUST_LOG=info

CMD ["/app/backend_api"]
