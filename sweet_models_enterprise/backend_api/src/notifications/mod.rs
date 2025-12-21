use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;
use std::collections::HashMap;
use chrono::{DateTime, Utc};
use reqwest::Client;
use serde_json::{json, Value};

pub mod handlers;

pub use handlers::*;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct DeviceToken {
    pub id: Uuid,
    pub user_id: Uuid,
    pub fcm_token: String,
    pub platform: String,  // 'ANDROID', 'IOS', 'WEB'
    pub device_name: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub last_updated: DateTime<Utc>,
    pub last_used: Option<DateTime<Utc>>,
}

/// Modelo de Notificación de Auditoría
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct NotificationLog {
    pub id: Uuid,
    pub user_id: Uuid,
    pub device_token_id: Option<Uuid>,
    pub notification_type: String,
    pub title: String,
    pub body: String,
    pub data: Option<serde_json::Value>,
    pub status: String,
    pub error_message: Option<String>,
    pub sent_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}

/// Payload de Notificación FCM
#[derive(Debug, Serialize, Deserialize)]
pub struct FcmNotificationPayload {
    pub message: FcmMessage,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FcmMessage {
    pub token: String,
    pub notification: FcmNotification,
    pub data: Option<HashMap<String, String>>,
    pub android: Option<FcmAndroidConfig>,
    pub apns: Option<FcmApnsConfig>,
    pub webpush: Option<FcmWebpushConfig>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FcmNotification {
    pub title: String,
    pub body: String,
    pub image: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FcmAndroidConfig {
    pub priority: String,  // HIGH, NORMAL
    pub notification: Option<FcmAndroidNotification>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FcmAndroidNotification {
    pub title: String,
    pub body: String,
    pub sound: String,
    pub click_action: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FcmApnsConfig {
    pub headers: HashMap<String, String>,
    pub payload: Option<FcmApnsPayload>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FcmApnsPayload {
    pub aps: Option<FcmAps>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FcmAps {
    pub alert: Option<FcmApnsAlert>,
    pub sound: String,
    pub badge: Option<i32>,
    pub mutable_content: bool,
    pub custom_key: Option<Value>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FcmApnsAlert {
    pub title: String,
    pub body: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FcmWebpushConfig {
    pub headers: HashMap<String, String>,
    pub data: Option<HashMap<String, String>>,
    pub notification: Option<FcmWebpushNotification>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FcmWebpushNotification {
    pub title: String,
    pub body: String,
    pub icon: Option<String>,
    pub badge: Option<String>,
}

/// Struct Principal del Servicio de Notificaciones
pub struct NotificationService {
    db: PgPool,
    http_client: Client,
    fcm_project_id: String,
    fcm_api_key: String,
}

impl NotificationService {
    /// Crear nueva instancia del servicio
    pub fn new(
        db: PgPool,
        fcm_project_id: String,
        fcm_api_key: String,
    ) -> Self {
        Self {
            db,
            http_client: Client::new(),
            fcm_project_id,
            fcm_api_key,
        }
    }

    /// Registrar un token FCM para un usuario
    pub async fn register_device(
        &self,
        user_id: Uuid,
        fcm_token: String,
        platform: String,
        device_name: Option<String>,
    ) -> Result<DeviceToken, String> {
        // Validar plataforma
        if !["ANDROID", "IOS", "WEB"].contains(&platform.as_str()) {
            return Err("Plataforma no válida. Usar: ANDROID, IOS, WEB".to_string());
        }

        // Insertar o actualizar el token
        let device = sqlx::query_as::<_, DeviceToken>(
            r#"
            INSERT INTO device_tokens 
            (user_id, fcm_token, platform, device_name, is_active, last_updated)
            VALUES ($1, $2, $3, $4, true, CURRENT_TIMESTAMP)
            ON CONFLICT (user_id, fcm_token) 
            DO UPDATE SET 
                is_active = true,
                last_updated = CURRENT_TIMESTAMP,
                device_name = COALESCE($4, device_tokens.device_name)
            RETURNING *
            "#,
        )
        .bind(user_id)
        .bind(fcm_token)
        .bind(platform)
        .bind(device_name)
        .fetch_one(&self.db)
        .await
        .map_err(|e| format!("Error al registrar dispositivo: {}", e))?;

        Ok(device)
    }

    /// Obtener todos los tokens activos de un usuario
    pub async fn get_user_tokens(
        &self,
        user_id: Uuid,
    ) -> Result<Vec<DeviceToken>, String> {
        let tokens = sqlx::query_as::<_, DeviceToken>(
            "SELECT * FROM device_tokens WHERE user_id = $1 AND is_active = true",
        )
        .bind(user_id)
        .fetch_all(&self.db)
        .await
        .map_err(|e| format!("Error al obtener tokens: {}", e))?;

        Ok(tokens)
    }

    /// Enviar alerta a un usuario
    pub async fn send_alert(
        &self,
        user_id: Uuid,
        title: String,
        body: String,
        data: Option<HashMap<String, String>>,
        notification_type: &str,
    ) -> Result<Vec<String>, String> {
        // Obtener tokens del usuario
        let devices = self.get_user_tokens(user_id).await?;

        if devices.is_empty() {
            return Err("El usuario no tiene dispositivos registrados".to_string());
        }

        let mut sent_tokens = Vec::new();

        // Enviar a cada dispositivo
        for device in devices {
            match self
                .send_to_device(&device, &title, &body, data.clone(), notification_type)
                .await
            {
                Ok(_) => {
                    sent_tokens.push(device.fcm_token.clone());

                    // Actualizar last_used
                    let _ = sqlx::query(
                        "UPDATE device_tokens SET last_used = CURRENT_TIMESTAMP WHERE id = $1",
                    )
                    .bind(device.id)
                    .execute(&self.db)
                    .await;

                    // Log exitoso
                    let _ = self
                        .log_notification(
                            user_id,
                            Some(device.id),
                            notification_type.to_string(),
                            title.clone(),
                            body.clone(),
                            data.clone(),
                            "SENT".to_string(),
                            None,
                        )
                        .await;
                }
                Err(e) => {
                    // Si el error es por token inválido/expirado, desactivar
                    if e.contains("invalid registration token")
                        || e.contains("registration token is invalid")
                    {
                        let _ = self.deactivate_token(&device.id).await;
                    }

                    // Log de error
                    let _ = self
                        .log_notification(
                            user_id,
                            Some(device.id),
                            notification_type.to_string(),
                            title.clone(),
                            body.clone(),
                            data.clone(),
                            "FAILED".to_string(),
                            Some(e),
                        )
                        .await;
                }
            }
        }

        Ok(sent_tokens)
    }

    /// Enviar notificación a un dispositivo específico
    async fn send_to_device(
        &self,
        device: &DeviceToken,
        title: &str,
        body: &str,
        data: Option<HashMap<String, String>>,
        notification_type: &str,
    ) -> Result<(), String> {
        // Construir payload según plataforma
        let message = match device.platform.as_str() {
            "ANDROID" => self.build_android_message(
                &device.fcm_token,
                title,
                body,
                data,
                notification_type,
            ),
            "IOS" => self.build_ios_message(
                &device.fcm_token,
                title,
                body,
                data,
                notification_type,
            ),
            "WEB" => self.build_web_message(
                &device.fcm_token,
                title,
                body,
                data,
                notification_type,
            ),
            _ => return Err("Plataforma no soportada".to_string()),
        };

        let payload = FcmNotificationPayload { message };

        // URL de FCM HTTP v1
        let url = format!(
            "https://fcm.googleapis.com/v1/projects/{}/messages:send",
            self.fcm_project_id
        );

        // Enviar request
        let response = self
            .http_client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.fcm_api_key))
            .header("Content-Type", "application/json")
            .json(&payload)
            .send()
            .await
            .map_err(|e| format!("Error al enviar solicitud: {}", e))?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Error desconocido".to_string());

            return Err(format!(
                "FCM error ({}): {}",
                status, error_text
            ));
        }

        Ok(())
    }

    /// Construir mensaje para Android
    fn build_android_message(
        &self,
        token: &str,
        title: &str,
        body: &str,
        data: Option<HashMap<String, String>>,
        notification_type: &str,
    ) -> FcmMessage {
        let mut headers = HashMap::new();
        headers.insert(
            "x-goog-api-key".to_string(),
            self.fcm_api_key.clone(),
        );

        FcmMessage {
            token: token.to_string(),
            notification: FcmNotification {
                title: title.to_string(),
                body: body.to_string(),
                image: None,
            },
            data,
            android: Some(FcmAndroidConfig {
                priority: "HIGH".to_string(),
                notification: Some(FcmAndroidNotification {
                    title: title.to_string(),
                    body: body.to_string(),
                    sound: "default".to_string(),
                    click_action: match notification_type {
                        "message" => Some("FLUTTER_NOTIFICATION_CLICK".to_string()),
                        "payment" => Some("PAYMENT_ACTION".to_string()),
                        "security" => Some("SECURITY_ACTION".to_string()),
                        _ => None,
                    },
                }),
            }),
            apns: None,
            webpush: None,
        }
    }

    /// Construir mensaje para iOS
    fn build_ios_message(
        &self,
        token: &str,
        title: &str,
        body: &str,
        data: Option<HashMap<String, String>>,
        notification_type: &str,
    ) -> FcmMessage {
        let mut headers = HashMap::new();
        headers.insert("apns-priority".to_string(), "10".to_string());

        FcmMessage {
            token: token.to_string(),
            notification: FcmNotification {
                title: title.to_string(),
                body: body.to_string(),
                image: None,
            },
            data,
            android: None,
            apns: Some(FcmApnsConfig {
                headers,
                payload: Some(FcmApnsPayload {
                    aps: Some(FcmAps {
                        alert: Some(FcmApnsAlert {
                            title: title.to_string(),
                            body: body.to_string(),
                        }),
                        sound: "default".to_string(),
                        badge: Some(1),
                        mutable_content: true,
                        custom_key: Some(json!({
                            "type": notification_type,
                            "category": notification_type
                        })),
                    }),
                }),
            }),
            webpush: None,
        }
    }

    /// Construir mensaje para Web
    fn build_web_message(
        &self,
        token: &str,
        title: &str,
        body: &str,
        data: Option<HashMap<String, String>>,
        _notification_type: &str,
    ) -> FcmMessage {
        let mut headers = HashMap::new();
        headers.insert("TTL".to_string(), "86400".to_string());

        FcmMessage {
            token: token.to_string(),
            notification: FcmNotification {
                title: title.to_string(),
                body: body.to_string(),
                image: None,
            },
            data: data.clone(),
            android: None,
            apns: None,
            webpush: Some(FcmWebpushConfig {
                headers,
                data,
                notification: Some(FcmWebpushNotification {
                    title: title.to_string(),
                    body: body.to_string(),
                    icon: None,
                    badge: None,
                }),
            }),
        }
    }

    /// Desactivar un token (cuando está expirado)
    async fn deactivate_token(&self, token_id: &Uuid) -> Result<(), String> {
        sqlx::query("UPDATE device_tokens SET is_active = false WHERE id = $1")
            .bind(token_id)
            .execute(&self.db)
            .await
            .map_err(|e| format!("Error desactivando token: {}", e))?;

        Ok(())
    }

    /// Registrar notificación en auditoría
    async fn log_notification(
        &self,
        user_id: Uuid,
        device_token_id: Option<Uuid>,
        notification_type: String,
        title: String,
        body: String,
        data: Option<HashMap<String, String>>,
        status: String,
        error_message: Option<String>,
    ) -> Result<(), String> {
        let data_json = data.map(|d| {
            serde_json::to_value(d).unwrap_or(serde_json::Value::Null)
        });

        sqlx::query(
            r#"
            INSERT INTO notification_logs 
            (user_id, device_token_id, notification_type, title, body, data, status, error_message, sent_at, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 
                    CASE WHEN $7 = 'SENT' THEN CURRENT_TIMESTAMP ELSE NULL END,
                    CURRENT_TIMESTAMP)
            "#,
        )
        .bind(user_id)
        .bind(device_token_id)
        .bind(notification_type)
        .bind(title)
        .bind(body)
        .bind(data_json)
        .bind(status)
        .bind(error_message)
        .execute(&self.db)
        .await
        .map_err(|e| format!("Error registrando notificación: {}", e))?;

        Ok(())
    }

    /// Obtener historial de notificaciones
    pub async fn get_notification_history(
        &self,
        user_id: Uuid,
        limit: i64,
    ) -> Result<Vec<NotificationLog>, String> {
        let logs = sqlx::query_as::<_, NotificationLog>(
            "SELECT * FROM notification_logs WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2",
        )
        .bind(user_id)
        .bind(limit)
        .fetch_all(&self.db)
        .await
        .map_err(|e| format!("Error obteniendo historial: {}", e))?;

        Ok(logs)
    }

    /// Limpiar tokens expirados (sin usar hace más de 30 días)
    pub async fn cleanup_stale_tokens(&self) -> Result<u64, String> {
        let result = sqlx::query(
            r#"
            UPDATE device_tokens 
            SET is_active = false 
            WHERE is_active = true 
              AND last_used IS NOT NULL 
              AND last_used < CURRENT_TIMESTAMP - INTERVAL '30 days'
            "#,
        )
        .execute(&self.db)
        .await
        .map_err(|e| format!("Error limpiando tokens: {}", e))?;

        Ok(result.rows_affected())
    }
}
