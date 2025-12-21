use axum::{
    extract::{State, Path},
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use deadpool_redis::redis::AsyncCommands;
use crate::state::AppState;
use crate::realtime::hub::RealtimeEvent;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryUpdate {
    pub room_id: String,
    pub platform: String,
    pub tokens_count: u32,
    pub tips_count: u32,
    pub viewers_count: u32,
    pub timestamp: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryResponse {
    pub status: String,
    pub message: String,
    pub processed_at: i64,
}

/// Recibe actualizaciones de telemetría desde la extensión Chrome
/// POST /api/tracking/telemetry
pub async fn telemetry_handler(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<TelemetryUpdate>,
) -> Result<(StatusCode, Json<TelemetryResponse>), (StatusCode, String)> {
    tracing::debug!(
        "📊 Telemetría recibida - Room: {}, Plataforma: {}, Tokens: {}",
        payload.room_id,
        payload.platform,
        payload.tokens_count
    );

    // Guardar en Redis para análisis
    let redis_key = format!("telemetry:{}:{}", payload.room_id, payload.platform);
    
    if let Ok(mut conn) = state.redis.get().await {
        let json_payload = serde_json::to_string(&payload).unwrap_or_default();
        let _ = conn.set::<&str, String, ()>(
            &redis_key,
            json_payload,
        ).await;
        
        // Expirar en 1 hora
        let _ = conn.expire::<&str, ()>(&redis_key, 3600).await;
    }

    // Publicar evento en WebSocket para God Mode
    let event = RealtimeEvent {
        event_type: "TELEMETRY_UPDATE".to_string(),
        room_id: payload.room_id.clone(),
        data: serde_json::json!({
            "platform": payload.platform,
            "tokens": payload.tokens_count,
            "tips": payload.tips_count,
            "viewers": payload.viewers_count,
            "timestamp": payload.timestamp,
        }),
        timestamp: chrono::Utc::now().timestamp(),
    };

    let _ = state.realtime_hub.publish(event);

    let response = TelemetryResponse {
        status: "success".to_string(),
        message: format!("Telemetría procesada para room {}", payload.room_id),
        processed_at: chrono::Utc::now().timestamp(),
    };

    Ok((StatusCode::OK, Json(response)))
}

/// Obtiene el último update de telemetría para una room
/// GET /api/tracking/telemetry/:room_id/:platform
pub async fn get_telemetry_handler(
    State(state): State<Arc<AppState>>,
    Path((room_id, platform)): Path<(String, String)>,
) -> Result<Json<TelemetryUpdate>, (StatusCode, String)> {
    let redis_key = format!("telemetry:{}:{}", room_id, platform);
    
    let mut conn = state.redis.get().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Redis error: {}", e)))?;
    
    let data: Option<String> = conn.get(&redis_key).await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Redis error: {}", e)))?;
    
    if let Some(json_string) = data {
        let telemetry: TelemetryUpdate = serde_json::from_str(&json_string)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Parse error: {}", e)))?;
        Ok(Json(telemetry))
    } else {
        Err((StatusCode::NOT_FOUND, "Telemetría no encontrada".to_string()))
    }
}

