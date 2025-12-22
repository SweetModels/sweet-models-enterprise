use axum::{extract::State, http::HeaderMap, response::IntoResponse, Json};
use axum::http::StatusCode;
use serde::{Deserialize, Serialize};
use sqlx::{PgPool};
use super::AppState;

use crate::services::jwt::{validate_jwt, JwtError};

#[derive(Debug, Deserialize)]
pub struct AdminProductionRequest {
    pub model_email: String,
    pub tokens: i64,
    pub platform: String,
}

#[derive(Debug, Serialize)]
pub struct AdminProductionResponse {
    pub message: String,
    pub total_points: f64,
}

pub async fn register_production(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(payload): Json<AdminProductionRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    // Validate bearer token and admin role
    let auth_header = headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or((StatusCode::UNAUTHORIZED, "Missing Authorization header".to_string()))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .or_else(|| auth_header.strip_prefix("bearer "))
        .ok_or((StatusCode::UNAUTHORIZED, "Invalid Authorization header".to_string()))?;

    let claims = match validate_jwt(token) {
        Ok(c) => c,
        Err(JwtError::TokenExpired) => {
            return Err((StatusCode::UNAUTHORIZED, "Token expired".to_string()))
        }
        Err(_) => return Err((StatusCode::UNAUTHORIZED, "Invalid token".to_string())),
    };

    let role_lower = claims.role.to_lowercase();
    if role_lower != "admin" {
        return Err((StatusCode::FORBIDDEN, "Admin role required".to_string()));
    }

    if payload.tokens <= 0 {
        return Err((StatusCode::BAD_REQUEST, "Tokens must be > 0".to_string()));
    }

    // Find user by email
    let model_id: uuid::Uuid = sqlx::query_scalar(
        "SELECT id FROM users WHERE email = $1 LIMIT 1"
    )
    .bind(&payload.model_email)
    .fetch_one(&state.db)
    .await
    .map_err(|e| (StatusCode::NOT_FOUND, format!("Model not found: {}", e)))?;

    // Upsert into daily_production for current date
    let today = chrono::Utc::now().date_naive();
    sqlx::query(
        r#"
        INSERT INTO daily_production (model_id, "date", platform, token_amount)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (model_id, "date", platform)
        DO UPDATE SET token_amount = daily_production.token_amount + EXCLUDED.token_amount
        "#
    )
    .bind(model_id)
    .bind(today)
    .bind(&payload.platform)
    .bind(payload.tokens)
    .execute(&state.db)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to upsert production: {}", e)))?;

    // Also append to points_ledger so the gamification & stats update immediately
    sqlx::query(
        "INSERT INTO points_ledger (user_id, amount, reason) VALUES ($1, $2, $3)"
    )
    .bind(model_id)
    .bind(payload.tokens as f64)
    .bind(format!("admin_production:{}", payload.platform))
    .execute(&state.db)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to award points: {}", e)))?;

    // Compute new total accumulated points
    let total_points: f64 = sqlx::query_scalar(
        "SELECT COALESCE(SUM(amount), 0)::float8 FROM points_ledger WHERE user_id = $1"
    )
    .bind(model_id)
    .fetch_one(&state.db)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to compute total: {}", e)))?;

    Ok((
        StatusCode::OK,
        Json(AdminProductionResponse {
            message: "Production recorded".to_string(),
            total_points,
        }),
    ))
}

#[derive(Debug, Deserialize)]
pub struct AdminPenaltyRequest {
    pub model_email: String,
    pub reason: String,
    pub xp_penalty: i64,
}

#[derive(Debug, Serialize)]
pub struct AdminPenaltyResponse {
    pub message: String,
    pub new_xp: f64,
}

/// POST /api/admin/penalize
/// Apply a penalty to a model: records penalty and deducts XP immediately
pub async fn penalize_model(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(payload): Json<AdminPenaltyRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    tracing::info!("⚠️ Penalize request: model_email={}, reason={}, xp_penalty={}", 
        payload.model_email, payload.reason, payload.xp_penalty);
    
    // Validate bearer token and admin role
    let auth_header = headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or((StatusCode::UNAUTHORIZED, "Missing Authorization header".to_string()))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .or_else(|| auth_header.strip_prefix("bearer "))
        .ok_or((StatusCode::UNAUTHORIZED, "Invalid Authorization header".to_string()))?;

    tracing::info!("🔐 Validating JWT for penalize");
    let claims = match validate_jwt(token) {
        Ok(c) => {
            tracing::info!("✅ JWT valid: user_id={}, role={}", c.sub, c.role);
            c
        },
        Err(JwtError::TokenExpired) => {
            tracing::warn!("⏰ Token expired");
            return Err((StatusCode::UNAUTHORIZED, "Token expired".to_string()))
        }
        Err(e) => {
            tracing::warn!("❌ JWT validation failed: {:?}", e);
            return Err((StatusCode::UNAUTHORIZED, "Invalid token".to_string()))
        },
    };

    if claims.role.to_lowercase() != "admin" {
        return Err((StatusCode::FORBIDDEN, "Admin role required".to_string()));
    }

    if payload.xp_penalty <= 0 {
        return Err((StatusCode::BAD_REQUEST, "xp_penalty must be > 0".to_string()));
    }

    // Resolve admin and model ids
    let admin_id = uuid::Uuid::parse_str(&claims.sub)
        .map_err(|_| (StatusCode::BAD_REQUEST, "Invalid admin user id".to_string()))?;

    let model_id: uuid::Uuid = sqlx::query_scalar(
        "SELECT id FROM users WHERE email = $1 LIMIT 1"
    )
    .bind(&payload.model_email)
    .fetch_one(&state.db)
    .await
    .map_err(|e| (StatusCode::NOT_FOUND, format!("Model not found: {}", e)))?;

    // 1) Record penalty entry
    sqlx::query(
        r#"
        INSERT INTO penalties (user_id, reason, xp_deduction, financial_fine, created_by)
        VALUES ($1, $2, $3, $4, $5)
        "#
    )
    .bind(model_id)
    .bind(&payload.reason)
    .bind(-(payload.xp_penalty as i32))
    .bind(0.0_f64)
    .bind(admin_id)
    .execute(&state.db)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to record penalty: {}", e)))?;

    // 2) Deduct points immediately via points_ledger (negative amount)
    sqlx::query(
        "INSERT INTO points_ledger (user_id, amount, reason) VALUES ($1, $2, $3)"
    )
    .bind(model_id)
    .bind(-(payload.xp_penalty as f64))
    .bind(format!("penalty:{}", payload.reason))
    .execute(&state.db)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to deduct points: {}", e)))?;

    // 3) Return new total XP (sum points_ledger)
    let new_xp: f64 = sqlx::query_scalar(
        "SELECT COALESCE(SUM(amount), 0)::float8 FROM points_ledger WHERE user_id = $1"
    )
    .bind(model_id)
    .fetch_one(&state.db)
    .await
    .unwrap_or(0.0);

    Ok((
        StatusCode::OK,
        Json(AdminPenaltyResponse {
            message: "Sanción aplicada".to_string(),
            new_xp,
        }),
    ))
}




