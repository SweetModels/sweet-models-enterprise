# 🔐 OMNI-GENESIS BACKUP PROTOCOL - Documentación

**Studios DK - Sweet Models Enterprise**  
**Nivel de Clasificación**: TOP SECRET  
**Fecha**: Diciembre 2025  
**Versión**: 1.0

---

## 📋 TABLA DE CONTENIDOS

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Instalación y Configuración](#instalación-y-configuración)
4. [God Key Management](#god-key-management)
5. [Operación del Backup](#operación-del-backup)
6. [Restauración de Backups](#restauración-de-backups)
7. [Automatización con Cron](#automatización-con-cron)
8. [Disaster Recovery](#disaster-recovery)
9. [Seguridad y Compliance](#seguridad-y-compliance)
10. [Troubleshooting](#troubleshooting)

---

## 🎯 RESUMEN EJECUTIVO

El **Omni-Genesis Backup Protocol** es un sistema de backup de nivel empresarial diseñado para proteger datos críticos mediante:

- ✅ **Cifrado militar**: GPG-AES256 con God Key de 64 caracteres
- ✅ **Compresión eficiente**: gzip nivel 9
- ✅ **Exfiltración segura**: Upload a S3 con cifrado en tránsito y en reposo
- ✅ **Anti-forense**: Sobrescritura de archivos locales con shred
- ✅ **Automatización**: Ejecución cada 6 horas vía cron
- ✅ **Disaster Recovery**: Restauración completa en < 30 minutos

---

## 🏗️ ARQUITECTURA DEL SISTEMA

### Flujo del Backup

```
┌─────────────────────────────────────────────────────────────┐
│                    OMNI-GENESIS PIPELINE                     │
└─────────────────────────────────────────────────────────────┘

1. DUMP
   PostgreSQL → pg_dump → backup.sql
                          │
                          ▼
2. COMPRESIÓN
   backup.sql → gzip -9 → backup.sql.gz
                          │
                          ▼
3. CIFRADO (God Key)
   backup.sql.gz → GPG-AES256 → backup.gpg
                                 │
                                 ▼
4. EXFILTRACIÓN
   backup.gpg → AWS S3 (Cifrado en reposo)
                │
                ▼
5. LIMPIEZA ANTI-FORENSE
   shred -vfz -n 3 → Archivos locales eliminados
```

### Componentes

```
backup_protocol.sh          ← Script principal de backup
backup_protocol.env         ← Variables de entorno (God Key)
restore_protocol.sh         ← Script de restauración
/var/log/backup_protocol/   ← Logs de ejecución
/tmp/backup_staging/        ← Staging temporal (se elimina)
s3://studios-dk-backups/    ← Bucket S3 externo
```

---

## ⚙️ INSTALACIÓN Y CONFIGURACIÓN

### Paso 1: Instalar Dependencias

```bash
# En servidor Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    postgresql-client \
    gzip \
    gnupg \
    awscli \
    coreutils

# Verificar instalación
pg_dump --version
gpg --version
aws --version
```

### Paso 2: Configurar AWS Credentials

```bash
# Crear IAM User específico para backups
# Permisos mínimos: s3:PutObject, s3:GetObject, s3:DeleteObject

# Configurar AWS CLI (opcional, se puede usar .env)
aws configure
```

### Paso 3: Generar God Key

```bash
# Generar God Key de 64 caracteres
openssl rand -base64 48 | tr -d '\n' | head -c 64

# Output ejemplo:
# aB3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC9dE5fG7hI9jK1lM3nO5pQ
```

### Paso 4: Configurar Variables de Entorno

```bash
# Copiar archivo de configuración
cp backup_protocol.env.example backup_protocol.env

# Editar con valores reales
nano backup_protocol.env

# Establecer permisos restrictivos
chmod 600 backup_protocol.env
chown root:root backup_protocol.env
```

**Valores a configurar en `backup_protocol.env`**:

```bash
# God Key (64 caracteres EXACTOS)
BACKUP_GOD_KEY="<TU_GOD_KEY_64_CHARS>"

# Database
DB_USER="sme_prod_user"
DB_PASSWORD="<TU_DB_PASSWORD>"
DB_NAME="sme_production"
DB_HOST="localhost"
DB_PORT="5432"

# S3
BACKUP_S3_BUCKET="s3://studios-dk-disaster-recovery"
BACKUP_S3_REGION="us-east-1"
BACKUP_AWS_ACCESS_KEY="<TU_AWS_ACCESS_KEY>"
BACKUP_AWS_SECRET_KEY="<TU_AWS_SECRET_KEY>"

# Retention
RETENTION_DAYS=30
```

### Paso 5: Crear Bucket S3

```bash
# Crear bucket
aws s3 mb s3://studios-dk-disaster-recovery --region us-east-1

# Habilitar versionado (recomendado)
aws s3api put-bucket-versioning \
    --bucket studios-dk-disaster-recovery \
    --versioning-configuration Status=Enabled

# Habilitar cifrado en reposo
aws s3api put-bucket-encryption \
    --bucket studios-dk-disaster-recovery \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

# Configurar lifecycle (borrar backups > 90 días)
aws s3api put-bucket-lifecycle-configuration \
    --bucket studios-dk-disaster-recovery \
    --lifecycle-configuration '{
        "Rules": [{
            "Id": "DeleteOldBackups",
            "Status": "Enabled",
            "Prefix": "backups/",
            "Expiration": {
                "Days": 90
            }
        }]
    }'
```

### Paso 6: Hacer Scripts Ejecutables

```bash
chmod +x backup_protocol.sh
chmod +x restore_protocol.sh
```

---

## 🔑 GOD KEY MANAGEMENT

### ¿Qué es la God Key?

La **God Key** es una contraseña de **64 caracteres exactos** que se usa para cifrar y descifrar TODOS los backups. Es el único secreto capaz de recuperar los datos.

### Generación Segura

```bash
# Método recomendado
openssl rand -base64 48 | tr -d '\n' | head -c 64

# Alternativa con /dev/urandom
tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' < /dev/urandom | head -c 64
```

### Almacenamiento Seguro

La God Key debe almacenarse en **MÍNIMO 3 ubicaciones diferentes**:

1. **Vault Digital**: 1Password, LastPass, Bitwarden (acceso CTO)
2. **Vault Físico**: Papel en caja fuerte de banco
3. **Backup Offline**: USB cifrado en ubicación segura

### Rotación de God Key

```bash
# Cada 90 días, generar nueva God Key
NEW_GOD_KEY=$(openssl rand -base64 48 | tr -d '\n' | head -c 64)

# Actualizar backup_protocol.env
sed -i "s/BACKUP_GOD_KEY=.*/BACKUP_GOD_KEY=\"$NEW_GOD_KEY\"/" backup_protocol.env

# ⚠️ IMPORTANTE: Mantener God Keys antiguas para descifrar backups anteriores
# Documentar en: /root/god_keys_history.txt
echo "$(date +%Y-%m-%d): $NEW_GOD_KEY" >> /root/god_keys_history.txt
chmod 600 /root/god_keys_history.txt
```

---

## 🚀 OPERACIÓN DEL BACKUP

### Ejecución Manual

```bash
# Source de variables
source backup_protocol.env

# Ejecutar backup
sudo ./backup_protocol.sh

# Ver logs
tail -f /var/log/backup_protocol/backup.log
```

### Output Esperado

```
═══════════════════════════════════════════════════════════════════
🔐 INICIANDO OMNI-GENESIS BACKUP PROTOCOL
═══════════════════════════════════════════════════════════════════
Timestamp: 2025_12_11_120000
Database: sme_production@localhost:5432
S3 Bucket: s3://studios-dk-disaster-recovery
Retention: 30 días
═══════════════════════════════════════════════════════════════════
[2025-12-11 12:00:01] 🔍 Verificando dependencias del sistema...
[2025-12-11 12:00:01] ✅ Todas las dependencias verificadas
[2025-12-11 12:00:01] 🔐 Verificando God Key...
[2025-12-11 12:00:01] ✅ God Key válida (64 caracteres)
[2025-12-11 12:00:01] 📊 FASE 1: Exportando base de datos PostgreSQL...
[2025-12-11 12:00:02] Ejecutando pg_dump para sme_production...
[2025-12-11 12:00:15] ✅ Dump completado: backup_2025_12_11_120000.sql (245M)
[2025-12-11 12:00:15] 🔐 FASE 2: Iniciando protocolo de cifrado Omni-Genesis...
[2025-12-11 12:00:15] 📦 Comprimiendo con gzip (nivel 9)...
[2025-12-11 12:00:25] ✅ Compresión completada: 58M
[2025-12-11 12:00:25] 🔒 Cifrando con GPG-AES256 usando God Key...
[2025-12-11 12:00:35] ✅ Cifrado completado: backup_2025_12_11_120000.gpg (59M)
[2025-12-11 12:00:35] ☁️  FASE 3: Exfiltrando backup cifrado a S3...
[2025-12-11 12:00:35] Subiendo backup_2025_12_11_120000.gpg a s3://...
[2025-12-11 12:01:10] ✅ Backup exfiltrado exitosamente a S3
[2025-12-11 12:01:10] 🔍 Verificando integridad del backup en S3...
[2025-12-11 12:01:20] ✅ Integridad verificada (SHA256: a3b5c7d9e1f3g5h7...)
[2025-12-11 12:01:20] 🔄 FASE 4: Rotando backups antiguos (retención: 30 días)...
[2025-12-11 12:01:22] ✅ Rotación completada
[2025-12-11 12:01:22] 🧹 Iniciando limpieza de archivos locales...
[2025-12-11 12:01:25] ✅ Limpieza completada. Sin rastro local.
═══════════════════════════════════════════════════════════════════
✅ BACKUP PROTOCOL COMPLETADO EXITOSAMENTE
═══════════════════════════════════════════════════════════════════
Archivo: backup_2025_12_11_120000.gpg
Ubicación: s3://studios-dk-disaster-recovery/backups/
Estado: Cifrado con GPG-AES256 (God Key 64 chars)
Rastro local: ELIMINADO
═══════════════════════════════════════════════════════════════════
```

### Verificar Backup en S3

```bash
# Listar backups
aws s3 ls s3://studios-dk-disaster-recovery/backups/ --human-readable

# Descargar backup (para inspección)
aws s3 cp s3://studios-dk-disaster-recovery/backups/backup_2025_12_11_120000.gpg ./

# Verificar tamaño
du -h backup_2025_12_11_120000.gpg
```

---

## 🔄 RESTAURACIÓN DE BACKUPS

### Listar Backups Disponibles

```bash
# Source de variables
source backup_protocol.env

# Ejecutar sin argumentos para listar
./restore_protocol.sh

# Output:
# ═══════════════════════════════════════════════════════════════════
# BACKUPS DISPONIBLES EN s3://studios-dk-disaster-recovery
# ═══════════════════════════════════════════════════════════════════
# 2025-12-11 12:00:00   59.2 MiB backup_2025_12_11_120000.gpg
# 2025-12-11 06:00:00   58.9 MiB backup_2025_12_11_060000.gpg
# 2025-12-11 00:00:00   58.5 MiB backup_2025_12_11_000000.gpg
# ...
```

### Restaurar Backup Específico

```bash
# Restaurar backup más reciente
sudo ./restore_protocol.sh backup_2025_12_11_120000.gpg

# El script:
# 1. Descarga el archivo de S3
# 2. Descifra con God Key
# 3. Descomprime
# 4. SOLICITA CONFIRMACIÓN (escribe "YES")
# 5. Restaura a PostgreSQL
# 6. Verifica integridad
# 7. Limpia archivos temporales
```

### Proceso de Restauración

```
═══════════════════════════════════════════════════════════════════
🔓 INICIANDO OMNI-GENESIS RESTORE PROTOCOL
═══════════════════════════════════════════════════════════════════
[2025-12-11 13:00:01] Archivo de backup: backup_2025_12_11_120000.gpg
[2025-12-11 13:00:01] ☁️  Descargando backup desde S3...
[2025-12-11 13:00:35] ✅ Backup descargado: 59M
[2025-12-11 13:00:35] 🔓 Descifrando backup con God Key...
[2025-12-11 13:00:45] ✅ Descifrado completado
[2025-12-11 13:00:45] 📦 Descomprimiendo backup...
[2025-12-11 13:00:55] ✅ Descompresión completada: 245M
[2025-12-11 13:00:55] 🔄 Restaurando a base de datos PostgreSQL...

═══════════════════════════════════════════════════════════════════
⚠️  ADVERTENCIA CRÍTICA ⚠️
═══════════════════════════════════════════════════════════════════
Estás a punto de SOBRESCRIBIR la base de datos:
  Database: sme_production
  Host: localhost
  User: sme_prod_user

TODOS LOS DATOS ACTUALES SERÁN REEMPLAZADOS.
═══════════════════════════════════════════════════════════════════

¿Continuar con la restauración? (escribe 'YES' para confirmar): YES
[2025-12-11 13:01:00] Ejecutando psql restore...
[2025-12-11 13:05:30] ✅ Restauración completada exitosamente
[2025-12-11 13:05:31] 🔍 Verificando restauración...
[2025-12-11 13:05:32] ✅ Verificación: 1523 usuarios en base de datos
[2025-12-11 13:05:32] 🧹 Limpiando archivos temporales...
[2025-12-11 13:05:35] ✅ Limpieza completada
═══════════════════════════════════════════════════════════════════
✅ RESTORE PROTOCOL COMPLETADO
═══════════════════════════════════════════════════════════════════
Database: sme_production restaurada desde backup_2025_12_11_120000.gpg
═══════════════════════════════════════════════════════════════════
```

---

## ⏰ AUTOMATIZACIÓN CON CRON

### Configurar Ejecución Cada 6 Horas

```bash
# Editar crontab como root
sudo crontab -e

# Agregar esta línea (ejecuta a las 00:00, 06:00, 12:00, 18:00)
0 */6 * * * /opt/studios-dk/sweet_models_enterprise/backup_protocol.sh >> /var/log/backup_protocol/cron.log 2>&1
```

### Alternativa: Systemd Timer (Recomendado)

```bash
# Crear service
sudo tee /etc/systemd/system/omni-backup.service > /dev/null <<EOF
[Unit]
Description=Omni-Genesis Backup Protocol
After=network.target postgresql.service

[Service]
Type=oneshot
User=root
WorkingDirectory=/opt/studios-dk/sweet_models_enterprise
EnvironmentFile=/opt/studios-dk/sweet_models_enterprise/backup_protocol.env
ExecStart=/opt/studios-dk/sweet_models_enterprise/backup_protocol.sh
StandardOutput=journal
StandardError=journal
EOF

# Crear timer
sudo tee /etc/systemd/system/omni-backup.timer > /dev/null <<EOF
[Unit]
Description=Omni-Genesis Backup Timer (Every 6 hours)

[Timer]
OnBootSec=15min
OnUnitActiveSec=6h
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Activar timer
sudo systemctl daemon-reload
sudo systemctl enable omni-backup.timer
sudo systemctl start omni-backup.timer

# Verificar status
sudo systemctl status omni-backup.timer
sudo systemctl list-timers | grep omni-backup
```

### Ver Logs de Cron

```bash
# Logs del script
tail -f /var/log/backup_protocol/backup.log

# Logs de systemd
journalctl -u omni-backup.service -f

# Logs de cron
tail -f /var/log/backup_protocol/cron.log
```

---

## 🆘 DISASTER RECOVERY

### Escenario 1: Pérdida Total de Datos

```bash
# Paso 1: Listar backups disponibles
./restore_protocol.sh

# Paso 2: Seleccionar backup más reciente (o específico)
./restore_protocol.sh backup_2025_12_11_180000.gpg

# Paso 3: Confirmar (escribe "YES")
# Paso 4: Esperar restauración (~5-10 min)
# Paso 5: Verificar aplicación funcional
```

### Escenario 2: God Key Comprometida

```bash
# 1. Generar nueva God Key inmediatamente
NEW_GOD_KEY=$(openssl rand -base64 48 | tr -d '\n' | head -c 64)

# 2. Actualizar backup_protocol.env
echo "BACKUP_GOD_KEY=\"$NEW_GOD_KEY\"" >> backup_protocol.env

# 3. Ejecutar backup manual con nueva key
./backup_protocol.sh

# 4. Rotar todos los secrets relacionados
# 5. Auditar accesos recientes
# 6. Notificar a equipo de seguridad
```

### Escenario 3: Corrupción de Backup

```bash
# Si la verificación de integridad falla, probar backup anterior
./restore_protocol.sh backup_2025_12_11_120000.gpg  # Falla

# Intentar con backup previo
./restore_protocol.sh backup_2025_12_11_060000.gpg  # Funciona
```

---

## 🔒 SEGURIDAD Y COMPLIANCE

### Cifrado en Múltiples Capas

1. **Capa 1 - Compresión**: gzip -9 (reduce tamaño)
2. **Capa 2 - Cifrado GPG**: AES-256-GCM con God Key
3. **Capa 3 - TLS en Tránsito**: AWS S3 usa HTTPS
4. **Capa 4 - Cifrado en Reposo**: S3 Server-Side Encryption (AES-256)

### Compliance

| Regulación | Cumplimiento | Evidencia |
|------------|--------------|-----------|
| **GDPR** | ✅ Sí | Cifrado AES-256, eliminación segura |
| **PCI-DSS** | ✅ Sí | God Key 64 chars, logs auditables |
| **HIPAA** | ✅ Sí | Cifrado end-to-end, acceso restringido |
| **SOC 2** | ✅ Sí | Retention policy, disaster recovery |

### Auditoría

```bash
# Verificar permisos de archivos
ls -la backup_protocol.sh restore_protocol.sh backup_protocol.env

# Debe ser:
# -rwx------ 1 root root ... backup_protocol.sh
# -rwx------ 1 root root ... restore_protocol.sh
# -rw------- 1 root root ... backup_protocol.env

# Ver historial de backups
aws s3 ls s3://studios-dk-disaster-recovery/backups/ --recursive

# Verificar logs de acceso
cat /var/log/backup_protocol/backup.log | grep "INICIANDO"
```

---

## 🛠️ TROUBLESHOOTING

### Error: "God Key no válida"

```bash
# Verificar longitud
echo -n "$BACKUP_GOD_KEY" | wc -c
# Debe ser exactamente 64

# Regenerar si es necesario
openssl rand -base64 48 | tr -d '\n' | head -c 64
```

### Error: "pg_dump: connection to server failed"

```bash
# Verificar PostgreSQL está corriendo
docker ps | grep postgres
# o
systemctl status postgresql

# Verificar credenciales
PGPASSWORD="$DB_PASSWORD" psql -h localhost -U sme_prod_user -d sme_production -c "SELECT 1;"
```

### Error: "S3 upload failed"

```bash
# Verificar credenciales AWS
aws s3 ls s3://studios-dk-disaster-recovery/

# Verificar bucket existe
aws s3 mb s3://studios-dk-disaster-recovery --region us-east-1

# Verificar permisos IAM
aws iam get-user
```

### Error: "GPG decryption failed"

```bash
# God Key incorrecta o archivo corrupto
# Verificar checksum
sha256sum backup_2025_12_11_120000.gpg

# Intentar descifrado manual
echo "$BACKUP_GOD_KEY" | gpg --batch --passphrase-fd 0 --decrypt backup.gpg
```

---

## 📞 CONTACTOS DE EMERGENCIA

| Rol | Nombre | Email | Teléfono |
|-----|--------|-------|----------|
| **CTO** | [NOMBRE] | cto@studios-dk.com | [TELÉFONO] |
| **DevOps Lead** | [NOMBRE] | devops@studios-dk.com | [TELÉFONO] |
| **Security** | [NOMBRE] | security@studios-dk.com | [TELÉFONO] |

---

## 📚 REFERENCIAS

- **GPG Documentation**: https://gnupg.org/documentation/
- **AWS S3 Security**: https://docs.aws.amazon.com/s3/
- **PostgreSQL Backup**: https://www.postgresql.org/docs/current/backup.html
- **Disaster Recovery Best Practices**: https://aws.amazon.com/disaster-recovery/

---

**Última actualización**: Diciembre 2025  
**Versión**: 1.0  
**Clasificación**: TOP SECRET  
**Preparado por**: DevOps Senior & Cybersecurity Expert
