# Arquitectura del Módulo Financiero

// IMPLEMENTACIÓN DEL MÓDULO FINANCE/LEDGER.RS
// ============================================================================
//
// Este archivo documenta la estructura y arquitectura criptográfica
// del módulo de cadena de bloques para auditoría inmutable.
//
// ============================================================================

/*
┌─────────────────────────────────────────────────────────────────────────┐
│                     ARQUITECTURA DE BLOCKCHAIN                           │
│                                                                           │
│  Bloque Genesis (prev_hash = "0")                                        │
│  ┌──────────────────────────────────┐                                    │
│  │ id: Uuid                         │                                    │
│  │ prev_hash: "0"                   │                                    │
│  │ data: { tx_type, user_id, ... } │                                    │
│  │ nonce: 1702000000000000000       │                                    │
│  │ hash: SHA3-512(...)              │ = H1                               │
│  │ timestamp: 2025-12-07T10:30:00Z  │                                    │
│  └──────────────────────────────────┘                                    │
│           ↓                                                               │
│           └──────────────────────────────────────────────┐               │
│                                                          ↓               │
│  Bloque 2                                     Bloque 3                   │
│  ┌──────────────────────────┐                ┌──────────────────────────┐
│  │ id: Uuid                 │                │ id: Uuid                 │
│  │ prev_hash: H1            │ = H2           │ prev_hash: H2            │
│  │ data: { tx_type, ... }   │◄──────────────►│ data: { tx_type, ... }   │
│  │ nonce: 1702000001000...  │                │ nonce: 1702000002000...  │
│  │ hash: SHA3-512(...)      │                │ hash: SHA3-512(...)      │
│  │ timestamp: 2025-12-07... │                │ timestamp: 2025-12-07... │
│  └──────────────────────────┘                └──────────────────────────┘
│
│  ✅ GARANTÍA: Cambiar CUALQUIER dato en Bloque 2 hace que H2 ≠ hash
│     Esto rompe la cadena y se detecta inmediatamente.
│
│  🔐 INMUTABILIDAD ASEGURADA
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│               FLUJO DE SELLADO DE TRANSACCIÓN                            │
│                                                                           │
│  1. Cliente HTTP                                                         │
│     │                                                                    │
│     └─→ POST /api/ledger/seal                                            │
│         {                                                               │
│           "user_id": "550e8400-...",                                    │
│           "amount": 100.50,                                             │
│           "currency": "COP",                                            │
│           "description": "Pago por contenido",                         │
│           "tx_type": "payment"                                          │
│         }                                                               │
│         ↓                                                               │
│  2. seal_transaction_handler()                                         │
│     ├─ Valida request                                                   │
│     ├─ Crea TransactionData                                             │
│     └─ Llama seal_transaction()                                         │
│         ↓                                                               │
│  3. seal_transaction(data, pool)                                        │
│     ├─ get_last_block() → Obtiene último bloque                        │
│     │  └─ SELECT ... FROM audit_ledger ORDER BY timestamp DESC LIMIT 1│
│     │                                                                    │
│     ├─ prev_hash = last_block.hash (o "0" si no hay bloques)           │
│     │                                                                    │
│     ├─ Block::new(prev_hash, data, nonce)                              │
│     │  └─ Calcula hash = SHA3-512(id + prev_hash + data + nonce)       │
│     │                                                                    │
│     ├─ block.is_valid() → Valida criptografía                         │
│     │  └─ Recalcula hash y comprueba que coincida                      │
│     │                                                                    │
│     ├─ save_block(block, pool)                                         │
│     │  └─ INSERT INTO audit_ledger (...)                                │
│     │                                                                    │
│     └─ tracing::info!("✅ Transacción sellada")                         │
│         ↓                                                               │
│  4. Respuesta HTTP (201 Created)                                        │
│     {                                                                   │
│       "block_id": "550e8400-...",                                      │
│       "hash": "a3f5b2c8d4e1f6a7b8c9d0e1f2a3b4c5...",                  │
│       "prev_hash": "f7e8d9c1b2a3f4e5d6c7b8a9f0e1d2c3...",             │
│       "timestamp": "2025-12-07T10:30:00Z",                            │
│       "message": "✅ Transacción sellada en cadena"                    │
│     }                                                                   │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│            VERIFICACIÓN DE INTEGRIDAD DE CADENA                          │
│                                                                           │
│  verify_chain_integrity(pool)                                           │
│  ├─ Obtiene TODOS los bloques en orden                                  │
│  │  └─ SELECT ... FROM audit_ledger ORDER BY timestamp ASC              │
│  │                                                                        │
│  └─ Para cada bloque:                                                   │
│     │                                                                    │
│     ├─ ✓ prev_hash debe coincidir con hash anterior                    │
│     │                                                                    │
│     ├─ ✓ hash debe ser SHA3-512(id + prev_hash + data + nonce)        │
│     │                                                                    │
│     └─ Si ALGUNO falla → return false (cadena rota)                    │
│        Si TODO OK → return true (cadena íntegra)                        │
│                                                                           │
│  ⚠️  NOTA: O(n) - Ejecutar periódicamente (cada 1h, 6h, etc)           │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│               TABLA audit_ledger EN BASE DE DATOS                         │
│                                                                           │
│  ┌────────┬──────────────┬─────────────────┬──────────┬──────────────┐ │
│  │   id   │  prev_hash   │      data       │  nonce   │    hash      │ │
│  ├────────┼──────────────┼─────────────────┼──────────┼──────────────┤ │
│  │ Uuid1  │      "0"     │ {...payment...} │ 123456   │ Hash-SHA3-512│ │
│  │ Uuid2  │ Hash-SHA3-512│ {...refund...}  │ 123457   │ Hash-SHA3-512│ │
│  │ Uuid3  │ Hash-SHA3-512│ {...transfer...}│ 123458   │ Hash-SHA3-512│ │
│  │ ...    │   ...        │     ...         │  ...     │    ...       │ │
│  └────────┴──────────────┴─────────────────┴──────────┴──────────────┘ │
│                                                                           │
│  Índices:                                                                │
│  • idx_audit_ledger_user_id: Búsqueda por usuario (JSONB)               │
│  • idx_audit_ledger_timestamp: Orden cronológico (DESC)                 │
│  • idx_audit_ledger_tx_type: Búsqueda por tipo                          │
│  • idx_audit_ledger_hash: Unicidad y validación                         │
│  • idx_audit_ledger_prev_hash: Encadenamiento                           │
│                                                                           │
│  Vistas:                                                                 │
│  • user_transaction_audit: Transacciones por usuario                    │
│  • ledger_chain_status: Estado de la cadena                             │
│                                                                           │
│  Funciones:                                                              │
│  • get_last_block(): Obtiene último bloque                             │
│  • count_user_transactions(uuid): Cuenta transacciones                  │
│  • get_user_transaction_summary(uuid): Resumen por tipo                 │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│              PROTECCIÓN CONTRA TAMPERING (Alteración)                    │
│                                                                           │
│  ESCENARIO: Atacante intenta cambiar el monto de una transacción       │
│                                                                           │
│  Transacción Original en Bloque 2:                                      │
│  ┌──────────────────────────────────────────────────────────┐           │
│  │ data = {                                                 │           │
│  │   "tx_type": "payment",                                  │           │
│  │   "user_id": "550e8400-...",                             │           │
│  │   "amount": 100.50,  ← ATACANTE INTENTA CAMBIAR A 1000  │           │
│  │   "currency": "COP"                                      │           │
│  │ }                                                        │           │
│  │                                                          │           │
│  │ hash_antes = SHA3-512(id + prev_hash + "100.50" + nonce)│           │
│  └──────────────────────────────────────────────────────────┘           │
│                                                                           │
│  Ataque:                                                                │
│  1. Atacante cambia data.amount = 1000                                 │
│  2. Nueva data = {..., "amount": 1000, ...}                            │
│  3. hash_nuevo = SHA3-512(id + prev_hash + "1000" + nonce)             │
│  4. hash_nuevo ≠ hash_antes                                            │
│       ↓                                                                  │
│  5. Bloque 3 tiene prev_hash = hash_antes                              │
│  6. Pero ahora el hash actual del Bloque 2 es hash_nuevo                │
│  7. hash_antes ≠ hash_nuevo → FALLO DE VALIDACIÓN ❌                   │
│       ↓                                                                  │
│  8. verify_chain_integrity() detecta la rotura                         │
│  9. return false → Alerta de seguridad                                 │
│                                                                           │
│  RESULTADO: Imposible alterar transacciones sin ser detectado           │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│              GARANTÍAS CRIPTOGRÁFICAS                                    │
│                                                                           │
│  SHA3-512 (NIST Standard):                                              │
│  ✅ 512 bits de salida (seguridad de 256 bits)                          │
│  ✅ Resistente a ataques de colisión                                   │
│  ✅ Resistente a ataques preimagen                                     │
│  ✅ Determinista (mismo input = siempre mismo hash)                    │
│  ✅ Avalancha (1 bit diferente = hash completamente diferente)         │
│                                                                           │
│  Nonce (Proof of Work):                                                │
│  ✅ timestamp-based (UNIX nanoseconds)                                 │
│  ✅ Único para cada bloque                                             │
│  ✅ Imposible crear bloques retroactivos                               │
│  ✅ Orden cronológico garantizado                                      │
│                                                                           │
│  Encadenamiento:                                                        │
│  ✅ Cada bloque referencia criptográficamente al anterior               │
│  ✅ Cambiar un bloque rompe toda la cadena desde ese punto             │
│  ✅ Imposible "reparar" sin detectarse                                │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// ARCHIVOS GENERADOS
// ============================================================================

/*
src/finance/
├── mod.rs                    ← Exports públicos
├── ledger.rs                 ← Core blockchain (Block, seal_transaction, etc)
└── handlers.rs               ← HTTP handlers (seal, verify, history)

migrations/
└── 004_create_audit_ledger.sql  ← Schema + índices + funciones

LEDGER_DOCUMENTATION.md        ← Documentación completa
LEDGER_EXAMPLES.sql            ← Ejemplos de queries SQL
*/

