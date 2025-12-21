# Requires: PowerShell 5.1+
# Usage: Run from the repo root `./setup.ps1`

$ErrorActionPreference = "Stop"

# Create monorepo structure
$root = "$PSScriptRoot"
$paths = @(
    "$root/backend_api",
    "$root/mobile_app",
    "$root/desktop_admin",
    "$root/database",
    "$root/docker"
)
foreach ($p in $paths) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }

# Initialize Rust backend
Set-Location "$root/backend_api"
if (-not (Test-Path "$root/backend_api/Cargo.toml")) {
    cargo init --bin | Out-Null
}

# Replace Cargo.toml with required dependencies
@"
[package]
name = "backend_api"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = "0.7"
tokio = { version = "1", features = ["rt-multi-thread", "macros"] }
sqlx = { version = "0.7", features = ["runtime-tokio", "postgres", "macros"] }
serde = { version = "1", features = ["derive"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "fmt"] }
argon2 = "0.5"
"@ | Set-Content "$root/backend_api/Cargo.toml"

@"
use axum::{routing::get, Router};
use std::net::SocketAddr;
use tracing::{info, Level};
use tracing_subscriber::{fmt, EnvFilter};

async fn secure_hello() -> &'static str {
    "Hola Mundo Seguro"
}

#[tokio::main]
async fn main() {
    let env_filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));
    fmt().with_max_level(Level::INFO).with_env_filter(env_filter).init();

    let app = Router::new().route("/", get(secure_hello));
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    info!("starting backend_api on {}", addr);

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .expect("server error");
}
"@ | Set-Content "$root/backend_api/src/main.rs"

# Dockerfile for backend
@"
FROM rust:1.81-alpine AS builder
RUN apk add --no-cache musl-dev openssl-dev pkgconfig
WORKDIR /app
COPY Cargo.toml ./
RUN mkdir -p src && echo "fn main(){}" > src/main.rs
RUN cargo build --release && rm -rf target/release/deps
COPY src ./src
RUN cargo build --release

FROM alpine:3.20
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /app/target/release/backend_api /usr/local/bin/backend_api
USER app
EXPOSE 8080
ENV RUST_LOG=info
CMD ["/usr/local/bin/backend_api"]
"@ | Set-Content "$root/backend_api/Dockerfile"

# Compose file at root
@"
version: "3.9"
services:
  postgres:
    image: postgres:16-alpine
    container_name: sme_postgres
    environment:
      POSTGRES_USER: sme_user
      POSTGRES_PASSWORD: sme_password
      POSTGRES_DB: sme_db
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - internal_net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sme_user -d sme_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./sweet_models_enterprise/backend_api
      dockerfile: Dockerfile
    container_name: sme_backend
    environment:
      DATABASE_URL: postgres://sme_user:sme_password@postgres:5432/sme_db
      RUST_LOG: info,sqlx=warn,hyper=info
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "8080:8080"
    networks:
      - internal_net

volumes:
  pgdata:

networks:
  internal_net:
    driver: bridge
    internal: true
"@ | Set-Content "$root/../docker-compose.yml"

Write-Host "Sweet Models Enterprise monorepo scaffolded."
