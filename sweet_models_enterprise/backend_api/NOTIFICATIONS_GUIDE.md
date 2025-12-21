/// GUÍA DE USO: SERVICIO DE PUSH NOTIFICATIONS (FCM)
/// =================================================
///
/// Este archivo documenta cómo integrar y usar el servicio de Push Notifications
/// basado en Firebase Cloud Messaging (FCM) HTTP v1 API.

// ============================================================================
// PASO 1: CONFIGURACIÓN INICIAL
// ============================================================================
//
// 1.1 Variables de entorno requeridas en .env:
//
//     FCM_PROJECT_ID=mi-proyecto-firebase
//     FCM_API_KEY=clave-de-servicio-firebase
//
// 1.2 Crear archivo de configuración (config.rs):
//
//     pub fn fcm_project_id() -> String {
//         std::env::var("FCM_PROJECT_ID")
//             .expect("FCM_PROJECT_ID no está configurado")
//     }
//
//     pub fn fcm_api_key() -> String {
//         std::env::var("FCM_API_KEY")
//             .expect("FCM_API_KEY no está configurado")
//     }

// ============================================================================
// PASO 2: INICIALIZAR SERVICIO EN MAIN.RS
// ============================================================================
//
// En el main.rs de tu aplicación:
//
//     use std::sync::Arc;
//     use backend_api::notifications::NotificationService;
//     use backend_api::config::{fcm_project_id, fcm_api_key};
//
//     #[tokio::main]
//     async fn main() -> Result<(), DynError> {
//         let db = setup_database().await?;
//
//         // Crear servicio de notificaciones
//         let notification_service = Arc::new(
//             NotificationService::new(
//                 db.clone(),
//                 fcm_project_id(),
//                 fcm_api_key(),
//             )
//         );
//
//         // Pasar a los handlers...
//     }

// ============================================================================
// PASO 3: ENDPOINTS HTTP
// ============================================================================

// 3.1 REGISTRAR DISPOSITIVO (POST /api/notifications/devices/:user_id)
//
//     POST /api/notifications/devices/550e8400-e29b-41d4-a716-446655440000
//     Content-Type: application/json
//
//     {
//         "fcm_token": "eoJ2RW2sDQ...", // Token del dispositivo
//         "platform": "ANDROID",         // ANDROID | IOS | WEB
//         "device_name": "iPhone 14"     // Opcional
//     }
//
//     Respuesta exitosa (201):
//     {
//         "success": true,
//         "message": "Dispositivo registrado exitosamente",
//         "data": {
//             "id": "550e8400-e29b-41d4-a716-446655440001",
//             "platform": "ANDROID",
//             "is_active": true,
//             "created_at": "2025-12-09T12:00:00Z"
//         }
//     }

// 3.2 ENVIAR NOTIFICACIÓN (POST /api/notifications/send)
//
//     POST /api/notifications/send
//     Content-Type: application/json
//
//     {
//         "user_id": "550e8400-e29b-41d4-a716-446655440000",
//         "title": "Nuevo mensaje de Juan",
//         "body": "¿Hola, cómo estás?",
//         "notification_type": "message",
//         "data": {
//             "from_user_id": "550e8400-e29b-41d4-a716-446655440002",
//             "chat_type": "direct_message"
//         }
//     }
//
//     Respuesta exitosa (200):
//     {
//         "success": true,
//         "message": "Notificación enviada a 2 dispositivos",
//         "data": {
//             "tokens_sent": 2,
//             "devices": [
//                 "eoJ2RW2sDQ...",
//                 "eoJ2RW2sDE..."
//             ]
//         }
//     }

// 3.3 OBTENER HISTORIAL DE NOTIFICACIONES (GET /api/notifications/:user_id/history/:limit)
//
//     GET /api/notifications/550e8400-e29b-41d4-a716-446655440000/history/10
//
//     Respuesta (200):
//     {
//         "success": true,
//         "message": "Historial obtenido",
//         "data": [
//             {
//                 "id": "...",
//                 "user_id": "...",
//                 "notification_type": "message",
//                 "title": "Nuevo mensaje de Juan",
//                 "body": "¿Hola, cómo estás?",
//                 "status": "SENT",
//                 "sent_at": "2025-12-09T12:00:00Z",
//                 "created_at": "2025-12-09T12:00:00Z"
//             }
//         ]
//     }

// 3.4 LIMPIAR TOKENS EXPIRADOS (POST /api/notifications/cleanup)
//
//     POST /api/notifications/cleanup
//
//     Respuesta (200):
//     {
//         "success": true,
//         "message": "5 tokens desactivados",
//         "data": {
//             "cleaned": 5
//         }
//     }