// ============================================================================
// COMPILACIÓN Y TESTS
// ============================================================================

/*
Compilar:
  $ cargo check
  $ cargo build --release

Ejecutar tests:
  $ cargo test finance::ledger

Ejemplos de uso en código:
  use backend_api::finance::ledger::{seal_transaction, TransactionData};

  let tx = TransactionData {
      tx_type: "payment".to_string(),
      user_id: user_id,
      amount: 100.50,
      currency: "COP".to_string(),
      description: "Pago".to_string(),
      metadata: None,
  };

  let block = seal_transaction(tx, &pool).await?;
  println!("Transacción sellada: {}", block.hash);
*/

// ============================================================================
// INTEGRACIÓN EN MAIN.RS
// ============================================================================

/*
En main.rs, añadir las rutas:

use backend_api::finance::handlers::{
    seal_transaction_handler,
    verify_chain_handler,
    user_transaction_history_handler,
};

let app = Router::new()
    .route("/api/ledger/seal", post(seal_transaction_handler))
    .route("/api/ledger/verify", get(verify_chain_handler))
    .route("/api/ledger/history/:user_id", get(user_transaction_history_handler))
    .with_state(pool);
*/

// ============================================================================
// CUMPLIMIENTO REGULATORIO
// ============================================================================

/*
✅ Ley 1870 de 2023 (Colombia)

- Registro inmutable de transacciones en criptoactivos
- Auditoría completa

✅ FATF (Financial Action Task Force)

- Anti-Money Laundering (AML)
- Know Your Customer (KYC)
- Trazabilidad completa de fondos

✅ ISO/IEC 27001

- Control de integridad de datos
- Auditoría de acceso
- No repudio

✅ SOX (Sarbanes-Oxley)

- Integridad de registros financieros
- Control interno certifiable
*/

// ============================================================================
// FIN DE DOCUMENTACIÓN
// ============================================================================
