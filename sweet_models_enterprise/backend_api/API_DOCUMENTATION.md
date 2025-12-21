# Sweet Models Enterprise API v2.0 - Documentación

## 🎯 Características Implementadas

### 1. Sistema de Doble TRM (Tasa Representativa del Mercado)

- Cálculo dinámico de nómina basado en tokens y TRM
- Dos escalas de porcentajes:
  - **Grupos pequeños (<10,000 tokens)**: Modelo 60% / Studio 40%
  - **Grupos grandes (≥10,000 tokens)**: Modelo 65% / Studio 35%
- Cálculo dinámico de nómina basado en tokens y TRM
- Dos escalas de porcentajes:
  - **Grupos pequeños (<10,000 tokens)**: Modelo 60% / Studio 40%
  - **Grupos grandes (≥10,000 tokens)**: Modelo 65% / Studio 35%


### 2. Gestión de TRM

- Endpoint administrativo para actualizar la TRM diaria
- Consulta del valor actual de TRM
- Almacenamiento en base de datos con historial
- Endpoint administrativo para actualizar la TRM diaria
- Consulta del valor actual de TRM
- Almacenamiento en base de datos con historial


### 3. Registro Avanzado de Modelos

- Campos adicionales: teléfono, dirección, cédula
- Validación de datos de identidad
- Preparación para autenticación biométrica
- Campos adicionales: teléfono, dirección, cédula
- Validación de datos de identidad
- Preparación para autenticación biométrica


### 4. Monitoreo de Cámaras

- Lista de cámaras de streaming RTSP
- Estado activo/inactivo
- Asociación con modelos y plataformas
- Lista de cámaras de streaming RTSP
- Estado activo/inactivo
- Asociación con modelos y plataformas
---


## 📡 Endpoints Disponibles

### Autenticación

#### `POST /setup_admin`

Crear usuario administrador

**Request:**


```json
{
  "email": "admin`@example.com`",
  "password": "SecurePassword123"
}

```

**Response:**


```json
{
  "message": "Admin user created successfully",
  "email": "admin`@example.com`",
  "role": "admin"
}

```

---


#### `POST /login`

Iniciar sesión

**Request:**


```json
{
  "email": "user`@example.com`",
  "password": "password"
}

```

**Response:**


```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "role": "admin",
  "user_id": "uuid-here"
}

```

---


#### `POST /register`

Registro básico de usuario

**Request:**


```json
{
  "email": "newuser`@example.com`",
  "password": "SecurePass123"
}

```

**Response:**


```json
{
  "user_id": "uuid-here",
  "email": "newuser`@example.com`",
  "role": "model",
  "message": "User registered successfully"
}

```

---


#### `POST /register_model`

Registro avanzado de modelo (con datos completos)

**Request:**


```json
{
  "email": "modelo`@example.com`",
  "password": "SecurePass123",
  "phone": "3001234567",
  "address": "Calle 123 #45-67",
  "national_id": "1234567890"
}

```

**Response:**


```json
{
  "user_id": "uuid-here",
  "email": "modelo`@example.com`",
  "role": "model",
  "message": "Model registered successfully. Verification pending."
}

```

**Validaciones:**
- Email: Formato válido
- Password: Mínimo 8 caracteres
- Phone: Mínimo 10 dígitos
- National ID: Mínimo 6 caracteres, único
---


### Gestión Financiera

#### `POST /admin/trm`

Actualizar TRM diaria (Solo Admin)

**Request:**


```json
{
  "trm_value": 4150.0
}

```

**Response:**


```json
{
  "trm_value": 4150.0,
  "updated_at": "2025-12-04T09:37:35Z",
  "updated_by": "admin"
}

```

**Validaciones:**
- TRM debe estar entre 3000 y 6000
---


#### `GET /admin/trm`

Consultar TRM actual

**Response:**


```json
{
  "trm_value": 4150.0,
  "updated_at": "2025-12-04T09:37:35Z",
  "updated_by": "system"
}

```

---


#### `POST /api/payroll/calculate`

Calcular nómina con sistema Doble TRM

**Request:**


```json
{
  "group_tokens": 15000,
  "members_count": 8,
  "manual_trm": 4150.0  // Opcional, si no se envía usa el TRM de la BD
}

```

**Response:**


```json
{
  "model_payment": 234609.375,
  "studio_revenue": 1089375.0,
  "tokens_total": 15000.0,
  "members_count": 8,
  "trm_used": 4150.0,
  "model_percentage": 65.0,
  "studio_percentage": 35.0
}

```

**Fórmulas:**
- **Pago Modelo** = (Tokens / Miembros) × % × 0.05 × (TRM - 300)
- **Ganancia Studio** = Tokens Total × % × 0.05 × TRM
**Porcentajes:**
- Grupos < 10,000 tokens: Modelo 60% / Studio 40%
- Grupos ≥ 10,000 tokens: Modelo 65% / Studio 35%
---


#### `POST /api/financial_planning`

Planificación financiera personal

**Request:**


```json
{
  "amount": 10000000,
  "risk_tolerance": "moderate"
}

```

**Response:**


```json
{
  "total_amount": 10000000.0,
  "stocks_percentage": 50.0,
  "bonds_percentage": 30.0,
  "cash_percentage": 20.0,
  "stocks_amount": 5000000.0,
  "bonds_amount": 3000000.0,
  "cash_amount": 2000000.0,
  "risk_tolerance": "moderate"
}

```

**Perfiles de Riesgo:**
- `conservative`: 30% acciones, 50% bonos, 20% efectivo
- `moderate`: 50% acciones, 30% bonos, 20% efectivo
- `aggressive`: 70% acciones, 20% bonos, 10% efectivo
---


