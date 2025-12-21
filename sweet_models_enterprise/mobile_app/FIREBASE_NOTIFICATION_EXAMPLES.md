# 🚀 EJEMPLOS DE NOTIFICACIONES - Firebase + Rust Backend

## 📌 Resumen

Este archivo contiene ejemplos completos de cómo enviar diferentes tipos de notificaciones desde el backend Rust al cliente Flutter.

---

## 🔗 Endpoints del Backend

### 1. Registrar Token de Dispositivo

**POST** `/api/notifications/devices/:user_id`

```bash
curl -X POST http://localhost:3000/api/notifications/devices/550e8400-e29b-41d4-a716-446655440000 \
  -H "Content-Type: application/json" \
  -d '{
    "fcm_token": "eRl_Np2gRhyXm...",
    "platform": "ANDROID",
    "device_name": "Samsung Galaxy S23 Ultra"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Token registrado exitosamente",
  "data": {
    "id": "550e8401-e29b-41d4-a716-446655440001",
    "platform": "ANDROID",
    "is_active": true,
    "created_at": "2024-12-10T15:30:00Z"
  }
}
```

---

## 📬 Ejemplos de Notificaciones

### 1️⃣ Chat Privado

**Escenario:** Juan envía un mensaje a María

**Backend (Rust):**
```rust
use crate::notifications::NotificationPayload;

let payload = NotificationPayload {
    title: "Nuevo mensaje de Juan".to_string(),
    body: "¿Hola María! ¿Cómo te va? 😊".to_string(),
    action: Some("open_chat".to_string()),
    from_user_id: Some("user_juan_123".to_string()),
    from_user_name: Some("Juan".to_string()),
    chat_id: Some("chat_maria_juan_456".to_string()),
    ..Default::default()
};

notification_service
    .send_alert("user_maria_789", payload, NotificationType::Chat)
    .await?;
```

**cURL:**
```bash
curl -X POST http://localhost:3000/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_maria_789",
    "title": "Nuevo mensaje de Juan",
    "body": "¿Hola María! ¿Cómo te va? 😊",
    "action": "open_chat",
    "from_user_id": "user_juan_123",
    "from_user_name": "Juan",
    "chat_id": "chat_maria_juan_456"
  }'
```

**Flutter Recibe:**
```dart
// 📲 Cuando la app está abierta:
// - Muestra SnackBar elegante
// - [FCM] ✅ Mensaje en foreground: msg_id_123

// 📲 Cuando toca la notificación:
// - onMessageOpenedApp se ejecuta
// - Navega a chat_maria_juan_456
// - Muestra conversación con Juan
```

---

### 2️⃣ Chat Grupal

**Escenario:** María comenta en grupo "Proyecto 2024"

**Backend (Rust):**
```rust
let payload = NotificationPayload {
    title: "Nuevo mensaje en Proyecto 2024".to_string(),
    body: "María: Vamos a empezar la grabación mañana a las 10am".to_string(),
    action: Some("open_group_chat".to_string()),
    group_id: Some("group_proyecto_2024".to_string()),
    group_name: Some("Proyecto 2024".to_string()),
    from_user_name: Some("María".to_string()),
    ..Default::default()
};

// Enviar a todos los miembros del grupo excepto María
for member_id in group_members.iter() {
    if member_id != "user_maria_789" {
        notification_service
            .send_alert(member_id, payload.clone(), NotificationType::Group)
            .await?;
    }
}
```

**cURL (para cada miembro):**
```bash
curl -X POST http://localhost:3000/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_juan_123",
    "title": "Nuevo mensaje en Proyecto 2024",
    "body": "María: Vamos a empezar la grabación mañana a las 10am",
    "action": "open_group_chat",
    "group_id": "group_proyecto_2024",
    "group_name": "Proyecto 2024",
    "from_user_name": "María"
  }'
```

---

### 3️⃣ Llamada Entrante

**Escenario:** Laura llama a Juan para hacer una sesión

**Backend (Rust):**
```rust
let payload = NotificationPayload {
    title: "Llamada de Laura".to_string(),
    body: "Laura quiere hablar contigo - Sesión disponible".to_string(),
    action: Some("answer_call".to_string()),
    from_user_id: Some("user_laura_456".to_string()),
    from_user_name: Some("Laura".to_string()),
    call_id: Some("call_abc123def".to_string()),
    call_type: Some("video_session".to_string()),
    ..Default::default()
};

notification_service
    .send_alert("user_juan_123", payload, NotificationType::Call)
    .await?;
```

