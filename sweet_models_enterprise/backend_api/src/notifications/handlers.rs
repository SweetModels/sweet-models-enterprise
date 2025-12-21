use axum::{
    extract::{State, Json, Path},
    http::StatusCode,
    response::IntoResponse,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::notifications::{NotificationService};
use std::collections::HashMap;

/// Request para registrar un dispositivo
#[derive(Debug, Serialize, Deserialize)]
pub struct RegisterDeviceRequest {
    pub fcm_token: String,
    pub platform: String,  // ANDROID, IOS, WEB
    pub device_name: Option<String>,
}

/// Request para enviar notificación
#[derive(Debug, Serialize, Deserialize)]
pub struct SendNotificationRequest {
    pub user_id: Uuid,
    pub title: String,
    pub body: String,
    pub data: Option<HashMap<String, String>>,
    pub notification_type: String,
}

/// Response genérico
#[derive(Debug, Serialize, Deserialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub message: String,
    pub data: Option<T>,
}

impl<T: Serialize> ApiResponse<T> {
    pub fn ok(message: String, data: T) -> Self {
        Self {
            success: true,
            message,
            data: Some(data),
        }
    }

    pub fn error(message: String) -> Self {
        Self {
            success: false,
            message,
            data: None,
        }
    }
}

/// Handler para registrar token FCM
pub async fn register_device_handler(
    State(notification_service): State<std::sync::Arc<NotificationService>>,
    Path(user_id): Path<Uuid>,
    Json(payload): Json<RegisterDeviceRequest>,
) -> impl IntoResponse {
    match notification_service
        .register_device(
            user_id,
            payload.fcm_token,
            payload.platform,
            payload.device_name,
        )
        .await
    {
        Ok(device) => {
            let response = ApiResponse::ok(
                "Dispositivo registrado exitosamente".to_string(),
                serde_json::json!({
                    "id": device.id,
                    "platform": device.platform,
                    "is_active": device.is_active,
                    "created_at": device.created_at,
                }),
            );
            (StatusCode::CREATED, Json(response)).into_response()
        }
        Err(e) => {
            let response: ApiResponse<()> = ApiResponse::error(e);
            (StatusCode::BAD_REQUEST, Json(response)).into_response()
        }
    }
}

/// Handler para enviar notificación
pub async fn send_notification_handler(
    State(notification_service): State<std::sync::Arc<NotificationService>>,
    Json(payload): Json<SendNotificationRequest>,
) -> impl IntoResponse {
    match notification_service
        .send_alert(
            payload.user_id,
            payload.title,
            payload.body,
            payload.data,
            &payload.notification_type,
        )
        .await
    {
        Ok(sent_tokens) => {
            let response = ApiResponse::ok(
                format!("Notificación enviada a {} dispositivos", sent_tokens.len()),
                serde_json::json!({
                    "tokens_sent": sent_tokens.len(),
                    "devices": sent_tokens,
                }),
            );
            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            let response: ApiResponse<()> = ApiResponse::error(format!("Error al enviar notificación: {}", e));
            (StatusCode::INTERNAL_SERVER_ERROR, Json(response)).into_response()
        }
    }
}

/// Handler para obtener historial de notificaciones
pub async fn get_notification_history_handler(
    State(notification_service): State<std::sync::Arc<NotificationService>>,
    Path((user_id, limit)): Path<(Uuid, i64)>,
) -> impl IntoResponse {
    match notification_service
        .get_notification_history(user_id, limit)
        .await
    {
        Ok(logs) => {
            let response = ApiResponse::ok(
                "Historial obtenido".to_string(),
                logs,
            );
            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            let response: ApiResponse<()> = ApiResponse::error(e);
            (StatusCode::INTERNAL_SERVER_ERROR, Json(response)).into_response()
        }
    }
}

/// Handler para limpiar tokens expirados
pub async fn cleanup_tokens_handler(
    State(notification_service): State<std::sync::Arc<NotificationService>>,
) -> impl IntoResponse {
    match notification_service.cleanup_stale_tokens().await {
        Ok(rows_affected) => {
            let response = ApiResponse::ok(
                format!("{} tokens desactivados", rows_affected),
                serde_json::json!({ "cleaned": rows_affected }),
            );
            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            let response: ApiResponse<()> = ApiResponse::error(e);
            (StatusCode::INTERNAL_SERVER_ERROR, Json(response)).into_response()
        }
    }
}
