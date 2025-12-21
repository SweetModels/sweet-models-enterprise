pub mod feed;
pub mod chat_notifications;

use std::{collections::HashMap, sync::Arc, time::SystemTime};

use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        Query, State,
    },
    response::IntoResponse,
    routing::{get, post},
    Router,
};
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use tokio::sync::{broadcast, mpsc, RwLock};
use uuid::Uuid;

use crate::state::AppState;

#[derive(Clone)]
pub struct ChatState {
    pub tx: broadcast::Sender<String>,
    pub peers: Arc<RwLock<HashMap<Uuid, mpsc::UnboundedSender<Message>>>>,
    pub presence: Arc<RwLock<HashMap<Uuid, SystemTime>>>,
}

pub fn social_routes_chat() -> Router<Arc<ChatState>> {
    Router::new()
        .route("/ws", get(websocket_handler))
        .route("/presence", axum::routing::post(register_presence))
        .route("/presence", axum::routing::get(list_presence))
}

pub fn social_routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/posts", post(feed::create_post))
        .route("/feed", get(feed::get_feed))
        .route("/posts/:id/like", post(feed::like_post))
}

#[derive(Debug, Deserialize)]
pub struct WsParams {
    pub user_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct PresencePayload {
    pub user_id: Uuid,
}

/// Mensaje de señalización WebRTC
#[derive(Debug, Deserialize, Serialize)]
pub struct SignalMessage {
    #[serde(rename = "type")]
    pub msg_type: String,
    pub target_id: Uuid,
    pub payload: Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub from_id: Option<Uuid>,
}

pub async fn websocket_handler(
    ws: WebSocketUpgrade,
    Query(params): Query<WsParams>,
    State(state): State<Arc<ChatState>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(params.user_id, socket, state))
}

/// Registra presencia del usuario (para prevalidar conexiones WS)
pub async fn register_presence(
    State(state): State<Arc<ChatState>>,
    axum::Json(payload): axum::Json<PresencePayload>,
) -> impl IntoResponse {
    state
        .presence
        .write()
        .await
        .insert(payload.user_id, SystemTime::now());

    axum::Json(serde_json::json!({
        "status": "ok",
        "user_id": payload.user_id,
    }))
}

/// Lista de usuarios con presencia registrada (online)
pub async fn list_presence(
    State(state): State<Arc<ChatState>>,
) -> impl IntoResponse {
    let users: Vec<_> = state
        .presence
        .read()
        .await
        .keys()
        .cloned()
        .collect();

    axum::Json(serde_json::json!({
        "status": "ok",
        "online": users,
    }))
}

async fn handle_socket(user_id: Uuid, stream: WebSocket, state: Arc<ChatState>) {
    let (mut ws_sender, mut ws_receiver) = stream.split();
    let mut rx = state.tx.subscribe();
    let tx = state.tx.clone();
    let state_for_recv = state.clone();

    // Canal dedicado para envíos directos a este usuario
    let (direct_tx, mut direct_rx) = mpsc::unbounded_channel::<Message>();
    {
        let mut peers = state.peers.write().await;
        peers.insert(user_id, direct_tx);
    }

    let mut send_task = tokio::spawn(async move {
        loop {
            tokio::select! {
                // Mensajes broadcast existentes (chat)
                Ok(msg) = rx.recv() => {
                    if ws_sender.send(Message::Text(msg)).await.is_err() {
                        break;
                    }
                }
                // Mensajes directos de señalización
                Some(msg) = direct_rx.recv() => {
                    if ws_sender.send(msg).await.is_err() {
                        break;
                    }
                }
            }
        }
    });

    let mut recv_task = tokio::spawn(async move {
        while let Some(Ok(msg)) = ws_receiver.next().await {
            match msg {
                Message::Text(text) => {
                    // Intentar parsear como señalización WebRTC
                    if let Ok(mut signal) = serde_json::from_str::<SignalMessage>(&text) {
                        // Solo reenviar, no persistir
                        signal.from_id = Some(user_id);

                        // Determinar si es tipo de señalización soportado
                        let kind = signal.msg_type.as_str();
                        let is_signal = matches!(
                            kind,
                            "offer" | "answer" | "ice-candidate" | "hangup"
                        );

                        if is_signal {
                            // Buscar target conectado y reenviar inmediatamente
                            if let Some(target_tx) = state_for_recv.peers.read().await.get(&signal.target_id).cloned() {
                                if let Ok(payload) = serde_json::to_string(&signal) {
                                    let _ = target_tx.send(Message::Text(payload));
                                }
                            } else {
                                let err = format!(
                                    "{{\"type\":\"error\",\"message\":\"Usuario no disponible\",\"target_id\":\"{}\"}}",
                                    signal.target_id
                                );
                                if let Some(self_tx) = state_for_recv.peers.read().await.get(&user_id).cloned() {
                                    let _ = self_tx.send(Message::Text(err));
                                }
                            }
                            continue;
                        }

                        // Si no es señalización, tratar como mensaje normal broadcast
                    }

                    println!("Mensaje recibido: {text}");
                    let _ = tx.send(text);
                }
                Message::Close(_) => break,
                _ => {}
            }
        }
    });

    tokio::select! {
        _ = (&mut send_task) => recv_task.abort(),
        _ = (&mut recv_task) => send_task.abort(),
    }

    // Limpieza de la tabla de peers
    {
        state.peers.write().await.remove(&user_id);
        state.presence.write().await.remove(&user_id);
    }
}
