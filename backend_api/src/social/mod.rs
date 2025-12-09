use std::sync::Arc;

use axum::{
    extract::{ws::{Message, WebSocket, WebSocketUpgrade}, State},
    response::IntoResponse,
    routing::get,
    Router,
};
use futures_util::{SinkExt, StreamExt};
use tokio::sync::broadcast;

#[derive(Clone)]
pub struct ChatState {
    pub tx: broadcast::Sender<String>,
}

pub fn social_routes() -> Router<Arc<ChatState>> {
    Router::new().route("/ws", get(websocket_handler))
}

pub async fn websocket_handler(
    ws: WebSocketUpgrade,
    State(state): State<Arc<ChatState>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, state))
}

async fn handle_socket(stream: WebSocket, state: Arc<ChatState>) {
    let (mut ws_sender, mut ws_receiver) = stream.split();
    let mut rx = state.tx.subscribe();
    let tx = state.tx.clone();

    let mut send_task = tokio::spawn(async move {
        while let Ok(msg) = rx.recv().await {
            if ws_sender.send(Message::Text(msg)).await.is_err() {
                break;
            }
        }
    });

    let mut recv_task = tokio::spawn(async move {
        while let Some(Ok(msg)) = ws_receiver.next().await {
            match msg {
                Message::Text(text) => {
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
}
