use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use std::sync::Arc;
use crate::{
    finance::ledger::{seal_transaction, TransactionData, verify_chain_integrity, get_user_transaction_history},
    state::AppState,
};

#[derive(Debug, Serialize, Deserialize)]
pub struct SealTransactionRequest {
    pub user_id: Uuid,
    pub amount: f64,
    pub currency: String,
    pub description: String,
    pub tx_type: String, // "payment", "refund", "transfer", etc.
}

#[derive(Debug, Serialize)]
pub struct SealTransactionResponse {
    pub block_id: Uuid,
    pub hash: String,
    pub prev_hash: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub message: String,
}

#[derive(Debug, Serialize)]
pub struct ChainStatusResponse {
    pub is_valid: bool,
    pub message: String,
    pub total_blocks: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct TransactionHistoryResponse {
    pub user_id: Uuid,
    pub transactions: Vec<TransactionHistoryItem>,
    pub total_amount: f64,
}

#[derive(Debug, Serialize)]
pub struct TransactionHistoryItem {
    pub block_id: Uuid,
    pub tx_type: String,
    pub amount: f64,
    pub currency: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub hash: String,
}

/// Sella una nueva transacción en la cadena de auditoría
pub async fn seal_transaction_handler(
    State(app_state): State<Arc<AppState>>,
    Json(req): Json<SealTransactionRequest>,
) -> impl IntoResponse {
    let pool = app_state.db.clone();
    let transaction_data = TransactionData {
        tx_type: req.tx_type,
        user_id: req.user_id,
        amount: req.amount,
        currency: req.currency.clone(),
        description: req.description,
        metadata: None,
    };

    match seal_transaction(transaction_data, &pool).await {
        Ok(block) => {
            let response = SealTransactionResponse {
                block_id: block.id,
                hash: block.hash,
                prev_hash: block.prev_hash,
                timestamp: block.timestamp,
                message: "✅ Transacción sellada en cadena de auditoría".to_string(),
            };
            (StatusCode::CREATED, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!("Error selando transacción: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({
                    "error": "Error selando transacción",
                    "details": e.to_string()
                })),
            )
                .into_response()
        }
    }
}

/// Verifica la integridad completa de la cadena de auditoría
pub async fn verify_chain_handler(
    State(app_state): State<Arc<AppState>>,
) -> impl IntoResponse {
    let pool = app_state.db.clone();
    match verify_chain_integrity(&pool).await {
        Ok(is_valid) => {
            let message = if is_valid {
                "✅ Cadena de auditoría íntegra y válida".to_string()
            } else {
                "❌ Cadena de auditoría comprometida".to_string()
            };

            let response = ChainStatusResponse {
                is_valid,
                message,
                total_blocks: None,
            };

            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!("Error verificando cadena: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({
                    "error": "Error verificando cadena",
                    "details": e.to_string()
                })),
            )
                .into_response()
        }
    }
}

/// Obtiene el historial de transacciones de un usuario
pub async fn user_transaction_history_handler(
    State(app_state): State<Arc<AppState>>,
    axum::extract::Path(user_id): axum::extract::Path<Uuid>,
) -> impl IntoResponse {
    let pool = app_state.db.clone();
    match get_user_transaction_history(user_id, &pool).await {
        Ok(history) => {
            let total_amount: f64 = history
                .iter()
                .map(|(_, tx)| tx.amount)
                .sum();

            let transactions = history
                .into_iter()
                .map(|(block, tx)| TransactionHistoryItem {
                    block_id: block.id,
                    tx_type: tx.tx_type,
                    amount: tx.amount,
                    currency: tx.currency,
                    timestamp: block.timestamp,
                    hash: block.hash,
                })
                .collect();

            let response = TransactionHistoryResponse {
                user_id,
                transactions,
                total_amount,
            };

            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!("Error obteniendo historial de transacciones: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({
                    "error": "Error obteniendo historial",
                    "details": e.to_string()
                })),
            )
                .into_response()
        }
    }
}
