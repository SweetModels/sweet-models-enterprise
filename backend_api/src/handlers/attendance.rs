use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    Json,
};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::PgPool;
use tracing::{error, info, warn};
use super::AppState;
use uuid::Uuid;

use crate::services::jwt::{validate_jwt, JwtError};

#[derive(Debug, Deserialize)]
pub struct CheckInRequest {
    #[serde(default)]
    pub ip_address: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CheckOutRequest {
    #[serde(default)]
    pub ip_address: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct CheckInResponse {
    pub message: String,
    pub check_in_time: String,
}

#[derive(Debug, Serialize)]
pub struct CheckOutResponse {
    pub message: String,
    pub check_out_time: String,
    pub duration_hours: f64,
    pub duration_minutes: i32,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct AttendanceStatus {
    pub is_working: bool,
    pub check_in_time: Option<String>,
    pub duration_minutes: Option<i32>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct ActiveShift {
    pub id: String,
    pub user_id: String,
    pub full_name: Option<String>,
    pub email: String,
    pub check_in: String,
}

/// POST /api/model/check-in
/// Marcar entrada del modelo
pub async fn check_in(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(payload): Json<CheckInRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let auth_header = headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Missing Authorization header"
            })),
        ))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .or_else(|| auth_header.strip_prefix("bearer "))
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Invalid Authorization header"
            })),
        ))?;

    let claims = match validate_jwt(token) {
        Ok(c) => c,
        Err(JwtError::TokenExpired) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Token expired"
                })),
            ))
        }
        Err(_) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid token"
                })),
            ))
        }
    };

    let user_id = Uuid::parse_str(&claims.sub).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Invalid user ID"
            })),
        )
    })?;

    info!("📍 Check-in attempt for user: {}", user_id);

    // Verificar si ya hay una sesión abierta
    let active_count: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM attendance_logs WHERE user_id = $1 AND status = 'OPEN'"
    )
    .bind(user_id)
    .fetch_one(&state.db)
    .await
    .map_err(|e| {
        error!("Database error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "error": "Database error"
            })),
        )
    })?;

    if active_count > 0 {
        warn!("⚠️ User {} already has an active session", user_id);
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Already working",
                "message": "Ya estás trabajando. Marca salida primero."
            })),
        ));
    }

    let now = chrono::Utc::now();
    let ip_addr = payload.ip_address.unwrap_or_else(|| "unknown".to_string());

    // Insertar nuevo registro
    let result = sqlx::query_as::<_, (String,)>(
        r#"
        INSERT INTO attendance_logs (user_id, check_in, status, ip_address)
        VALUES ($1, $2, 'OPEN', $3)
        RETURNING check_in::TEXT
        "#,
    )
    .bind(user_id)
    .bind(now)
    .bind(&ip_addr)
    .fetch_one(&state.db)
    .await
    .map_err(|e| {
        error!("Failed to insert attendance log: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "error": "Failed to record check-in"
            })),
        )
    })?;

    info!("✅ Check-in successful for user: {}", user_id);

    Ok((
        StatusCode::OK,
        Json(CheckInResponse {
            message: "¡Bienvenida! Turno iniciado.".to_string(),
            check_in_time: result.0,
        }),
    ))
}

