#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# OMNI-GENESIS BACKUP PROTOCOL
# Studios DK - Sweet Models Enterprise
# 
# NIVEL DE SEGURIDAD: MÁXIMO
# Cifrado: GPG-AES256 con God Key (64 caracteres)
# Exfiltración: S3 externo cifrado
# Retención: 30 días
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'

# ═══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN CRÍTICA
# ═══════════════════════════════════════════════════════════════════

# Database credentials
DB_USER="${DB_USER:-sme_prod_user}"
DB_NAME="${DB_NAME:-sme_production}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

# God Key (64 caracteres - CAMBIAR INMEDIATAMENTE)
# Generar con: openssl rand -base64 48 | tr -d '\n' | head -c 64
GPG_PASSPHRASE="${BACKUP_GOD_KEY:-CHANGE_ME_IMMEDIATELY_USE_openssl_rand_base64_48_EXACTLY_64_CHARS}"

# S3 Configuration (Backup secundario externo)
S3_BUCKET="${BACKUP_S3_BUCKET:-s3://studios-dk-backups}"
S3_REGION="${BACKUP_S3_REGION:-us-east-1}"
AWS_ACCESS_KEY="${BACKUP_AWS_ACCESS_KEY:-}"
AWS_SECRET_KEY="${BACKUP_AWS_SECRET_KEY:-}"

# Paths
BACKUP_DIR="/tmp/backup_staging"
LOG_DIR="/var/log/backup_protocol"
TIMESTAMP=$(date +%Y_%m_%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}"

# Retention (días)
RETENTION_DAYS=30

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE UTILIDAD
# ═══════════════════════════════════════════════════════════════════

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_DIR}/backup.log"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "${LOG_DIR}/backup.log" >&2
    cleanup
    exit 1
}

cleanup() {
    log "🧹 Iniciando limpieza de archivos locales (No dejar rastro)..."
    
    # Sobrescribir archivos antes de borrar (Anti-forense)
    if [ -f "${BACKUP_DIR}/${BACKUP_NAME}.sql" ]; then
        shred -vfz -n 3 "${BACKUP_DIR}/${BACKUP_NAME}.sql" 2>/dev/null || rm -f "${BACKUP_DIR}/${BACKUP_NAME}.sql"
    fi
    
    if [ -f "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz" ]; then
        shred -vfz -n 3 "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz" 2>/dev/null || rm -f "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz"
    fi
    
    if [ -f "${BACKUP_DIR}/${BACKUP_NAME}.gpg" ]; then
        shred -vfz -n 3 "${BACKUP_DIR}/${BACKUP_NAME}.gpg" 2>/dev/null || rm -f "${BACKUP_DIR}/${BACKUP_NAME}.gpg"
    fi
    
    # Eliminar staging directory
    rm -rf "${BACKUP_DIR}" 2>/dev/null || true
    
    log "✅ Limpieza completada. Sin rastro local."
}

verify_dependencies() {
    log "🔍 Verificando dependencias del sistema..."
    
    local deps=("pg_dump" "gzip" "gpg" "aws" "shred")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Dependencia faltante: $dep. Instalar con: apt-get install postgresql-client gzip gnupg awscli coreutils"
        fi
    done
    
    log "✅ Todas las dependencias verificadas"
}

