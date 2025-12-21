use axum::{
    routing::{get, post},
    Json, Router,
    response::IntoResponse,
    extract::State,
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use tower_http::cors::CorsLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use std::net::SocketAddr;
use tokio::net::TcpListener;
use uuid::Uuid;
use sqlx::types::chrono;
use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey};
use argon2::{Argon2, PasswordHasher, PasswordHash, PasswordVerifier};
use argon2::password_hash::SaltString;
use rand::Rng;

// ============================================================================
// ESTRUCTURAS DE DATOS
// ============================================================================

#[derive(Serialize)]
struct HealthResponse {
    status: &'static str,
}

#[derive(Serialize)]
struct MessageResponse {
    message: String,
}

/// Payload de entrada para login
#[derive(Deserialize)]
struct LoginPayload {
    email: String,
    password: String,
}

/// Respuesta de login con token JWT y datos del usuario
#[derive(Serialize)]
struct LoginResponse {
    token: String,
    refresh_token: String,
    role: String,
    name: String,
    user_id: String,
    expires_in: i64,
}

/// Claims para JWT
#[derive(Serialize, Deserialize, Debug)]
struct Claims {
    sub: String,           // user_id
    email: String,
    role: String,
    exp: i64,              // expiration time
    iat: i64,              // issued at
}

/// Estructura del usuario en la base de datos
#[derive(Serialize, Deserialize, sqlx::FromRow)]
struct User {
    id: Uuid,
    email: String,
    password_hash: String,
    role: String,
    created_at: chrono::DateTime<chrono::Utc>,
}

/// Payload para registro
#[derive(Deserialize)]
struct RegisterPayload {
    email: String,
    password: String,
    name: String,
}

// ============================================================================
// CONFIGURACIÓN
// ============================================================================

// JWT_SECRET se lee desde la variable de entorno JWT_SECRET
// NO debe ser hardcodeado en el código
const TOKEN_EXPIRATION: i64 = 3600;  // 1 hora en segundos

/// Obtiene el JWT_SECRET desde las variables de entorno
/// Panics si no está configurado (comportamiento esperado en producción)
fn get_jwt_secret() -> Vec<u8> {
    std::env::var("JWT_SECRET")
        .expect("JWT_SECRET environment variable must be set")
        .into_bytes()
}

// ============================================================================
// FUNCIONES HELPER
// ============================================================================

/// Hash de contraseña con Argon2
fn hash_password(password: &str) -> Result<String, String> {
    let salt = SaltString::generate(rand::thread_rng());
    let argon2 = Argon2::default();
    
    argon2
        .hash_password(password.as_bytes(), &salt)
        .map_err(|e| format!("Error hashing password: {}", e))?
        .to_string()
        .split('$')
        .collect::<Vec<_>>()
        .join("$")
        .parse()
        .map_err(|_| "Failed to parse hash".to_string())
}

/// Verifica contraseña con hash Argon2
fn verify_password(password: &str, hash: &str) -> Result<bool, String> {
    let parsed_hash = PasswordHash::new(hash)
        .map_err(|e| format!("Error parsing hash: {}", e))?;
    
    let argon2 = Argon2::default();
    
    argon2
        .verify_password(password.as_bytes(), &parsed_hash)
        .map(|_| true)
        .or_else(|_| Ok(false))
}

/// Genera JWT token
fn generate_jwt(user_id: &str, email: &str, role: &str) -> Result<(String, String), String> {
    let now = chrono::Utc::now().timestamp();
    
    // Access token (1 hora)
    let claims = Claims {
        sub: user_id.to_string(),
        email: email.to_string(),
        role: role.to_string(),
        exp: now + TOKEN_EXPIRATION,
        iat: now,
    };
    
    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(&get_jwt_secret()),
    ).map_err(|e| format!("Error generating token: {}", e))?;
    
    // Refresh token (7 días)
    let refresh_claims = Claims {
        sub: user_id.to_string(),
        email: email.to_string(),
        role: role.to_string(),
        exp: now + (7 * 24 * 3600),
        iat: now,
    };
    
    let refresh_token = encode(
        &Header::default(),
        &refresh_claims,
        &EncodingKey::from_secret(&get_jwt_secret()),
    ).map_err(|e| format!("Error generating refresh token: {}", e))?;
    
    Ok((token, refresh_token))
}

