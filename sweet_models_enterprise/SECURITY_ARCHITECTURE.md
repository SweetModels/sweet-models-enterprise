# 🔐 ARQUITECTURA DE SEGURIDAD - Studios DK Production

## TABLA DE CONTENIDOS

1. [Principios de Seguridad](#principios-de-seguridad)
2. [Capas de Seguridad](#capas-de-seguridad)
3. [Criptografía](#criptografía)
4. [Autenticación & Autorización](#autenticación--autorización)
5. [Red y Firewall](#red-y-firewall)
6. [Respuesta a Incidentes](#respuesta-a-incidentes)

---

## 🎯 PRINCIPIOS DE SEGURIDAD

### Defense in Depth (Defensa en Profundidad)
```
┌─────────────────────────────────────┐
│  Capa 1: Internet / Firewall        │ ← UFW/IPTables
├─────────────────────────────────────┤
│  Capa 2: WAF / Nginx Rate Limiting  │ ← Nginx
├─────────────────────────────────────┤
│  Capa 3: API Authentication         │ ← JWT + API Keys
├─────────────────────────────────────┤
│  Capa 4: Application Logic          │ ← Rust Type Safety
├─────────────────────────────────────┤
│  Capa 5: Database Permissions       │ ← Row-Level Security
├─────────────────────────────────────┤
│  Capa 6: Encryption at Rest         │ ← AES-256
└─────────────────────────────────────┘
```

### Zero Trust Model
- Verificar cada petición, incluso si vienen de dentro
- No confiar en ubicación de red
- Requiere autenticación para todo
- Principio de mínimo privilegio

### Principle of Least Privilege
```
┌─────────────────┬──────────────────┐
│ Usuario/Rol     │ Permisos Mínimos │
├─────────────────┼──────────────────┤
│ Anonymous User  │ GET /api/public  │
│ Authenticated   │ GET/POST /api    │
│ Admin           │ ALL /api/admin   │
│ Service Account │ Scope específico │
└─────────────────┴──────────────────┘
```

---

## 🔒 CAPAS DE SEGURIDAD

### 1. PERÍMETRO (Firewall)

```bash
# Inbound Rules
22/tcp   (SSH)      → Only from authorized IPs
80/tcp   (HTTP)     → All (redirect to 443)
443/tcp  (HTTPS)    → All
3000-9090/tcp       → DENY (internal only)

# Outbound Rules
Allow all (application controlled)

# IP Blocking
fail2ban active     → Block after 5 failed auth
Geo-blocking (opt)  → Block specific countries
```

### 2. GATEWAY (Nginx)

```nginx
# Rate Limiting Zones
api_limit: 100 req/sec
auth_limit: 10 req/sec
upload_limit: 5 req/sec

# Security Headers
Strict-Transport-Security: max-age=31536000
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'self'

# DDoS Protection
- Connection limiting: 10 simultaneous
- Request body size: 100MB max
- Timeout: 20s client_body_timeout
```

### 3. TRANSPORTE (TLS/SSL)

```
TLS Configuration:
├── Protocol: TLS 1.3 (primary), TLS 1.2 (fallback)
├── Cipher Suites:
│   ├── ECDHE-ECDSA-AES128-GCM-SHA256
│   ├── ECDHE-RSA-AES128-GCM-SHA256
│   └── ECDHE-RSA-AES256-GCM-SHA384
├── Certificate: Let's Encrypt
├── HSTS: max-age=31536000, preload
└── OCSP Stapling: enabled
```

### 4. APLICACIÓN (Authentication)

```rust
// JWT Token Flow
Request with "Authorization: Bearer <TOKEN>"
    ↓
Verify signature (using JWT_SECRET)
    ↓
Check expiration (86400 seconds)
    ↓
Extract claims (user_id, role, scopes)
    ↓
Proceed or deny

// Token Payload
{
  "sub": "user_id",
  "role": "admin",
  "scopes": ["api:read", "api:write"],
  "iat": 1702320000,
  "exp": 1702406400
}
```

### 5. DATOS (Database)

```sql
-- Row-Level Security (PostgreSQL)
CREATE POLICY user_isolation ON users
  USING (id = current_user_id());

-- Column-Level Encryption
password_hash: NEVER returned
api_keys: NEVER returned
sensitive_data: Encrypted with AES-256

-- Audit Trail
Every INSERT/UPDATE/DELETE logged
-- Table: audit_logs with full context
```

### 6. ALMACENAMIENTO (MinIO/S3)

```
Object Storage Security:
├── Buckets: Private by default
├── Access: Authenticated only (API keys)
├── Encryption: Server-side (AES-256)
├── Versioning: Enabled (disaster recovery)
├── ACLs: Least privilege
└── Lifecycle: Auto-delete old versions
```

---

## 🔐 CRIPTOGRAFÍA

### Algoritmos Aprobados

```
Propósito            │ Algoritmo      │ Tamaño
─────────────────────┼────────────────┼──────────
Password Hashing     │ bcrypt         │ cost=12
JWT Signing          │ HMAC-SHA256    │ 256 bits
Data Encryption      │ AES-GCM        │ 256 bits
TLS/SSL              │ ECDHE + AES    │ 256 bits
Random Token Gen     │ /dev/urandom   │ 256 bits
```

### Generación de Claves

```bash
# JWT Secret (use in .env.prod)
openssl rand -base64 32
# Output: fT8h+2kL9pQvWxYzA/B5cD7eF6gH1iJ2kL3mN4oP5qR6sT7u=

# API Keys
openssl rand -hex 32
# Output: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3

# Database Password
openssl rand -base64 16
# Output: aB9cD2eF5gH8iK1lM4nO7pQ

# Encryption Key (for sensitive data)
openssl rand -base64 32
# Output: [44 characters base64]
```

### Rotación de Keys

```bash
# Implementar rotation policy:
├── JWT_SECRET: cada 90 días
├── API_KEYS: cada 180 días
├── DB_PASSWORD: cada 365 días
├── ENCRYPTION_KEY: cuando compromised

# Proceso de rotación:
1. Generar nueva clave
2. Configurar como "active"
3. Mantener anterior como "legacy"
4. Esperar 30 días para deprecar
5. Remover clave anterior
```

---

## 🔑 AUTENTICACIÓN & AUTORIZACIÓN

### Session Management

```
User Login:
1. POST /api/auth/login
   ├── Validate credentials (bcrypt)
   ├── Check 2FA if enabled
   ├── Generate JWT token (exp: 24h)
   ├── Generate refresh token (exp: 7d)
   └── Return tokens + user info

2. Client stores:
   ├── access_token: in memory (NOT localStorage)
   ├── refresh_token: in secure httpOnly cookie

3. Requests:
   ├── Include: Authorization: Bearer <access_token>
   └── Nginx validates signature + expiration
```

### Role-Based Access Control (RBAC)

```
Roles Hierarchy:
├── super_admin
│   └── Can: Everything + user management
├── admin
│   └── Can: API operations + content management
├── moderator
│   └── Can: Content review + user support
├── authenticated_user
│   └── Can: Personal data access + API read
└── anonymous
    └── Can: Public endpoints only
```

### Scope-Based API Access

```
Scopes available:
├── api:read       → GET requests
├── api:write      → POST/PUT/DELETE requests
├── admin:manage   → Admin endpoints
├── storage:read   → Read files from S3
├── storage:write  → Upload files to S3
└── user:profile   → Read own profile

Token with scopes:
{
  "scopes": ["api:read", "storage:read"],
  "exp": 1702406400
}
```

---

## 🌐 RED Y FIREWALL

### Network Topology

```
     Internet
        │
        ▼
    ┌─────────┐
    │  Nginx  │  Port 443 (Public)
    │ Gateway │
    └────┬────┘
         │
    Internal Network (172.28.0.0/16)
    ├── App (3000)
    ├── PostgreSQL (5432)
    ├── Redis (6379)
    ├── NATS (4222)
    ├── MinIO (9000)
    └── Prometheus (9090)
```

### Firewall Rules

```bash
# UFW Configuration
sudo ufw status
     To                         Action      From
     --                         ------      ----
22/tcp                         ALLOW       Anywhere
22/tcp (v6)                    ALLOW       Anywhere (v6)
80/tcp                         ALLOW       Anywhere
80/tcp (v6)                    ALLOW       Anywhere (v6)
443/tcp                        ALLOW       Anywhere
443/tcp (v6)                   ALLOW       Anywhere (v6)
3000/tcp                       DENY        Anywhere
5432/tcp                       DENY        Anywhere
6379/tcp                       DENY        Anywhere

# Restricción por IP (ejemplo)
sudo ufw allow from 203.0.113.0/24 to any port 3000
```

### DDoS Protection

```nginx
# en nginx.conf

# 1. Connection Limiting
limit_conn_zone $binary_remote_addr zone=addr:10m;
limit_conn addr 10;  # Max 10 conexiones simultáneas

# 2. Request Rate Limiting
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;
limit_req zone=api_limit burst=200 nodelay;

# 3. Timeouts (prevenir Slowloris)
client_body_timeout 20s;
client_header_timeout 20s;
send_timeout 20s;

# 4. Buffer Limits
client_body_buffer_size 1k;
client_header_buffer_size 1k;
large_client_header_buffers 4 8k;
```

---

## 🚨 RESPUESTA A INCIDENTES

### Detección

```
Monitoring Alerts:
├── CPU > 80% para 5 min
├── Memory > 85%
├── Disk > 90%
├── Response time > 1s
├── Error rate > 1%
├── Failed login attempts > 10 in 1min
└── Unusual traffic pattern
```

### Escalonamiento

```
Level 1: Alert (automated)
  └─ Slack notification
     └─ Auto-scale if possible

Level 2: Incident (30+ min)
  ├─ Page on-call engineer
  ├─ Create incident ticket
  └─ Start incident bridge

Level 3: Crisis (service down)
  ├─ Execute incident response plan
  ├─ Notify stakeholders
  └─ Consider rollback
```

### Procedimiento de Rollback

```bash
#!/bin/bash
# Disaster Recovery Plan

echo "🚨 EXECUTING EMERGENCY ROLLBACK"

# 1. Stop services
docker-compose -f docker-compose.prod.yml down

# 2. Restore from backup
gunzip < backup-latest.sql.gz | \
  docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U sme_prod_user sme_production

# 3. Restore code
git checkout HEAD~1

# 4. Start services
docker-compose -f docker-compose.prod.yml up -d

# 5. Verify
sleep 10
curl https://api.studios-dk.com/health

echo "✅ Rollback completed. Investigate cause."
```

### Post-Incident

```
Postmortem Meeting (24-48h):
1. What happened?
   └─ Timeline of events
2. Why did it happen?
   └─ Root cause analysis
3. How do we prevent it?
   └─ Action items with owners
4. How do we detect it faster?
   └─ Monitoring improvements
5. Update runbooks & procedures
```

---

## 📋 CHECKLIST MENSUAL DE SEGURIDAD

- [ ] Revisar logs de audit
- [ ] Actualizar dependencias
- [ ] Revisar acceso de usuarios
- [ ] Verificar certificados SSL
- [ ] Realizar backup test
- [ ] Revisar políticas de firewall
- [ ] Verificar rotación de logs
- [ ] Revisar alertas de seguridad
- [ ] Actualizar runbooks
- [ ] Realizar security drill

---

## 📚 REFERENCIAS

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- CIS Docker Benchmark: https://www.cisecurity.org/benchmark/docker/
- PostgreSQL Security: https://www.postgresql.org/docs/current/sql-syntax-lexical.html
- NIST Cybersecurity Framework: https://www.nist.gov/cyberframework/

---

**Última revisión**: Diciembre 2025  
**Responsable de Seguridad**: [DevOps Lead]  
**Próxima revisión**: Enero 2026
