use std::sync::Arc;

use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

use crate::state::AppState;

// ============================================================================
// TIPOS Y MODELOS (usando f64 para decimales, compatible con sqlx DECIMAL)
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Transaction {
    pub id: Uuid,
    pub user_id: Uuid,
    pub amount: f64, // DECIMAL(20,8) en DB mapeado a f64
    pub r#type: String, // EARNING, WITHDRAWAL, PENALTY
    pub reference: Option<String>,
    pub blockchain_tx_hash: Option<String>,
    pub status: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BalanceResponse {
    pub user_id: Uuid,
    pub total_balance: f64,
    pub transactions: Vec<Transaction>,
}

#[derive(Debug, Deserialize)]
pub struct WithdrawRequest {
    pub amount_usdt: f64,
    pub wallet_address: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct WithdrawalRecord {
    pub id: Uuid,
    pub user_id: Uuid,
    pub amount_usdt: f64,
    pub wallet_address: String,
    pub status: String,
    pub blockchain_tx_hash: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct WithdrawResponse {
    pub withdrawal_id: Uuid,
    pub status: String,
    pub message: String,
}

// ============================================================================
// FUNCIONES DE NEGOCIO
// ============================================================================

/// Obtener balance actual del usuario
pub async fn get_balance(
    db: &sqlx::PgPool,
    user_id: Uuid,
) -> Result<f64, (StatusCode, String)> {
    let result = sqlx::query_scalar::<_, f64>(
        "SELECT COALESCE(total_balance, 0) FROM balance_cache WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_optional(db)
    .await
    .map_err(|e| {
        tracing::error!("DB error fetching balance: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    Ok(result.unwrap_or(0.0))
}

/// Crear una transacción (uso interno)
pub async fn create_transaction(
    db: &sqlx::PgPool,
    user_id: Uuid,
    amount: f64,
    tx_type: &str,
    reference: Option<String>,
) -> Result<Transaction, (StatusCode, String)> {
    let transaction = sqlx::query_as::<_, Transaction>(
        r#"
        INSERT INTO transactions (user_id, amount, type, reference, status)
        VALUES ($1, $2, $3, $4, 'CONFIRMED')
        RETURNING *
        "#,
    )
    .bind(user_id)
    .bind(amount)
    .bind(tx_type)
    .bind(reference)
    .fetch_one(db)
    .await
    .map_err(|e| {
        tracing::error!("DB error creating transaction: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    Ok(transaction)
}

/// Solicitar retiro de USDT (Withdrawal)
pub async fn request_payout(
    state: &Arc<AppState>,
    user_id: Uuid,
    amount_usdt: f64,
    wallet_address: String,
) -> Result<WithdrawalRecord, (StatusCode, String)> {
    // 1. Verificar saldo suficiente
    let balance = get_balance(&state.db, user_id).await?;

    if balance < amount_usdt {
        return Err((
            StatusCode::BAD_REQUEST,
            format!(
                "Insufficient balance. Available: {}, Requested: {}",
                balance, amount_usdt
            ),
        ));
    }

    // 2. Crear transacción de retiro (negativa)
    let withdrawal_amount = -amount_usdt;
    let tx = create_transaction(
        &state.db,
        user_id,
        withdrawal_amount,
        "WITHDRAWAL",
        Some(format!("Withdrawal to {}", wallet_address)),
    )
    .await?;

    // 3. Crear solicitud de retiro
    let withdrawal = sqlx::query_as::<_, WithdrawalRecord>(
        r#"
        INSERT INTO withdrawal_requests (user_id, amount_usdt, wallet_address, status, transaction_id)
        VALUES ($1, $2, $3, 'PENDING', $4)
        RETURNING *
        "#,
    )
    .bind(user_id)
    .bind(amount_usdt)
    .bind(&wallet_address)
    .bind(tx.id)
    .fetch_one(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("DB error creating withdrawal: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    // 4. Iniciar transferencia en blockchain (llamar a web3 service)
    // Esta es una llamada asíncrona que procesará el retiro en blockchain
    let state_clone = state.clone();
    let withdrawal_clone = withdrawal.clone();
    tokio::spawn(async move {
        if let Err(e) = process_blockchain_withdrawal(state_clone, withdrawal_clone).await {
            tracing::error!("Blockchain withdrawal error: {}", e);
            // Aquí podrías marcar la transacción como FAILED si es necesario
        }
    });

    Ok(withdrawal)
}

/// Procesar retiro en blockchain (Web3 integration)
async fn process_blockchain_withdrawal(
    state: Arc<AppState>,
    withdrawal: WithdrawalRecord,
) -> Result<(), Box<dyn std::error::Error>> {
    tracing::info!(
        "Processing blockchain withdrawal: {} USDT to {}",
        withdrawal.amount_usdt,
        withdrawal.wallet_address
    );

    // TODO: Integrar con módulo web3 para transferencia de USDT
    // Ejemplo de lo que harías:
    // let tx_hash = web3_service.transfer_usdt(
    //     withdrawal.wallet_address,
    //     withdrawal.amount_usdt,
    // ).await?;

    // Por ahora, simular un hash de transacción
    let simulated_tx_hash = format!("0x{:x}", uuid::Uuid::new_v4());

    // Actualizar registro de retiro con hash
    sqlx::query(
        r#"
        UPDATE withdrawal_requests
        SET status = 'SENT', blockchain_tx_hash = $1
        WHERE id = $2
        "#,
    )
    .bind(&simulated_tx_hash)
    .bind(withdrawal.id)
    .execute(&state.db)
    .await?;

    // Actualizar transacción con hash
    sqlx::query(
        r#"
        UPDATE transactions
        SET status = 'CONFIRMED', blockchain_tx_hash = $1
        WHERE id = $2
        "#,
    )
    .bind(&simulated_tx_hash)
    .bind(withdrawal.id)
    .execute(&state.db)
    .await?;

    tracing::info!("Blockchain withdrawal completed: {}", simulated_tx_hash);

    Ok(())
}

// ============================================================================
// HANDLERS HTTP
// ============================================================================

/// GET /api/finance/balance
pub async fn get_balance_handler(
    State(state): State<Arc<AppState>>,
) -> Result<Json<BalanceResponse>, (StatusCode, String)> {
    // En producción, obtener user_id del JWT
    let user_id = Uuid::new_v4();

    let balance = get_balance(&state.db, user_id).await?;

    let transactions = sqlx::query_as::<_, Transaction>(
        r#"
        SELECT * FROM transactions
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT 100
        "#,
    )
    .bind(user_id)
    .fetch_all(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("DB error fetching transactions: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    Ok(Json(BalanceResponse {
        user_id,
        total_balance: balance,
        transactions,
    }))
}

/// POST /api/finance/withdraw
pub async fn request_withdraw_handler(
    State(state): State<Arc<AppState>>,
    Json(req): Json<WithdrawRequest>,
) -> Result<(StatusCode, Json<WithdrawResponse>), (StatusCode, String)> {
    // En producción, obtener user_id del JWT
    let user_id = Uuid::new_v4();

    if req.amount_usdt <= 0.0 {
        return Err((
            StatusCode::BAD_REQUEST,
            "Amount must be greater than zero".to_string(),
        ));
    }

    if req.wallet_address.is_empty() {
        return Err((
            StatusCode::BAD_REQUEST,
            "Wallet address is required".to_string(),
        ));
    }

    let withdrawal = request_payout(&state, user_id, req.amount_usdt, req.wallet_address).await?;

    Ok((
        StatusCode::ACCEPTED,
        Json(WithdrawResponse {
            withdrawal_id: withdrawal.id,
            status: withdrawal.status.clone(),
            message: format!(
                "Withdrawal request created. Amount: {} USDT. Status: {}",
                withdrawal.amount_usdt, withdrawal.status
            ),
        }),
    ))
}

/// GET /api/finance/withdrawals (Listar solicitudes de retiro)
pub async fn list_withdrawals_handler(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<WithdrawalRecord>>, (StatusCode, String)> {
    // En producción, obtener user_id del JWT
    let user_id = Uuid::new_v4();

    let withdrawals = sqlx::query_as::<_, WithdrawalRecord>(
        r#"
        SELECT * FROM withdrawal_requests
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT 50
        "#,
    )
    .bind(user_id)
    .fetch_all(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("DB error fetching withdrawals: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    Ok(Json(withdrawals))
}
