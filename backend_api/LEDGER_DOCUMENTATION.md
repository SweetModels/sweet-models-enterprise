# 🔐 Módulo Ledger - Cadena de Auditoría Blockchain

## Descripción General

El módulo `finance/ledger.rs` implementa un sistema de **blockchain criptográfico** para garantizar la **inmutabilidad e integridad** de todas las transacciones financieras en Sweet Models Enterprise.

Este sistema es crítico para:

- ✅ **Auditoría**: Historial completo y verificable de transacciones
- ✅ **Cumplimiento**: Regulaciones financieras y antilavado
- ✅ **Transparencia**: Prueba criptográfica de transacciones
- ✅ **Seguridad**: Imposible modificar transacciones posteriores sin detectarse


## Arquitectura

### Estructura de Bloque (`Block`)

```rust
pub struct Block {
    pub id: Uuid,                           // Identificador único
    pub prev_hash: String,                  // SHA3-512 del bloque anterior
    pub data: Value,                        // JSON con datos de transacción
    pub nonce: u64,                         // Timestamp-based proof
    pub hash: String,                       // SHA3-512 del bloque completo
    pub timestamp: chrono::DateTime<Utc>,   // Timestamp de sellado
}

```

### Hash Criptográfico

El hash de cada bloque se calcula como:

```

SHA3-512(id + prev_hash + data + nonce)

```

Esto garantiza que cualquier modificación en:

- ID del bloque
- Hash anterior
- Datos de transacción
- Nonce


...resultará en un hash completamente diferente, detectando inmediatamente la corrupción.

## Datos de Transacción

```rust
pub struct TransactionData {
    pub tx_type: String,        // "payment", "refund", "transfer"
    pub user_id: Uuid,          // ID del usuario
    pub amount: f64,            // Monto
    pub currency: String,       // "COP", "USD", "USDT"
    pub description: String,    // Descripción
    pub metadata: Option<Value>,// Datos adicionales (JSON)
}

```

## Funciones Principales

### 1. `seal_transaction(transaction_data, pool)`

Sella una nueva transacción en la cadena.

**Proceso:**
1. Obtiene el último bloque (su hash)
2. Crea nuevo bloque enlazado al anterior
3. Calcula SHA3-512 del bloque completo
4. Valida que el hash sea correcto
5. Guarda en `audit_ledger`
**Ejemplo de uso:**


```rust
let tx_data = TransactionData {
    tx_type: "payment".to_string(),
    user_id: user_id,
    amount: 100.50,
    currency: "COP".to_string(),
    description: "Pago por contenido".to_string(),
    metadata: None,
};

let block = seal_transaction(tx_data, &pool).await?;
println!("✅ Transacción sellada: {}", block.hash);

```

### 2. `verify_chain_integrity(pool)`

Verifica que toda la cadena sea íntegra.

**Validaciones:**
- Cada `prev_hash` coincide con el hash anterior
- Cada hash de bloque es criptográficamente válido
- No hay saltos o desconexiones
**Retorna:** `Ok(true)` si la cadena es válida, `Ok(false)` si está comprometida


```rust
let is_valid = verify_chain_integrity(&pool).await?;
if is_valid {
    println!("✅ Cadena íntegra");
} else {
    println!("❌ Cadena comprometida");
}

```

### 3. `get_user_transaction_history(user_id, pool)`

Obtiene el historial completo de transacciones de un usuario.

```rust
let history = get_user_transaction_history(user_id, &pool).await?;
for (block, tx) in history {
    println!("Transacción: {} | Monto: {} {}",

        tx.tx_type, tx.amount, tx.currency);
}

```

## Handlers HTTP

### POST `/api/ledger/seal`

Sella una nueva transacción.

**Request:**


```json
{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "amount": 100.50,
    "currency": "COP",
    "description": "Pago por contenido",
    "tx_type": "payment"
}

```

**Response (201 Created):**


```json
{
    "block_id": "550e8400-e29b-41d4-a716-446655440001",
    "hash": "a3f5b2c8d4e1...",
    "prev_hash": "f7e8d9c1b2a3...",
    "timestamp": "2025-12-07T10:30:00Z",
    "message": "✅ Transacción sellada en cadena de auditoría"
}

```

### GET `/api/ledger/verify`

Verifica la integridad de la cadena.

**Response (200 OK):**


```json
{
    "is_valid": true,
    "message": "✅ Cadena de auditoría íntegra y válida",
    "total_blocks": 1234
}

```

### GET `/api/ledger/history/{user_id}`