/// POST /api/model/check-out
/// Marcar salida del modelo
pub async fn check_out(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(payload): Json<CheckOutRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let auth_header = headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Missing Authorization header"
            })),
        ))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .or_else(|| auth_header.strip_prefix("bearer "))
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Invalid Authorization header"
            })),
        ))?;

    let claims = match validate_jwt(token) {
        Ok(c) => c,
        Err(JwtError::TokenExpired) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Token expired"
                })),
            ))
        }
        Err(_) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid token"
                })),
            ))
        }
    };

    let user_id = Uuid::parse_str(&claims.sub).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Invalid user ID"
            })),
        )
    })?;

    info!("📍 Check-out attempt for user: {}", user_id);

    // Buscar sesión abierta
    let open_session: (String, String) = sqlx::query_as(
        r#"
        SELECT id::TEXT, check_in::TEXT 
        FROM attendance_logs 
        WHERE user_id = $1 AND status = 'OPEN' 
        ORDER BY check_in DESC 
        LIMIT 1
        "#,
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        error!("Database error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "error": "Database error"
            })),
        )
    })?
    .ok_or((
        StatusCode::BAD_REQUEST,
        Json(json!({
            "error": "No active session",
            "message": "No hay una sesión abierta. Marca entrada primero."
        })),
    ))?;

    let session_id = Uuid::parse_str(&open_session.0).map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "error": "Invalid session ID"
            })),
        )
    })?;
    let now = chrono::Utc::now();
    let ip_addr = payload.ip_address.unwrap_or_else(|| "unknown".to_string());

    // Actualizar sesión
    let result = sqlx::query_as::<_, (String, i32)>(
        r#"
        UPDATE attendance_logs
        SET check_out = $1, status = 'CLOSED',
            duration_minutes = EXTRACT(EPOCH FROM ($1 - check_in))::INTEGER / 60,
            ip_address = $2
        WHERE id = $3
        RETURNING check_out::TEXT, duration_minutes
        "#,
    )
    .bind(now)
    .bind(&ip_addr)
    .bind(session_id)
    .fetch_one(&state.db)
    .await
    .map_err(|e| {
        error!("Failed to update attendance log: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "error": "Failed to record check-out"
            })),
        )
    })?;

    let duration_minutes = result.1;
    let duration_hours = duration_minutes as f64 / 60.0;

    info!(
        "✅ Check-out successful for user: {} (duration: {} minutes)",
        user_id, duration_minutes
    );

    Ok((
        StatusCode::OK,
        Json(CheckOutResponse {
            message: "¡Gracias por trabajar! Turno finalizado.".to_string(),
            check_out_time: result.0,
            duration_hours,
            duration_minutes,
        }),
    ))
}

/// GET /api/model/attendance-status
/// Obtener estado actual de asistencia
pub async fn get_attendance_status(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let auth_header = headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Missing Authorization header"
            })),
        ))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .or_else(|| auth_header.strip_prefix("bearer "))
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Invalid Authorization header"
            })),
        ))?;

    let claims = match validate_jwt(token) {
        Ok(c) => c,
        Err(_) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid token"
                })),
            ))
        }
    };

    let user_id = Uuid::parse_str(&claims.sub).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Invalid user ID"
            })),
        )
    })?;

    // Buscar sesión activa
    let active_session: Option<(String,)> = sqlx::query_as(
        "SELECT check_in::TEXT FROM attendance_logs WHERE user_id = $1 AND status = 'OPEN' LIMIT 1"
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        error!("Database error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "error": "Database error"
            })),
        )
    })?;

    let is_working = active_session.is_some();
    let check_in_time = active_session.map(|s| s.0);

    // Calcular duración si está trabajando
    let duration_minutes = if is_working {
        let now = chrono::Utc::now();
        if let Some(check_in_str) = &check_in_time {
            if let Ok(check_in_dt) = chrono::DateTime::parse_from_rfc3339(check_in_str) {
                let duration = now.signed_duration_since(check_in_dt);
                Some(duration.num_minutes() as i32)
            } else {
                None
            }
        } else {
            None
        }
    } else {
        None
    };

    Ok(Json(AttendanceStatus {
        is_working,
        check_in_time,
        duration_minutes,
    }))
}

/// GET /api/admin/active-shifts
/// Obtener lista de modelos actualmente trabajando
pub async fn get_active_shifts(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let auth_header = headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Missing Authorization header"
            })),
        ))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .or_else(|| auth_header.strip_prefix("bearer "))
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Invalid Authorization header"
            })),
        ))?;

    let claims = match validate_jwt(token) {
        Ok(c) => {
            if c.role.to_lowercase() != "admin" {
                return Err((
                    StatusCode::FORBIDDEN,
                    Json(json!({
                        "error": "Admin role required"
                    })),
                ));
            }
            c
        }
        Err(_) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid token"
                })),
            ))
        }
    };

    // Obtener modelos activas
    let active_shifts: Vec<ActiveShift> = sqlx::query_as(
        r#"
        SELECT 
            al.id::TEXT,
            u.id::TEXT as user_id,
            u.full_name,
            u.email,
            al.check_in::TEXT
        FROM attendance_logs al
        JOIN users u ON al.user_id = u.id
        WHERE al.status = 'OPEN'
        ORDER BY al.check_in DESC
        "#,
    )
    .fetch_all(&state.db)
    .await
    .map_err(|e| {
        error!("Database error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "error": "Database error"
            })),
        )
    })?;

    info!("📊 Active shifts: {} models working", active_shifts.len());

    Ok(Json(json!({
        "count": active_shifts.len(),
        "shifts": active_shifts
    })))
}
 




