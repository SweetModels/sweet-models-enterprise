// ============================================================================
// Sweet Models Enterprise - Social Module
// Sistema de Chat en Tiempo Real y Feed Social con WebSockets
// ============================================================================

use axum::{
    extract::{
        ws::{Message as WsMessage, WebSocket, WebSocketUpgrade},
        Extension, Path, Query,
    },
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use dashmap::DashMap;
use futures_util::{sink::SinkExt, stream::StreamExt};
use serde::{Deserialize, Serialize};
use sqlx::{PgPool, types::chrono::{DateTime, Utc}};
use std::sync::Arc;
use tokio::sync::broadcast;
use uuid::Uuid;
use tracing::{error, info, warn};

// ============================================================================
// ESTRUCTURAS DE DATOS
// ============================================================================

/// Mensaje privado entre usuarios
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Message {
    pub id: Uuid,
    pub sender_id: Uuid,
    pub receiver_id: Uuid,
    /// Contenido encriptado (AES-256-GCM)
    pub content: String,
    pub timestamp: DateTime<Utc>,
    pub read: bool,
    pub message_type: MessageType,
}

/// Tipos de mensaje
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "message_type", rename_all = "lowercase")]
pub enum MessageType {
    Text,
    Image,
    Video,
    Audio,
    File,
}

/// Post del feed social
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Post {
    pub id: Uuid,
    pub user_id: Uuid,
    pub content: String,
    pub likes_count: i32,
    pub comments_count: i32,
    pub media_url: Option<String>,
    pub media_type: Option<MediaType>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Tipos de media en posts
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "media_type", rename_all = "lowercase")]
pub enum MediaType {
    Photo,
    Video,
    Gallery,
}

/// Like en un post
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Like {
    pub id: Uuid,
    pub post_id: Uuid,
    pub user_id: Uuid,
    pub created_at: DateTime<Utc>,
}

/// Comentario en un post
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Comment {
    pub id: Uuid,
    pub post_id: Uuid,
    pub user_id: Uuid,
    pub content: String,
    pub created_at: DateTime<Utc>,
}

// ============================================================================
// ESTADO DEL CHAT (Gestión de Conexiones WebSocket)
// ============================================================================

/// Estado compartido del sistema de chat
#[derive(Clone)]
pub struct ChatState {
    /// Usuarios conectados actualmente: user_id -> WebSocket sender
    pub connections: Arc<DashMap<Uuid, broadcast::Sender<String>>>,
    /// Pool de base de datos
    pub db: PgPool,
    /// Cliente Redis para cola de mensajes pendientes
    pub redis: Arc<deadpool_redis::Pool>,
    /// Cliente NATS para broadcasting
    pub nats: Option<Arc<async_nats::Client>>,
}

impl ChatState {
    /// Crea una nueva instancia del estado del chat
    pub fn new(db: PgPool, redis: Arc<deadpool_redis::Pool>) -> Self {
        Self {
            connections: Arc::new(DashMap::new()),
            db,
            redis,
            nats: None,
        }
    }

    /// Configura el cliente NATS
    pub fn with_nats(mut self, nats: Arc<async_nats::Client>) -> Self {
        self.nats = Some(nats);
        self
    }

    /// Verifica si un usuario está conectado
    pub fn is_user_online(&self, user_id: &Uuid) -> bool {
        self.connections.contains_key(user_id)
    }

    /// Envía un mensaje a un usuario específico
    pub async fn send_to_user(&self, user_id: &Uuid, message: &str) -> Result<(), SocialError> {
        if let Some(tx) = self.connections.get(user_id) {
            tx.send(message.to_string())
                .map_err(|e| SocialError::BroadcastError(e.to_string()))?;
            Ok(())
        } else {
            // Usuario no conectado, guardar en Redis como mensaje pendiente
            self.queue_pending_message(user_id, message).await?;
            Err(SocialError::UserOffline(*user_id))
        }
    }

    /// Encola mensaje pendiente en Redis
    async fn queue_pending_message(&self, user_id: &Uuid, message: &str) -> Result<(), SocialError> {
        use deadpool_redis::redis::AsyncCommands;
        
        let mut conn = self.redis.get().await
            .map_err(|e| SocialError::RedisError(e.to_string()))?;
        
        let key = format!("pending_messages:{}", user_id);
        let _: () = conn.rpush(key, message).await
            .map_err(|e| SocialError::RedisError(e.to_string()))?;
        
        info!("Mensaje encolado para usuario offline: {}", user_id);
        Ok(())
    }