verify_god_key() {
    log "🔐 Verificando God Key..."
    
    if [ "$GPG_PASSPHRASE" == "CHANGE_ME_IMMEDIATELY_USE_openssl_rand_base64_48_EXACTLY_64_CHARS" ]; then
        error "⚠️  GOD KEY NO CONFIGURADA. Genera una con: openssl rand -base64 48 | tr -d '\n' | head -c 64"
    fi
    
    # Verificar longitud (debe ser exactamente 64 caracteres)
    local key_length=${#GPG_PASSPHRASE}
    if [ $key_length -ne 64 ]; then
        error "⚠️  God Key debe tener EXACTAMENTE 64 caracteres (actual: $key_length)"
    fi
    
    log "✅ God Key válida (64 caracteres)"
}

# ═══════════════════════════════════════════════════════════════════
# FASE 1: DUMP DE BASE DE DATOS
# ═══════════════════════════════════════════════════════════════════

dump_database() {
    log "📊 FASE 1: Exportando base de datos PostgreSQL..."
    
    # Crear directorio temporal staging
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$LOG_DIR"
    chmod 700 "$BACKUP_DIR"  # Solo owner puede acceder
    
    # Exportar base de datos (formato custom comprimido)
    log "Ejecutando pg_dump para $DB_NAME..."
    
    PGPASSWORD="${DB_PASSWORD}" pg_dump \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        --format=plain \
        --no-owner \
        --no-acl \
        --verbose \
        > "${BACKUP_DIR}/${BACKUP_NAME}.sql" 2>> "${LOG_DIR}/backup.log"
    
    if [ ! -f "${BACKUP_DIR}/${BACKUP_NAME}.sql" ]; then
        error "pg_dump falló. Revisar logs."
    fi
    
    local sql_size=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.sql" | cut -f1)
    log "✅ Dump completado: ${BACKUP_NAME}.sql (${sql_size})"
}

# ═══════════════════════════════════════════════════════════════════
# FASE 2: CIFRADO OMNI-GENESIS (Compresión + GPG)
# ═══════════════════════════════════════════════════════════════════

encrypt_backup() {
    log "🔐 FASE 2: Iniciando protocolo de cifrado Omni-Genesis..."
    
    # Paso 1: Compresión Gzip (nivel 9 - máxima compresión)
    log "📦 Comprimiendo con gzip (nivel 9)..."
    gzip -9 "${BACKUP_DIR}/${BACKUP_NAME}.sql"
    
    if [ ! -f "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz" ]; then
        error "Compresión falló"
    fi
    
    local gz_size=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz" | cut -f1)
    log "✅ Compresión completada: ${gz_size}"
    
    # Paso 2: Cifrado GPG con AES256 + God Key
    log "🔒 Cifrando con GPG-AES256 usando God Key..."
    
    echo "$GPG_PASSPHRASE" | gpg \
        --batch \
        --yes \
        --passphrase-fd 0 \
        --cipher-algo AES256 \
        --compress-algo none \
        --s2k-mode 3 \
        --s2k-count 65011712 \
        --s2k-digest-algo SHA512 \
        --symmetric \
        --armor \
        --output "${BACKUP_DIR}/${BACKUP_NAME}.gpg" \
        "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz"
    
    if [ ! -f "${BACKUP_DIR}/${BACKUP_NAME}.gpg" ]; then
        error "Cifrado GPG falló"
    fi
    
    local gpg_size=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.gpg" | cut -f1)
    log "✅ Cifrado completado: ${BACKUP_NAME}.gpg (${gpg_size})"
    
    # Borrar archivo comprimido (ya no es necesario)
    shred -vfz -n 3 "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz" 2>/dev/null || rm -f "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz"
}

# ═══════════════════════════════════════════════════════════════════
# FASE 3: EXFILTRACIÓN SEGURA A S3
# ═══════════════════════════════════════════════════════════════════

upload_to_s3() {
    log "☁️  FASE 3: Exfiltrando backup cifrado a S3..."
    
    # Configurar AWS credentials temporalmente
    export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"
    export AWS_DEFAULT_REGION="$S3_REGION"
    
    # Upload con verificación de integridad (checksum)
    log "Subiendo ${BACKUP_NAME}.gpg a ${S3_BUCKET}..."
    
    aws s3 cp \
        "${BACKUP_DIR}/${BACKUP_NAME}.gpg" \
        "${S3_BUCKET}/backups/${BACKUP_NAME}.gpg" \
        --region "$S3_REGION" \
        --storage-class STANDARD_IA \
        --server-side-encryption AES256 \
        --metadata "timestamp=${TIMESTAMP},encrypted=gpg-aes256" \
        2>> "${LOG_DIR}/backup.log"
    
    if [ $? -ne 0 ]; then
        error "Upload a S3 falló. Revisar credenciales AWS."
    fi
    
    log "✅ Backup exfiltrado exitosamente a S3"
    
    # Limpiar variables de entorno
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_DEFAULT_REGION
}

# ═══════════════════════════════════════════════════════════════════
# FASE 4: LIMPIEZA Y ROTACIÓN
# ═══════════════════════════════════════════════════════════════════

rotate_old_backups() {
    log "🔄 FASE 4: Rotando backups antiguos (retención: ${RETENTION_DAYS} días)..."
    
    # Calcular fecha límite
    local cutoff_date=$(date -d "${RETENTION_DAYS} days ago" +%s)
    
    # Listar backups en S3
    aws s3 ls "${S3_BUCKET}/backups/" --recursive | while read -r line; do
        # Extraer fecha del nombre del archivo
        local file_date=$(echo "$line" | awk '{print $1}')
        local file_name=$(echo "$line" | awk '{print $4}')
        local file_timestamp=$(date -d "$file_date" +%s)
        
        # Borrar si es más antiguo que la retención
        if [ $file_timestamp -lt $cutoff_date ]; then
            log "🗑️  Borrando backup antiguo: $file_name"
            aws s3 rm "${S3_BUCKET}/${file_name}"
        fi
    done
    
    log "✅ Rotación completada"
}

# ═══════════════════════════════════════════════════════════════════
# VERIFICACIÓN POST-BACKUP (Opcional pero recomendado)
# ═══════════════════════════════════════════════════════════════════

verify_backup_integrity() {
    log "🔍 Verificando integridad del backup en S3..."
    
    # Descargar backup temporal para verificación
    local temp_verify="/tmp/verify_${TIMESTAMP}.gpg"
    
    aws s3 cp \
        "${S3_BUCKET}/backups/${BACKUP_NAME}.gpg" \
        "$temp_verify" \
        --region "$S3_REGION" \
        --quiet
    
    if [ ! -f "$temp_verify" ]; then
        error "No se pudo descargar backup de S3 para verificación"
    fi
    
    # Comparar checksums
    local local_checksum=$(sha256sum "${BACKUP_DIR}/${BACKUP_NAME}.gpg" | awk '{print $1}')
    local s3_checksum=$(sha256sum "$temp_verify" | awk '{print $1}')
    
    if [ "$local_checksum" != "$s3_checksum" ]; then
        error "⚠️  CHECKSUMS NO COINCIDEN. Backup corrupto o upload incompleto."
    fi
    
    log "✅ Integridad verificada (SHA256: ${local_checksum:0:16}...)"
    
    # Limpiar archivo temporal de verificación
    shred -vfz -n 3 "$temp_verify" 2>/dev/null || rm -f "$temp_verify"
}

# ═══════════════════════════════════════════════════════════════════
# ENVÍO DE NOTIFICACIONES (Opcional)
# ═══════════════════════════════════════════════════════════════════

send_notification() {
    local status="$1"
    local message="$2"
    
    log "📧 Enviando notificación: $status"
    
    # Webhook de Slack (opcional)
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        curl -X POST "$SLACK_WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "{\"text\":\"🔐 Backup Protocol: $status\n$message\"}" \
            &> /dev/null || true
    fi
    
    # Email via AWS SES (opcional)
    if [ -n "${ALERT_EMAIL:-}" ]; then
        aws ses send-email \
            --from "backups@studios-dk.com" \
            --to "$ALERT_EMAIL" \
            --subject "Backup Protocol: $status" \
            --text "$message" \
            --region "$S3_REGION" \
            &> /dev/null || true
    fi
}

# ═══════════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL
# ═══════════════════════════════════════════════════════════════════

main() {
    log "═══════════════════════════════════════════════════════════════════"
    log "🔐 INICIANDO OMNI-GENESIS BACKUP PROTOCOL"
    log "═══════════════════════════════════════════════════════════════════"
    log "Timestamp: $TIMESTAMP"
    log "Database: $DB_NAME@$DB_HOST:$DB_PORT"
    log "S3 Bucket: $S3_BUCKET"
    log "Retention: $RETENTION_DAYS días"
    log "═══════════════════════════════════════════════════════════════════"
    
    # Trap para limpieza en caso de error
    trap cleanup EXIT INT TERM
    
    # Verificaciones pre-backup
    verify_dependencies
    verify_god_key
    
    # Ejecutar pipeline de backup
    dump_database
    encrypt_backup
    upload_to_s3
    verify_backup_integrity
    rotate_old_backups
    
    # Limpieza final (ejecutada automáticamente por trap)
    cleanup
    
    # Notificación de éxito
    local success_msg="Backup completado exitosamente\nArchivo: ${BACKUP_NAME}.gpg\nSize: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.gpg" 2>/dev/null | cut -f1 || echo 'N/A')\nLocation: ${S3_BUCKET}/backups/"
    send_notification "✅ SUCCESS" "$success_msg"
    
    log "═══════════════════════════════════════════════════════════════════"
    log "✅ BACKUP PROTOCOL COMPLETADO EXITOSAMENTE"
    log "═══════════════════════════════════════════════════════════════════"
    log "Archivo: ${BACKUP_NAME}.gpg"
    log "Ubicación: ${S3_BUCKET}/backups/"
    log "Estado: Cifrado con GPG-AES256 (God Key 64 chars)"
    log "Rastro local: ELIMINADO"
    log "═══════════════════════════════════════════════════════════════════"
}

# ═══════════════════════════════════════════════════════════════════
# PUNTO DE ENTRADA
# ═══════════════════════════════════════════════════════════════════

# Verificar que se ejecuta como root o con permisos necesarios
if [ "$EUID" -ne 0 ] && [ "$(id -u)" -ne 0 ]; then 
    log "⚠️  Advertencia: No se ejecuta como root. Algunos comandos pueden fallar."
fi

# Ejecutar función principal
main "$@"

exit 0
