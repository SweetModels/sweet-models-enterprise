#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# OMNI-GENESIS RESTORE PROTOCOL
# Studios DK - Sweet Models Enterprise
# 
# PROPÓSITO: Descifrar y restaurar backups desde S3
# NIVEL DE SEGURIDAD: MÁXIMO
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail
IFS=$'\n\t'

# ═══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════

# Source environment variables
if [ -f "./backup_protocol.env" ]; then
    source ./backup_protocol.env
else
    echo "⚠️  ERROR: backup_protocol.env no encontrado"
    exit 1
fi

RESTORE_DIR="/tmp/restore_staging"
LOG_DIR="/var/log/restore_protocol"
TIMESTAMP=$(date +%Y_%m_%d_%H%M%S)

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES
# ═══════════════════════════════════════════════════════════════════

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_DIR}/restore.log"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "${LOG_DIR}/restore.log" >&2
    cleanup
    exit 1
}

cleanup() {
    log "🧹 Limpiando archivos temporales..."
    
    if [ -d "$RESTORE_DIR" ]; then
        # Sobrescribir archivos sensibles antes de borrar
        find "$RESTORE_DIR" -type f -exec shred -vfz -n 3 {} \; 2>/dev/null || true
        rm -rf "$RESTORE_DIR"
    fi
    
    log "✅ Limpieza completada"
}

list_available_backups() {
    log "📋 Listando backups disponibles en S3..."
    
    export AWS_ACCESS_KEY_ID="$BACKUP_AWS_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$BACKUP_AWS_SECRET_KEY"
    export AWS_DEFAULT_REGION="$BACKUP_S3_REGION"
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "BACKUPS DISPONIBLES EN ${BACKUP_S3_BUCKET}"
    echo "═══════════════════════════════════════════════════════════════════"
    
    aws s3 ls "${BACKUP_S3_BUCKET}/backups/" --human-readable --summarize | grep "backup_"
    
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
}

download_backup() {
    local backup_file="$1"
    
    log "☁️  Descargando backup desde S3: $backup_file"
    
    mkdir -p "$RESTORE_DIR"
    mkdir -p "$LOG_DIR"
    chmod 700 "$RESTORE_DIR"
    
    export AWS_ACCESS_KEY_ID="$BACKUP_AWS_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$BACKUP_AWS_SECRET_KEY"
    export AWS_DEFAULT_REGION="$BACKUP_S3_REGION"
    
    aws s3 cp \
        "${BACKUP_S3_BUCKET}/backups/${backup_file}" \
        "${RESTORE_DIR}/${backup_file}" \
        --region "$BACKUP_S3_REGION"
    
    if [ ! -f "${RESTORE_DIR}/${backup_file}" ]; then
        error "Descarga de S3 falló"
    fi
    
    local file_size=$(du -h "${RESTORE_DIR}/${backup_file}" | cut -f1)
    log "✅ Backup descargado: ${file_size}"
    
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION
}

decrypt_backup() {
    local encrypted_file="$1"
    local base_name="${encrypted_file%.gpg}"
    
    log "🔓 Descifrando backup con God Key..."
    
    echo "$BACKUP_GOD_KEY" | gpg \
        --batch \
        --yes \
        --passphrase-fd 0 \
        --decrypt \
        --output "${RESTORE_DIR}/${base_name}.sql.gz" \
        "${RESTORE_DIR}/${encrypted_file}"
    
    if [ ! -f "${RESTORE_DIR}/${base_name}.sql.gz" ]; then
        error "Descifrado GPG falló. Verificar God Key."
    fi
    
    log "✅ Descifrado completado"
    
    # Borrar archivo cifrado
    shred -vfz -n 3 "${RESTORE_DIR}/${encrypted_file}" 2>/dev/null || rm -f "${RESTORE_DIR}/${encrypted_file}"
}

decompress_backup() {
    local compressed_file="$1"
    local base_name="${compressed_file%.sql.gz}"
    
    log "📦 Descomprimiendo backup..."
    
    gunzip "${RESTORE_DIR}/${compressed_file}"
    
    if [ ! -f "${RESTORE_DIR}/${base_name}.sql" ]; then
        error "Descompresión falló"
    fi
    
    local sql_size=$(du -h "${RESTORE_DIR}/${base_name}.sql" | cut -f1)
    log "✅ Descompresión completada: ${sql_size}"
}

restore_to_database() {
    local sql_file="$1"
    
    log "🔄 Restaurando a base de datos PostgreSQL..."
    
    # Advertencia crítica
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "⚠️  ADVERTENCIA CRÍTICA ⚠️"
    echo "═══════════════════════════════════════════════════════════════════"
    echo "Estás a punto de SOBRESCRIBIR la base de datos:"
    echo "  Database: $DB_NAME"
    echo "  Host: $DB_HOST"
    echo "  User: $DB_USER"
    echo ""
    echo "TODOS LOS DATOS ACTUALES SERÁN REEMPLAZADOS."
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    
    read -p "¿Continuar con la restauración? (escribe 'YES' para confirmar): " confirm
    
    if [ "$confirm" != "YES" ]; then
        log "❌ Restauración cancelada por el usuario"
        exit 0
    fi
    
    log "Ejecutando psql restore..."
    
    # Opción 1: Drop y recrear database (recomendado)
    PGPASSWORD="${DB_PASSWORD}" dropdb \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        "$DB_NAME" \
        --if-exists
    
    PGPASSWORD="${DB_PASSWORD}" createdb \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        "$DB_NAME"
    
    # Restaurar desde SQL
    PGPASSWORD="${DB_PASSWORD}" psql \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -f "${RESTORE_DIR}/${sql_file}" \
        &>> "${LOG_DIR}/restore.log"
    
    if [ $? -eq 0 ]; then
        log "✅ Restauración completada exitosamente"
    else
        error "Restauración falló. Revisar logs en ${LOG_DIR}/restore.log"
    fi
}

verify_restore() {
    log "🔍 Verificando restauración..."
    
    # Contar registros en tabla users
    local user_count=$(PGPASSWORD="${DB_PASSWORD}" psql \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
    
    log "✅ Verificación: ${user_count} usuarios en base de datos"
}

# ═══════════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL
# ═══════════════════════════════════════════════════════════════════

main() {
    log "═══════════════════════════════════════════════════════════════════"
    log "🔓 INICIANDO OMNI-GENESIS RESTORE PROTOCOL"
    log "═══════════════════════════════════════════════════════════════════"
    
    trap cleanup EXIT INT TERM
    
    # Si no se proporciona archivo, listar disponibles
    if [ $# -eq 0 ]; then
        list_available_backups
        echo ""
        echo "Uso: $0 <nombre_del_backup.gpg>"
        echo "Ejemplo: $0 backup_2025_12_11_120000.gpg"
        exit 0
    fi
    
    local backup_file="$1"
    local base_name="${backup_file%.gpg}"
    
    log "Archivo de backup: $backup_file"
    
    # Pipeline de restauración
    download_backup "$backup_file"
    decrypt_backup "$backup_file"
    decompress_backup "${base_name}.sql.gz"
    restore_to_database "${base_name}.sql"
    verify_restore
    
    # Limpieza (automática por trap)
    cleanup
    
    log "═══════════════════════════════════════════════════════════════════"
    log "✅ RESTORE PROTOCOL COMPLETADO"
    log "═══════════════════════════════════════════════════════════════════"
    log "Database: $DB_NAME restaurada desde $backup_file"
    log "═══════════════════════════════════════════════════════════════════"
}

# Ejecutar
main "$@"

exit 0
