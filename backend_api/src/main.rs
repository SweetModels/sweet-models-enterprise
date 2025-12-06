use axum::{
    routing::{get, post},
    Json, Router,
    response::IntoResponse,
    extract::{State, Multipart},
    http::StatusCode,
};
use serde::{Serialize, Deserialize};
use sqlx::{postgres::PgPoolOptions, PgPool, Row};
use tower_http::cors::CorsLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use std::net::SocketAddr;
use tokio::net::TcpListener;
use uuid::Uuid;
use chrono::{self, NaiveDate, Utc, Duration, Datelike};
use jsonwebtoken::{encode, decode, Header, EncodingKey, DecodingKey, Validation};
use argon2::{Argon2, PasswordHasher, PasswordHash, PasswordVerifier};
use argon2::password_hash::SaltString;
use rand::{thread_rng, Rng};
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::fs;
use tokio::io::AsyncWriteExt;
use std::path::Path;


// ============================================================================
// CONSTANTS
// ============================================================================

const JWT_SECRET: &[u8] = b"your-secret-key-change-in-production-minimum-32-chars-12345";
const JWT_EXPIRATION_HOURS: i64 = 24;
const DEFAULT_TRM: f64 = 4000.0;
const TRM_ADJUSTMENT: f64 = 300.0;
const TOKEN_VALUE_MULTIPLIER: f64 = 0.05; // 5% base rate

// ============================================================================
// AUTH STRUCTURES
// ============================================================================

#[derive(Serialize, Deserialize, Debug, Clone)]
struct Claims {
    sub: String,
    email: String,
    role: String,
    exp: i64,
}

#[derive(Deserialize)]
struct LoginPayload {
    email: String,
    password: String,
}

#[derive(Serialize)]
struct LoginResponse {
    access_token: String,
    token_type: String,
    expires_in: i64,
    role: String,
    user_id: String,
}

#[derive(Deserialize)]
struct RegisterPayload {
    email: String,
    password: String,
}

#[derive(Deserialize)]
struct RegisterModelPayload {
    email: String,
    password: String,
    phone: Option<String>,
    address: Option<String>,
    national_id: Option<String>,
}

#[derive(Serialize)]
struct RegisterResponse {
    user_id: String,
    email: String,
    role: String,
    message: String,
}

// ============================================================================
// FINANCIAL STRUCTURES
// ============================================================================

#[derive(Serialize, Deserialize)]
struct PayrollCalculation {
    model_payment: f64,
    studio_revenue: f64,
    tokens_total: f64,
    members_count: i32,
    trm_used: f64,
    model_percentage: f64,
    studio_percentage: f64,
}

#[derive(Deserialize)]
struct PayrollRequest {
    group_tokens: f64,
    members_count: i32,
    manual_trm: Option<f64>,
}

#[derive(Deserialize)]
struct TrmUpdateRequest {
    trm_value: f64,
}

#[derive(Serialize)]
struct TrmResponse {
    trm_value: f64,
    updated_at: String,
    updated_by: String,
}

#[derive(Serialize)]
struct Camera {
    id: i32,
    name: String,
    stream_url: String,
    platform: String,
    is_active: bool,
}

impl sqlx::FromRow<'_, sqlx::postgres::PgRow> for Camera {
    fn from_row(row: &sqlx::postgres::PgRow) -> Result<Self, sqlx::Error> {
        use sqlx::Row;
        Ok(Camera {
            id: row.try_get("id")?,
            name: row.try_get("name")?,
            stream_url: row.try_get("stream_url")?,
            platform: row.try_get("platform")?,
            is_active: row.try_get("is_active")?,
        })
    }
}

#[derive(Serialize)]
struct CamerasResponse {
    cameras: Vec<Camera>,
    total_active: i32,
}

#[derive(Deserialize)]
struct FinancialPlanRequest {
    amount: f64,
    risk_tolerance: String,
}

#[derive(Serialize)]
struct FinancialPlanResponse {
    total_amount: f64,
    stocks_percentage: f64,
    bonds_percentage: f64,
    cash_percentage: f64,
    stocks_amount: f64,
    bonds_amount: f64,
    cash_amount: f64,
    risk_tolerance: String,
}

// ============================================================================
// OPERATIONS MODULE STRUCTURES
// ============================================================================

#[derive(Deserialize)]
struct ProductionLogRequest {
    group_id: String,
    date: String,
    tokens: f64,
}

#[derive(Serialize)]
struct ProductionLogResponse {
    id: String,
    group_id: String,
    date: String,
    amount_tokens: f64,
    message: String,
}

#[derive(Serialize)]
struct AuditLogResponse {
    id: String,
    entity_type: String,
    entity_id: String,
    action: String,
    old_value: Option<serde_json::Value>,
    new_value: serde_json::Value,
    user_id: String,
    timestamp: String,
}

#[derive(Serialize)]
struct DailyMetaNotification {
    achieved: bool,
    group_id: String,
    total_tokens: f64,
    message: String,
    timestamp: String,
}

// ============================================================================
// MODEL MODULE STRUCTURES
// ============================================================================

#[derive(Serialize)]
struct ModelHomeStats {
    today_earnings_cop: f64,
    week_earnings_cop: f64,
    month_earnings_cop: f64,
    active_points: f64,
}

#[derive(Deserialize)]
struct ContractUploadPayload {
    image_base64: String,
}

#[derive(Deserialize)]
struct SocialLinkRequest {
    platform: String,
    handle: String,
}

// ============================================================================
// OTP & SMS VERIFICATION STRUCTURES
// ============================================================================

#[derive(Deserialize)]
struct SendOtpRequest {
    phone: String,
}

#[derive(Serialize)]
struct SendOtpResponse {
    success: bool,
    message: String,
    expires_in_minutes: i32,
}

#[derive(Deserialize)]
struct VerifyOtpRequest {
    phone: String,
    code: String,
}

#[derive(Serialize)]
struct VerifyOtpResponse {
    success: bool,
    message: String,
    phone_verified: bool,
}

