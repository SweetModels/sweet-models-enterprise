FROM rust:1.88-alpine AS builder
RUN apk add --no-cache musl-dev openssl-dev pkgconfig
WORKDIR /app
COPY Cargo.toml ./
COPY Cargo.lock ./
RUN mkdir -p src && echo "fn main(){}" > src/main.rs
# Pre-compile dependencies only
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release 2>&1 | head -100 || true
COPY src ./src
COPY migrations ./migrations
RUN cargo build --release

FROM alpine:3.20
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /app/target/release/backend_api /usr/local/bin/backend_api
USER app
EXPOSE 3000
ENV RUST_LOG=info
CMD ["/usr/local/bin/backend_api"]
