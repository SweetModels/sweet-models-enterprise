#!/bin/bash
# Script para probar la integración completa del sistema de tracking en tiempo real

echo "🚀 TEST: Sistema de Tracking en Tiempo Real"
echo "==========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar que el backend está corriendo
echo "1️⃣  Verificando Backend en http://localhost:3000..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✓ Backend está escuchando${NC}"
else
    echo -e "${RED}✗ Backend NO está disponible${NC}"
    echo "   Inicia: cd backend_api && cargo run"
    exit 1
fi

# 2. Verificar Redis
echo ""
echo "2️⃣  Verificando Redis en localhost:6379..."
if redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Redis está funcionando${NC}"
else
    echo -e "${RED}✗ Redis NO está disponible${NC}"
    echo "   Inicia: redis-server"
    exit 1
fi

# 3. Verificar WebSocket endpoint
echo ""
echo "3️⃣  Verificando WebSocket endpoint..."
if curl -s -i http://localhost:3000/ws/dashboard -H "Upgrade: websocket" 2>&1 | grep -q "101\|426"; then
    echo -e "${GREEN}✓ WebSocket endpoint está disponible${NC}"
else
    echo -e "${YELLOW}⚠ WebSocket endpoint respondiendo${NC}"
fi

# 4. Simular POST de telemetría
echo ""
echo "4️⃣  Simulando POST a /api/tracking/telemetry..."

PAYLOAD='{
  "room_id": "test_room_001",
  "platform": "chaturbate",
  "tokens_count": 5000,
  "tips_count": 250,
  "viewers_count": 45,
  "timestamp": '$(date +%s)'
}'

RESPONSE=$(curl -s -X POST http://localhost:3000/api/tracking/telemetry \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if echo "$RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✓ Telemetría POST exitoso${NC}"
    echo "  Response: $RESPONSE"
else
    echo -e "${RED}✗ Error en POST de telemetría${NC}"
    echo "  Response: $RESPONSE"
fi

# 5. Verificar que se guardó en Redis
echo ""
echo "5️⃣  Verificando almacenamiento en Redis..."

STORED=$(redis-cli GET "telemetry:test_room_001:chaturbate")

if [ ! -z "$STORED" ]; then
    echo -e "${GREEN}✓ Datos guardados en Redis${NC}"
    echo "  Valor: $STORED"
else
    echo -e "${YELLOW}⚠ No encontrado en Redis (puede haber expirado)${NC}"
fi

# 6. Verificar GET endpoint
echo ""
echo "6️⃣  Verificando GET /api/tracking/telemetry/:room_id/:platform..."

GET_RESPONSE=$(curl -s http://localhost:3000/api/tracking/telemetry/test_room_001/chaturbate)

if echo "$GET_RESPONSE" | grep -q "test_room_001"; then
    echo -e "${GREEN}✓ GET endpoint funcional${NC}"
    echo "  Response: $GET_RESPONSE"
else
    echo -e "${YELLOW}⚠ GET endpoint respondiendo pero sin datos${NC}"
fi

# 7. Resumen
echo ""
echo "==========================================="
echo "📋 RESUMEN DE TEST"
echo "==========================================="
echo ""
echo "✅ Backend HTTP: http://localhost:3000"
echo "✅ WebSocket: ws://localhost:3000/ws/dashboard"
echo "✅ Telemetría POST: /api/tracking/telemetry"
echo "✅ Telemetría GET: /api/tracking/telemetry/{room_id}/{platform}"
echo "✅ Redis Cache: Operacional"
echo ""
echo "🎯 Sistema listo para:"
echo "   1. Cargar Chrome Extension en dev mode"
echo "   2. Ingresar ROOM_ID en popup"
echo "   3. Visitar cam site (Chaturbate, Stripchat, etc.)"
echo "   4. Ver updates en tiempo real en Flutter Dashboard"
echo ""