// ============================================================================
// KYC & FILE UPLOAD STRUCTURES
// ============================================================================

#[derive(Serialize)]
struct UploadKycResponse {
    success: bool,
    message: String,
    document_id: String,
    file_path: String,
}

#[derive(Serialize)]
struct KycDocument {
    id: String,
    document_type: String,
    status: String,
    uploaded_at: chrono::DateTime<chrono::Utc>,
}

// ============================================================================
// DASHBOARD STRUCTURES (EXISTING)
// ============================================================================

#[derive(Serialize, Deserialize, Debug, Clone)]
struct GroupDTO {
    name: String,
    platform: String,
    total_tokens: f64,
    members_count: i32,
    payout_per_member_cop: f64,
    created_at: chrono::DateTime<chrono::Utc>,
}

impl sqlx::FromRow<'_, sqlx::postgres::PgRow> for GroupDTO {
    fn from_row(row: &sqlx::postgres::PgRow) -> Result<Self, sqlx::Error> {
        use sqlx::Row;
        Ok(GroupDTO {
            name: row.try_get("name")?,
            platform: row.try_get("platform")?,
            total_tokens: row.try_get("total_tokens")?,
            members_count: row.try_get("members_count")?,
            payout_per_member_cop: row.try_get("payout_per_member_cop")?,
            created_at: row.try_get("created_at")?,
        })
    }
}

#[derive(Serialize)]
struct DashboardResponse {
    groups: Vec<GroupDTO>,
    total_tokens: f64,
    total_members: i32,
    total_payout_cop: f64,
    trm_used: f64,
}

// ============================================================================
// FINANCIAL ANALYTICS - CANDLESTICK DATA
// ============================================================================

#[derive(Serialize, Clone)]
struct FinancialCandle {
    date: String,  // Formato "YYYY-MM-DD"
    open: f64,     // Valor apertura del día
    high: f64,     // Valor máximo del día
    low: f64,      // Valor mínimo del día
    close: f64,    // Valor cierre del día
    volume: f64,   // Total tokens procesados
}

/// Genera datos históricos simulados de los últimos 30 días
/// con variación realista para probar gráficos financieros
fn get_historical_data(days: i64) -> Vec<FinancialCandle> {
    let mut rng = thread_rng();
    let mut candles = Vec::new();
    
    // Valores iniciales
    let mut last_close: f64 = 50000.0; // $50,000 COP base
    let today = Utc::now().naive_utc().date();
    
    for day_offset in (0..days).rev() {
        let date = today - Duration::days(day_offset);
        
        // Variación diaria: entre -15% y +20% (más volatilidad realista)
        let variation: f64 = rng.gen_range(-0.15..0.20);
        let day_change: f64 = last_close * variation;
        
        let open: f64 = last_close;
        let close: f64 = (last_close + day_change).max(10000.0); // Mínimo $10k
        
        // High y Low basados en open/close
        let high: f64 = open.max(close) * rng.gen_range(1.0..1.08);
        let low: f64 = open.min(close) * rng.gen_range(0.92..1.0);
        
        // Volumen aleatorio: entre 5,000 y 50,000 tokens
        let volume: f64 = rng.gen_range(5000.0..50000.0);
        
        candles.push(FinancialCandle {
            date: date.format("%Y-%m-%d").to_string(),
            open: (open * 100.0).round() / 100.0,
            high: (high * 100.0).round() / 100.0,
            low: (low * 100.0).round() / 100.0,
            close: (close * 100.0).round() / 100.0,
            volume: volume.round(),
        });
        
        last_close = close;
    }
    
    tracing::info!("📊 Generated {} candles, last close: ${:.2}", candles.len(), last_close);
    candles
}

// ============================================================================
// FINANCIAL LOGIC - DOBLE TRM SYSTEM
// ============================================================================

/// Calcula el pago de nómina con el sistema de "Doble TRM"
/// 
/// Lógica:
/// 1. Si tokens < 10,000: Modelo 60% / Studio 40%
/// 2. Si tokens >= 10,000: Modelo 65% / Studio 35%
/// 3. Pago Modelo = (Tokens / Miembros) * % * 0.05 * (TRM - 300)
/// 4. Ganancia Studio = Tokens Total * % * 0.05 * TRM
fn calculate_payroll(group_tokens: f64, members_count: i32, manual_trm: f64) -> PayrollCalculation {
    tracing::info!("💰 Calculating payroll: tokens={}, members={}, trm={}", 
        group_tokens, members_count, manual_trm);

    // Validations
    if members_count <= 0 {
        tracing::warn!("⚠️  Invalid members_count: {}", members_count);
        return PayrollCalculation {
            model_payment: 0.0,
            studio_revenue: 0.0,
            tokens_total: group_tokens,
            members_count,
            trm_used: manual_trm,
            model_percentage: 0.0,
            studio_percentage: 0.0,
        };
    }

    // Determine percentages based on token threshold
    let (model_pct, studio_pct) = if group_tokens < 10000.0 {
        (0.60, 0.40) // Small groups: 60% model, 40% studio
    } else {
        (0.65, 0.35) // Large groups: 65% model, 35% studio
    };

    // Calculate model payment per member
    let tokens_per_member = group_tokens / (members_count as f64);
    let model_payment_per_member = tokens_per_member 
        * model_pct 
        * TOKEN_VALUE_MULTIPLIER 
        * (manual_trm - TRM_ADJUSTMENT);

    // Calculate studio revenue (total)
    let studio_revenue = group_tokens 
        * studio_pct 
        * TOKEN_VALUE_MULTIPLIER 
        * manual_trm;

    tracing::info!(
        "✅ Payroll calculated: model_pct={}%, studio_pct={}%, payment_per_model=${:.2}, studio_revenue=${:.2}",
        model_pct * 100.0, studio_pct * 100.0, model_payment_per_member, studio_revenue
    );

    PayrollCalculation {
        model_payment: model_payment_per_member,
        studio_revenue,
        tokens_total: group_tokens,
        members_count,
        trm_used: manual_trm,
        model_percentage: model_pct * 100.0,
        studio_percentage: studio_pct * 100.0,
    }
}

