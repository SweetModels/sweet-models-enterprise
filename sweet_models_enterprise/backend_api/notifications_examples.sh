#!/bin/bash
# Script de ejemplos cURL para el servicio de Push Notifications
# Uso: bash notifications_examples.sh

BASE_URL="http://localhost:3000/api/notifications"

# Color codes para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Push Notifications Service - Examples ===${NC}\n"

# ============================================================================
# EJEMPLO 1: Registrar un dispositivo Android
# ============================================================================
echo -e "${YELLOW}1. Registrando dispositivo Android...${NC}"
curl -X POST "$BASE_URL/devices/550e8400-e29b-41d4-a716-446655440000" \
  -H "Content-Type: application/json" \
  -d '{
    "fcm_token": "eoJ2RW2sDQ8:APA91bHrq_12345abcdef",
    "platform": "ANDROID",
    "device_name": "Samsung Galaxy S21"
  }' | jq .

echo -e "\n${GREEN}✓ Dispositivo Android registrado${NC}\n"

# ============================================================================
# EJEMPLO 2: Registrar un dispositivo iOS
# ============================================================================
echo -e "${YELLOW}2. Registrando dispositivo iOS...${NC}"
curl -X POST "$BASE_URL/devices/550e8400-e29b-41d4-a716-446655440000" \
  -H "Content-Type: application/json" \
  -d '{
    "fcm_token": "d6f2e1c9d8b7a6f5e4d3c2b1a0f9e8d7c6b5a4f",
    "platform": "IOS",
    "device_name": "iPhone 14 Pro"
  }' | jq .

echo -e "\n${GREEN}✓ Dispositivo iOS registrado${NC}\n"

# ============================================================================
# EJEMPLO 3: Enviar notificación de mensaje
# ============================================================================
echo -e "${YELLOW}3. Enviando notificación de nuevo mensaje...${NC}"
curl -X POST "$BASE_URL/send" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Nuevo mensaje de Juan García",
    "body": "Hola, ¿cómo estás? ¿Quieres salir mañana?",
    "notification_type": "message",
    "data": {
      "from_user_id": "550e8400-e29b-41d4-a716-446655440001",
      "from_user_name": "Juan García",
      "chat_type": "direct_message",
      "action": "open_chat"
    }
  }' | jq .

echo -e "\n${GREEN}✓ Notificación de mensaje enviada${NC}\n"

# ============================================================================
# EJEMPLO 4: Enviar notificación de llamada entrante
# ============================================================================
echo -e "${YELLOW}4. Enviando notificación de llamada entrante...${NC}"
curl -X POST "$BASE_URL/send" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Llamada de María López",
    "body": "Pulsa para responder",
    "notification_type": "incoming_call",
    "data": {
      "from_user_id": "550e8400-e29b-41d4-a716-446655440002",
      "from_user_name": "María López",
      "call_type": "incoming",
      "action": "answer_call"
    }
  }' | jq .

echo -e "\n${GREEN}✓ Notificación de llamada enviada${NC}\n"

# ============================================================================
# EJEMPLO 5: Enviar notificación de mensaje de grupo
# ============================================================================
echo -e "${YELLOW}5. Enviando notificación de mensaje de grupo...${NC}"
curl -X POST "$BASE_URL/send" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Nuevo mensaje en Proyecto Q4 2025",
    "body": "Carlos: Acabo de finalizar el módulo de autenticación",
    "notification_type": "group_message",
    "data": {
      "from_user_id": "550e8400-e29b-41d4-a716-446655440003",
      "from_user_name": "Carlos",
      "group_id": "550e8400-e29b-41d4-a716-446655440010",
      "group_name": "Proyecto Q4 2025",
      "chat_type": "group_message"
    }
  }' | jq .

echo -e "\n${GREEN}✓ Notificación de grupo enviada${NC}\n"

# ============================================================================
# EJEMPLO 6: Enviar notificación de pago
# ============================================================================
echo -e "${YELLOW}6. Enviando notificación de pago...${NC}"
curl -X POST "$BASE_URL/send" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Pago recibido",
    "body": "Recibiste $150.50 USDT de Juan García",
    "notification_type": "payment",
    "data": {
      "amount": "150.50",
      "currency": "USDT",
      "from_user": "Juan García",
      "transaction_id": "txn_abc123xyz789"
    }
  }' | jq .

