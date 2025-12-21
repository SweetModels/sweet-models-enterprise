# Sistema de Autenticación - Sweet Models Enterprise

## 📁 Estructura del Proyecto

El sistema de autenticación está organizado de forma modular:

```
backend_api/
├── src/
│   ├── models/
│   │   ├── mod.rs
│   │   └── user.rs          # Modelo User (coincide con tabla PostgreSQL)
│   ├── services/
│   │   ├── mod.rs
│   │   ├── password.rs      # Hashing Argon2
│   │   └── jwt.rs           # Generación y validación de JWT
│   ├── handlers/
│   │   ├── mod.rs
│   │   └── auth.rs          # Endpoint POST /api/auth/login
│   ├── bin/
│   │   └── gen_hash.rs      # Utilidad para generar hashes
│   ├── main.rs              # Servidor principal (completo)
│   └── main_auth.rs         # Servidor de autenticación (mínimo)
├── migrations/
│   ├── 20251217_create_users_table.up.sql
│   ├── 20251217_create_users_table.down.sql
│   ├── 20251217_alter_users_table.up.sql
│   └── 20251217_alter_users_table.down.sql
├── test_login.ps1           # Script de prueba
└── Cargo.toml
```

## 🔐 Componentes del Sistema

### 1. Modelo de Usuario (`models/user.rs`)

El struct `User` mapea directamente a la tabla `users` en PostgreSQL:

```rust
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub password_hash: String,  // Hash Argon2
    pub role: String,            // user, admin, model, monitor
    pub full_name: Option<String>,
    pub platform_usernames: Option<serde_json::Value>,  // JSONB
    pub is_active: bool,
    // ... otros campos
}
```

**Structs adicionales:**
- `LoginRequest`: Email + password para autenticación
- `LoginResponse`: Token JWT + role + name + user_id

### 2. Servicio de Password (`services/password.rs`)

Usa **Argon2** para hashing seguro de contraseñas.

#### Funciones principales:

- `hash_password(password: &str) -> Result<String, PasswordError>`
  - Genera salt aleatorio
  - Hashea con Argon2 (parámetros seguros por defecto)
  - Retorna hash en formato PHC

- `verify_password(password: &str, password_hash: &str) -> Result<bool, PasswordError>`
  - Parsea el hash almacenado
  - Verifica la contraseña contra el hash
  - Retorna `true` si coincide

### 3. Servicio de JWT (`services/jwt.rs`)

Genera y valida tokens **JSON Web Token (JWT)**.

#### Claims incluidos:
```rust
pub struct Claims {
    pub sub: String,          // User ID (UUID)
    pub email: String,        // Email del usuario
    pub role: String,         // ADMIN, MODEL, MONITOR
    pub name: Option<String>, // Nombre completo
    pub exp: i64,             // Expiración (Unix timestamp)
    pub iat: i64,             // Emisión (Unix timestamp)
}
```

#### Funciones principales:

- `generate_jwt(user_id, email, role, name) -> Result<String, JwtError>`
  - Crea claims con expiración de 24 horas
  - Firma con clave secreta (HS256)
  - Retorna token JWT string

- `validate_jwt(token: &str) -> Result<Claims, JwtError>`
  - Valida firma y expiración
  - Decodifica claims
  - Retorna datos del usuario

### 4. Handler de Autenticación (`handlers/auth.rs`)

#### Endpoint: `POST /api/auth/login`

**Request:**
```json
{
  "email": "modelo@sweet.com",
  "password": "modelo123"
}
```

**Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "role": "model",
  "name": "Usuario Modelo",
  "user_id": "5cc2ce93-49ea-437e-9239-28888bb0989a"
}
```

**Respuestas de error:**
- `400 Bad Request`: Email o password vacíos
- `401 Unauthorized`: Credenciales incorrectas o cuenta inactiva
- `500 Internal Server Error`: Error de base de datos

#### Flujo de autenticación:

1. **Validar campos**: Email y password no vacíos
2. **Buscar usuario**: Query a PostgreSQL por email
3. **Verificar cuenta activa**: `is_active = true`
4. **Verificar contraseña**: Argon2 verification
5. **Generar JWT**: Token válido por 24 horas
6. **Retornar**: Token + datos del usuario

## 🚀 Uso

### 1. Generar hash de contraseña

```powershell
cargo run --bin gen_hash <contraseña>
```

Ejemplo:
```powershell
cargo run --bin gen_hash modelo123
```

Output:
```
✅ Hash generado exitosamente:

$argon2id$v=19$m=19456,t=2,p=1$VKfc8Iq6/58K49BeXRNQkw$eulixTav0gINkuQKIjHQpwd71Rz4GebexJPDy7ltKPk

📋 Para insertar en PostgreSQL:

INSERT INTO users (email, password_hash, role, full_name)
VALUES (
  'usuario@sweet.com',
  '$argon2id$v=19$m=19456,t=2,p=1$...',
  'MODEL',
  'Nombre del Usuario'
);
```

### 2. Iniciar servidor de autenticación

```powershell
cd backend_api
cargo run --bin main_auth
```

Output esperado:
```
🚀 Starting Sweet Models Enterprise Backend API
📊 Connecting to database...
✅ Database connected successfully
🌐 Server listening on http://0.0.0.0:3000