    /// Recupera mensajes pendientes de Redis
    pub async fn get_pending_messages(&self, user_id: &Uuid) -> Result<Vec<String>, SocialError> {
        use deadpool_redis::redis::AsyncCommands;
        
        let mut conn = self.redis.get().await
            .map_err(|e| SocialError::RedisError(e.to_string()))?;
        
        let key = format!("pending_messages:{}", user_id);
        let messages: Vec<String> = conn.lrange(&key, 0, -1).await
            .map_err(|e| SocialError::RedisError(e.to_string()))?;
        
        // Limpiar la cola después de recuperar
        if !messages.is_empty() {
            let _: () = conn.del(key).await
                .map_err(|e| SocialError::RedisError(e.to_string()))?;
        }
        
        Ok(messages)
    }

    /// Publica actualización de feed en NATS
    pub async fn publish_feed_update(&self, update: &FeedUpdate) -> Result<(), SocialError> {
        if let Some(nats) = &self.nats {
            let payload = serde_json::to_vec(update)
                .map_err(|e| SocialError::SerializationError(e.to_string()))?;
            
            nats.publish("feed.updates", payload.into()).await
                .map_err(|e| SocialError::NatsError(e.to_string()))?;
            
            info!("Feed update publicado: {:?}", update.update_type);
        }
        Ok(())
    }
}

// ============================================================================
// TIPOS DE MENSAJES WEBSOCKET
// ============================================================================

/// Mensaje entrante del cliente WebSocket
#[derive(Debug, Deserialize)]
#[serde(tag = "type")]
pub enum IncomingMessage {
    #[serde(rename = "private_message")]
    PrivateMessage {
        receiver_id: Uuid,
        content: String,
    },
    #[serde(rename = "typing")]
    Typing {
        receiver_id: Uuid,
    },
    #[serde(rename = "read_receipt")]
    ReadReceipt {
        message_id: Uuid,
    },
    #[serde(rename = "ping")]
    Ping,
}

/// Mensaje saliente al cliente WebSocket
#[derive(Debug, Serialize)]
#[serde(tag = "type")]
pub enum OutgoingMessage {
    #[serde(rename = "private_message")]
    PrivateMessage {
        message: Message,
    },
    #[serde(rename = "feed_update")]
    FeedUpdate {
        update: FeedUpdate,
    },
    #[serde(rename = "typing")]
    Typing {
        user_id: Uuid,
    },
    #[serde(rename = "user_status")]
    UserStatus {
        user_id: Uuid,
        online: bool,
    },
    #[serde(rename = "pong")]
    Pong,
    #[serde(rename = "error")]
    Error {
        message: String,
    },
}

