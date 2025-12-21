# 🪟 NOTAS DE DESPLIEGUE PARA WINDOWS

## ⚠️ IMPORTANTE: Entorno Actual vs Producción

Actualmente estás en un **entorno de desarrollo Windows**. Los scripts de backup están diseñados para **servidores Linux de producción**. Aquí está lo que ya se completó y lo que necesitas hacer en producción:

---

## ✅ COMPLETADO EN WINDOWS (Desarrollo)

### 1. God Key Generada ✅
```
Archivo: god_key_GENERATED.txt
Clave: d0NuTiMAWzpCK9LmReqIbXtFEx5yV7c6grP3BsYkOD1ShUoalJZHnQ4vG2wj8f
```

**🔐 ALMACENAMIENTO SEGURO REQUERIDO:**
- [ ] **Vault Digital**: Guardar en 1Password/LastPass/Bitwarden (acceso CTO)
- [ ] **Vault Físico**: Escribir en papel, guardar en caja fuerte bancaria
- [ ] **Backup Offline**: Guardar en USB cifrado en ubicación segura
- [ ] **Documentar**: Agregar a `/root/god_keys_history.txt` en servidor de producción

### 2. Configuración Actualizada ✅
```
Archivo: backup_protocol.env
Estado: God Key insertada
```

### 3. Scripts de Backup Listos ✅
- `backup_protocol.sh` - Pipeline de cifrado (16.5 KB)
- `restore_protocol.sh` - Procedimiento de recuperación (10.2 KB)
- `BACKUP_PROTOCOL_GUIDE.md` - Documentación completa (20.3 KB)

---

## 🚀 PENDIENTE EN SERVIDOR LINUX DE PRODUCCIÓN

### Paso 1: Transferir Archivos al Servidor

```bash
# En tu máquina Windows, transferir a servidor de producción
scp backup_protocol.sh root@studios-dk-prod:/opt/studios-dk/sweet_models_enterprise/
scp restore_protocol.sh root@studios-dk-prod:/opt/studios-dk/sweet_models_enterprise/
scp backup_protocol.env root@studios-dk-prod:/opt/studios-dk/sweet_models_enterprise/
scp BACKUP_PROTOCOL_GUIDE.md root@studios-dk-prod:/opt/studios-dk/sweet_models_enterprise/
```

### Paso 2: Configurar Permisos (Linux)

```bash
# SSH al servidor de producción
ssh root@studios-dk-prod

# Navegar al directorio
cd /opt/studios-dk/sweet_models_enterprise/

# Hacer ejecutables los scripts
chmod +x backup_protocol.sh
chmod +x restore_protocol.sh

# Asegurar archivo de configuración (CRÍTICO)
chmod 600 backup_protocol.env
chown root:root backup_protocol.env
```

### Paso 3: Editar backup_protocol.env con Valores de Producción

```bash
nano backup_protocol.env
```

**Cambiar ESTOS valores:**

```bash
# Database - usar credenciales de producción
DB_PASSWORD="TU_PASSWORD_POSTGRESQL_PRODUCCION"

# AWS - crear usuario IAM específico para backups
BACKUP_AWS_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE"  # ← Cambiar
BACKUP_AWS_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"  # ← Cambiar

# La God Key ya está configurada (d0NuTiMAWzpCK9LmReqIbXtFEx5yV7c6grP3BsYkOD1ShUoalJZHnQ4vG2wj8f)
```

### Paso 4: Crear Bucket S3

```bash
# Instalar AWS CLI si no está instalado
sudo apt-get install -y awscli

# Configurar credenciales AWS
aws configure

# Crear bucket con cifrado
aws s3 mb s3://studios-dk-disaster-recovery --region us-east-1

# Habilitar versionado (protección contra eliminación accidental)
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

# Habilitar logging
aws s3api put-bucket-logging \
  --bucket studios-dk-disaster-recovery \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "studios-dk-disaster-recovery",
      "TargetPrefix": "logs/"
    }
  }'
```

### Paso 5: Instalar Dependencias en Servidor Linux

```bash
# PostgreSQL client
sudo apt-get install -y postgresql-client

# Herramientas de compresión y cifrado
sudo apt-get install -y gzip gnupg coreutils

# AWS CLI (si no está instalado)
sudo apt-get install -y awscli

# Verificar instalación
pg_dump --version
gpg --version
aws --version
shred --version
```

### Paso 6: Ejecutar Backup Manual de Prueba

```bash
# Cargar variables de entorno
source /opt/studios-dk/sweet_models_enterprise/backup_protocol.env

# Ejecutar backup manual
/opt/studios-dk/sweet_models_enterprise/backup_protocol.sh
```

**Verificar salida esperada:**
```
[INICIO] Omni-Genesis Backup Protocol iniciado...
[OK] Dependencias verificadas
[OK] God Key válida (64 caracteres)
[OK] Database dump completado
[OK] Backup cifrado con GPG-AES256
[OK] Backup subido a S3
[OK] Integridad verificada (SHA256)
[OK] Archivos locales eliminados (shred 3-pass)
[ÉXITO] Backup completado: backup_2025_12_11_143022.tar.gz.gpg
```

### Paso 7: Verificar en S3

```bash
# Listar backups en S3
aws s3 ls s3://studios-dk-disaster-recovery/backups/ --human-readable

# Descargar para verificar (opcional)
aws s3 cp s3://studios-dk-disaster-recovery/backups/backup_2025_12_11_143022.tar.gz.gpg /tmp/
```