// ============================================================================
// PASO 4: INTEGRACIÓN CON CHAT (NOTIFICACIONES AUTOMÁTICAS)
// ============================================================================
//
// En tu handler de mensajes de chat:
//
//     use backend_api::social::chat_notifications::{
//         ChatNotificationManager,
//         ChatMessage,
//     };
//
//     pub async fn send_message_handler(
//         State(notification_service): State<Arc<NotificationService>>,
//         Json(payload): Json<MessagePayload>,
//     ) -> impl IntoResponse {
//         // 1. Guardar mensaje en BD
//         let message_id = save_message(&payload).await?;
//
//         // 2. Crear gestor de notificaciones de chat
//         let chat_notifier = ChatNotificationManager::new(
//             notification_service.clone(),
//         );
//
//         // 3. Preparar mensaje
//         let chat_msg = ChatMessage {
//             from_user_id: payload.from_id,
//             to_user_id: payload.to_id,
//             from_user_name: "Juan".to_string(),
//             content: payload.content.clone(),
//             timestamp: Utc::now(),
//         };
//
//         // 4. Obtener usuarios conectados al WebSocket
//         let connected_users = get_connected_users(); // Tu lógica
//
//         // 5. Enviar notificación si el usuario está offline
//         if let Err(e) = chat_notifier
//             .notify_if_offline(chat_msg, &connected_users)
//             .await
//         {
//             eprintln!("Error enviando notificación: {}", e);
//         }
//
//         Ok(Json(json!({ "status": "ok", "message_id": message_id })))
//     }

// ============================================================================
// PASO 5: NOTIFICACIONES PERSONALIZADAS
// ============================================================================

// 5.1 Llamadas entrantes:
//
//     let chat_notifier = ChatNotificationManager::new(notification_service);
//     chat_notifier.notify_incoming_call(
//         from_user_id,
//         "María García".to_string(),
//         to_user_id,
//     ).await?;

// 5.2 Mensajes de grupo:
//
//     chat_notifier.notify_group_message(
//         group_id,
//         from_user_id,
//         "Carlos".to_string(),
//         "Nuevo proyecto...".to_string(),
//         vec![user_a, user_b, user_c], // Recipients
//         &connected_users,
//     ).await?;

// 5.3 Reacciones a mensajes:
//
//     chat_notifier.notify_message_reaction(
//         from_user_id,
//         "Ana".to_string(),
//         to_user_id,
//         "❤️".to_string(),
//     ).await?;

// ============================================================================
// PASO 6: MANEJO DE ERRORES
// ============================================================================
//
// El servicio maneja automáticamente:
// - Tokens expirados/inválidos: Se desactivan automáticamente
// - Fallos de conexión: Se registran en notification_logs
// - Usuarios sin dispositivos: Retorna error específico
//
// Log de errores en BD:
// - status = "FAILED"
// - error_message = detalles del error

// ============================================================================
// PASO 7: TESTING
// ============================================================================
//
// Ejemplo de test unitario:
//
//     #[tokio::test]
//     async fn test_send_notification() {
//         let db = setup_test_db().await;
//         let service = NotificationService::new(
//             db,
//             "test-project".to_string(),
//             "test-api-key".to_string(),
//         );
//
//         let result = service.send_alert(
//             user_id,
//             "Prueba".to_string(),
//             "Contenido de prueba".to_string(),
//             None,
//             "test",
//         ).await;
//
//         assert!(result.is_ok());
//     }

// ============================================================================
// PASO 8: CRON JOBS (LIMPIEZA)
// ============================================================================
//
// Ejecutar cada 30 días para limpiar tokens obsoletos:
//
//     let notif_service = notification_service.clone();
//     tokio::spawn(async move {
//         loop {
//             tokio::time::sleep(Duration::from_secs(30 * 24 * 60 * 60)).await;
//             if let Err(e) = notif_service.cleanup_stale_tokens().await {
//                 eprintln!("Error limpiando tokens: {}", e);
//             }
//         }
//     });

// ============================================================================
// TIPOS DE NOTIFICACIONES SOPORTADAS
// ============================================================================
//
// - "message":          Nuevo mensaje de chat directo
// - "group_message":    Mensaje en grupo
// - "incoming_call":    Llamada entrante
// - "message_reaction": Reacción a un mensaje
// - "payment":          Notificación de pago
// - "security":         Alerta de seguridad
// - "custom":           Personalizada

// ============================================================================
// PLATAFORMAS SOPORTADAS
// ============================================================================
//
// - ANDROID:  Usar FCM Android config con HIGH priority
// - IOS:      Usar APNS config con silent push + alert
// - WEB:      Usar Webpush config con headers TTL

// ============================================================================
// ESTRUCTURA DE BD
// ============================================================================
//
// Tabla: device_tokens
// - id (UUID, PK)
// - user_id (UUID, FK -> users)
// - fcm_token (TEXT, unique con user_id)
// - platform (VARCHAR: ANDROID, IOS, WEB)
// - device_name (VARCHAR, opcional)
// - is_active (BOOLEAN, default true)
// - created_at (TIMESTAMP)
// - last_updated (TIMESTAMP)
// - last_used (TIMESTAMP, nullable)
//
// Tabla: notification_logs
// - id (UUID, PK)
// - user_id (UUID, FK -> users)
// - device_token_id (UUID, FK -> device_tokens, nullable)
// - notification_type (VARCHAR: message, call, etc)
// - title (VARCHAR 255)
// - body (TEXT)
// - data (JSONB, nullable)
// - status (VARCHAR: PENDING, SENT, FAILED, EXPIRED)
// - error_message (TEXT, nullable)
// - sent_at (TIMESTAMP, nullable)
// - created_at (TIMESTAMP)

// ============================================================================
// COSTO & LÍMITES
// ============================================================================
//
// Firebase Cloud Messaging (FCM) es GRATIS
// - Notificaciones ilimitadas
// - API v1 es la recomendada
// - No hay límite de dispositivos por usuario

// ============================================================================