/// Verifica JWT token
fn verify_jwt(token: &str) -> Result<Claims, String> {
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(&get_jwt_secret()),
        &Validation::default(),
    )
    .map(|data| data.claims)
    .map_err(|e| format!("Invalid token: {}", e))
}

// ============================================================================
// HANDLERS
// ============================================================================

async fn root() -> impl IntoResponse {
    "Sweet Models Enterprise: ONLINE v2.0 (JWT + Argon2)"
}

async fn health() -> impl IntoResponse {
    Json(HealthResponse { status: "ok" })
}

async fn setup_admin(State(pool): State<PgPool>) -> Result<impl IntoResponse, (StatusCode, String)> {
    // Hash de contraseña antes de guardar
    let password_hash = hash_password("temporal_123456")
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;

    let result = sqlx::query(
        r#"
        INSERT INTO users (id, email, password_hash, role, created_at)
        VALUES (gen_random_uuid(), $1, $2, $3, NOW())
        ON CONFLICT (email) DO NOTHING
        "#
    )
    .bind("admin@sweetmodels.com")
    .bind(&password_hash)
    .bind("admin")
    .execute(&pool)
    .await;

    match result {
        Ok(_) => Ok((
            StatusCode::CREATED,
            Json(MessageResponse {
                message: "Admin user created successfully with Argon2 hash".to_string(),
            }),
        )),
        Err(e) => {
            tracing::error!("Error creating admin: {:?}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Database error: {}", e),
            ))
        }
    }
}

/// Endpoint de Login - Autentica un usuario y devuelve JWT
/// POST /login
async fn login_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<LoginPayload>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("🔐 Intento de login para: {}", payload.email);

    // Validar que email y password no estén vacíos
    if payload.email.is_empty() || payload.password.is_empty() {
        tracing::warn!("❌ Email o contraseña vacíos");
        return Err((
            StatusCode::BAD_REQUEST,
            "Email y contraseña son requeridos".to_string(),
        ));
    }

    // Buscar el usuario en la base de datos por email
    let user: Option<User> = sqlx::query_as(
        r#"
        SELECT id, email, password_hash, role, created_at
        FROM users
        WHERE email = $1
        "#
    )
    .bind(&payload.email)
    .fetch_optional(&pool)
    .await
    .map_err(|e| {
        tracing::error!("Error en query de usuarios: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            "Error al consultar base de datos".to_string(),
        )
    })?;

    // Verificar que el usuario exista
    let user = match user {
        Some(u) => u,
        None => {
            tracing::warn!("❌ Usuario no encontrado: {}", payload.email);
            return Err((StatusCode::UNAUTHORIZED, "Email o contraseña incorrectos".to_string()));
        }
    };

    // Verificar contraseña con Argon2
    match verify_password(&payload.password, &user.password_hash) {
        Ok(true) => {
            tracing::info!("✅ Login exitoso para: {} (role: {})", payload.email, user.role);
        },
        Ok(false) => {
            tracing::warn!("❌ Contraseña incorrecta para: {}", payload.email);
            return Err((StatusCode::UNAUTHORIZED, "Email o contraseña incorrectos".to_string()));
        },
        Err(e) => {
            tracing::error!("Error verificando contraseña: {}", e);
            return Err((StatusCode::INTERNAL_SERVER_ERROR, "Error en autenticación".to_string()));
        }
    }

    // Generar JWT tokens
    let (token, refresh_token) = generate_jwt(
        &user.id.to_string(),
        &user.email,
        &user.role,
    ).map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;

    tracing::info!("🎫 JWT generado para: {}", payload.email);

    Ok((
        StatusCode::OK,
        Json(LoginResponse {
            token,
            refresh_token,
            role: user.role,
            name: payload.email.clone(),
            user_id: user.id.to_string(),
            expires_in: TOKEN_EXPIRATION,
        }),
    ))
}