### Paso 8: Configurar Cron (Automatización)

```bash
# Editar crontab como root
sudo crontab -e

# Agregar línea (backups cada 6 horas: 00:00, 06:00, 12:00, 18:00)
0 */6 * * * /opt/studios-dk/sweet_models_enterprise/backup_protocol.sh >> /var/log/backup_protocol/cron.log 2>&1

# Crear directorio de logs
sudo mkdir -p /var/log/backup_protocol
sudo chmod 700 /var/log/backup_protocol

# Verificar cron configurado
sudo crontab -l
```

**Alternativa: Systemd Timer**

Ver archivo: `BACKUP_PROTOCOL_GUIDE.md` sección 8 para configuración de systemd.

---

## 🧪 TESTING Y VERIFICACIÓN

### Test 1: Backup Manual
```bash
./backup_protocol.sh
```

### Test 2: Listar Backups Disponibles
```bash
./restore_protocol.sh
# Elegir opción 1: Listar backups disponibles
```

### Test 3: Restauración en Staging (NO EN PRODUCCIÓN)
```bash
# Crear base de datos temporal para prueba
createdb sme_test_restore

# Restaurar
./restore_protocol.sh backup_2025_12_11_143022.tar.gz.gpg

# Cuando pregunte, escribir: YES
```

### Test 4: Verificar Integridad
```bash
# Conectar a base de datos restaurada
psql -U sme_prod_user -d sme_test_restore -c "SELECT COUNT(*) FROM users;"

# Comparar con producción
psql -U sme_prod_user -d sme_production -c "SELECT COUNT(*) FROM users;"

# Deben coincidir
```

---

## 📊 MONITOREO

### Ver Logs de Cron
```bash
tail -f /var/log/backup_protocol/cron.log
```

### Ver Logs de Sistema
```bash
journalctl -u backup_protocol -f
```

### Alertas por Email (Opcional)

Editar `backup_protocol.env`:
```bash
ALERT_EMAIL="devops@studiosdk.com"
```

---

## 🆘 DISASTER RECOVERY

### Escenario 1: Pérdida Total de Base de Datos

```bash
# 1. Listar backups disponibles
./restore_protocol.sh

# 2. Elegir backup más reciente
# 3. Confirmar restauración escribiendo: YES
# 4. Verificar integridad
```

**RTO (Recovery Time Objective)**: ~15 minutos
**RPO (Recovery Point Objective)**: 6 horas (frecuencia de backup)

### Escenario 2: God Key Comprometida

```bash
# 1. Generar nueva God Key
openssl rand -base64 48 | tr -d '\n' | head -c 64

# 2. Re-cifrar todos los backups existentes
# (Requiere script personalizado - contactar a DevOps)

# 3. Actualizar backup_protocol.env
# 4. Documentar rotación en /root/god_keys_history.txt
```

### Escenario 3: Bucket S3 Comprometido

```bash
# 1. Rotar credenciales AWS
aws iam create-access-key --user-name backup-user

# 2. Actualizar backup_protocol.env
# 3. Revocar credenciales antiguas
aws iam delete-access-key --access-key-id OLD_KEY --user-name backup-user

# 4. Auditar accesos con CloudTrail
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=studios-dk-disaster-recovery
```

---

## 🔒 SEGURIDAD

### Checklist de Seguridad Post-Despliegue

- [ ] `backup_protocol.env` tiene permisos 600 (solo root)
- [ ] God Key almacenada en 3 ubicaciones separadas
- [ ] Usuario IAM de AWS tiene SOLO permisos S3 (principio de mínimo privilegio)
- [ ] Bucket S3 tiene versionado habilitado
- [ ] Bucket S3 tiene cifrado en reposo habilitado
- [ ] MFA habilitada en cuenta AWS
- [ ] Logs de acceso S3 configurados
- [ ] Alertas configuradas (email/Slack)
- [ ] Test de restauración exitoso
- [ ] Documentación actualizada
- [ ] Equipo capacitado en procedimiento de recuperación

### Rotación de God Key (Cada 90 días)

```bash
# 1. Generar nueva clave
NEW_KEY=$(openssl rand -base64 48 | tr -d '\n' | head -c 64)

# 2. Documentar en historial
echo "$(date +%Y-%m-%d) - Rotación God Key - Old: d0NuTiMAWzpC... New: $NEW_KEY" >> /root/god_keys_history.txt

# 3. Actualizar backup_protocol.env
sed -i "s/BACKUP_GOD_KEY=.*/BACKUP_GOD_KEY=\"$NEW_KEY\"/" backup_protocol.env

# 4. Reiniciar cron
sudo systemctl restart cron
```

---

## 📞 CONTACTO DE EMERGENCIA

**DevOps Lead**: devops@studiosdk.com
**CTO**: cto@studiosdk.com
**Soporte 24/7**: +1-XXX-XXX-XXXX

---

## 🔗 REFERENCIAS

- **Guía Completa**: `BACKUP_PROTOCOL_GUIDE.md`
- **Deployment Checklist**: `DEPLOYMENT_CHECKLIST.md`
- **Arquitectura de Seguridad**: `SECURITY_ARCHITECTURE.md`
- **Despliegue Producción**: `PRODUCTION_DEPLOYMENT_GUIDE.md`

---

**Última actualización**: 2025-12-11
**Versión**: 1.0.0
**Estado**: ✅ LISTO PARA PRODUCCIÓN
