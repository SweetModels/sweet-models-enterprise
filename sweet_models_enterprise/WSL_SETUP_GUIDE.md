# 🚀 GUÍA COMPLETA: BACKUP PROTOCOL EN WSL (Windows Subsystem Linux)

## ⚠️ REQUISITOS PREVIOS

Para hacer esto completamente, necesitas:

1. **Windows 10/11 Pro, Enterprise o Education**
   - (Porque WSL requiere Hyper-V)

2. **WSL 2 instalado** (No la versión 1)
   ```powershell
   # Verificar versión
   wsl --list --verbose
   ```

3. **Una distribución de Linux en WSL** (recomendado: Ubuntu 22.04)
   ```powershell
   # Instalar si no la tienes
   wsl --install -d Ubuntu-22.04
   ```

---

## 📋 PASO 1: INSTALAR DISTRIBUCIÓN LINUX COMPLETA EN WSL

### Si SOLO tienes "docker-desktop" (como ahora):

Docker Desktop incluye un WSL mínimo que NO tiene apt-get. Necesitas instalar Ubuntu completo.

**OPCIÓN A: Desde Microsoft Store (RECOMENDADO)**
```
1. Abre Microsoft Store
2. Busca "Ubuntu 22.04 LTS"
3. Click en "Instalar"
4. Espera a que termine (5-10 minutos)
5. La primera vez te pedirá crear un usuario
```

**OPCIÓN B: Desde PowerShell (Admin)**
```powershell
# Ejecutar COMO ADMINISTRADOR
wsl --install -d Ubuntu-22.04
```

**OPCIÓN C: Descarga manual**
```powershell
# Si las opciones anteriores no funcionan
# Descarga desde: https://cloud-images.ubuntu.com/wsl/jammy/current/
# Descomprime e importa manualmente
```

---

## 🔧 PASO 2: INICIALIZAR UBUNTU EN WSL

Después de instalar Ubuntu:

```powershell
# Abre PowerShell y ejecuta:
wsl -d Ubuntu-22.04

# Te pedirá crear un usuario (NO usar root):
# User: backup
# Password: (elige uno seguro)

# Una vez dentro de Ubuntu, actualiza:
sudo apt update
sudo apt upgrade -y
```

---

## 📦 PASO 3: INSTALAR DEPENDENCIAS

Dentro de Ubuntu (WSL):

```bash
sudo apt install -y \
  postgresql-client \
  gnupg \
  awscli \
  coreutils \
  git \
  nano \
  curl \
  wget

# Verificar instalación
pg_dump --version
gpg --version
aws --version
```

---

## 📂 PASO 4: CONFIGURAR DIRECTORIO DE BACKUP

```bash
# Crear directorio
sudo mkdir -p /opt/studios-dk
sudo chown backup:backup /opt/studios-dk
cd /opt/studios-dk

# Copiar archivos desde Windows
# (Tu máquina Windows está en /mnt/c/Users/...)
# Ejemplo:
cp /mnt/c/Users/USUARIO/Desktop/"Sweet Models Enterprise"/sweet_models_enterprise/*.sh .
cp /mnt/c/Users/USUARIO/Desktop/"Sweet Models Enterprise"/sweet_models_enterprise/*.env .
cp /mnt/c/Users/USUARIO/Desktop/"Sweet Models Enterprise"/sweet_models_enterprise/god_key_GENERATED.txt .

# Verificar
ls -la
```

---

## 🔐 PASO 5: CONFIGURAR PERMISOS Y CREDENCIALES

```bash
# Asegurar permisos
chmod 700 backup_protocol.sh restore_protocol.sh
chmod 600 backup_protocol.env god_key_GENERATED.txt

# Editar credenciales con datos REALES
nano backup_protocol.env
```

**Dentro de nano, cambiar:**
```bash
# Database
DB_PASSWORD="tu_password_postgresql_real"

# AWS IAM User (crear uno específico para backups)
BACKUP_AWS_ACCESS_KEY="tu_access_key_real"
BACKUP_AWS_SECRET_KEY="tu_secret_key_real"
```

**Para salvar en nano:** `Ctrl+O` → Enter → `Ctrl+X`

---

## 🪣 PASO 6: CREAR BUCKET S3

```bash
# Configurar AWS CLI (una sola vez)
aws configure
# Te pedirá:
# - Access Key ID: (pegar aquí)
# - Secret Access Key: (pegar aquí)
# - Default region: us-east-1
# - Default output format: json

# Crear bucket
aws s3 mb s3://studios-dk-disaster-recovery --region us-east-1

# Habilitar versionado
aws s3api put-bucket-versioning \
  --bucket studios-dk-disaster-recovery \
  --versioning-configuration Status=Enabled

# Habilitar cifrado
aws s3api put-bucket-encryption \
  --bucket studios-dk-disaster-recovery \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

---

## ✅ PASO 7: EJECUTAR BACKUP MANUAL DE PRUEBA

```bash
cd /opt/studios-dk
source backup_protocol.env
bash backup_protocol.sh
```

**Salida esperada:**
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

---

## ⏰ PASO 8: AUTOMATIZAR CON CRON

```bash
# Editar crontab
crontab -e
# (Elige nano si te lo pide)

