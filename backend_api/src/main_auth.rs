// =====================================================
// Sweet Models Enterprise - Backend API
// Sistema de Autenticación Modular
// =====================================================
//
// Este archivo demuestra cómo usar el sistema de autenticación
// modular implementado en src/models, src/handlers y src/services
//
// Estructura:
// - models/user.rs: Definición del modelo User y structs relacionados
// - services/password.rs: Hashing y verificación con Argon2
// - services/jwt.rs: Generación y validación de JWT tokens
// - handlers/auth.rs: Endpoints de autenticación (login, verify)

use axum::{
    routing::{get, post},
    Router,
};
use sqlx::postgres::PgPoolOptions;
use tower_http::cors::CorsLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use std::net::SocketAddr;

// Declarar módulos
mod models;
mod handlers;
mod services;

// Importar los handlers
use handlers::auth;

#[tokio::main]
async fn main() {
    // Inicializar logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "backend_api=debug,tower_http=debug,sqlx=info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    tracing::info!("🚀 Starting Sweet Models Enterprise Backend API");

    // Cargar variables de entorno
    dotenvy::dotenv().ok();
    
    // Obtener DATABASE_URL del entorno
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| {
            "postgres://sme_user:sme_password@localhost:5432/sme_db".to_string()
        });

    // Conectar a PostgreSQL
    tracing::info!("📊 Connecting to database...");
    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
        .expect("Failed to connect to PostgreSQL");

    tracing::info!("✅ Database connected successfully");

    // Crear el router de Axum
    let app = Router::new()
        // Rutas de autenticación
        .route("/api/auth/login", post(auth::login))
        
        // Ruta de health check
        .route("/health", get(health_check))
        
        // Compartir el pool de conexiones con todos los handlers
        .with_state(pool)
        
        // Configurar CORS
        .layer(CorsLayer::permissive());

    // Configurar dirección y puerto
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    tracing::info!("🌐 Server listening on http://{}", addr);
    tracing::info!("");
    tracing::info!("📋 Available endpoints:");
    tracing::info!("  POST /api/auth/login - Autenticación de usuarios");
    tracing::info!("  GET  /health         - Health check");
    tracing::info!("");

    // Iniciar el servidor
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("Failed to bind to address");

    axum::serve(listener, app)
        .await
        .expect("Server failed to start");
}

/// Health check endpoint
async fn health_check() -> &'static str {
    "OK"
}
