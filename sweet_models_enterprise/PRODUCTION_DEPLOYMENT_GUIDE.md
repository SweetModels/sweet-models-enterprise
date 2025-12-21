# 🚀 GUÍA COMPLETA DE DESPLIEGUE PRODUCCIÓN - Studios DK

**Documento confidencial - DevOps Professional Setup**

---

## 📋 TABLA DE CONTENIDOS

1. [Requisitos Previos](#requisitos-previos)
2. [Arquitectura de Despliegue](#arquitectura-de-despliegue)
3. [Preparación del Servidor](#preparación-del-servidor)
4. [Configuración de Seguridad](#configuración-de-seguridad)
5. [Proceso de Despliegue](#proceso-de-despliegue)
6. [Post-Despliegue](#post-despliegue)
7. [Monitoreo y Mantenimiento](#monitoreo-y-mantenimiento)
8. [Recuperación de Desastres](#recuperación-de-desastres)

---

## 🔧 REQUISITOS PREVIOS

### Hardware Mínimo Recomendado
```
CPU: 4 vCPU (8 recomendado para HA)
RAM: 8 GB (16 GB para producción)
Almacenamiento: 100 GB SSD (depende de datos)
Ancho de banda: 100 Mbps mínimo
Uptime SLA: 99.9%
```

### Software Requerido
```bash
- Docker Engine 24.0+
- Docker Compose 2.0+
- OpenSSL 1.1.1+
- curl / wget
- git
- Ansible (opcional, para HA)
```

### Configuración DNS
```
api.studios-dk.com      → <IP_SERVIDOR>
*.studios-dk.com        → <IP_SERVIDOR> (wildcard para subdomios)
```

---

## 🏗️ ARQUITECTURA DE DESPLIEGUE

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET (443)                        │
└────────────────────────────┬────────────────────────────────┘
                             │
                    ┌────────▼──────────┐
                    │   Nginx Gateway    │
                    │ (Reverse Proxy)    │
                    │  Rate Limiting     │
                    │   SSL/TLS (443)    │
                    └────────┬───────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼────┐         ┌────▼────┐         ┌────▼────┐
   │Backend  │         │ MinIO    │         │Monitoring│
   │(Rust)   │         │(Storage) │         │(Prometheus)│
   │:3000    │         │:9000     │         │:9090     │
   └────┬────┘         └────┬────┘         └──────────┘
        │                   │
   ┌────┴───────────────────┴──────────────┐
   │                                       │
┌──▼──┐    ┌──────┐    ┌──────┐    ┌──────▼──┐
│ PG  │    │Redis │    │NATS  │    │Certificates│
│5432 │    │6379  │    │4222  │    │(LetsEncrypt)│
└─────┘    └──────┘    └──────┘    └───────────┘
```

---

## 🔐 PREPARACIÓN DEL SERVIDOR

### 1. Acceso al Servidor

```bash
# SSH a tu servidor (ajusta IP y puerto)
ssh -p 22 admin@<IP_SERVIDOR>

# O con clave privada
ssh -i ~/.ssh/id_rsa -p 22 admin@<IP_SERVIDOR>
```

### 2. Actualizar Sistema

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y curl wget git openssl htop

# Cambiar zona horaria
sudo timedatectl set-timezone UTC
```

### 3. Instalar Docker & Docker Compose

```bash
# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar
docker --version
docker-compose --version
```

### 4. Configurar Firewall

```bash
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Puertos necesarios
sudo ufw allow 22/tcp          # SSH
sudo ufw allow 80/tcp          # HTTP (Let's Encrypt)
sudo ufw allow 443/tcp         # HTTPS
sudo ufw allow 3000/tcp        # Backend (interno)
sudo ufw allow 4222/tcp        # NATS (interno)
sudo ufw allow 5432/tcp        # PostgreSQL (interno)
sudo ufw allow 6379/tcp        # Redis (interno)
sudo ufw allow 9000/tcp        # MinIO (interno)

# Verificar
sudo ufw status
```

### 5. Crear Usuario de Aplicación

```bash
# Crear usuario no-root
sudo useradd -m -s /bin/bash appuser
sudo usermod -aG docker appuser

# Crear directorio de aplicación
sudo mkdir -p /opt/studios-dk
sudo chown -R appuser:appuser /opt/studios-dk
```

---

## 🔒 CONFIGURACIÓN DE SEGURIDAD

### 1. Generar Variables de Entorno Seguras

```bash
# Generar contraseñas fuertes (usar en .env.prod)
openssl rand -base64 32      # JWT_SECRET
openssl rand -base64 32      # DB_PASSWORD
openssl rand -base64 32      # REDIS_PASSWORD
openssl rand -base64 32      # S3_SECRET_KEY
openssl rand -hex 32         # API_KEY_INTERNAL
openssl rand -hex 32         # API_KEY_EXTERNAL
```

### 2. Proteger Variables de Entorno

```bash
# Copiar .env.prod con permisos restrictivos
cp .env.prod.example .env.prod
chmod 600 .env.prod

# Solo propietario puede leer
ls -la .env.prod
```

### 3. Configurar SSH Hardening

```bash
# Editar /etc/ssh/sshd_config
sudo nano /etc/ssh/sshd_config

# Cambios recomendados:
Port 2222                    # Cambiar puerto por defecto
PermitRootLogin no
PasswordAuthentication no     # Solo clave privada
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
MaxSessions 5
```

### 4. Habilitar Fail2Ban

```bash
sudo apt-get install -y fail2ban

# Crear configuración
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
maxretry = 5

[sshd]
enabled = true
port = 2222
EOF

sudo systemctl restart fail2ban
```

---

## 📦 PROCESO DE DESPLIEGUE

### 1. Clonar Repositorio

```bash
cd /opt/studios-dk
git clone <tu-repo> .
cd sweet_models_enterprise
```

### 2. Configurar Variables de Entorno

```bash
# Copiar y editar
cp .env.prod.example .env.prod
nano .env.prod

# Variables CRÍTICAS a cambiar:
DOMAIN=api.studios-dk.com
DB_PASSWORD=<USAR_CONTRASEÑA_FUERTE>
REDIS_PASSWORD=<USAR_CONTRASEÑA_FUERTE>
JWT_SECRET=<USAR_OPENSSL_RAND_BASE64_32>
OPENAI_API_KEY=<TU_DEEPSEEK_API_KEY>
```

### 3. Ejecutar Despliegue Automático

```bash
# Hacer script ejecutable
chmod +x deploy-prod.sh

# Ejecutar (requiere permisos sudo)
sudo ./deploy-prod.sh

# O manual:
docker-compose -f docker-compose.prod.yml up -d
```

### 4. Verificar Despliegue

```bash
# Comprobar servicios
docker-compose -f docker-compose.prod.yml ps

# Ver logs
docker-compose -f docker-compose.prod.yml logs -f

# Prueba de conectividad
curl -k https://api.studios-dk.com/health
```

---

## ✅ POST-DESPLIEGUE

### 1. Cambiar Credenciales Iniciales

```bash
# Acceder a base de datos
docker-compose -f docker-compose.prod.yml exec postgres psql -U sme_prod_user -d sme_production

# Cambiar contraseña admin
UPDATE users SET password_hash = '<NUEVO_HASH>' WHERE email = 'admin@studios-dk.com';
```

### 2. Crear Buckets S3

```bash
# Crear bucket en MinIO
docker-compose -f docker-compose.prod.yml exec minio mc mb minio/studios-dk

# Configurar política pública si es necesario
docker-compose -f docker-compose.prod.yml exec minio \
  mc policy set public minio/studios-dk
```

### 3. Verificar Certificados SSL

```bash
# Revisar certificado
openssl s_client -connect api.studios-dk.com:443 -tls1_3

# Verificar renovación automática
docker-compose -f docker-compose.prod.yml logs certbot | tail -20
```

### 4. Configurar Backups Automáticos

```bash
# Crear script de backup
cat > backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U sme_prod_user sme_production | gzip > $BACKUP_DIR/postgres.sql.gz

# Backup MinIO
docker-compose -f docker-compose.prod.yml exec -T minio \
  tar czf - /data > $BACKUP_DIR/minio.tar.gz

echo "Backup completado en $BACKUP_DIR"
EOF

chmod +x backup.sh

# Scheduler (crontab)
0 2 * * * /opt/studios-dk/backup.sh
```

---

## 📊 MONITOREO Y MANTENIMIENTO

### 1. Prometheus & Grafana

```bash
# Acceder a Prometheus
docker-compose -f docker-compose.prod.yml exec prometheus \
  curl http://localhost:9090/api/v1/targets

# Ver métricas
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq .
```

### 2. Logs Centralizados

```bash
# Ver logs en tiempo real
docker-compose -f docker-compose.prod.yml logs -f app

# Buscar errores
docker-compose -f docker-compose.prod.yml logs | grep ERROR

# Exportar logs
docker-compose -f docker-compose.prod.yml logs > logs-export.txt
```

### 3. Health Checks

```bash
#!/bin/bash
# health-check.sh

echo "🔍 Comprobando servicios..."

# HTTP
curl -f https://api.studios-dk.com/health && echo "✓ HTTP" || echo "✗ HTTP"

# Database
docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_isready -U sme_prod_user && echo "✓ Database" || echo "✗ Database"

# Redis
docker-compose -f docker-compose.prod.yml exec -T redis \
  redis-cli ping && echo "✓ Redis" || echo "✗ Redis"

# NATS
docker-compose -f docker-compose.prod.yml exec -T nats \
  curl -s http://localhost:8222/varz > /dev/null && echo "✓ NATS" || echo "✗ NATS"
```

### 4. Monitoreo de Recursos

```bash
# CPU y Memoria
docker stats

# Almacenamiento
df -h

# Conexiones activas
netstat -an | grep ESTABLISHED | wc -l
```

---

## 🔄 RECUPERACIÓN DE DESASTRES

### 1. Backup & Restore

```bash
# Backup completo
docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U sme_prod_user sme_production | gzip > backup-$(date +%s).sql.gz

# Restaurar desde backup
gunzip < backup-1234567890.sql.gz | \
  docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U sme_prod_user sme_production
```

### 2. Rollback de Versión

```bash
# Si algo falla después del despliegue
docker-compose -f docker-compose.prod.yml down
git revert HEAD~1
docker-compose -f docker-compose.prod.yml up -d
```

### 3. Escalado Horizontal

```yaml
# En docker-compose.prod.yml, agregar múltiples instancias de app:

services:
  app1:
    build: ./backend_api
    expose:
      - "3000"
  
  app2:
    build: ./backend_api
    expose:
      - "3000"
  
  app3:
    build: ./backend_api
    expose:
      - "3000"
```

---

## 📈 OPTIMIZACIONES AVANZADAS

### 1. CDN para Contenido Estático

```nginx
# En nginx.conf
location ~* \.(jpg|jpeg|png|gif|css|js|svg)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
    # Si usas CloudFlare:
    # add_header Cloudflare-CDN "true";
}
```

### 2. Caché Distribuido

```bash
# Redis Cluster (opcional)
# Múltiples instancias de Redis con replicación
```

### 3. Base de Datos Replicada

```sql
-- PostgreSQL Replication (Primary-Standby)
-- Configurar en postgresql.conf
wal_level = replica
max_wal_senders = 10
hot_standby = on
```

---

## 🚨 ALERTAS Y NOTIFICACIONES

### Email para Alertas

```bash
# Configurar en .env.prod
SMTP_HOST=smtp.resend.io
SMTP_PASSWORD=<API_KEY>
ALERT_EMAIL=ops@studios-dk.com
```

### Webhook para Slack

```bash
# En scripts de monitoreo
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"⚠️ Alert: CPU > 80%"}'
```

---

## 📞 SOPORTE Y CONTACTO

**DevOps Team**: devops@studios-dk.com  
**Emergency Line**: +1-XXX-XXX-XXXX  
**Status Page**: https://status.studios-dk.com

---

**Última actualización**: Diciembre 2025  
**Versión**: 1.0  
**Estado**: Production Ready ✅