📋 Available endpoints:
  POST /api/auth/login - Autenticación de usuarios
  GET  /health         - Health check
```

### 3. Probar login manualmente

```powershell
$body = @{
    email = "modelo@sweet.com"
    password = "modelo123"
} | ConvertTo-Json

$response = Invoke-RestMethod `
    -Uri "http://localhost:3000/api/auth/login" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

$response | ConvertTo-Json
```

### 4. Ejecutar tests automatizados

```powershell
cd backend_api
.\test_login.ps1
```

El script prueba:
- ✅ Login exitoso con credenciales válidas
- ❌ Contraseña incorrecta (debe rechazar)
- ❌ Usuario inexistente (debe rechazar)
- ❌ Campos vacíos (debe rechazar)

## 🔧 Configuración

### Variables de entorno

Crear archivo `.env` en `backend_api/`:

```env
DATABASE_URL=postgres://sme_user:sme_password@localhost:5432/sme_db
RUST_LOG=info
JWT_SECRET=your-secret-key-change-in-production-minimum-32-chars-12345
```

**⚠️ IMPORTANTE:** Cambiar `JWT_SECRET` en producción!

### Base de datos

Las migraciones están en `backend_api/migrations/`:

```powershell
# Aplicar migración (crear tabla users)
Get-Content migrations/20251217_create_users_table.up.sql | `
    docker exec -i sme_postgres psql -U sme_user -d sme_db

# Agregar columnas (full_name, platform_usernames, is_active)
Get-Content migrations/20251217_alter_users_table.up.sql | `
    docker exec -i sme_postgres psql -U sme_user -d sme_db
```

## 📊 Schema de la tabla users

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('ADMIN', 'MODEL', 'MONITOR')),
    full_name VARCHAR(255),
    platform_usernames JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- ... otros campos
);

-- Índices
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_platform_usernames ON users USING GIN (platform_usernames);
```

## 🧪 Testing

### Crear usuario de prueba

```sql
-- 1. Generar hash
-- cargo run --bin gen_hash modelo123

-- 2. Insertar usuario
INSERT INTO users (email, password_hash, role, full_name)
VALUES (
    'modelo@sweet.com',
    '$argon2id$v=19$m=19456,t=2,p=1$VKfc8Iq6/58K49BeXRNQkw$eulixTav0gINkuQKIjHQpwd71Rz4GebexJPDy7ltKPk',
    'MODEL',
    'Usuario Modelo'
);
```

### Verificar token JWT

Puedes decodificar el token en https://jwt.io/

Claims esperados:
```json
{
  "sub": "5cc2ce93-49ea-437e-9239-28888bb0989a",
  "email": "modelo@sweet.com",
  "role": "MODEL",
  "name": "Usuario Modelo",
  "exp": 1734566318,
  "iat": 1734479918
}
```

## 🔒 Seguridad

### Hashing de contraseñas
- **Algoritmo**: Argon2id (ganador de Password Hashing Competition)
- **Parámetros**: m=19456, t=2, p=1 (configuración segura por defecto)
- **Salt**: Aleatorio de 128 bits por contraseña
- **Output**: ~100 caracteres en formato PHC

### JWT Tokens
- **Algoritmo**: HS256 (HMAC-SHA256)
- **Expiración**: 24 horas
- **Clave secreta**: 32+ caracteres (cambiar en producción)
- **Claims**: User ID, email, role, name

### Validaciones
- ✅ Email y password obligatorios
- ✅ Usuario debe existir en DB
- ✅ Cuenta debe estar activa (`is_active = true`)
- ✅ Contraseña verificada con timing-safe comparison
- ✅ Token firmado y con expiración

## 📝 Próximos pasos

- [ ] Refresh tokens (expiración de 30 días)
- [ ] Logout (invalidar tokens)
- [ ] Rate limiting (prevenir brute force)
- [ ] 2FA/MFA (autenticación de dos factores)
- [ ] Recuperación de contraseña (reset password)
- [ ] Registro de usuarios (signup)
- [ ] Middleware de autorización por rol
- [ ] Logging de intentos fallidos (audit trail)

## 🐛 Troubleshooting

### Error: "Failed to connect to PostgreSQL"
```
✅ Verificar que Docker esté corriendo
✅ Verificar que el contenedor sme_postgres esté activo
✅ Verificar DATABASE_URL en .env
```

### Error: "Invalid credentials"
```
✅ Verificar que el email existe en la DB
✅ Verificar que la contraseña coincida con el hash
✅ Usar cargo run --bin gen_hash para regenerar hash
```

### Error: "Account disabled"
```
✅ Verificar que is_active = true en la DB
✅ UPDATE users SET is_active = true WHERE email = 'email@example.com';
```

## 📚 Referencias

- [Argon2 RFC 9106](https://www.rfc-editor.org/rfc/rfc9106.html)
- [JWT RFC 7519](https://www.rfc-editor.org/rfc/rfc7519)
- [Axum Web Framework](https://docs.rs/axum/)
- [SQLx PostgreSQL](https://docs.rs/sqlx/)