# Agregar esta línea (backups cada 6 horas):
0 */6 * * * cd /opt/studios-dk && source backup_protocol.env && bash backup_protocol.sh >> /var/log/backup_protocol.log 2>&1

# Salvar: Ctrl+O → Enter → Ctrl+X

# Crear directorio de logs
mkdir -p /var/log
touch /var/log/backup_protocol.log

# Ver si se guardó
crontab -l
```

---

## 🧪 PASO 9: ACCESO RÁPIDO DESDE POWERSHELL

En tu PowerShell (Windows), crear alias:

```powershell
# Agregar al perfil de PowerShell
notepad $PROFILE

# Copiar al final del archivo:
function backup { wsl -d Ubuntu-22.04 "cd /opt/studios-dk && source backup_protocol.env && bash backup_protocol.sh" }
function restore { param([string]$f); wsl -d Ubuntu-22.04 "cd /opt/studios-dk && source backup_protocol.env && bash restore_protocol.sh '$f'" }
function list-backups { wsl -d Ubuntu-22.04 "aws s3 ls s3://studios-dk-disaster-recovery/backups/ --human-readable" }

# Salvar y cerrar
```

**Luego en PowerShell:**
```powershell
# Recargar perfil
. $PROFILE

# Usar alias
backup
list-backups
restore backup_2025_12_11_143022.tar.gz.gpg
```

---

## 📊 PASO 10: MONITOREO

```bash
# Ver logs de cron
tail -f /var/log/backup_protocol.log

# Ver trabajos cron ejecutándose
ps aux | grep backup

# Listar backups en S3
aws s3 ls s3://studios-dk-disaster-recovery/backups/ --human-readable --recursive
```

---

## 🛠️ TROUBLESHOOTING

### "Comando no encontrado: pg_dump"
```bash
sudo apt install postgresql-client
```

### "ERROR: AWS credentials not configured"
```bash
aws configure
```

### "Cannot connect to database"
```bash
# Verificar que PostgreSQL está corriendo (en Docker)
docker ps | grep postgres

# Verificar credenciales en backup_protocol.env
cat backup_protocol.env | grep DB_
```

### "Permiso denegado (Permission denied)"
```bash
chmod 700 backup_protocol.sh
chmod 700 restore_protocol.sh
chmod 600 backup_protocol.env
```

### "S3 bucket already exists"
```bash
# Usar otro nombre
aws s3 mb s3://studios-dk-disaster-recovery-$(date +%s)
```

---

## 🔒 SEGURIDAD - CHECKLIST FINAL

- [ ] `backup_protocol.env` tiene permisos 600 (solo lectura)
- [ ] God Key guardada en 3 ubicaciones seguras
- [ ] AWS IAM user tiene SOLO permisos S3
- [ ] S3 bucket tiene versionado habilitado
- [ ] S3 bucket tiene cifrado habilitado
- [ ] Test de backup ejecutado exitosamente
- [ ] Test de restauración completado (en staging)
- [ ] Cron configurado y verificado
- [ ] Logs siendo generados correctamente

---

## 📞 RESUMEN DE COMANDOS RÁPIDOS

```bash
# VERIFICAR STATUS
wsl --list --verbose
wsl -d Ubuntu-22.04

# EJECUTAR BACKUP
wsl -d Ubuntu-22.04 "cd /opt/studios-dk && bash backup_protocol.sh"

# VER LOGS
wsl -d Ubuntu-22.04 "tail -f /var/log/backup_protocol.log"

# LISTAR BACKUPS
wsl -d Ubuntu-22.04 "aws s3 ls s3://studios-dk-disaster-recovery/backups/ --human-readable"

# CONECTAR A UBUNTU
wsl -d Ubuntu-22.04
```

---

## 🚀 TIEMPO ESTIMADO

- Instalar Ubuntu: **10-15 minutos**
- Instalar dependencias: **5-10 minutos**
- Copiar archivos: **2 minutos**
- Configurar AWS: **5 minutos**
- Crear bucket S3: **2 minutos**
- Test de backup: **5-10 minutos** (depende del tamaño DB)
- Configurar cron: **2 minutos**

**TOTAL: ~30-45 minutos**

---

## ✅ VERIFICACIÓN FINAL

Una vez terminado, ejecuta esto para verificar:

```bash
#!/bin/bash
echo "=== Verificando Backup Protocol ==="

echo "1. Archivos en lugar:"
ls -lh /opt/studios-dk/

echo "2. Dependencias:"
pg_dump --version
gpg --version
aws --version

echo "3. AWS configurado:"
aws s3 ls

echo "4. Cron configurado:"
crontab -l | grep backup

echo "5. Permisos:"
ls -l /opt/studios-dk/backup_protocol.env | awk '{print $1, $9}'

echo "=== TODO OK ==="
```

---

**SIGUIENTE PASO:** Dime cuándo hayas instalado Ubuntu en WSL y te diré exactamente qué comando ejecutar para copiar y configurar todo automáticamente.