echo -e "\n${GREEN}✓ Notificación de pago enviada${NC}\n"

# ============================================================================
# EJEMPLO 7: Enviar notificación de seguridad
# ============================================================================
echo -e "${YELLOW}7. Enviando alerta de seguridad...${NC}"
curl -X POST "$BASE_URL/send" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Intento de acceso inusual",
    "body": "Se detectó acceso desde Nueva York a las 10:45 AM",
    "notification_type": "security",
    "data": {
      "event_type": "suspicious_login",
      "location": "New York, NY",
      "device": "Chrome on Windows",
      "timestamp": "2025-12-09T10:45:00Z"
    }
  }' | jq .

echo -e "\n${GREEN}✓ Alerta de seguridad enviada${NC}\n"

# ============================================================================
# EJEMPLO 8: Obtener historial de notificaciones
# ============================================================================
echo -e "${YELLOW}8. Obteniendo historial de notificaciones (últimas 10)...${NC}"
curl -X GET "$BASE_URL/550e8400-e29b-41d4-a716-446655440000/history/10" \
  -H "Content-Type: application/json" | jq .

echo -e "\n${GREEN}✓ Historial obtenido${NC}\n"

# ============================================================================
# EJEMPLO 9: Limpiar tokens expirados
# ============================================================================
echo -e "${YELLOW}9. Limpiando tokens expirados (> 30 días sin usar)...${NC}"
curl -X POST "$BASE_URL/cleanup" \
  -H "Content-Type: application/json" | jq .

echo -e "\n${GREEN}✓ Limpieza completada${NC}\n"

# ============================================================================
# EJEMPLO 10: Registrar dispositivo Web
# ============================================================================
echo -e "${YELLOW}10. Registrando dispositivo Web/PWA...${NC}"
curl -X POST "$BASE_URL/devices/550e8400-e29b-41d4-a716-446655440000" \
  -H "Content-Type: application/json" \
  -d '{
    "fcm_token": "fPqy9OjE_1w:APA91bFx7K-web-push-token-example",
    "platform": "WEB",
    "device_name": "Chrome en MacBook"
  }' | jq .

echo -e "\n${GREEN}✓ Dispositivo Web registrado${NC}\n"

# ============================================================================
# EJEMPLO 11: Enviar notificación personalizada sin datos
# ============================================================================
echo -e "${YELLOW}11. Enviando notificación simple sin datos adicionales...${NC}"
curl -X POST "$BASE_URL/send" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Recordatorio",
    "body": "No olvides completar tu perfil KYC",
    "notification_type": "reminder",
    "data": null
  }' | jq .

echo -e "\n${GREEN}✓ Notificación simple enviada${NC}\n"

# ============================================================================
# EJEMPLO 12: Enviar notificación con muchos datos
# ============================================================================
echo -e "${YELLOW}12. Enviando notificación con datos complejos...${NC}"
curl -X POST "$BASE_URL/send" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Oferta especial",
    "body": "Obtén 20% de descuento en tu próxima transacción",
    "notification_type": "promotion",
    "data": {
      "discount_percentage": "20",
      "code": "SWEET20",
      "valid_until": "2025-12-31T23:59:59Z",
      "categories": "payments,transfers,withdrawals",
      "min_amount": "50.00",
      "redirect_url": "app://promotions/sweet20"
    }
  }' | jq .

echo -e "\n${GREEN}✓ Notificación con oferta especial enviada${NC}\n"

# ============================================================================
# RESUMEN
# ============================================================================
echo -e "${BLUE}=== Resumen de ejemplos ===${NC}"
echo -e "${GREEN}✓${NC} Registrar dispositivos (Android, iOS, Web)"
echo -e "${GREEN}✓${NC} Enviar notificaciones personalizadas"
echo -e "${GREEN}✓${NC} Casos de uso: mensajes, llamadas, pagos, seguridad"
echo -e "${GREEN}✓${NC} Obtener historial"
echo -e "${GREEN}✓${NC} Limpieza de tokens"
echo -e "\n${YELLOW}Próximos pasos:${NC}"
echo "1. Verificar que el servidor esté corriendo en http://localhost:3000"
echo "2. Actualizar los UUIDs con valores reales"
echo "3. Verificar base de datos para los registros"
echo "4. Revisar notification_logs para ver auditoría"
echo -e "\n${BLUE}¡Listo para usar! 🚀${NC}\n"
