mod ai;

use std::{net::SocketAddr, sync::Arc, time::Duration, io};

use axum::{routing::{get, post}, body::Bytes, Json, Router};
use deadpool_redis::redis::AsyncCommands;
use serde_json::json;
use sqlx::postgres::PgPoolOptions;
use tokio::{signal, task::JoinHandle, time::interval, sync::broadcast};
use tokio::net::TcpListener;
use tonic::transport::Server;
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::fmt::writer::MakeWriterExt;

use backend_api::finance::handlers::{
    seal_transaction_handler,
    verify_chain_handler,
    user_transaction_history_handler,
};
use backend_api::state::AppState;
use backend_api::social;
use backend_api::auth;
use backend_api::config;
use backend_api::tls::TlsConfiguration;

type DynError = Box<dyn std::error::Error + Send + Sync>;
#[tokio::main]
async fn main() -> Result<(), DynError> {
    dotenvy::dotenv().ok();

    // Validate environment variables before starting
    config::validate_environment();

    let file = std::fs::File::create("errors.log").unwrap_or_else(|_| {
        std::fs::File::create("phoenix_errors.log").expect("No se pudo crear errors.log")
    });
    let subscriber = tracing_subscriber::fmt()
        .with_target(false)
        .with_writer(io::stdout.and(file))
        .finish();
    let _ = tracing::subscriber::set_global_default(subscriber);

    tokio::spawn(async {
        ai::phoenix::start_sentinel().await;
    });

    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let redis_url = std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://127.0.0.1:6379".to_string());
    let nats_url = std::env::var("NATS_URL").unwrap_or_else(|_| "nats://127.0.0.1:4222".to_string());

    let db = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    let redis_cfg = deadpool_redis::Config::from_url(redis_url);
    let redis = redis_cfg.create_pool(Some(deadpool_redis::Runtime::Tokio1))?;

    let nats = async_nats::connect(nats_url).await?;

    let state = Arc::new(AppState { db, redis, nats });

    let (tx, _rx) = broadcast::channel(100);
    let chat_state = Arc::new(social::ChatState { tx });

    let (shutdown_tx, _) = tokio::sync::broadcast::channel::<()>(1);

    let http_handle = spawn_http_server(state.clone(), chat_state.clone(), shutdown_tx.subscribe());
    let grpc_handle = spawn_grpc_server(state.clone(), shutdown_tx.subscribe());
    let ledger_handle = spawn_ledger_worker(state.clone(), shutdown_tx.subscribe());

    tokio::select! {
        _ = signal::ctrl_c() => {
            tracing::info!("Ctrl+C recibido, cerrando Colmena...");
        }
        res = async {
            let (r1, r2, r3) = tokio::join!(http_handle, grpc_handle, ledger_handle);
            r1??;
            r2??;
            r3??;
            Ok::<(), DynError>(())
        } => {
            if let Err(e) = res {
                tracing::error!("Error en alguna tarea: {e}");
            }
        }
    }

    let _ = shutdown_tx.send(());

    Ok(())
}

fn spawn_http_server(
    state: Arc<AppState>,
    chat_state: Arc<social::ChatState>,
    mut shutdown: tokio::sync::broadcast::Receiver<()>,
) -> JoinHandle<Result<(), DynError>> {
    tokio::spawn(async move {
        let zk_router = auth::zk::router(state.clone());

        let app = Router::new()
            .route("/health", get(health_handler))
            .route("/api/ledger/seal", post(seal_transaction_handler))
            .route("/api/ledger/verify", get(verify_chain_handler))
            .route("/api/ledger/history/:user_id", get(user_transaction_history_handler))
            .nest("/api/chat", social::social_routes().with_state(chat_state))
            .nest("/api/web3", auth::web3::web3_routes())
            .nest("/api/zk", zk_router)
            .layer(CorsLayer::new().allow_origin(Any).allow_headers(Any).allow_methods(Any))
            .with_state(state);

        let addr = std::net::SocketAddr::from(([0, 0, 0, 0], 3000));

        // Check for TLS configuration
        if let Some(tls_config) = TlsConfiguration::from_env() {
            match tls_config.build_config() {
                Ok(_server_config) => {
                    tracing::info!("🔒 TLS configuration loaded successfully");
                    tracing::warn!("⚠️  HTTPS support requires axum 0.8+ with proper hyper integration");
                    tracing::warn!("   Falling back to HTTP for now. TLS infrastructure is ready for upgrade.");
                    backend_api::tls::print_dev_cert_instructions();
                }
                Err(e) => {
                    tracing::warn!("❌ Failed to load TLS config: {}", e);
                    tracing::warn!("⚠️  Falling back to HTTP (insecure)");
                    backend_api::tls::print_dev_cert_instructions();
                }
            }
        } else {
            tracing::info!("ℹ️  TLS not configured (TLS_CERT_PATH/TLS_KEY_PATH not set)");
            tracing::info!("   Running in HTTP mode (not recommended for production)");
        }

        // HTTP server (TLS requires additional dependencies/configuration)
        let listener = TcpListener::bind(addr).await?;
        tracing::info!("🌐 HTTP/WebSocket server escuchando en http://0.0.0.0:3000");

        axum::serve(listener, app)
            .with_graceful_shutdown(async move {
                let _ = shutdown.recv().await;
            })
            .await?;
        Ok(())
    })
}

fn spawn_grpc_server(
    state: Arc<AppState>,
    mut shutdown: tokio::sync::broadcast::Receiver<()>,
) -> JoinHandle<Result<(), DynError>> {
    tokio::spawn(async move {
        let addr: SocketAddr = "0.0.0.0:50051".parse()?;

        let (mut reporter, health_service) = tonic_health::server::health_reporter();
        reporter.set_serving::<HealthGrpc>().await;

        tracing::info!("  gRPC server escuchando en {}", addr);

        Server::builder()
            .add_service(health_service)
            .serve_with_shutdown(addr, async move {
                let _ = shutdown.recv().await;
            })
            .await?;
        let _ = state;
        Ok(())
    })
}

fn spawn_ledger_worker(
    state: Arc<AppState>,
    mut shutdown: tokio::sync::broadcast::Receiver<()>,
) -> JoinHandle<Result<(), DynError>> {
    tokio::spawn(async move {
        let mut ticker = interval(Duration::from_secs(5));
        tracing::info!(" Ledger worker iniciado (intervalo 5s)");
        loop {
            tokio::select! {
                _ = ticker.tick() => {
                    if let Err(e) = seal_ledger_tick(&state).await {
                        tracing::warn!("Ledger tick error: {e}");
                    }
                }
                _ = shutdown.recv() => {
                    tracing::info!("Ledger worker apagado");
                    break;
                }
            }
        }
        Ok(())
    })
}

async fn seal_ledger_tick(state: &AppState) -> Result<(), DynError> {
    let mut conn = state.redis.get().await?;
    let _: () = conn
        .set("ledger:last_seal", chrono::Utc::now().to_rfc3339())
        .await?;
    let _ = state.nats.publish("ledger.sealed", Bytes::from_static(b"ok")).await;
    Ok(())
}

async fn health_handler() -> Json<serde_json::Value> {
    Json(json!({
        "status": "ok",
        "http": true,
        "grpc": true,
        "ledger_worker": "running"
    }))
}

#[derive(Debug, Clone)]
struct HealthGrpc;

impl tonic::server::NamedService for HealthGrpc {
    const NAME: &'static str = "sme.health.v1.Health";
}
