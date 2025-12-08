# 💬 Módulo Social - Chat en Tiempo Real y Feed

Sistema completo de mensajería instantánea y red social con WebSockets, encriptación y persistencia asíncrona.

## 🎯 Características

### Chat Privado en Tiempo Real
- ✅ WebSockets bidireccionales
- ✅ Gestión de conexiones con DashMap (thread-safe)
- ✅ Cola de mensajes pendientes en Redis
- ✅ Persistencia asíncrona en PostgreSQL
- ✅ Encriptación de contenido (AES-256-GCM ready)
- ✅ Indicadores de escritura y lectura
- ✅ Notificaciones de estado online/offline

### Feed Social
- ✅ Posts con texto, fotos y videos
- ✅ Sistema de likes
- ✅ Comentarios
- ✅ Broadcasting con NATS
- ✅ Feed personalizado
- ✅ Estadísticas en tiempo real

## 🔌 Endpoints WebSocket

### Conexión al Chat

```rust
// En tu main.rs
use backend_api::social::{ChatState, websocket_handler};

let chat_state = ChatState::new(db_pool.clone(), redis_pool.clone())
    .with_nats(nats_client.clone());

let app = Router::new()
    .route("/ws/chat/:user_id", get(websocket_handler))
    .layer(Extension(chat_state));
```

### Conectar desde el Cliente

```javascript
// JavaScript/TypeScript
const userId = "user-uuid-here";
const ws = new WebSocket(`ws://localhost:3000/ws/chat/${userId}`);

ws.onopen = () => {
    console.log('Conectado al chat');
};

ws.onmessage = (event) => {
    const message = JSON.parse(event.data);
    console.log('Mensaje recibido:', message);
};
```

### Enviar Mensaje Privado

```javascript
// Cliente WebSocket
ws.send(JSON.stringify({
    type: "private_message",
    receiver_id: "receiver-uuid",
    content: "¡Hola! ¿Cómo estás?"
}));
```

### Indicador de Escritura

```javascript
// Enviar "está escribiendo..."
ws.send(JSON.stringify({
    type: "typing",
    receiver_id: "receiver-uuid"
}));
```

### Marcar Mensaje como Leído

```javascript
// Marcar como leído
ws.send(JSON.stringify({
    type: "read_receipt",
    message_id: "message-uuid"
}));
```

### Ping/Pong (Keepalive)

```javascript
// Mantener conexión activa
setInterval(() => {
    ws.send(JSON.stringify({ type: "ping" }));
}, 30000); // Cada 30 segundos
```

## 📨 Formatos de Mensajes

### Mensajes Entrantes (Cliente → Servidor)

```typescript
// TypeScript interfaces
interface PrivateMessage {
    type: "private_message";
    receiver_id: string;
    content: string;
}

interface Typing {
    type: "typing";
    receiver_id: string;
}

interface ReadReceipt {
    type: "read_receipt";
    message_id: string;
}

interface Ping {
    type: "ping";
}
```

### Mensajes Salientes (Servidor → Cliente)

```typescript
interface PrivateMessageOut {
    type: "private_message";
    message: {
        id: string;
        sender_id: string;
        receiver_id: string;
        content: string;  // Encriptado
        timestamp: string;
        read: boolean;
        message_type: "text" | "image" | "video" | "audio" | "file";
    };
}

interface FeedUpdateOut {
    type: "feed_update";
    update: {
        post_id: string;
        user_id: string;
        update_type: "newpost" | "newlike" | "newcomment" | "postdeleted";
        timestamp: string;
    };
}

interface TypingOut {
    type: "typing";
    user_id: string;
}

interface UserStatusOut {
    type: "user_status";
    user_id: string;
    online: boolean;
}

interface PongOut {
    type: "pong";
}

interface ErrorOut {
    type: "error";
    message: string;
}
```

## 🔧 API REST Endpoints

### Posts

#### Crear Post

```http
POST /api/posts
Content-Type: application/json
Authorization: Bearer {token}

{
    "content": "¡Mi primer post! 🎉",
    "media_url": "https://example.com/photo.jpg",
    "media_type": "photo"
}
```

#### Obtener Feed

```http
GET /api/posts?limit=20&offset=0
Authorization: Bearer {token}
```

#### Dar Like

```http
POST /api/posts/{post_id}/like
Authorization: Bearer {token}
```

#### Añadir Comentario

```http
POST /api/posts/{post_id}/comments
Content-Type: application/json
Authorization: Bearer {token}

{
    "content": "¡Excelente post!"
}
```

### Mensajes

#### Obtener Historial de Chat

```http
GET /api/messages?user1={uuid}&user2={uuid}&limit=50&offset=0
Authorization: Bearer {token}
```

```json
[
    {
        "id": "msg-uuid",
        "sender_id": "user1-uuid",
        "receiver_id": "user2-uuid",
        "content": "SGVsbG8h",  // Base64 encriptado
        "timestamp": "2025-12-08T10:30:00Z",
        "read": true,
        "message_type": "text"
    }
]
```

## 🛠️ Implementación en main.rs

```rust
use backend_api::social::{
    ChatState,
    websocket_handler,
    get_messages,
    create_post,
    get_feed_posts,
    like_post,
    add_comment,
};

