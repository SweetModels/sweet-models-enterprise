use serde::{Deserialize, Serialize};
use tokio::sync::broadcast;
use std::sync::Arc;

/// Evento que se difunde a través del canal realtime
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RealtimeEvent {
    pub event_type: String, // "ROOM_UPDATE", "MEMBER_JOIN", etc.
    pub room_id: String,
    pub data: serde_json::Value,
    pub timestamp: i64,
}

/// Hub central de difusión (Broadcast Channel)
/// Todos los clientes WebSocket se suscriben a este canal.
pub struct RealtimeHub {
    /// Transmisor broadcast: cualquier component puede enviar eventos
    pub tx: broadcast::Sender<RealtimeEvent>,
}

impl RealtimeHub {
    /// Crea un nuevo Hub con capacidad inicial
    pub fn new(capacity: usize) -> Self {
        let (tx, _) = broadcast::channel(capacity);
        RealtimeHub { tx }
    }

    /// Obtiene un receptor para suscribirse a eventos
    pub fn subscribe(&self) -> broadcast::Receiver<RealtimeEvent> {
        self.tx.subscribe()
    }

    /// Publica un evento al canal (usado por endpoints de telemetría)
    pub fn publish(&self, event: RealtimeEvent) -> Result<usize, broadcast::error::SendError<RealtimeEvent>> {
        self.tx.send(event)
    }

    /// Envía un evento ROOM_UPDATE (caso de uso principal)
    pub fn room_update(
        &self,
        room_id: String,
        new_total: f64,
        members: Vec<serde_json::Value>,
    ) -> Result<usize, broadcast::error::SendError<RealtimeEvent>> {
        let event = RealtimeEvent {
            event_type: "ROOM_UPDATE".to_string(),
            room_id,
            data: serde_json::json!({
                "new_total": new_total,
                "members": members,
            }),
            timestamp: chrono::Utc::now().timestamp(),
        };
        self.publish(event)
    }
}

/// Crea una instancia global del Hub
pub fn create_global_hub() -> Arc<RealtimeHub> {
    Arc::new(RealtimeHub::new(128)) // Capacidad de 128 eventos en buffer
}
