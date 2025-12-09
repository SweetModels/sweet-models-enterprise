use serde::{Serialize, Deserialize};
use sqlx::PgPool;
use uuid::Uuid;
use sha3::{Sha3_512, Digest};
use serde_json::Value;

/// Representa un bloque en la cadena de auditoría inmutable
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Block {
    pub id: Uuid,
    pub prev_hash: String,          // SHA3-512 del bloque anterior
    pub data: Value,                // JSON con los datos de la transacción
    pub nonce: u64,                 // Nonce para prueba de trabajo
    pub hash: String,               // SHA3-512 del bloque completo
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

impl Block {
    /// Calcula el hash SHA3-512 de un bloque
    fn calculate_hash(id: &str, prev_hash: &str, data: &str, nonce: u64) -> String {
        let content = format!("{}{}{}{}", id, prev_hash, data, nonce);
        let mut hasher = Sha3_512::new();
        hasher.update(content.as_bytes());
        format!("{:x}", hasher.finalize())
    }

    /// Crea un nuevo bloque enlazado al anterior
    pub fn new(prev_hash: String, data: Value, nonce: u64) -> Self {
        let id = Uuid::new_v4();
        let data_str = serde_json::to_string(&data).unwrap_or_default();
        let hash = Self::calculate_hash(&id.to_string(), &prev_hash, &data_str, nonce);

        Block {
            id,
            prev_hash,
            data,
            nonce,
            hash,
            timestamp: chrono::Utc::now(),
        }
    }

    /// Valida que el hash del bloque sea correcto
    pub fn is_valid(&self) -> bool {
        let data_str = serde_json::to_string(&self.data).unwrap_or_default();
        let calculated_hash = Self::calculate_hash(&self.id.to_string(), &self.prev_hash, &data_str, self.nonce);
        calculated_hash == self.hash
    }
}

/// Estructura para datos de transacción financiera
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionData {
    pub tx_type: String,             // "payment", "refund", "transfer", etc.
    pub user_id: Uuid,
    pub amount: f64,
    pub currency: String,            // "COP", "USD", etc.
    pub description: String,
    pub metadata: Option<Value>,
}

/// Sellar una transacción en la cadena de auditoría inmutable
pub async fn seal_transaction(
    transaction_data: TransactionData,
    pool: &PgPool,
) -> Result<Block, Box<dyn std::error::Error + Send + Sync>> {
    // 1. Buscar el último bloque sellado
    let last_block = get_last_block(pool).await?;
    let prev_hash = last_block.map(|b| b.hash).unwrap_or_else(|| "0".to_string());

    // 2. Crear el nuevo bloque con los datos de la transacción
    let transaction_json = serde_json::to_value(&transaction_data)?;
    let nonce = generate_nonce();
    let block = Block::new(prev_hash, transaction_json, nonce);

    // 3. Validar el bloque
    if !block.is_valid() {
        return Err("Bloque inválido".into());
    }

    // 4. Guardar el bloque en la base de datos
    save_block(&block, pool).await?;

    // 5. Log de auditoría
    tracing::info!(
        "✅ Transacción sellada: {} | User: {} | Amount: {} {}",
        block.id,
        transaction_data.user_id,
        transaction_data.amount,
        transaction_data.currency
    );

    Ok(block)
}

/// Obtiene el último bloque sellado de la cadena
async fn get_last_block(pool: &PgPool) -> Result<Option<Block>, Box<dyn std::error::Error + Send + Sync>> {
    let row = sqlx::query_as::<_, (Uuid, String, Value, i64, String, chrono::DateTime<chrono::Utc>)>(
        "SELECT id, prev_hash, data, nonce, hash, timestamp FROM audit_ledger ORDER BY timestamp DESC LIMIT 1"
    )
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|(id, prev_hash, data, nonce, hash, timestamp)| Block {
        id,
        prev_hash,
        data,
        nonce: nonce as u64,
        hash,
        timestamp,
    }))
}

/// Guarda un bloque en la base de datos
async fn save_block(block: &Block, pool: &PgPool) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    sqlx::query(
        "INSERT INTO audit_ledger (id, prev_hash, data, nonce, hash, timestamp) 
         VALUES ($1, $2, $3, $4, $5, $6)"
    )
    .bind(block.id)
    .bind(&block.prev_hash)
    .bind(&block.data)
    .bind(block.nonce as i64)
    .bind(&block.hash)
    .bind(block.timestamp)
    .execute(pool)
    .await?;

    Ok(())
}