// ============================================================================
// AUTH HELPERS
// ============================================================================

fn require_role(headers: &axum::http::HeaderMap, expected_role: &str) -> Result<Claims, StatusCode> {
    let auth_header = headers
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let claims = decode::<Claims>(
        token,
        &DecodingKey::from_secret(JWT_SECRET),
        &Validation::default(),
    )
    .map_err(|_| StatusCode::UNAUTHORIZED)?
    .claims;

    if claims.role != expected_role {
        return Err(StatusCode::FORBIDDEN);
    }

    Ok(claims)
}

async fn current_trm(pool: &PgPool) -> f64 {
    let trm_result: Option<(String,)> = sqlx::query_as(
        "SELECT config_value FROM financial_config WHERE config_key = 'trm_daily'"
    )
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();

    trm_result
        .and_then(|(v,)| v.parse::<f64>().ok())
        .unwrap_or(DEFAULT_TRM)
}

async fn sum_points_since(
    pool: &PgPool,
    user_id: &str,
    since: Option<chrono::DateTime<chrono::Utc>>,
) -> Result<f64, (StatusCode, String)> {
    let user_uuid = uuid::Uuid::parse_str(user_id)
        .map_err(|_| (StatusCode::BAD_REQUEST, "Invalid user ID".to_string()))?;
    
    let total: f64 = if let Some(since_date) = since {
        sqlx::query_scalar::<_, f64>(
            "SELECT COALESCE(SUM(amount), 0) FROM points_ledger WHERE user_id = $1 AND created_at >= $2"
        )
        .bind(user_uuid)
        .bind(since_date)
        .fetch_one(pool).await
    } else {
        sqlx::query_scalar::<_, f64>(
            "SELECT COALESCE(SUM(amount), 0) FROM points_ledger WHERE user_id = $1"
        )
        .bind(user_uuid)
        .fetch_one(pool).await
    }
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;
    
    Ok(total)
}

async fn award_points(
    pool: &PgPool,
    user_id: &str,
    amount: f64,
    reason: &str,
) -> Result<(), (StatusCode, String)> {
    let user_uuid = uuid::Uuid::parse_str(user_id)
        .map_err(|_| (StatusCode::BAD_REQUEST, "Invalid user ID".to_string()))?;
    
    sqlx::query(
        "INSERT INTO points_ledger (user_id, amount, reason) VALUES ($1, $2, $3)"
    )
    .bind(user_uuid)
    .bind(amount)
    .bind(reason)
    .execute(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to award points: {}", e)))?;
    
    Ok(())
}

// ============================================================================
// SECURITY FUNCTIONS
// ============================================================================

fn hash_password(password: &str) -> Result<String, String> {
    let salt = SaltString::generate(thread_rng());
    let argon2 = Argon2::default();
    
    argon2
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|e| format!("Error hashing password: {}", e))
}

fn verify_password(password: &str, hash: &str) -> Result<bool, String> {
    let parsed_hash = PasswordHash::new(hash)
        .map_err(|e| format!("Invalid hash: {}", e))?;
    
    let argon2 = Argon2::default();
    match argon2.verify_password(password.as_bytes(), &parsed_hash) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}

fn generate_jwt(user_id: &str, email: &str, role: &str) -> Result<String, String> {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64;
    
    let exp = now + (JWT_EXPIRATION_HOURS * 3600);
    
    let claims = Claims {
        sub: user_id.to_string(),
        email: email.to_string(),
        role: role.to_string(),
        exp,
    };
    
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(JWT_SECRET),
    )
    .map_err(|e| format!("JWT generation error: {}", e))
}

fn validate_jwt(token: &str) -> Result<Claims, String> {
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(JWT_SECRET),
        &Validation::default(),
    )
    .map(|data| data.claims)
    .map_err(|e| format!("JWT validation error: {}", e))
}

/// Genera un código OTP de 6 dígitos
fn generate_otp_code() -> String {
    let mut rng = thread_rng();
    format!("{:06}", rng.gen_range(100000..=999999))
}

/// Valida formato de número de teléfono (Colombia: +57)
fn validate_phone_number(phone: &str) -> bool {
    let cleaned = phone.replace(&['+', ' ', '-'][..], "");
    cleaned.len() >= 10 && cleaned.chars().all(|c| c.is_numeric())
}

/// Crea el directorio de uploads si no existe
async fn ensure_uploads_dir() -> Result<(), std::io::Error> {
    let uploads_path = Path::new("./uploads");
    if !uploads_path.exists() {
        fs::create_dir_all(uploads_path).await?;
        tracing::info!("📁 Created uploads directory");
    }
    Ok(())
}

// ============================================================================
// API ENDPOINTS
// ============================================================================

async fn root() -> &'static str {
    "🏢 Sweet Models Enterprise API v2.0 - Advanced Financial System"
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "version": "2.0.0",
        "features": ["doble_trm", "biometric_auth", "camera_monitoring"]
    }))
}

