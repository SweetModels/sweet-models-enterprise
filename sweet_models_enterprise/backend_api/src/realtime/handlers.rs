use axum::{
    extract::{ws::{WebSocket, WebSocketUpgrade}, State},
    response::IntoResponse,
    http::StatusCode,
};
use futures_util::{SinkExt, StreamExt};
use std::sync::Arc;
use crate::state::AppState;
use crate::middleware::auth::AuthenticatedUser;

/// Manejador para WebSocket en GET /ws/dashboard
/// Requiere autenticación (cualquier usuario).
pub async fn ws_dashboard_handler(
    ws: WebSocketUpgrade,
    State(state): State<Arc<AppState>>,
    auth: AuthenticatedUser, // Requiere token JWT válido
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let hub = state.realtime_hub.clone();
    Ok(ws.on_upgrade(move |socket| handle_socket(socket, hub, auth.user_id)))
}

/// Maneja la conexión WebSocket activa
async fn handle_socket(
    socket: WebSocket,
    hub: Arc<crate::realtime::RealtimeHub>,
    user_id: String,
) {
    let (mut sender, mut receiver) = socket.split();
    
    // Suscribirse al canal de broadcast
    let mut rx = hub.subscribe();
    
    // Tarea 1: Recibir mensajes del cliente (opcional ping/pong)
    let user_id_clone = user_id.clone();
    tokio::spawn(async move {
        while let Some(Ok(msg)) = receiver.next().await {
            match msg {
                axum::extract::ws::Message::Text(text) => {
                    tracing::debug!("User {} sent: {}", user_id_clone, text);
                    // Opcional: procesar comandos del cliente
                }
                axum::extract::ws::Message::Close(_) => {
                    tracing::info!("User {} disconnected", user_id_clone);
                    break;
                }
                _ => {}
            }
        }
    });

    // Tarea 2: Enviar eventos del canal al cliente
    tracing::info!("User {} connected to WebSocket dashboard", user_id);
    while let Ok(event) = rx.recv().await {
        let msg = axum::extract::ws::Message::Text(
            serde_json::to_string(&event).unwrap_or_default()
        );
        if sender.send(msg).await.is_err() {
            tracing::info!("User {} socket closed", user_id);
            break;
        }
    }
}
