/// Integración del servicio de notificaciones con el módulo de chat
/// Este archivo contiene la lógica para enviar notificaciones FCM cuando
/// un usuario recibe un mensaje de chat y NO está conectado al WebSocket.

use std::collections::HashMap;
use std::sync::Arc;
use uuid::Uuid;
use crate::notifications::NotificationService;

/// Mensaje de chat que disparará la notificación
#[derive(Debug, Clone)]
pub struct ChatMessage {
    pub from_user_id: Uuid,
    pub to_user_id: Uuid,
    pub from_user_name: String,
    pub content: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

/// Gestor de notificaciones para chat
pub struct ChatNotificationManager {
    notification_service: Arc<NotificationService>,
}

impl ChatNotificationManager {
    /// Crear nueva instancia del gestor
    pub fn new(
        notification_service: Arc<NotificationService>,
    ) -> Self {
        Self {
            notification_service,
        }
    }

    /// Enviar notificación de nuevo mensaje si el usuario NO está conectado
    pub async fn notify_if_offline(
        &self,
        message: ChatMessage,
        connected_users: &HashMap<Uuid, bool>, // user_id -> is_connected
    ) -> Result<(), String> {
        // Verificar si el usuario receptor está conectado
        let is_recipient_online = connected_users.get(&message.to_user_id).copied().unwrap_or(false);

        // Solo enviar notificación si el usuario NO está en línea
        if !is_recipient_online {
            let title = format!("Nuevo mensaje de {}", message.from_user_name);
            let body = format!("{}", message.content);

            let mut data = HashMap::new();
            data.insert("from_user_id".to_string(), message.from_user_id.to_string());
            data.insert("from_user_name".to_string(), message.from_user_name);
            data.insert("chat_type".to_string(), "direct_message".to_string());
            data.insert("action".to_string(), "open_chat".to_string());

            // Enviar notificación
            self.notification_service
                .send_alert(
                    message.to_user_id,
                    title,
                    body,
                    Some(data),
                    "message",
                )
                .await?;
        }

        Ok(())
    }

    /// Enviar notificación de mensaje grupal
    pub async fn notify_group_message(
        &self,
        group_id: Uuid,
        from_user_id: Uuid,
        from_user_name: String,
        content: String,
        recipient_ids: Vec<Uuid>,
        connected_users: &HashMap<Uuid, bool>,
    ) -> Result<usize, String> {
        let mut notified_count = 0;

        for recipient_id in recipient_ids {
            // No enviar notificación al remitente
            if recipient_id == from_user_id {
                continue;
            }

            let is_online = connected_users.get(&recipient_id).copied().unwrap_or(false);

            // Solo notificar offline
            if !is_online {
                let title = format!("Nuevo mensaje de {} en grupo", from_user_name);
                let body = format!("{}", content);

                let mut data = HashMap::new();
                data.insert("from_user_id".to_string(), from_user_id.to_string());
                data.insert("group_id".to_string(), group_id.to_string());
                data.insert("from_user_name".to_string(), from_user_name.clone());
                data.insert("chat_type".to_string(), "group_message".to_string());
                data.insert("action".to_string(), "open_group_chat".to_string());

                match self
                    .notification_service
                    .send_alert(
                        recipient_id,
                        title,
                        body,
                        Some(data),
                        "group_message",
                    )
                    .await
                {
                    Ok(_) => notified_count += 1,
                    Err(e) => {
                        eprintln!(
                            "Error notificando usuario {:?}: {}",
                            recipient_id, e
                        );
                    }
                }
            }
        }

        Ok(notified_count)
    }

    /// Enviar notificación de llamada entrante
    pub async fn notify_incoming_call(
        &self,
        from_user_id: Uuid,
        from_user_name: String,
        to_user_id: Uuid,
    ) -> Result<(), String> {
        let title = format!("Llamada de {}", from_user_name);
        let body = "Pulsa para responder".to_string();

        let mut data = HashMap::new();
        data.insert("from_user_id".to_string(), from_user_id.to_string());
        data.insert("call_type".to_string(), "incoming".to_string());
        data.insert("action".to_string(), "answer_call".to_string());

        self.notification_service
            .send_alert(
                to_user_id,
                title,
                body,
                Some(data),
                "incoming_call",
            )
            .await?;

        Ok(())
    }

    /// Enviar notificación de reacción a mensaje
    pub async fn notify_message_reaction(
        &self,
        from_user_id: Uuid,
        from_user_name: String,
        to_user_id: Uuid,
        reaction: String,
    ) -> Result<(), String> {
        let title = format!("{} reaccionó a tu mensaje", from_user_name);
        let body = format!("Con: {}", reaction);

        let mut data = HashMap::new();
        data.insert("from_user_id".to_string(), from_user_id.to_string());
        data.insert("reaction".to_string(), reaction);
        data.insert("action".to_string(), "show_reaction".to_string());

        self.notification_service
            .send_alert(
                to_user_id,
                title,
                body,
                Some(data),
                "message_reaction",
            )
            .await?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_notification_offline_only() {
        // Este test verificaría que la notificación solo se envía si el usuario está offline
        // Implementar según sea necesario
    }
}