// SETUP ADMIN
async fn setup_admin(
    State(pool): State<PgPool>,
    Json(payload): Json<RegisterPayload>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("🔧 Creating admin user: {}", payload.email);
    
    if !payload.email.contains('@') {
        return Err((StatusCode::BAD_REQUEST, "Invalid email format".to_string()));
    }
    
    if payload.password.len() < 8 {
        return Err((StatusCode::BAD_REQUEST, "Password must be at least 8 characters".to_string()));
    }
    
    let hashed = hash_password(&payload.password)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;
    
    sqlx::query(
        r#"
        INSERT INTO users (id, email, password_hash, role, created_at)
        VALUES (gen_random_uuid(), $1, $2, $3, NOW())
        ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash
        "#
    )
    .bind(&payload.email)
    .bind(&hashed)
    .bind("admin")
    .execute(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    tracing::info!("✅ Admin user created successfully");
    Ok((
        StatusCode::CREATED,
        Json(serde_json::json!({
            "message": "Admin user created successfully",
            "email": payload.email,
            "role": "admin"
        })),
    ))
}

// SETUP MODELO USER (for testing)
async fn setup_modelo(
    State(pool): State<PgPool>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("🔧 Creating modelo test user");
    
    let email = "modelo@sweet.com";
    let password = "Modelo123!";
    
    let hashed = hash_password(password)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;
    
    sqlx::query(
        r#"
        INSERT INTO users (id, email, password_hash, role, created_at)
        VALUES (gen_random_uuid(), $1, $2, $3, NOW())
        ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash
        "#
    )
    .bind(email)
    .bind(&hashed)
    .bind("model")
    .execute(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    tracing::info!("✅ Modelo user created successfully");
    Ok((
        StatusCode::CREATED,
        Json(serde_json::json!({
            "message": "Modelo user created successfully",
            "email": email,
            "password": password,
            "role": "model"
        })),
    ))
}

// LOGIN
async fn login_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<LoginPayload>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("🔐 Login attempt: {}", payload.email);

    let user: Option<(Uuid, String, String, String)> = sqlx::query_as(
        "SELECT id, email, password_hash, role FROM users WHERE email = $1"
    )
    .bind(&payload.email)
    .fetch_optional(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    let (user_id, email, password_hash, role) = user
        .ok_or((StatusCode::UNAUTHORIZED, "Invalid credentials".to_string()))?;

    let valid = verify_password(&payload.password, &password_hash)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;

    if !valid {
        return Err((StatusCode::UNAUTHORIZED, "Invalid credentials".to_string()));
    }

    let token = generate_jwt(&user_id.to_string(), &email, &role)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;

    tracing::info!("✅ Login successful: {}", email);

    Ok((
        StatusCode::OK,
        Json(LoginResponse {
            access_token: token,
            token_type: "Bearer".to_string(),
            expires_in: JWT_EXPIRATION_HOURS * 3600,
            role,
            user_id: user_id.to_string(),
        }),
    ))
}

// REGISTER BASIC USER
async fn register_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<RegisterPayload>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("📝 Registration: {}", payload.email);

    if payload.password.len() < 8 {
        return Err((StatusCode::BAD_REQUEST, "Password must be at least 8 characters".to_string()));
    }

    let hashed = hash_password(&payload.password)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;

    let user_id = Uuid::new_v4();

    sqlx::query(
        "INSERT INTO users (id, email, password_hash, role) VALUES ($1, $2, $3, $4)"
    )
    .bind(user_id)
    .bind(&payload.email)
    .bind(&hashed)
    .bind("model")
    .execute(&pool)
    .await
    .map_err(|e| {
        if e.to_string().contains("duplicate") {
            (StatusCode::CONFLICT, "Email already registered".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, "Registration failed".to_string())
        }
    })?;

    Ok((
        StatusCode::CREATED,
        Json(RegisterResponse {
            user_id: user_id.to_string(),
            email: payload.email,
            role: "model".to_string(),
            message: "User registered successfully".to_string(),
        }),
    ))
}

// REGISTER MODEL (ADVANCED)
async fn register_model_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<RegisterModelPayload>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("👤 Model registration: {}", payload.email);

    // Validations
    if payload.password.len() < 8 {
        return Err((StatusCode::BAD_REQUEST, "Password must be at least 8 characters".to_string()));
    }

    if let Some(ref phone) = payload.phone {
        if phone.len() < 10 {
            return Err((StatusCode::BAD_REQUEST, "Invalid phone number".to_string()));
        }
    }

    if let Some(ref national_id) = payload.national_id {
        if national_id.len() < 6 {
            return Err((StatusCode::BAD_REQUEST, "Invalid national ID".to_string()));
        }
    }

    let hashed = hash_password(&payload.password)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;

    let user_id = Uuid::new_v4();

    sqlx::query(
        r#"
        INSERT INTO users (id, email, password_hash, role, phone, address, national_id)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        "#
    )
    .bind(user_id)
    .bind(&payload.email)
    .bind(&hashed)
    .bind("model")
    .bind(&payload.phone)
    .bind(&payload.address)
    .bind(&payload.national_id)
    .execute(&pool)
    .await
    .map_err(|e| {
        if e.to_string().contains("duplicate") {
            (StatusCode::CONFLICT, "Email or National ID already registered".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Registration failed: {}", e))
        }
    })?;

    tracing::info!("✅ Model registered successfully: {}", payload.email);

    Ok((
        StatusCode::CREATED,
        Json(RegisterResponse {
            user_id: user_id.to_string(),
            email: payload.email,
            role: "model".to_string(),
            message: "Model registered successfully. Verification pending.".to_string(),
        }),
    ))
}

// UPDATE TRM (ADMIN ONLY)
async fn update_trm_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<TrmUpdateRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("💱 TRM update request: {}", payload.trm_value);

    if payload.trm_value < 3000.0 || payload.trm_value > 6000.0 {
        return Err((StatusCode::BAD_REQUEST, "TRM must be between 3000 and 6000".to_string()));
    }

    let _result = sqlx::query(
        r#"
        INSERT INTO financial_config (config_key, config_value, description, updated_at)
        VALUES ('trm_daily', $1::TEXT, 'Tasa Representativa del Mercado (TRM) diaria', NOW())
        ON CONFLICT (config_key) 
        DO UPDATE SET config_value = EXCLUDED.config_value, updated_at = NOW()
        "#
    )
    .bind(payload.trm_value.to_string())
    .execute(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    tracing::info!("✅ TRM updated to: {}", payload.trm_value);

    Ok((
        StatusCode::OK,
        Json(TrmResponse {
            trm_value: payload.trm_value,
            updated_at: chrono::Utc::now().to_rfc3339(),
            updated_by: "admin".to_string(),
        }),
    ))
}

// GET CURRENT TRM
async fn get_trm_handler(
    State(pool): State<PgPool>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let result: Option<(String, String)> = sqlx::query_as(
        "SELECT config_value, updated_at::TEXT FROM financial_config WHERE config_key = 'trm_daily'"
    )
    .fetch_optional(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    let (trm_str, updated_at) = result
        .unwrap_or((DEFAULT_TRM.to_string(), chrono::Utc::now().to_rfc3339()));

    let trm_value = trm_str.parse::<f64>().unwrap_or(DEFAULT_TRM);

    Ok((
        StatusCode::OK,
        Json(TrmResponse {
            trm_value,
            updated_at,
            updated_by: "system".to_string(),
        }),
    ))
}

// CALCULATE PAYROLL
async fn calculate_payroll_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<PayrollRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("🧮 Payroll calculation request");

    // Get TRM (use manual if provided, otherwise fetch from DB)
    let trm = if let Some(manual) = payload.manual_trm {
        manual
    } else {
        let result: Option<(String,)> = sqlx::query_as(
            "SELECT config_value FROM financial_config WHERE config_key = 'trm_daily'"
        )
        .fetch_optional(&pool)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

        result
            .and_then(|(v,)| v.parse::<f64>().ok())
            .unwrap_or(DEFAULT_TRM)
    };

    let calculation = calculate_payroll(payload.group_tokens, payload.members_count, trm);

    Ok((StatusCode::OK, Json(calculation)))
}

// GET CAMERAS (ADMIN ONLY)
async fn get_cameras_handler(
    State(pool): State<PgPool>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("📹 Fetching cameras list");

    let cameras: Vec<Camera> = sqlx::query_as::<_, Camera>(
        "SELECT id, name, stream_url, platform, is_active FROM cameras ORDER BY id"
    )
    .fetch_all(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    let total_active = cameras.iter().filter(|c| c.is_active).count() as i32;

    Ok((
        StatusCode::OK,
        Json(CamerasResponse {
            cameras,
            total_active,
        }),
    ))
}

// ============================================================================
// OTP & SMS VERIFICATION HANDLERS
// ============================================================================

// SEND OTP CODE
async fn send_otp_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<SendOtpRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("📱 OTP request for phone: {}", payload.phone);

    // Validar formato del teléfono
    if !validate_phone_number(&payload.phone) {
        return Err((StatusCode::BAD_REQUEST, "Invalid phone number format".to_string()));
    }

    // Generar código OTP de 6 dígitos
    let otp_code = generate_otp_code();
    
    // Calcular tiempo de expiración (10 minutos)
    let expires_at = chrono::Utc::now() + chrono::Duration::minutes(10);

    // Guardar en la base de datos
    sqlx::query(
        r#"
        INSERT INTO otp_codes (phone_number, code, expires_at, used)
        VALUES ($1, $2, $3, $4)
        "#
    )
    .bind(&payload.phone)
    .bind(&otp_code)
    .bind(expires_at)
    .bind(false)
    .execute(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    // 🚨 SIMULACIÓN: Imprimir código en consola (en producción usar Twilio)
    tracing::warn!("📨 ENVIO SMS A [{}]: CÓDIGO OTP = {}", payload.phone, otp_code);
    tracing::warn!("⏰ Código expira en 10 minutos");

    Ok((
        StatusCode::OK,
        Json(SendOtpResponse {
            success: true,
            message: format!("OTP code sent to {}", payload.phone),
            expires_in_minutes: 10,
        }),
    ))
}

// VERIFY OTP CODE
async fn verify_otp_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<VerifyOtpRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("🔐 OTP verification for phone: {}", payload.phone);

    // Buscar el código OTP más reciente no usado
    let otp_record: Option<(Uuid, String, chrono::DateTime<chrono::Utc>, bool)> = sqlx::query_as(
        r#"
        SELECT id, code, expires_at, used
        FROM otp_codes
        WHERE phone_number = $1
        ORDER BY created_at DESC
        LIMIT 1
        "#
    )
    .bind(&payload.phone)
    .fetch_optional(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    let (otp_id, stored_code, expires_at, used) = match otp_record {
        Some(record) => record,
        None => return Err((StatusCode::NOT_FOUND, "No OTP code found for this phone number".to_string())),
    };

    // Verificar si ya fue usado
    if used {
        return Err((StatusCode::BAD_REQUEST, "OTP code already used".to_string()));
    }

    // Verificar si expiró
    if chrono::Utc::now() > expires_at {
        return Err((StatusCode::BAD_REQUEST, "OTP code expired".to_string()));
    }

    // Verificar si el código coincide
    if payload.code != stored_code {
        return Err((StatusCode::UNAUTHORIZED, "Invalid OTP code".to_string()));
    }

    // Marcar OTP como usado
    sqlx::query("UPDATE otp_codes SET used = TRUE WHERE id = $1")
        .bind(otp_id)
        .execute(&pool)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    // Actualizar usuario como phone_verified = true
    sqlx::query(
        r#"
        UPDATE users
        SET phone_verified = TRUE
        WHERE phone = $1
        "#
    )
    .bind(&payload.phone)
    .execute(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    tracing::info!("✅ Phone verified successfully: {}", payload.phone);

    Ok((
        StatusCode::OK,
        Json(VerifyOtpResponse {
            success: true,
            message: "Phone number verified successfully".to_string(),
            phone_verified: true,
        }),
    ))
}

// ============================================================================
// KYC & FILE UPLOAD HANDLERS
// ============================================================================

// UPLOAD KYC DOCUMENT
async fn upload_kyc_handler(
    State(pool): State<PgPool>,
    mut multipart: Multipart,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("📄 KYC document upload request");

    // Asegurar que existe el directorio uploads
    ensure_uploads_dir()
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to create uploads directory: {}", e)))?;

    let mut user_id: Option<String> = None;
    let mut document_type: Option<String> = None;
    let mut file_data: Option<Vec<u8>> = None;
    let mut file_name: Option<String> = None;
    let mut content_type: Option<String> = None;

    // Procesar multipart form data
    while let Some(field) = multipart.next_field().await.unwrap() {
        let name = field.name().unwrap_or("").to_string();

        match name.as_str() {
            "user_id" => {
                user_id = Some(field.text().await.unwrap());
            }
            "document_type" => {
                document_type = Some(field.text().await.unwrap());
            }
            "file" => {
                file_name = field.file_name().map(|s| s.to_string());
                content_type = field.content_type().map(|s| s.to_string());
                file_data = Some(field.bytes().await.unwrap().to_vec());
            }
            _ => {}
        }
    }

    // Validaciones
    let user_id = user_id.ok_or((StatusCode::BAD_REQUEST, "user_id required".to_string()))?;
    let document_type = document_type.ok_or((StatusCode::BAD_REQUEST, "document_type required".to_string()))?;
    let file_data = file_data.ok_or((StatusCode::BAD_REQUEST, "file required".to_string()))?;
    let file_name = file_name.ok_or((StatusCode::BAD_REQUEST, "file_name required".to_string()))?;

    // Validar tipos de documento permitidos
    let valid_types = ["national_id_front", "national_id_back", "selfie", "proof_address"];
    if !valid_types.contains(&document_type.as_str()) {
        return Err((StatusCode::BAD_REQUEST, format!("Invalid document_type. Allowed: {:?}", valid_types)));
    }

    // Generar nombre único para el archivo
    let file_ext = Path::new(&file_name)
        .extension()
        .and_then(|s| s.to_str())
        .unwrap_or("jpg");
    
    let unique_filename = format!("{}_{}_{}_{}.{}", 
        user_id, 
        document_type,
        Uuid::new_v4(),
        chrono::Utc::now().timestamp(),
        file_ext
    );
    
    let file_path = format!("./uploads/{}", unique_filename);

    // Guardar archivo en disco
    let mut file = fs::File::create(&file_path)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to create file: {}", e)))?;
    
    file.write_all(&file_data)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to write file: {}", e)))?;

    tracing::info!("💾 File saved: {}", file_path);

    // Guardar registro en base de datos
    let document_id = Uuid::new_v4();
    let user_uuid = Uuid::parse_str(&user_id)
        .map_err(|_| (StatusCode::BAD_REQUEST, "Invalid user_id format".to_string()))?;

    sqlx::query(
        r#"
        INSERT INTO kyc_documents (id, user_id, document_type, file_path, file_size, mime_type, status)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        "#
    )
    .bind(document_id)
    .bind(user_uuid)
    .bind(&document_type)
    .bind(&file_path)
    .bind(file_data.len() as i32)
    .bind(content_type.unwrap_or("image/jpeg".to_string()))
    .bind("pending")
    .execute(&pool)
    .await
    .map_err(|e| {
        if e.to_string().contains("duplicate") {
            (StatusCode::CONFLICT, "Document of this type already uploaded".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e))
        }
    })?;

    tracing::info!("✅ KYC document uploaded: user={}, type={}, doc_id={}", user_id, document_type, document_id);

    Ok((
        StatusCode::CREATED,
        Json(UploadKycResponse {
            success: true,
            message: "KYC document uploaded successfully".to_string(),
            document_id: document_id.to_string(),
            file_path,
        }),
    ))
}

// DASHBOARD (EXISTING)
async fn get_dashboard(
    State(pool): State<PgPool>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("📊 Dashboard request");

    let groups: Vec<GroupDTO> = sqlx::query_as::<_, GroupDTO>(
        r#"
        SELECT 
            name, 
            platform, 
            total_tokens::float8, 
            members_count,
            payout_per_member_cop::float8,
            created_at
        FROM groups 
        ORDER BY created_at DESC
        "#
    )
    .fetch_all(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    let total_tokens: f64 = groups.iter().map(|g| g.total_tokens).sum();
    let total_members: i32 = groups.iter().map(|g| g.members_count).sum();
    let total_payout: f64 = groups
        .iter()
        .map(|g| g.payout_per_member_cop * g.members_count as f64)
        .sum();

    let trm_result: Option<(String,)> = sqlx::query_as(
        "SELECT config_value FROM financial_config WHERE config_key = 'trm_daily'"
    )
    .fetch_optional(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    let trm = trm_result
        .and_then(|(v,)| v.parse::<f64>().ok())
        .unwrap_or(DEFAULT_TRM);

    Ok((
        StatusCode::OK,
        Json(DashboardResponse {
            groups,
            total_tokens,
            total_members,
            total_payout_cop: total_payout,
            trm_used: trm,
        }),
    ))
}

// FINANCIAL PLANNING
async fn financial_planning_handler(
    Json(payload): Json<FinancialPlanRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("💰 Financial planning: amount={}, risk={}", payload.amount, payload.risk_tolerance);

    if payload.amount <= 0.0 {
        return Err((StatusCode::BAD_REQUEST, "Amount must be positive".to_string()));
    }

    let (stocks_pct, bonds_pct, cash_pct) = match payload.risk_tolerance.to_lowercase().as_str() {
        "conservative" => (30.0, 50.0, 20.0),
        "moderate" => (50.0, 30.0, 20.0),
        "aggressive" => (70.0, 20.0, 10.0),
        _ => (50.0, 30.0, 20.0),
    };

    Ok((
        StatusCode::OK,
        Json(FinancialPlanResponse {
            total_amount: payload.amount,
            stocks_percentage: stocks_pct,
            bonds_percentage: bonds_pct,
            cash_percentage: cash_pct,
            stocks_amount: payload.amount * (stocks_pct / 100.0),
            bonds_amount: payload.amount * (bonds_pct / 100.0),
            cash_amount: payload.amount * (cash_pct / 100.0),
            risk_tolerance: payload.risk_tolerance,
        }),
    ))
}

// ============================================================================
// MODEL MODULE HANDLERS
// ============================================================================

async fn get_model_home(
    State(pool): State<PgPool>,
    headers: axum::http::HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let claims = require_role(&headers, "model").map_err(|s| (s, "Unauthorized".to_string()))?;

    let now = Utc::now();
    let today_start = now.date_naive().and_hms_opt(0, 0, 0).unwrap().and_utc();

    let weekday = now.weekday().num_days_from_monday();
    let week_start_date = now.date_naive() - Duration::days(weekday as i64);
    let week_start = week_start_date.and_hms_opt(0, 0, 0).unwrap().and_utc();

    let month_start_date = NaiveDate::from_ymd_opt(now.year(), now.month(), 1).unwrap();
    let month_start = month_start_date.and_hms_opt(0, 0, 0).unwrap().and_utc();

    let trm = current_trm(&pool).await;

    let today_points = sum_points_since(&pool, &claims.sub, Some(today_start)).await?;
    let week_points = sum_points_since(&pool, &claims.sub, Some(week_start)).await?;
    let month_points = sum_points_since(&pool, &claims.sub, Some(month_start)).await?;
    let active_points = sum_points_since(&pool, &claims.sub, None).await?;

    let token_to_cop = |points: f64| points * TOKEN_VALUE_MULTIPLIER * (trm - TRM_ADJUSTMENT);

    let stats = ModelHomeStats {
        today_earnings_cop: token_to_cop(today_points),
        week_earnings_cop: token_to_cop(week_points),
        month_earnings_cop: token_to_cop(month_points),
        active_points,
    };

    Ok((StatusCode::OK, Json(stats)))
}

async fn sign_contract_handler(
    State(pool): State<PgPool>,
    headers: axum::http::HeaderMap,
    mut multipart: Multipart,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let claims = require_role(&headers, "model").map_err(|s| (s, "Unauthorized".to_string()))?;
    
    let mut signature_data: Option<Vec<u8>> = None;
    
    // Procesar multipart form data
    while let Ok(Some(field)) = multipart.next_field().await {
        if let Some(name) = field.name() {
            if name == "signature" {
                signature_data = Some(field.bytes().await.map_err(|e| {
                    (StatusCode::BAD_REQUEST, format!("Failed to read signature: {}", e))
                })?.to_vec());
            }
        }
    }
    
    let signature = signature_data.ok_or((StatusCode::BAD_REQUEST, "No signature provided".to_string()))?;
    
    // Guardar firma en archivo
    let filename = format!("contract_{}.png", uuid::Uuid::new_v4());
    let path = format!("uploads/contracts/{}", filename);
    
    std::fs::create_dir_all("uploads/contracts")
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to create directory: {}", e)))?;
    
    std::fs::write(&path, &signature)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to save signature: {}", e)))?;
    
    // Guardar en base de datos
    let user_uuid = uuid::Uuid::parse_str(&claims.sub)
        .map_err(|_| (StatusCode::BAD_REQUEST, "Invalid user ID".to_string()))?;
    
    sqlx::query(
        "INSERT INTO contracts (user_id, signature_path, ip_address) VALUES ($1, $2, $3)"
    )
    .bind(user_uuid)
    .bind(path)
    .bind("unknown")
    .execute(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    Ok((StatusCode::CREATED, Json(serde_json::json!({
        "success": true,
        "message": "Contract signed successfully",
    }))))
}

async fn create_social_link(
    State(pool): State<PgPool>,
    headers: axum::http::HeaderMap,
    Json(payload): Json<SocialLinkRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let claims = require_role(&headers, "model").map_err(|s| (s, "Unauthorized".to_string()))?;

    let platform = payload.platform.to_lowercase();
    if platform != "instagram" && platform != "twitter" {
        return Err((StatusCode::BAD_REQUEST, "Platform must be instagram or twitter".to_string()));
    }

    // Insertar o actualizar red social
    let user_uuid = uuid::Uuid::parse_str(&claims.sub)
        .map_err(|_| (StatusCode::BAD_REQUEST, "Invalid user ID".to_string()))?;
    
    sqlx::query(
        "INSERT INTO social_links (user_id, platform, handle) VALUES ($1, $2, $3)
         ON CONFLICT (user_id, platform) DO UPDATE SET handle = $3, updated_at = NOW()"
    )
    .bind(user_uuid)
    .bind(&platform)
    .bind(&payload.handle)
    .execute(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    Ok((StatusCode::CREATED, Json(serde_json::json!({
        "success": true,
        "platform": platform,
        "handle": payload.handle,
    }))))
}

// ============================================================================
// OPERATIONS MODULE HANDLERS
// ============================================================================

/// GET /api/mod/groups
/// Retorna los grupos asignados al moderador actual
async fn get_moderator_groups(
    State(pool): State<PgPool>,
    headers: axum::http::HeaderMap,
) -> Result<Json<Vec<serde_json::Value>>, (StatusCode, String)> {
    let claims = require_role(&headers, "moderator").map_err(|s| (s, "Unauthorized".to_string()))?;

    // Get groups for this moderator - assuming user_id refers to the moderator
    let groups: Vec<(String, String, i32, String)> = sqlx::query_as(
        "SELECT id::text, name, members_count, total_tokens::text FROM groups WHERE user_id = $1 ORDER BY created_at DESC",
    )
    .bind(uuid::Uuid::parse_str(&claims.sub).unwrap())
    .fetch_all(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Database error: {}", e)))?;

    let result: Vec<serde_json::Value> = groups.into_iter()
        .map(|(id, name, members_count, total_tokens)| {
            serde_json::json!({
                "id": id,
                "name": name,
                "members_count": members_count,
                "total_tokens": total_tokens
            })
        })
        .collect();

    tracing::info!("📋 Moderator {} retrieved {} groups", claims.email, result.len());
    Ok(Json(result))
}

/// POST /api/mod/production
/// Registra tokens de producción diarios y auditoría
async fn register_production_handler(
    State(pool): State<PgPool>,
    headers: axum::http::HeaderMap,
    Json(payload): Json<ProductionLogRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let claims = require_role(&headers, "moderator").map_err(|s| (s, "Unauthorized".to_string()))?;

    // Validar tokens > 0
    if payload.tokens <= 0.0 {
        return Err((StatusCode::BAD_REQUEST, "Tokens must be greater than 0".to_string()));
    }

    // Validar fecha no futura
    let production_date = chrono::NaiveDate::parse_from_str(&payload.date, "%Y-%m-%d")
        .map_err(|e| (StatusCode::BAD_REQUEST, format!("Invalid date format: {}", e)))?;
    
    if production_date > chrono::Local::now().naive_local().date() {
        return Err((StatusCode::BAD_REQUEST, "Date cannot be in the future".to_string()));
    }

    let group_id = uuid::Uuid::parse_str(&payload.group_id)
        .map_err(|e| (StatusCode::BAD_REQUEST, format!("Invalid group_id: {}", e)))?;
    let user_id = uuid::Uuid::parse_str(&claims.sub).unwrap();

    // Insertar log de producción
    let log_result = sqlx::query(
        "INSERT INTO production_logs (group_id, date, amount_tokens, entered_by) VALUES ($1, $2, $3, $4) RETURNING id"
    )
    .bind(group_id)
    .bind(production_date)
    .bind(payload.tokens as f64)
    .bind(user_id)
    .fetch_one(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to insert production log: {}", e)))?;

    let log_id: uuid::Uuid = log_result.get("id");

    // Auditoría: Registrar en audit_trail
    let audit_value = serde_json::json!({
        "group_id": payload.group_id,
        "date": payload.date,
        "amount_tokens": payload.tokens
    });

    sqlx::query(
        "INSERT INTO audit_trail (entity_type, entity_id, action, new_value, user_id, ip_address) VALUES ($1, $2, $3, $4, $5, $6)"
    )
    .bind("production")
    .bind(log_id)
    .bind("create")
    .bind(audit_value)
    .bind(user_id)
    .bind("0.0.0.0")
    .execute(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Audit trail error: {}", e)))?;

    // Verificar si alcanzó la meta de 10,000 tokens en el día
    let daily_total_result = sqlx::query(
        "SELECT COALESCE(SUM(amount_tokens), 0)::text as total FROM production_logs WHERE group_id = $1 AND date = $2"
    )
    .bind(group_id)
    .bind(production_date)
    .fetch_one(&pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Error calculating daily total: {}", e)))?;

    let total_str: String = daily_total_result.get("total");
    let total: f64 = total_str.parse().unwrap_or(0.0);
    let mut notification_message = format!("✅ Producción registrada: {} tokens", payload.tokens);
    
    if total >= 10000.0 {
        notification_message = format!("🎉 ¡META ALCANZADA! Total del día: {:.2} tokens", total);
        tracing::warn!("🎯 Daily production goal achieved for group {} on {}: {:.2} tokens", 
            payload.group_id, payload.date, total);
    }

    Ok((StatusCode::CREATED, Json(ProductionLogResponse {
        id: log_id.to_string(),
        group_id: payload.group_id,
        date: payload.date,
        amount_tokens: payload.tokens,
        message: notification_message,
    })))
}

// ============================================================================
// MAIN
// ============================================================================

// ============================================================================
// FINANCIAL ANALYTICS HANDLER
// ============================================================================

/// GET /api/admin/financial-history
/// Retorna datos históricos en formato candlestick para gráficos
/// Requiere rol 'admin'
async fn get_financial_history(
    State(_pool): State<PgPool>,
    headers: axum::http::HeaderMap,
) -> Result<Json<Vec<FinancialCandle>>, StatusCode> {
    // Extraer y validar token
    let auth_header = headers
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let claims = decode::<Claims>(
        token,
        &DecodingKey::from_secret(JWT_SECRET),
        &Validation::default(),
    )
    .map_err(|e| {
        tracing::warn!("❌ Invalid token: {}", e);
        StatusCode::UNAUTHORIZED
    })?
    .claims;

    // Verificar rol admin
    if claims.role != "admin" {
        tracing::warn!("⛔ Access denied for role: {}", claims.role);
        return Err(StatusCode::FORBIDDEN);
    }

    tracing::info!("📈 Financial history requested by admin: {}", claims.email);
    
    // Generar datos de los últimos 30 días
    let candles = get_historical_data(30);
    
    Ok(Json(candles))
}

// ============================================================================
// MAIN FUNCTION
// ============================================================================

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();
    
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL not set");
    
    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
        .expect("Failed to create pool");

    tracing::info!("🔄 Running migrations...");
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .expect("Failed to run migrations");

    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health))
        .route("/setup_admin", post(setup_admin))
        .route("/setup_modelo", post(setup_modelo))
        .route("/login", post(login_handler))
        .route("/register", post(register_handler))
        .route("/register_model", post(register_model_handler))
        .route("/dashboard", get(get_dashboard))
        .route("/api/financial_planning", post(financial_planning_handler))
        .route("/admin/trm", post(update_trm_handler))
        .route("/admin/trm", get(get_trm_handler))
        .route("/admin/cameras", get(get_cameras_handler))
        .route("/api/payroll/calculate", post(calculate_payroll_handler))
        // 👩‍💻 Model module
        .route("/api/model/home", get(get_model_home))
        .route("/api/model/sign-contract", post(sign_contract_handler))
        .route("/api/model/social", post(create_social_link))
        // 📊 Operations (Moderator)
        .route("/api/mod/groups", get(get_moderator_groups))
        .route("/api/mod/production", post(register_production_handler))
        // 📊 Financial Analytics
        .route("/api/admin/financial-history", get(get_financial_history))
        // 🆕 OTP & SMS Verification
        .route("/auth/send-otp", post(send_otp_handler))
        .route("/auth/verify-otp", post(verify_otp_handler))
        // 🆕 KYC Document Upload
        .route("/upload/kyc", post(upload_kyc_handler))
        .layer(CorsLayer::permissive())
        .with_state(pool);

    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    let listener = TcpListener::bind(&addr).await.expect("Failed to bind");

    tracing::info!("🚀 Server running on {}", addr);
    tracing::info!("✨ Features: Doble TRM, Biometric Auth, Camera Monitoring, OTP Verification, KYC Upload");

    axum::serve(listener, app)
        .await
        .expect("Failed to start server");
}