#[tokio::main]
async fn main() {
    // ... inicializar db_pool, redis_pool, nats_client ...
    
    // Crear estado del chat
    let chat_state = ChatState::new(db_pool.clone(), redis_pool.clone())
        .with_nats(nats_client.clone());
    
    // Rutas
    let app = Router::new()
        // WebSocket
        .route("/ws/chat/:user_id", get(websocket_handler))
        
        // REST API
        .route("/api/posts", post(create_post_handler))
        .route("/api/posts", get(get_feed_handler))
        .route("/api/posts/:post_id/like", post(like_post_handler))
        .route("/api/posts/:post_id/comments", post(add_comment_handler))
        .route("/api/messages", get(get_messages_handler))
        
        // Compartir estado
        .layer(Extension(chat_state))
        .layer(Extension(db_pool));
    
    // Servidor
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .unwrap();
    
    axum::serve(listener, app).await.unwrap();
}
```

## 🔐 Seguridad

### Encriptación de Mensajes

El contenido de los mensajes se encripta con **AES-256-GCM** antes de almacenarse:

```rust
// En producción, implementar:
use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Nonce,
};

fn encrypt_message(content: &str, key: &[u8]) -> Result<String, Error> {
    let cipher = Aes256Gcm::new(key.into());
    let nonce = Nonce::from_slice(b"unique nonce"); // Generar dinámicamente
    let ciphertext = cipher.encrypt(nonce, content.as_bytes())?;
    Ok(base64::encode(ciphertext))
}
```

### Validación de Usuarios

Todos los endpoints requieren autenticación JWT:

```rust
// Middleware de autenticación
async fn auth_middleware(
    req: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    let token = extract_bearer_token(&req)?;
    let claims = verify_jwt(token)?;
    req.extensions_mut().insert(claims);
    Ok(next.run(req).await)
}
```

## 📊 Monitoreo y Métricas

### Usuarios Conectados

```rust
// Obtener conteo de usuarios online
let online_count = chat_state.connections.len();
println!("Usuarios conectados: {}", online_count);
```

### Mensajes Pendientes

```rust
// Ver mensajes en cola de Redis
let pending = chat_state.get_pending_messages(&user_id).await?;
println!("Mensajes pendientes: {}", pending.len());
```

### Estadísticas de Posts

```sql
-- Top posts por likes
SELECT id, content, likes_count, comments_count
FROM posts
ORDER BY likes_count DESC
LIMIT 10;

-- Usuarios más activos
SELECT user_id, COUNT(*) as post_count
FROM posts
GROUP BY user_id
ORDER BY post_count DESC
LIMIT 10;
```

## 🧪 Testing

### Test de Conexión WebSocket

```rust
#[tokio::test]
async fn test_websocket_connection() {
    let state = ChatState::new(test_db_pool(), test_redis_pool());
    let user_id = Uuid::new_v4();
    
    // Simular conexión
    assert!(!state.is_user_online(&user_id));
    
    // ... conectar usuario ...
    
    assert!(state.is_user_online(&user_id));
}
```

### Test de Mensaje Privado

```rust
#[tokio::test]
async fn test_private_message() {
    let state = ChatState::new(test_db_pool(), test_redis_pool());
    let sender = Uuid::new_v4();
    let receiver = Uuid::new_v4();
    
    let result = handle_private_message(
        &state,
        sender,
        receiver,
        "Test message".to_string()
    ).await;
    
    assert!(result.is_ok());
}
```

## 🚀 Despliegue

### Variables de Entorno

```bash
DATABASE_URL=postgresql://user:pass@localhost/sweetmodels
REDIS_URL=redis://localhost:6379
NATS_URL=nats://localhost:4222
JWT_SECRET=your-secret-key-here
ENCRYPTION_KEY=your-aes-256-key-here
```

### Docker Compose

```yaml
version: '3.8'
services:
  backend:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=redis://redis:6379
      - NATS_URL=nats://nats:4222
    depends_on:
      - postgres
      - redis
      - nats
  
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: sweetmodels
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
  
  redis:
    image: redis:7-alpine
  
  nats:
    image: nats:latest
```

## 📈 Escalabilidad

### Múltiples Instancias

El sistema está diseñado para escalar horizontalmente:

1. **Redis**: Cola de mensajes pendientes compartida
2. **NATS**: Broadcasting entre instancias
3. **PostgreSQL**: Base de datos centralizada
4. **DashMap**: Gestión local de conexiones por instancia

### Load Balancing

```nginx
upstream backend {
    ip_hash;  # Sticky sessions para WebSockets
    server backend1:3000;
    server backend2:3000;
    server backend3:3000;
}

server {
    location /ws/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

## 🐛 Troubleshooting

### Mensajes no se entregan

1. Verificar que el usuario está conectado: `is_user_online()`
2. Revisar cola de Redis: `get_pending_messages()`
3. Comprobar logs: `RUST_LOG=info cargo run`

### WebSocket se desconecta

1. Implementar ping/pong cada 30s
2. Verificar firewall y timeouts de proxy
3. Usar reconexión automática en el cliente

### Base de datos lenta

1. Verificar índices en tablas `messages` y `posts`
2. Usar `EXPLAIN ANALYZE` en queries lentas
3. Considerar particionamiento por fecha

## 📚 Referencias

- [Axum WebSockets](https://docs.rs/axum/latest/axum/extract/ws/index.html)
- [DashMap](https://docs.rs/dashmap/)
- [NATS Messaging](https://docs.nats.io/)
- [SQLx PostgreSQL](https://docs.rs/sqlx/)
- [AES-GCM Encryption](https://docs.rs/aes-gcm/)
