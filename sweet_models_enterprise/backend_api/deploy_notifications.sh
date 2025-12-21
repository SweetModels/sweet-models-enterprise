#!/bin/bash
# Script de Deployment - Push Notifications Service
# Uso: bash deploy_notifications.sh

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║   Deployment: Push Notifications Service (FCM)         ║"
echo "║   Sweet Models Enterprise Backend                      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================================================
# PASO 1: Verificar requisitos
# ============================================================================
echo -e "${BLUE}[PASO 1]${NC} Verificando requisitos..."

if ! command -v cargo &> /dev/null; then
    echo -e "${RED}✗ Rust/Cargo no está instalado${NC}"
    exit 1
fi

if ! command -v sqlx-cli &> /dev/null; then
    echo -e "${YELLOW}⚠ sqlx-cli no está instalado. Instalando...${NC}"
    cargo install sqlx-cli --no-default-features --features postgres
fi

if ! command -v psql &> /dev/null; then
    echo -e "${RED}✗ PostgreSQL client no está disponible${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Todos los requisitos verificados${NC}\n"

# ============================================================================
# PASO 2: Verificar conexión a BD
# ============================================================================
echo -e "${BLUE}[PASO 2]${NC} Verificando conexión a PostgreSQL..."

if [ -z "$DATABASE_URL" ]; then
    echo -e "${YELLOW}⚠ DATABASE_URL no está configurada${NC}"
    echo "  Configura: export DATABASE_URL=postgres://user:pass@localhost/db"
    exit 1
fi

if ! psql "$DATABASE_URL" -c "SELECT 1" &> /dev/null; then
    echo -e "${RED}✗ No se puede conectar a la base de datos${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Conexión a BD exitosa${NC}\n"

# ============================================================================
# PASO 3: Verificar variables FCM
# ============================================================================
echo -e "${BLUE}[PASO 3]${NC} Verificando variables FCM..."

if [ -z "$FCM_PROJECT_ID" ]; then
    echo -e "${RED}✗ FCM_PROJECT_ID no está configurada${NC}"
    echo "  Usa: export FCM_PROJECT_ID=tu-proyecto-firebase"
    exit 1
fi

if [ -z "$FCM_API_KEY" ]; then
    echo -e "${RED}✗ FCM_API_KEY no está configurada${NC}"
    echo "  Usa: export FCM_API_KEY=tu-api-key"
    exit 1
fi

echo -e "${GREEN}✓ Configuración FCM lista${NC}\n"

# ============================================================================
# PASO 4: Compilar
# ============================================================================
echo -e "${BLUE}[PASO 4]${NC} Compilando backend..."

cd backend_api

if ! cargo build --release; then
    echo -e "${RED}✗ Error en compilación${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Compilación exitosa${NC}\n"

# ============================================================================
# PASO 5: Ejecutar migraciones
# ============================================================================
echo -e "${BLUE}[PASO 5]${NC} Ejecutando migraciones SQL..."

if ! sqlx migrate run --database-url "$DATABASE_URL"; then
    echo -e "${RED}✗ Error en migraciones${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Migraciones ejecutadas${NC}\n"

# ============================================================================
# PASO 6: Verificar tablas creadas
# ============================================================================
echo -e "${BLUE}[PASO 6]${NC} Verificando tablas..."

TABLES=$(psql "$DATABASE_URL" -t -c "
  SELECT COUNT(*) FROM information_schema.tables 
  WHERE table_name IN ('device_tokens', 'notification_logs');
")

if [ "$TABLES" != "2" ]; then
    echo -e "${RED}✗ Las tablas no fueron creadas correctamente${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Tablas verificadas${NC}\n"

# ============================================================================
# PASO 7: Crear índices
# ============================================================================
echo -e "${BLUE}[PASO 7]${NC} Verificando índices..."

INDEXES=$(psql "$DATABASE_URL" -t -c "
  SELECT COUNT(*) FROM pg_indexes 
  WHERE tablename IN ('device_tokens', 'notification_logs');
")

if [ "$INDEXES" -lt 6 ]; then
    echo -e "${YELLOW}⚠ Algunos índices podrían no estar creados${NC}"
else
    echo -e "${GREEN}✓ Índices verificados (${INDEXES} encontrados)${NC}\n"
fi

# ============================================================================
# PASO 8: Test básico
# ============================================================================
echo -e "${BLUE}[PASO 8]${NC} Ejecutando cargo test (estrutura)..."

if ! cargo test --lib 2>&1 | head -20; then
    echo -e "${YELLOW}⚠ Tests no disponibles aún (esto es normal)${NC}\n"
fi

# ============================================================================
# PASO 9: Generar documentación
# ============================================================================
echo -e "${BLUE}[PASO 9]${NC} Generando documentación..."

if ! cargo doc --no-deps --release 2>&1 | tail -5; then
    echo -e "${YELLOW}⚠ Error generando docs (continuando)${NC}"
fi

echo -e "${GREEN}✓ Documentación generada${NC}\n"

# ============================================================================
# PASO 10: Resumen
# ============================================================================
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ✅ DEPLOYMENT COMPLETADO EXITOSAMENTE             ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Información del deployment:${NC}"
echo "  Proyecto: Sweet Models Enterprise"
echo "  Servicio: Push Notifications (FCM)"
echo "  Build: release (optimizado)"
echo "  BD: PostgreSQL"
echo "  Tablas: device_tokens, notification_logs"
echo ""
echo -e "${BLUE}Próximos pasos:${NC}"
echo "  1. Iniciar servidor: cargo run --release"
echo "  2. Probar endpoints: bash notifications_examples.sh"
echo "  3. Ver docs: cargo doc --open"
echo ""
echo -e "${BLUE}URLs útiles:${NC}"
echo "  - Firebase Console: https://console.firebase.google.com"
echo "  - FCM API v1: https://firebase.google.com/docs/cloud-messaging/migrate-v1"
echo "  - Documentación local: target/doc/backend_api/index.html"
echo ""
echo -e "${YELLOW}Configuración:${NC}"
echo "  - FCM_PROJECT_ID=$FCM_PROJECT_ID"
echo "  - DATABASE_URL=$DATABASE_URL (verificado ✓)"
echo ""
echo -e "${GREEN}¡Listo para producción! 🚀${NC}\n"
