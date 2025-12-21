use std::sync::Arc;

use axum::{
    extract::State,
    http::{Request, StatusCode, Method},
    middleware::Next,
    response::IntoResponse,
    Json,
    body::Body,
};
use chrono::{DateTime, Utc};
use deadpool_redis::redis::AsyncCommands;
use serde::{Deserialize, Serialize};
use serde_json::json;

use crate::{middleware::SuperAdminOnly, state::AppState};

const EMERGENCY_KEY: &str = "system:emergency_stop";

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct EmergencyStatus {
    pub active: bool,
    pub activated_at: Option<DateTime<Utc>>,
    pub activated_by: Option<String>,
    pub reason: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct EmergencyFreezeRequest {
    pub reason: Option<String>,
}

/// Solo Super Admin: activa el modo emergencia global para detener operaciones críticas.
pub async fn freeze_handler(
    State(state): State<Arc<AppState>>,
    _admin: SuperAdminOnly,
    Json(payload): Json<EmergencyFreezeRequest>,
) -> Result<Json<EmergencyStatus>, (StatusCode, String)> {
    let status = EmergencyStatus {
        active: true,
        activated_at: Some(Utc::now()),
        activated_by: Some(_admin.email),
        reason: payload.reason,
    };

    persist_status(&state, &status).await?;

    Ok(Json(status))
}

/// Consulta el estado actual (público) para que los clientes sepan si hay mantenimiento.
pub async fn status_handler(
    State(state): State<Arc<AppState>>,
) -> Result<Json<EmergencyStatus>, (StatusCode, String)> {
    let status = get_status(&state).await?;
    Ok(Json(status))
}

/// Middleware global: devuelve 503 cuando el modo emergencia está activo.
pub async fn enforce_emergency_stop(
    State(state): State<Arc<AppState>>,
    req: Request<Body>,
    next: Next,
) -> Result<axum::response::Response, StatusCode> {
    let path = req.uri().path();

    // Permitir health, opciones CORS y los endpoints de emergencia.
    if path == "/health" || path.starts_with("/api/admin/emergency") || req.method() == Method::OPTIONS {
        return Ok(next.run(req).await);
    }

    let status = match get_status(&state).await {
        Ok(status) => status,
        Err((_, msg)) => {
            let mut resp = Json(json!({
                "error": "maintenance_check_failed",
                "message": format!("No se pudo verificar modo emergencia: {msg}"),
            }))
            .into_response();
            *resp.status_mut() = StatusCode::SERVICE_UNAVAILABLE;
            return Ok(resp);
        }
    };

    if status.active {
        let mut resp = Json(json!({
            "error": "emergency_stop_active",
            "message": "Modo mantenimiento activo por emergencia. Operaciones bloqueadas temporalmente.",
            "activated_at": status.activated_at,
            "reason": status.reason,
        }))
        .into_response();
        *resp.status_mut() = StatusCode::SERVICE_UNAVAILABLE;
        return Ok(resp);
    }

    Ok(next.run(req).await)
}

async fn get_status(state: &AppState) -> Result<EmergencyStatus, (StatusCode, String)> {
    let mut conn = state
        .redis
        .get()
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Redis pool error: {e}")))?;

    let data: Option<String> = conn
        .get(EMERGENCY_KEY)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Redis error: {e}")))?;

    if let Some(json_str) = data {
        serde_json::from_str(&json_str)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Parse error: {e}")))
    } else {
        Ok(EmergencyStatus::default())
    }
}

async fn persist_status(state: &AppState, status: &EmergencyStatus) -> Result<(), (StatusCode, String)> {
    let mut conn = state
        .redis
        .get()
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Redis pool error: {e}")))?;

    let payload = serde_json::to_string(status)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Serialization error: {e}")))?;

    conn.set::<_, _, ()>(EMERGENCY_KEY, payload)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Redis error: {e}")))?;

    Ok(())
}