/// Genera un nonce aleatorio
fn generate_nonce() -> u64 {
    use std::time::{SystemTime, UNIX_EPOCH};
    let duration = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    duration.as_nanos() as u64
}

/// Verifica la integridad de toda la cadena (auditoría completa)
pub async fn verify_chain_integrity(pool: &PgPool) -> Result<bool, Box<dyn std::error::Error + Send + Sync>> {
    let blocks = sqlx::query_as::<_, (Uuid, String, Value, i64, String, chrono::DateTime<chrono::Utc>)>(
        "SELECT id, prev_hash, data, nonce, hash, timestamp FROM audit_ledger ORDER BY timestamp ASC"
    )
    .fetch_all(pool)
    .await?;

    let mut expected_prev_hash = "0".to_string();

    let total_blocks = blocks.len();
    for (id, prev_hash, data, nonce, hash, _) in &blocks {
        // Validar que el prev_hash sea correcto
        if prev_hash != &expected_prev_hash {
            tracing::warn!(
                "❌ Cadena rota en bloque {}: prev_hash no coincide",
                id
            );
            return Ok(false);
        }

        // Validar que el hash del bloque sea correcto
        let data_str = serde_json::to_string(&data).unwrap_or_default();
        let calculated_hash = Block::calculate_hash(&id.to_string(), prev_hash, &data_str, *nonce as u64);
        if calculated_hash != *hash {
            tracing::warn!(
                "❌ Hash inválido en bloque {}: esperado {}, obtenido {}",
                id, hash, calculated_hash
            );
            return Ok(false);
        }

        expected_prev_hash = hash.clone();
    }

    tracing::info!("✅ Cadena de auditoría verificada correctamente ({} bloques)", total_blocks);
    Ok(true)
}

/// Obtiene el historial completo de transacciones de un usuario
pub async fn get_user_transaction_history(
    user_id: Uuid,
    pool: &PgPool,
) -> Result<Vec<(Block, TransactionData)>, Box<dyn std::error::Error + Send + Sync>> {
    let blocks = sqlx::query_as::<_, (Uuid, String, Value, i64, String, chrono::DateTime<chrono::Utc>)>(
        "SELECT id, prev_hash, data, nonce, hash, timestamp FROM audit_ledger 
         WHERE data->>'user_id' = $1 
         ORDER BY timestamp DESC"
    )
    .bind(user_id.to_string())
    .fetch_all(pool)
    .await?;

    let mut result = Vec::new();
    for (id, prev_hash, data, nonce, hash, timestamp) in blocks {
        let block = Block {
            id,
            prev_hash,
            data: data.clone(),
            nonce: nonce as u64,
            hash,
            timestamp,
        };

        if let Ok(tx_data) = serde_json::from_value::<TransactionData>(data) {
            result.push((block, tx_data));
        }
    }

    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_block_creation_and_validation() {
        let data = json!({
            "user_id": "550e8400-e29b-41d4-a716-446655440000",
            "amount": 100.50,
            "currency": "COP"
        });

        let block = Block::new("0".to_string(), data, 12345);
        assert!(block.is_valid(), "El bloque debe ser válido");
    }

    #[test]
    fn test_block_hash_consistency() {
        use chrono::Utc;
        
        let data = json!({"test": "data"});
        let nonce = 100u64;
        let id = Uuid::new_v4();
        let now = Utc::now();
        let block1 = Block {
            id,
            prev_hash: "prev_hash_1".to_string(),
            data: data.clone(),
            nonce,
            hash: String::new(),
            timestamp: now,
        };
        let block2 = Block {
            id,
            prev_hash: "prev_hash_1".to_string(),
            data: data.clone(),
            nonce,
            hash: String::new(),
            timestamp: now,
        };

        assert_eq!(block1.hash, block2.hash, "Bloques idénticos deben tener el mismo hash");
    }

    #[test]
    fn test_invalid_block_hash() {
        let data = json!({"test": "data"});
        let mut block = Block::new("prev_hash".to_string(), data, 100);
        
        // Modificar el hash para simular corrupción
        block.hash = "invalid_hash".to_string();
        
        assert!(!block.is_valid(), "El bloque con hash inválido debe fallar la validación");
    }
}