**cURL:**
```bash
curl -X POST http://localhost:3000/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_juan_123",
    "title": "Llamada de Laura",
    "body": "Laura quiere hablar contigo - Sesión disponible",
    "action": "answer_call",
    "from_user_id": "user_laura_456",
    "from_user_name": "Laura",
    "call_id": "call_abc123def",
    "call_type": "video_session"
  }'
```

**Flutter Recibe:**
```dart
// 📱 Notificación del sistema
// 🔔 "Llamada de Laura"
// 
// Si toca: Abre pantalla de llamada
// - Muestra avatar de Laura
// - Botón "Aceptar" (verde)
// - Botón "Rechazar" (rojo)
```

---

### 4️⃣ Notificación de Pago

**Escenario:** Juan recibe pago por una sesión completada

**Backend (Rust):**
```rust
let payload = NotificationPayload {
    title: "💰 Pago Recibido".to_string(),
    body: "Recibiste $150 USD por sesión con Laura".to_string(),
    action: Some("show_payment".to_string()),
    amount: Some("150".to_string()),
    currency: Some("USD".to_string()),
    payment_method: Some("stripe".to_string()),
    reference_id: Some("pay_xyz789".to_string()),
    ..Default::default()
};

notification_service
    .send_alert("user_juan_123", payload, NotificationType::Payment)
    .await?;
```

**cURL:**
```bash
curl -X POST http://localhost:3000/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_juan_123",
    "title": "💰 Pago Recibido",
    "body": "Recibiste $150 USD por sesión con Laura",
    "action": "show_payment",
    "amount": "150",
    "currency": "USD",
    "payment_method": "stripe",
    "reference_id": "pay_xyz789"
  }'
```

**Flutter Recibe:**
```dart
// 🔔 Notificación con monto destacado
// Si toca: Abre pantalla de pagos
// - Muestra historial de transacciones
// - Resalta la transacción reciente
```

---

### 5️⃣ Alerta de Seguridad

**Escenario:** Se detecta intento de login no autorizado

**Backend (Rust):**
```rust
let payload = NotificationPayload {
    title: "🔒 Actividad Sospechosa Detectada".to_string(),
    body: "Intento de login desde 192.168.1.100 - Nueva York, USA".to_string(),
    action: Some("show_security_alert".to_string()),
    alert_type: Some("unauthorized_login_attempt".to_string()),
    ip_address: Some("192.168.1.100".to_string()),
    location: Some("Nueva York, USA".to_string()),
    timestamp: Some(Utc::now().to_rfc3339()),
    ..Default::default()
};

notification_service
    .send_alert("user_juan_123", payload, NotificationType::Security)
    .await?;
```

**cURL:**
```bash
curl -X POST http://localhost:3000/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_juan_123",
    "title": "🔒 Actividad Sospechosa Detectada",
    "body": "Intento de login desde 192.168.1.100 - Nueva York, USA",
    "action": "show_security_alert",
    "alert_type": "unauthorized_login_attempt",
    "ip_address": "192.168.1.100",
    "location": "Nueva York, USA"
  }'
```

---

### 6️⃣ Seguidor Nuevo

**Escenario:** Laura sigue a Juan

**Backend (Rust):**
```rust
let payload = NotificationPayload {
    title: "👤 Laura te está siguiendo".to_string(),
    body: "Laura Rodríguez (@laura.rodez) te empezó a seguir".to_string(),
    action: Some("open_profile".to_string()),
    from_user_id: Some("user_laura_456".to_string()),
    from_user_name: Some("Laura".to_string()),
    profile_image_url: Some("https://cdn.example.com/laura.jpg".to_string()),
    ..Default::default()
};

notification_service
    .send_alert("user_juan_123", payload, NotificationType::Social)
    .await?;
```

---

### 7️⃣ Post o Contenido Destacado

**Escenario:** Un post de Juan tiene muchas interacciones

**Backend (Rust):**
```rust
let payload = NotificationPayload {
    title: "🔥 Tu post es tendencia".to_string(),
    body: "Tu último post tiene 1,234 likes y 567 comentarios".to_string(),
    action: Some("open_post".to_string()),
    post_id: Some("post_juan_2024_001".to_string()),
    likes_count: Some("1234".to_string()),
    comments_count: Some("567".to_string()),
    ..Default::default()
};

notification_service
    .send_alert("user_juan_123", payload, NotificationType::Social)
    .await?;
```

---

## 🧪 Script de Prueba Completo

**`test_notifications.sh`**