### Monitoreo

#### `GET /admin/cameras`

Lista de cámaras de streaming (Solo Admin)

**Response:**


```json
{
  "cameras": [
    {
      "id": 1,
      "name": "Main Studio Cam 1",
      "stream_url": "rtsp://192.168.1.100:554/stream1",
      "platform": "Studio",
      "is_active": true
    },
    {
      "id": 2,
      "name": "Main Studio Cam 2",
      "stream_url": "rtsp://192.168.1.101:554/stream1",
      "platform": "Studio",
      "is_active": true
    }
  ],
  "total_active": 4
}

```

---


#### `GET /dashboard`

Métricas del dashboard

**Response:**


```json
{
  "groups": [
    {
      "name": "VIP Models WhatsApp",
      "platform": "WhatsApp",
      "total_tokens": 15000.0,
      "members_count": 25,
      "payout_per_member_cop": 45000.0,
      "created_at": "2025-12-04T..."
    }
  ],
  "total_tokens": 46500.0,
  "total_members": 24,
  "total_payout_cop": 5543525.0,
  "trm_used": 4150.0
}

```

---


### Sistema

#### `GET /health`

Estado del sistema

**Response:**


```json
{
  "status": "healthy",
  "version": "2.0.0",
  "features": [
    "doble_trm",
    "biometric_auth",
    "camera_monitoring"
  ]
}

```

---


## 🗄️ Esquema de Base de Datos

### Tabla `users`

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'model',
    phone TEXT,
    address TEXT,
    national_id TEXT UNIQUE,
    is_verified BOOLEAN DEFAULT FALSE,
    biometric_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

```

### Tabla `financial_config`

```sql
CREATE TABLE financial_config (
    id SERIAL PRIMARY KEY,
    config_key TEXT UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    description TEXT
);

```

### Tabla `cameras`

```sql
CREATE TABLE cameras (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    stream_url TEXT NOT NULL,
    model_id UUID REFERENCES users(id),
    platform TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_active_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

```

### Tabla `groups`

```sql
CREATE TABLE groups (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    platform TEXT NOT NULL,
    user_id UUID REFERENCES users(id),
    total_tokens NUMERIC(12, 2) NOT NULL,
    members_count INTEGER NOT NULL,
    payout_per_member_cop NUMERIC(12, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

```

---


## 🧮 Ejemplos de Cálculos

### Ejemplo 1: Grupo Pequeño (8,000 tokens, 5 miembros)

**Input:**
- Tokens: 8,000
- Miembros: 5
- TRM: 4,150
**Cálculo:**
- Porcentajes: Modelo 60%, Studio 40% (< 10k tokens)
- Tokens por miembro: 8,000 / 5 = 1,600
- Pago por modelo: 1,600 × 0.60 × 0.05 × (4,150 - 300) = **184,800 COP**
- Ganancia studio: 8,000 × 0.40 × 0.05 × 4,150 = **664,000 COP**
---


### Ejemplo 2: Grupo Grande (15,000 tokens, 8 miembros)

**Input:**
- Tokens: 15,000
- Miembros: 8
- TRM: 4,150
**Cálculo:**
- Porcentajes: Modelo 65%, Studio 35% (≥ 10k tokens)
- Tokens por miembro: 15,000 / 8 = 1,875
- Pago por modelo: 1,875 × 0.65 × 0.05 × (4,150 - 300) = **234,609.38 COP**
- Ganancia studio: 15,000 × 0.35 × 0.05 × 4,150 = **1,089,375 COP**
---


## 🔒 Seguridad

- **Autenticación**: JWT tokens con expiración de 24 horas
- **Contraseñas**: Hashing con Argon2 (OWASP recomendado)
- **CORS**: Configurado permisivo (ajustar en producción)
- **Validaciones**: Email, teléfono, cédula, rangos de TRM
---


## 🚀 Comandos de Prueba

### Actualizar TRM

```powershell
$body = @{trm_value=4200.0} | ConvertTo-Json

Invoke-WebRequest -Uri "`http://localhost:3000/admin/trm`" -Method POST -ContentType "application/json" -Body $body

```

### Calcular Nómina

```powershell
$body = @{group_tokens=12000; members_count=6} | ConvertTo-Json

Invoke-WebRequest -Uri "`http://localhost:3000/api/payroll/calculate`" -Method POST -ContentType "application/json" -Body $body

```

### Registrar Modelo

```powershell
$body = @{
    email="modelo2`@example.com`"
    password="SecurePass123"
    phone="3109876543"
    address="Carrera 10 #20-30"
    national_id="9876543210"
} | ConvertTo-Json

Invoke-WebRequest -Uri "`http://localhost:3000/register_model`" -Method POST -ContentType "application/json" -Body $body

```

---


## 📊 Estado del Sistema

- **Backend**: Rust 1.88 + Axum + SQLx
- **Base de Datos**: PostgreSQL 16-alpine
- **Puerto**: 3000
- **Migraciones**: Automáticas al inicio
- **Logs**: tracing con nivel INFO
---


## ✨ Próximas Características

1. ✅ Sistema Doble TRM - **IMPLEMENTADO**
2. ✅ Registro avanzado de modelos - **IMPLEMENTADO**
3. ✅ Gestión de cámaras - **IMPLEMENTADO**
4. ⏳ Autenticación biométrica - EN PROGRESO
5. ⏳ Webhooks para notificaciones
6. ⏳ Dashboard de analíticas en tiempo real
7. ⏳ Integración con plataformas de streaming
---
**Versión**: 2.0.0
**Fecha**: Diciembre 2025
**Autor**: Sweet Models Enterprise Team
