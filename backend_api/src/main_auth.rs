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
use sqlx::mysql::MySqlPoolOptions;
use aws_config;
use aws_sdk_s3::Client as S3Client;
use deadpool_redis::{Config as RedisConfig, Runtime as RedisRuntime};
use mongodb::Client as MongoClient;

// Declarar módulos
mod models;
mod handlers;
mod services;
mod state;

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

    // Conectar a MySQL (respaldo)
    let mysql_url = std::env::var("MYSQL_URL")
        .unwrap_or_else(|_| "mysql://sme_user:sme_password@localhost:3306/sme_db".to_string());
    let mysql_pool = MySqlPoolOptions::new()
        .max_connections(10)
        .connect(&mysql_url)
        .await
        .expect("Failed to connect to MySQL");
    tracing::info!("✅ MySQL connected successfully");

    // Conectar a Redis
    let redis_url = std::env::var("REDIS_URL")
        .unwrap_or_else(|_| "redis://127.0.0.1:6379".to_string());
    let redis_cfg = RedisConfig::from_url(redis_url);
    let redis_pool = redis_cfg
        .create_pool(Some(RedisRuntime::Tokio1))
        .expect("Failed to create Redis pool");
    tracing::info!("✅ Redis connected successfully");

    // Conectar a MongoDB
    let mongodb_url = std::env::var("MONGODB_URL")
        .unwrap_or_else(|_| "mongodb://127.0.0.1:27017".to_string());
    let mongo_client = MongoClient::with_uri_str(&mongodb_url)
        .await
        .expect("Failed to connect to MongoDB");
    tracing::info!("✅ MongoDB connected successfully");

    // Cliente S3
    let aws_conf = aws_config::load_from_env().await;
    let s3_client = S3Client::new(&aws_conf);

    // Construir AppState compartido
    let app_state = state::AppState {
        db: pool.clone(),
        mongo: mongo_client.clone(),
        redis: redis_pool.clone(),
        mysql: mysql_pool.clone(),
        s3: s3_client.clone(),
    };

    // Crear el router de Axum
    let app = Router::new()
        // Rutas de autenticación
        .route("/api/auth/login", post(auth::login))
        
        // Ruta de health check
        .route("/health", get(health_check))
        
        // Compartir AppState con todos los handlers
        .with_state(app_state)
        
        // Configurar CORS
        .layer(CorsLayer::permissive());

    // Configurar dirección y puerto (usa PORT o 3000 por defecto) y bind a 0.0.0.0
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    let addr = format!("0.0.0.0:{}", port);
    tracing::info!("🌐 Server listening on http://{}", addr);
    tracing::info!("");
    tracing::info!("📋 Available endpoints:");
    tracing::info!("  POST /api/auth/login - Autenticación de usuarios");
    tracing::info!("  GET  /health         - Health check");
    tracing::info!("");

    // Iniciar el servidor
    let listener = tokio::net::TcpListener::bind(&addr)
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