/// Actualización del feed social
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeedUpdate {
    pub post_id: Uuid,
    pub user_id: Uuid,
    pub update_type: FeedUpdateType,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum FeedUpdateType {
    NewPost,
    NewLike,
    NewComment,
    PostDeleted,
}

// ============================================================================
// HANDLER PRINCIPAL DE WEBSOCKET
// ============================================================================

/// Handler principal para conexiones WebSocket
pub async fn websocket_handler(
    ws: WebSocketUpgrade,
    Extension(state): Extension<ChatState>,
    Path(user_id): Path<Uuid>,
) -> Response {
    info!("WebSocket upgrade request de usuario: {}", user_id);
    
    ws.on_upgrade(move |socket| handle_socket(socket, state, user_id))
}

/// Maneja una conexión WebSocket individual
async fn handle_socket(socket: WebSocket, state: ChatState, user_id: Uuid) {
    let (mut sender, mut receiver) = socket.split();
    
    // Crear canal de broadcast para este usuario
    let (tx, mut rx) = broadcast::channel::<String>(100);
    
    // Registrar conexión
    state.connections.insert(user_id, tx.clone());
    info!("Usuario {} conectado al chat", user_id);
    
    // Notificar a otros usuarios que este usuario está online
    let status_msg = OutgoingMessage::UserStatus {
        user_id,
        online: true,
    };
    if let Ok(msg_json) = serde_json::to_string(&status_msg) {
        broadcast_to_all(&state, &msg_json, Some(user_id)).await;
    }
    
    // Enviar mensajes pendientes
    if let Ok(pending) = state.get_pending_messages(&user_id).await {
        for msg in pending {
            if let Err(e) = sender.send(WsMessage::Text(msg)).await {
                error!("Error enviando mensaje pendiente: {}", e);
            }
        }
    }
    
    // Tarea para enviar mensajes desde el broadcast channel
    let mut send_task = tokio::spawn(async move {
        while let Ok(msg) = rx.recv().await {
            if sender.send(WsMessage::Text(msg)).await.is_err() {
                break;
            }
        }
    });
    
    // Tarea para recibir mensajes del cliente
    let state_clone = state.clone();
    let mut recv_task = tokio::spawn(async move {
        while let Some(Ok(msg)) = receiver.next().await {
            if let Err(e) = handle_client_message(msg, &state_clone, user_id).await {
                error!("Error procesando mensaje de {}: {}", user_id, e);
                
                let error_msg = OutgoingMessage::Error {
                    message: e.to_string(),
                };
                if let Ok(json) = serde_json::to_string(&error_msg) {
                    let _ = state_clone.send_to_user(&user_id, &json).await;
                }
            }
        }
    });
    
    // Esperar a que una de las tareas termine
    tokio::select! {
        _ = (&mut send_task) => recv_task.abort(),
        _ = (&mut recv_task) => send_task.abort(),
    };
    
    // Desconexión: limpiar y notificar
    state.connections.remove(&user_id);
    info!("Usuario {} desconectado del chat", user_id);
    
    // Notificar a otros usuarios que este usuario está offline
    let status_msg = OutgoingMessage::UserStatus {
        user_id,
        online: false,
    };
    if let Ok(msg_json) = serde_json::to_string(&status_msg) {
        broadcast_to_all(&state, &msg_json, Some(user_id)).await;
    }
}

/// Procesa un mensaje recibido del cliente WebSocket
async fn handle_client_message(
    msg: WsMessage,
    state: &ChatState,
    sender_id: Uuid,
) -> Result<(), SocialError> {
    match msg {
        WsMessage::Text(text) => {
            // Parsear mensaje JSON
            let incoming: IncomingMessage = serde_json::from_str(&text)
                .map_err(|e| SocialError::InvalidMessage(e.to_string()))?;
            
            match incoming {
                IncomingMessage::PrivateMessage { receiver_id, content } => {
                    handle_private_message(state, sender_id, receiver_id, content).await?;
                }
                IncomingMessage::Typing { receiver_id } => {
                    let typing_msg = OutgoingMessage::Typing {
                        user_id: sender_id,
                    };
                    let json = serde_json::to_string(&typing_msg)
                        .map_err(|e| SocialError::SerializationError(e.to_string()))?;
                    
                    let _ = state.send_to_user(&receiver_id, &json).await;
                }
                IncomingMessage::ReadReceipt { message_id } => {
                    mark_message_as_read(&state.db, message_id).await?;
                }
                IncomingMessage::Ping => {
                    let pong = OutgoingMessage::Pong;
                    let json = serde_json::to_string(&pong)
                        .map_err(|e| SocialError::SerializationError(e.to_string()))?;
                    
                    let _ = state.send_to_user(&sender_id, &json).await;
                }
            }
        }
        WsMessage::Close(_) => {
            info!("Cliente {} cerró la conexión", sender_id);
        }
        WsMessage::Ping(_) => {
            // Axum maneja automáticamente los pings
        }
        _ => {
            warn!("Tipo de mensaje WebSocket no soportado de {}", sender_id);
        }
    }
    
    Ok(())
}

/// Maneja el envío de un mensaje privado
async fn handle_private_message(
    state: &ChatState,
    sender_id: Uuid,
    receiver_id: Uuid,
    content: String,
) -> Result<(), SocialError> {
    // Crear mensaje
    let message = Message {
        id: Uuid::new_v4(),
        sender_id,
        receiver_id,
        content: encrypt_content(&content)?,
        timestamp: Utc::now(),
        read: false,
        message_type: MessageType::Text,
    };
    
    // Guardar en base de datos asíncronamente (no bloquea el envío)
    let db = state.db.clone();
    let msg_clone = message.clone();
    tokio::spawn(async move {
        if let Err(e) = save_message(&db, &msg_clone).await {
            error!("Error guardando mensaje en BD: {}", e);
        }
    });
    
    // Preparar mensaje para enviar
    let outgoing = OutgoingMessage::PrivateMessage {
        message: message.clone(),
    };
    let json = serde_json::to_string(&outgoing)
        .map_err(|e| SocialError::SerializationError(e.to_string()))?;
    
    // Intentar enviar al destinatario
    match state.send_to_user(&receiver_id, &json).await {
        Ok(_) => info!("Mensaje enviado de {} a {}", sender_id, receiver_id),
        Err(SocialError::UserOffline(_)) => {
            info!("Usuario {} offline, mensaje encolado", receiver_id);
        }
        Err(e) => return Err(e),
    }
    
    // También enviar confirmación al remitente
    let _ = state.send_to_user(&sender_id, &json).await;
    
    Ok(())
}

// ============================================================================
// FUNCIONES DE BASE DE DATOS
// ============================================================================

/// Guarda un mensaje en la base de datos
async fn save_message(db: &PgPool, message: &Message) -> Result<(), SocialError> {
    sqlx::query!(
        r#"
        INSERT INTO messages (id, sender_id, receiver_id, content, timestamp, read, message_type)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        "#,
        message.id,
        message.sender_id,
        message.receiver_id,
        message.content,
        message.timestamp,
        message.read,
        message.message_type as MessageType,
    )
    .execute(db)
    .await
    .map_err(|e| SocialError::DatabaseError(e.to_string()))?;
    
    Ok(())
}

/// Marca un mensaje como leído
async fn mark_message_as_read(db: &PgPool, message_id: Uuid) -> Result<(), SocialError> {
    sqlx::query!(
        "UPDATE messages SET read = true WHERE id = $1",
        message_id
    )
    .execute(db)
    .await
    .map_err(|e| SocialError::DatabaseError(e.to_string()))?;
    
    Ok(())
}

/// Obtiene mensajes entre dos usuarios
pub async fn get_messages(
    db: &PgPool,
    user1: Uuid,
    user2: Uuid,
    limit: i64,
    offset: i64,
) -> Result<Vec<Message>, SocialError> {
    let messages = sqlx::query_as!(
        Message,
        r#"
        SELECT id, sender_id, receiver_id, content, timestamp, read, 
               message_type as "message_type: MessageType"
        FROM messages
        WHERE (sender_id = $1 AND receiver_id = $2) 
           OR (sender_id = $2 AND receiver_id = $1)
        ORDER BY timestamp DESC
        LIMIT $3 OFFSET $4
        "#,
        user1,
        user2,
        limit,
        offset,
    )
    .fetch_all(db)
    .await
    .map_err(|e| SocialError::DatabaseError(e.to_string()))?;
    
    Ok(messages)
}

/// Crea un nuevo post
pub async fn create_post(
    db: &PgPool,
    user_id: Uuid,
    content: String,
    media_url: Option<String>,
    media_type: Option<MediaType>,
) -> Result<Post, SocialError> {
    let post = sqlx::query_as!(
        Post,
        r#"
        INSERT INTO posts (id, user_id, content, media_url, media_type, likes_count, comments_count, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, 0, 0, NOW(), NOW())
        RETURNING id, user_id, content, likes_count, comments_count, media_url, 
                  media_type as "media_type: MediaType", created_at, updated_at
        "#,
        Uuid::new_v4(),
        user_id,
        content,
        media_url,
        media_type as Option<MediaType>,
    )
    .fetch_one(db)
    .await
    .map_err(|e| SocialError::DatabaseError(e.to_string()))?;
    
    Ok(post)
}

/// Obtiene posts del feed (ordenados por fecha)
pub async fn get_feed_posts(
    db: &PgPool,
    limit: i64,
    offset: i64,
) -> Result<Vec<Post>, SocialError> {
    let posts = sqlx::query_as!(
        Post,
        r#"
        SELECT id, user_id, content, likes_count, comments_count, media_url,
               media_type as "media_type: MediaType", created_at, updated_at
        FROM posts
        ORDER BY created_at DESC
        LIMIT $1 OFFSET $2
        "#,
        limit,
        offset,
    )
    .fetch_all(db)
    .await
    .map_err(|e| SocialError::DatabaseError(e.to_string()))?;
    
    Ok(posts)
}

/// Da like a un post
pub async fn like_post(
    db: &PgPool,
    post_id: Uuid,
    user_id: Uuid,
) -> Result<Like, SocialError> {
    // Verificar si ya existe el like
    let existing = sqlx::query!("SELECT id FROM likes WHERE post_id = $1 AND user_id = $2", post_id, user_id)
        .fetch_optional(db)
        .await
        .map_err(|e| SocialError::DatabaseError(e.to_string()))?;
    
    if existing.is_some() {
        return Err(SocialError::AlreadyLiked);
    }
    
    // Crear like
    let like = sqlx::query_as!(
        Like,
        "INSERT INTO likes (id, post_id, user_id, created_at) VALUES ($1, $2, $3, NOW()) RETURNING *",
        Uuid::new_v4(),
        post_id,
        user_id,
    )
    .fetch_one(db)
    .await
    .map_err(|e| SocialError::DatabaseError(e.to_string()))?;
    
    // Incrementar contador
    sqlx::query!("UPDATE posts SET likes_count = likes_count + 1 WHERE id = $1", post_id)
        .execute(db)
        .await
        .map_err(|e| SocialError::DatabaseError(e.to_string()))?;
    
    Ok(like)
}

/// Añade un comentario a un post
pub async fn add_comment(
    db: &PgPool,
    post_id: Uuid,
    user_id: Uuid,
    content: String,
) -> Result<Comment, SocialError> {
    let comment = sqlx::query_as!(
        Comment,
        "INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING *",
        Uuid::new_v4(),
        post_id,
        user_id,
        content,
    )
    .fetch_one(db)
    .await
    .map_err(|e| SocialError::DatabaseError(e.to_string()))?;
    
    // Incrementar contador
    sqlx::query!("UPDATE posts SET comments_count = comments_count + 1 WHERE id = $1", post_id)
        .execute(db)
        .await
        .map_err(|e| SocialError::DatabaseError(e.to_string()))?;
    
    Ok(comment)
}

// ============================================================================
// UTILIDADES DE ENCRIPTACIÓN
// ============================================================================

/// Encripta el contenido del mensaje (simulado - implementar AES-256-GCM en producción)
fn encrypt_content(content: &str) -> Result<String, SocialError> {
    // TODO: Implementar encriptación real con AES-256-GCM
    // Por ahora, solo convertimos a base64 como placeholder
    Ok(base64::encode(content))
}

/// Desencripta el contenido del mensaje
#[allow(dead_code)]
fn decrypt_content(encrypted: &str) -> Result<String, SocialError> {
    // TODO: Implementar desencriptación real
    base64::decode(encrypted)
        .ok()
        .and_then(|bytes| String::from_utf8(bytes).ok())
        .ok_or_else(|| SocialError::EncryptionError("Failed to decrypt".to_string()))
}

// ============================================================================
// BROADCASTING
// ============================================================================

/// Envía un mensaje a todos los usuarios conectados
async fn broadcast_to_all(state: &ChatState, message: &str, exclude: Option<Uuid>) {
    for entry in state.connections.iter() {
        let user_id = *entry.key();
        if let Some(excluded) = exclude {
            if user_id == excluded {
                continue;
            }
        }
        
        let _ = entry.value().send(message.to_string());
    }
}

// ============================================================================
// MANEJO DE ERRORES
// ============================================================================

#[derive(Debug, thiserror::Error)]
pub enum SocialError {
    #[error("Error de base de datos: {0}")]
    DatabaseError(String),
    
    #[error("Error de Redis: {0}")]
    RedisError(String),
    
    #[error("Error de NATS: {0}")]
    NatsError(String),
    
    #[error("Usuario offline: {0}")]
    UserOffline(Uuid),
    
    #[error("Mensaje inválido: {0}")]
    InvalidMessage(String),
    
    #[error("Error de serialización: {0}")]
    SerializationError(String),
    
    #[error("Error de broadcast: {0}")]
    BroadcastError(String),
    
    #[error("Error de encriptación: {0}")]
    EncryptionError(String),
    
    #[error("Ya has dado like a este post")]
    AlreadyLiked,
}

impl IntoResponse for SocialError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            SocialError::DatabaseError(_) => (StatusCode::INTERNAL_SERVER_ERROR, self.to_string()),
            SocialError::UserOffline(_) => (StatusCode::NOT_FOUND, self.to_string()),
            SocialError::InvalidMessage(_) => (StatusCode::BAD_REQUEST, self.to_string()),
            SocialError::AlreadyLiked => (StatusCode::CONFLICT, self.to_string()),
            _ => (StatusCode::INTERNAL_SERVER_ERROR, self.to_string()),
        };
        
        (status, Json(serde_json::json!({ "error": message }))).into_response()
    }
}

// ============================================================================
// MÓDULO EXTERNO
// ============================================================================

use base64;