```bash
#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

API="http://localhost:3000"
USER_ID="550e8400-e29b-41d4-a716-446655440000"

echo -e "${BLUE}🚀 Pruebas de Notificaciones - Sweet Models${NC}\n"

# Test 1: Chat Privado
echo -e "${BLUE}[1/7] Chat Privado...${NC}"
curl -X POST $API/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "'$USER_ID'",
    "title": "Nuevo mensaje de Juan",
    "body": "¡Hola! ¿Cómo estás?",
    "action": "open_chat",
    "from_user_id": "user_123",
    "from_user_name": "Juan",
    "chat_id": "chat_456"
  }' | jq .
echo -e "\n"

# Test 2: Llamada
echo -e "${BLUE}[2/7] Llamada Entrante...${NC}"
curl -X POST $API/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "'$USER_ID'",
    "title": "Llamada de Laura",
    "body": "Laura quiere hablar contigo",
    "action": "answer_call",
    "from_user_id": "user_789",
    "from_user_name": "Laura",
    "call_id": "call_abc123"
  }' | jq .
echo -e "\n"

# Test 3: Pago
echo -e "${BLUE}[3/7] Notificación de Pago...${NC}"
curl -X POST $API/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "'$USER_ID'",
    "title": "💰 Pago Recibido",
    "body": "Recibiste $150 USD",
    "action": "show_payment",
    "amount": "150",
    "currency": "USD"
  }' | jq .
echo -e "\n"

# Test 4: Chat Grupal
echo -e "${BLUE}[4/7] Chat Grupal...${NC}"
curl -X POST $API/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "'$USER_ID'",
    "title": "Nuevo mensaje en Trabajo",
    "body": "María: Grabamos mañana a las 10am",
    "action": "open_group_chat",
    "group_id": "group_789",
    "group_name": "Trabajo"
  }' | jq .
echo -e "\n"

# Test 5: Seguridad
echo -e "${BLUE}[5/7] Alerta de Seguridad...${NC}"
curl -X POST $API/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "'$USER_ID'",
    "title": "🔒 Actividad Sospechosa",
    "body": "Intento de login desde Nueva York",
    "action": "show_security_alert",
    "alert_type": "unauthorized_login"
  }' | jq .
echo -e "\n"

# Test 6: Seguidor
echo -e "${BLUE}[6/7] Seguidor Nuevo...${NC}"
curl -X POST $API/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "'$USER_ID'",
    "title": "👤 Laura te está siguiendo",
    "body": "Laura Rodríguez te empezó a seguir",
    "action": "open_profile",
    "from_user_id": "user_456",
    "from_user_name": "Laura"
  }' | jq .
echo -e "\n"

# Test 7: Historial
echo -e "${BLUE}[7/7] Obtener Historial de Notificaciones...${NC}"
curl -X GET "$API/api/notifications/history/$USER_ID?limit=10" | jq .
echo -e "\n"

echo -e "${GREEN}✅ Pruebas completadas${NC}"
```

---

## 📊 Payload Completo (Estructura)

```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Nuevo mensaje",
  "body": "Este es el cuerpo",
  "action": "open_chat",
  "from_user_id": "user_123",
  "from_user_name": "Juan",
  "chat_id": "chat_456",
  "group_id": "group_789",
  "group_name": "Trabajo",
  "call_id": "call_abc123",
  "call_type": "video_session",
  "amount": "150",
  "currency": "USD",
  "payment_method": "stripe",
  "reference_id": "pay_xyz789",
  "alert_type": "unauthorized_login",
  "ip_address": "192.168.1.100",
  "location": "Nueva York, USA",
  "post_id": "post_123",
  "likes_count": "1234",
  "comments_count": "567"
}
```

---

## ✅ Checklist de Prueba

- [ ] Notificación llega cuando app está abierta → muestra SnackBar
- [ ] Notificación llega cuando app está cerrada → muestra en sistema
- [ ] Tocar notificación abierta → navega al destino correcto
- [ ] Token se registra en BD → SELECT FROM device_tokens
- [ ] múltiples dispositivos reciben notificaciones
- [ ] Notificaciones incluyen payload correcto
- [ ] Los emojis se muestran correctamente
- [ ] Las acciones de deep linking funcionan

---

## 🔗 Referencias

- Backend Rust: `/sweet_models_enterprise/backend_api/src/notifications/mod.rs`
- Flutter Service: `/sweet_models_enterprise/mobile_app/lib/services/push_notification_service.dart`
- Ejemplos Screen: `/sweet_models_enterprise/mobile_app/lib/screens/push_notification_example_screen.dart`