Obtiene el historial de transacciones de un usuario.

**Response (200 OK):**


```json
{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "total_amount": 5000.00,
    "transactions": [
        {
            "block_id": "550e8400-e29b-41d4-a716-446655440001",
            "tx_type": "payment",
            "amount": 100.50,
            "currency": "COP",
            "timestamp": "2025-12-07T10:30:00Z",
            "hash": "a3f5b2c8d4e1..."
        }
    ]
}

```

## Base de Datos

### Tabla `audit_ledger`

```sql
CREATE TABLE audit_ledger (
    id UUID PRIMARY KEY,
    prev_hash VARCHAR(128) NOT NULL,    -- Hash SHA3-512 anterior
    data JSONB NOT NULL,                -- Datos de transacción
    nonce BIGINT NOT NULL,              -- Timestamp proof
    hash VARCHAR(128) NOT NULL UNIQUE,  -- Hash SHA3-512 del bloque
    timestamp TIMESTAMP WITH TIME ZONE  -- Cuando se selló
);

```

### Índices

- `idx_audit_ledger_user_id`: Búsqueda rápida por usuario
- `idx_audit_ledger_timestamp`: Orden cronológico
- `idx_audit_ledger_tx_type`: Búsqueda por tipo de transacción
- `idx_audit_ledger_hash`: Validación de integridad
- `idx_audit_ledger_prev_hash`: Encadenamiento


### Vistas

#### `user_transaction_audit`

Historial de transacciones por usuario con todos los detalles.

#### `ledger_chain_status`

Estado actual de la cadena (total de bloques, últimas transacciones, etc.).

## Garantías de Seguridad

### 1. **Inmutabilidad de Datos**

Si alguien intenta modificar una transacción anterior:

- El hash de ese bloque cambia
- El `prev_hash` del siguiente bloque ya no coincide
- La verificación de integridad falla inmediatamente


```

Cadena Original:
Bloque 1: hash = H1
Bloque 2: prev_hash = H1, hash = H2
Bloque 3: prev_hash = H2, hash = H3

Intento de Modificación:
Bloque 1: [modificado] hash = H1'
Bloque 2: prev_hash = H1 (NO COINCIDE CON H1')
❌ Verificación fallida

```

### 2. **Integridad Criptográfica**

Usa **SHA3-512** (último estándar NIST):

- 512 bits de salida
- Resistente a ataques de colisión
- Imposible encontrar dos bloques con el mismo hash


### 3. **Cadena Temporal**

El `nonce` es timestamp-based:

- Imposible crear bloques retroactivos
- Orden cronológico garantizado
- Previene ataques de replay


### 4. **Auditoría Completa**

Cada transacción:

- Está ligada a la anterior criptográficamente
- Incluye timestamp verificable
- Almacena metadata completa
- Puede ser auditada de forma independiente


## Pruebas

El módulo incluye tests unitarios:

```rust
#[test]
fn test_block_creation_and_validation() {
    // Verifica que los bloques se crean correctamente
}

#[test]
fn test_block_hash_consistency() {
    // Verifica que bloques idénticos tienen el mismo hash
}

#[test]
fn test_invalid_block_hash() {
    // Verifica que la validación detecta hashes inválidos
}

```

Ejecutar tests:

```bash
cargo test finance::ledger

```

## Integración en main.rs

Los handlers se pueden integrar en el router HTTP:

```rust
let app = Router::new()
    .route("/api/ledger/seal", post(seal_transaction_handler))
    .route("/api/ledger/verify", get(verify_chain_handler))
    .route("/api/ledger/history/:user_id", get(user_transaction_history_handler))
    // ... más rutas
    .with_state(pool);

```

## Consideraciones de Rendimiento

- **O(1)** para sellar: Una inserción en base de datos
- **O(n)** para verificar: Recorre todos los bloques (idealmente ejecutar periodicamente)
- Índices de base de datos optimizan búsquedas
- JSON queries en PostgreSQL son eficientes


## Cumplimiento Regulatorio

Este módulo ayuda a cumplir:

- ✅ **Ley 1870 de 2023** (Colombia): Regulación de criptoactivos
- ✅ **FATF (Financial Action Task Force)**: AML/KYC
- ✅ **ISO/IEC 27001**: Auditoría y trazabilidad
- ✅ **SOX (Sarbanes-Oxley)**: Integridad de registros financieros
---
**Última actualización:** Diciembre 7, 2025
**Autor:** Experto en Criptografía
**Estado:** ✅ Producción