/// Endpoint de Registro - Crea un nuevo usuario
/// POST /register
async fn register_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<RegisterPayload>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("📝 Intento de registro para: {}", payload.email);

    // Validar campos
    if payload.email.is_empty() || payload.password.is_empty() || payload.name.is_empty() {
        return Err((
            StatusCode::BAD_REQUEST,
            "Email, contraseña y nombre son requeridos".to_string(),
        ));
    }

    // Validar longitud de contraseña
    if payload.password.len() < 8 {
        return Err((
            StatusCode::BAD_REQUEST,
            "La contraseña debe tener al menos 8 caracteres".to_string(),
        ));
    }

    // Hash de la contraseña
    let password_hash = hash_password(&payload.password)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;

    // Insertar usuario
    let result = sqlx::query(
        r#"
        INSERT INTO users (id, email, password_hash, role, created_at)
        VALUES (gen_random_uuid(), $1, $2, 'model', NOW())
        "#
    )
    .bind(&payload.email)
    .bind(&password_hash)
    .execute(&pool)
    .await;

    match result {
        Ok(_) => {
            tracing::info!("✅ Registro exitoso para: {}", payload.email);
            Ok((
                StatusCode::CREATED,
                Json(MessageResponse {
                    message: "Usuario registrado exitosamente".to_string(),
                }),
            ))
        },
        Err(e) => {
            if e.to_string().contains("unique constraint") {
                tracing::warn!("❌ Email ya registrado: {}", payload.email);
                Err((
                    StatusCode::CONFLICT,
                    "Este email ya está registrado".to_string(),
                ))
            } else {
                tracing::error!("Error en registro: {:?}", e);
                Err((
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Error al registrar usuario".to_string(),
                ))
            }
        }
    }
}

/// Endpoint de Verificación de Token - Valida JWT
/// GET /verify-token
/// Headers: Authorization: Bearer <token>
async fn verify_token_handler(
    axum::extract::ConnectInfo(addr): axum::extract::ConnectInfo<std::net::SocketAddr>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    // Este handler requeriría middleware para extraer el token del header
    // Por ahora es un stub
    Ok((StatusCode::OK, Json(MessageResponse {
        message: "Endpoint para verificar tokens".to_string(),
    })))
}

// ============================================================================
// DATABASE INITIALIZATION
// ============================================================================

async fn initialize_database(pool: &PgPool) -> Result<(), sqlx::Error> {
    tracing::info!("Inicializando esquema de base de datos...");

    // Crear tabla users
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS users (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL CHECK (role IN ('admin', 'moderator', 'model')),
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
        "#
    )
    .execute(pool)
    .await?;

    tracing::info!("✓ Tabla 'users' verificada");

    // Crear tabla groups
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS groups (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name TEXT NOT NULL,
            moderator_id UUID REFERENCES users(id) ON DELETE SET NULL,
            platform TEXT CHECK (platform IN ('chaturbate', 'stripchat')),
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
        "#
    )
    .execute(pool)
    .await?;

    tracing::info!("✓ Tabla 'groups' verificada");
    tracing::info!("Base de datos inicializada correctamente");

    Ok(())
}

// ============================================================================
// MAIN
// ============================================================================

#[tokio::main]
async fn main() {
    // Inicializa el logger con filtro por entorno
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into())
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Carga variables de entorno
    dotenvy::dotenv().ok();

    // Lee DATABASE_URL del .env
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL debe estar definida en el archivo .env");

    tracing::info!("Conectando a PostgreSQL...");

    // Crea el pool de conexiones
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Error al conectar con PostgreSQL. Verifica DATABASE_URL y que el servidor esté ejecutándose.");

    tracing::info!("✓ Conexión a PostgreSQL establecida");

    // Inicializa el esquema de base de datos
    initialize_database(&pool)
        .await
        .expect("Error al inicializar la base de datos");

    // CORS permisivo para desarrollo
    let cors = CorsLayer::very_permissive();

    // Define las rutas con estado compartido (pool)
    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health))
        .route("/setup_admin", post(setup_admin))
        .route("/login", post(login_handler))
        .route("/register", post(register_handler))
        .route("/verify-token", get(verify_token_handler))
        .with_state(pool)
        .layer(cors);

    // Inicia el servidor
    let addr: SocketAddr = "0.0.0.0:3000".parse().unwrap();
    let listener = TcpListener::bind(addr).await.unwrap();
    tracing::info!("🚀 Servidor escuchando en {} (JWT + Argon2)", addr);
    axum::serve(listener, app).await.unwrap();
}
