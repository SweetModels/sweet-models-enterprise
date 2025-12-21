/// Ejemplo de integración del servicio de notificaciones en main.rs
/// Este archivo muestra cómo agregar los routes y handlers al servidor principal.

/*

// En main.rs, agregar las importaciones:

use std::sync::Arc;
use backend_api::notifications::NotificationService;
use backend_api::notifications::handlers::{
    register_device_handler,
    send_notification_handler,
    get_notification_history_handler,
    cleanup_tokens_handler,
};

// En la función main(), después de crear el pool de base de datos:

#[tokio::main]
async fn main() -> Result<(), DynError> {
    // ... código existente ...

    // 1. Crear servicio de notificaciones
    let notification_service = Arc::new(
        NotificationService::new(
            db.clone(),
            std::env::var("FCM_PROJECT_ID")
                .expect("FCM_PROJECT_ID environment variable must be set"),
            std::env::var("FCM_API_KEY")
                .expect("FCM_API_KEY environment variable must be set"),
        )
    );

    // 2. Crear rutas de notificaciones
    let notifications_routes = Router::new()
        .route(
            "/api/notifications/devices/:user_id",
            post(register_device_handler)
                .with_state(notification_service.clone()),
        )
        .route(
            "/api/notifications/send",
            post(send_notification_handler)
                .with_state(notification_service.clone()),
        )
        .route(
            "/api/notifications/:user_id/history/:limit",
            get(get_notification_history_handler)
                .with_state(notification_service.clone()),
        )
        .route(
            "/api/notifications/cleanup",
            post(cleanup_tokens_handler)
                .with_state(notification_service.clone()),
        );

    // 3. Agregar al router principal
    let app = Router::new()
        .nest("/", notifications_routes)
        .nest("/api/finance", finance::routes(db.clone()))
        .nest("/api/social", social::social_routes())
        .nest("/ws", social::social_routes_chat())
        // ... otros routes ...
        .layer(cors_layer)
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(DefaultMakeSpan::new().include_headers(true)),
        );

    // 4. OPCIONAL: Ejecutar limpieza de tokens cada 30 días
    {
        let notif_service = notification_service.clone();
        tokio::spawn(async move {
            use std::time::Duration;
            loop {
                tokio::time::sleep(Duration::from_secs(30 * 24 * 60 * 60)).await;
                match notif_service.cleanup_stale_tokens().await {
                    Ok(count) => {
                        println!("[NOTIFICATIONS] {} tokens obsoletos desactivados", count);
                    }
                    Err(e) => {
                        eprintln!("[NOTIFICATIONS] Error en limpieza: {}", e);
                    }
                }
            }
        });
    }

    // 5. Iniciar servidor
    let listener = TcpListener::bind("0.0.0.0:3000").await?;
    tracing::info!("Servidor escuchando en puerto 3000");
    axum::serve(listener, app).await?;

    Ok(())
}

*/

// ============================================================================
// EJEMPLO: USO EN HANDLER DE CHAT
// ============================================================================

/*

use backend_api::social::chat_notifications::{
    ChatNotificationManager,
    ChatMessage,
};
use chrono::Utc;
use std::collections::HashMap;
use uuid::Uuid;

#[derive(Deserialize)]
pub struct SendMessageRequest {
    from_id: Uuid,
    to_id: Uuid,
    content: String,
}

pub async fn send_message_handler(
    State(notification_service): State<Arc<NotificationService>>,
    State(connected_users): State<Arc<RwLock<HashMap<Uuid, bool>>>>,
    Json(payload): Json<SendMessageRequest>,
) -> impl IntoResponse {
    // 1. Guardar mensaje en la base de datos
    // (Tu lógica aquí...)
    let message_id = Uuid::new_v4();

    // 2. Crear gestor de notificaciones
    let chat_notifier = ChatNotificationManager::new(
        notification_service.clone(),
    );

    // 3. Preparar información del mensaje
    let chat_msg = ChatMessage {
        from_user_id: payload.from_id,
        to_user_id: payload.to_id,
        from_user_name: "Usuario".to_string(), // Obtener del DB
        content: payload.content.clone(),
        timestamp: Utc::now(),
    };

    // 4. Obtener usuarios conectados al WebSocket
    let connected = connected_users.read().await.clone();

    // 5. Enviar notificación si el usuario no está conectado
    if let Err(e) = chat_notifier.notify_if_offline(chat_msg, &connected).await {
        eprintln!("Error notificando usuario: {}", e);
        // No fallar la operación si la notificación falla
    }

    (
        StatusCode::CREATED,
        Json(json!({
            "status": "ok",
            "message_id": message_id,
        })),
    )
}

*/

// ============================================================================
// EJEMPLO: REGISTRAR DISPOSITIVO EN FLUTTER
// ============================================================================

/*
// En Flutter, después de obtener el token FCM:

import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static Future<void> initializeNotifications(String userId) async {
    final fcm = FirebaseMessaging.instance;
    
    // Obtener token
    String? token = await fcm.getToken();
    
    if (token != null) {
      // Registrar en backend
      await registerDeviceToken(
        userId: userId,
        token: token,
        platform: 'ANDROID', // o 'IOS'
        deviceName: 'Mi dispositivo',
      );
    }
  }
  
  static Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
    required String deviceName,
  }) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/notifications/devices/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fcm_token': token,
        'platform': platform,
        'device_name': deviceName,
      }),
    );
    
    if (response.statusCode == 201) {
      print('Dispositivo registrado correctamente');
    }
  }
}

// En main.dart:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Inicializar notificaciones después de login
  String userId = await AuthService.getUserId();
  await NotificationService.initializeNotifications(userId);
  
  runApp(MyApp());
}
*/

// ============================================================================
// VARIABLES DE ENTORNO (.env)
// ============================================================================

/*
# Firebase Cloud Messaging Configuration
FCM_PROJECT_ID=my-firebase-project
FCM_API_KEY=AIzaSyD...rest-of-api-key

# O usar Service Account JSON (alternativa más segura):
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
*/

// ============================================================================
// MIGRACIONES SQL (Ya incluidas en 20251209000002_create_device_tokens.sql)
// ============================================================================

/*
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('ANDROID', 'IOS', 'WEB')),
    device_name VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP,
    UNIQUE(user_id, fcm_token)
);

CREATE TABLE notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token_id UUID REFERENCES device_tokens(id) ON DELETE SET NULL,
    notification_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    error_message TEXT,
    sent_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
*/

pub fn example_placeholder() {
    // Este archivo solo contiene ejemplos y documentación
    // No es código ejecutable, es una referencia de integración
}
