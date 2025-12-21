use std::collections::HashMap;

use axum::{extract::State, http::StatusCode, Json};
use serde::{Deserialize, Serialize};
use sqlx::types::chrono::{DateTime, Utc};
use uuid::Uuid;
use chrono::Datelike;

use crate::state::AppState;

// Penalizaciones y metas de producción
pub const GROUP_QUOTA: f64 = 1500.0;
pub const GROUP_SHORTFALL_PENALTY_COP: f64 = 50_000.0;
pub const DIRTY_ROOM_PENALTY_COP: f64 = 500_000.0;
pub const STRIKE3_PENALTY_COP: f64 = 1_000_000.0;

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, Copy, PartialEq, Eq, Hash)]
#[sqlx(type_name = "payment_method", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum PaymentMethodDb {
    NEQUI,
    BANCOLOMBIA,
    DAVIPLATA,
    EFECTIVO,
    USDT,
}

#[derive(Debug, Serialize)]
pub struct PendingPayrollItem {
    pub user_id: Uuid,
    pub user: String,
    pub account: String,
    pub amount_cop: Option<f64>,
    pub amount_usdt: Option<f64>,
}

#[derive(Debug, Serialize)]
pub struct PendingPayrollResponse {
    pub nequi: Vec<PendingPayrollItem>,
    pub bancolombia: Vec<PendingPayrollItem>,
    pub daviplata: Vec<PendingPayrollItem>,
    pub efectivo: Vec<PendingPayrollItem>,
    pub usdt: Vec<PendingPayrollItem>,
    pub total_cop_needed: f64,
    pub total_usdt_needed: f64,
}

#[derive(Debug, Deserialize)]
pub struct MarkPaidRequest {
    pub user_id: Uuid,
    pub payment_reference: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct MarkPaidResponse {
    pub user_id: Uuid,
    pub paid_at: DateTime<Utc>,
    pub message: String,
}

/// GET /api/admin/finance/payroll/pending
pub async fn pending_payroll_handler(
    State(state): State<std::sync::Arc<AppState>>,
) -> Result<Json<PendingPayrollResponse>, (StatusCode, String)> {
    let pool = &state.db;

    // Semana anterior (lunes a domingo)
    let today = chrono::Utc::now().date_naive();
    let last_monday = today - chrono::Duration::days((today.weekday().num_days_from_monday() as i64) + 7);
    let last_sunday = last_monday + chrono::Duration::days(6);

    #[derive(sqlx::FromRow)]
    struct Row {
        user_id: Uuid,
        user_name: String,
        account_number: String,
        payment_method: PaymentMethodDb,
        amount_cop: f64,
        amount_usdt: f64,
    }

    let rows = sqlx::query_as::<_, Row>(
        r#"
        SELECT p.user_id,
               COALESCE(u.display_name, u.username, 'Modelo') AS user_name,
               p.account_number,
               p.payment_method,
               COALESCE(p.amount_cop::DOUBLE PRECISION, 0) AS amount_cop,
               COALESCE(p.amount_usdt::DOUBLE PRECISION, 0) AS amount_usdt
        FROM payroll_payouts p
        JOIN users u ON u.id = p.user_id
        WHERE p.status = 'APPROVED'
          AND p.paid_at IS NULL
          AND p.week_start >= $1 AND p.week_end <= $2
        "#,
    )
    .bind(last_monday)
    .bind(last_sunday)
    .fetch_all(pool)
    .await
    .map_err(|e| {
        tracing::error!("DB error fetching payroll pending: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    let mut buckets: HashMap<PaymentMethodDb, Vec<PendingPayrollItem>> = HashMap::new();
    let mut total_cop = 0.0;
    let mut total_usdt = 0.0;

    for r in rows {
        let item = PendingPayrollItem {
            user_id: r.user_id,
            user: r.user_name,
            account: r.account_number,
            amount_cop: if r.payment_method == PaymentMethodDb::USDT { None } else { Some(r.amount_cop) },
            amount_usdt: if r.payment_method == PaymentMethodDb::USDT { Some(r.amount_usdt) } else { None },
        };
        if r.payment_method == PaymentMethodDb::USDT {
            total_usdt += r.amount_usdt;
        } else {
            total_cop += r.amount_cop;
        }
        buckets.entry(r.payment_method).or_default().push(item);
    }

    let resp = PendingPayrollResponse {
        nequi: buckets.remove(&PaymentMethodDb::NEQUI).unwrap_or_default(),
        bancolombia: buckets.remove(&PaymentMethodDb::BANCOLOMBIA).unwrap_or_default(),
        daviplata: buckets.remove(&PaymentMethodDb::DAVIPLATA).unwrap_or_default(),
        efectivo: buckets.remove(&PaymentMethodDb::EFECTIVO).unwrap_or_default(),
        usdt: buckets.remove(&PaymentMethodDb::USDT).unwrap_or_default(),
        total_cop_needed: total_cop,
        total_usdt_needed: total_usdt,
    };

    Ok(Json(resp))
}

/// POST /api/admin/finance/payroll/mark-paid
pub async fn mark_paid_handler(
    State(state): State<std::sync::Arc<AppState>>,
    Json(req): Json<MarkPaidRequest>,
) -> Result<Json<MarkPaidResponse>, (StatusCode, String)> {
    let pool = &state.db;

    let row = sqlx::query_as::<_, (DateTime<Utc>,)>(
        r#"
        UPDATE payroll_payouts
        SET paid_at = NOW(),
            status = 'PAID',
            payment_reference = COALESCE($2, payment_reference)
        WHERE user_id = $1 AND paid_at IS NULL AND status = 'APPROVED'
        RETURNING paid_at
        "#,
    )
    .bind(req.user_id)
    .bind(&req.payment_reference)
    .fetch_optional(pool)
    .await
    .map_err(|e| {
        tracing::error!("DB error marking paid: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    let Some((paid_at,)) = row else {
        return Err((StatusCode::NOT_FOUND, "No pending payout for user".to_string()));
    };

    // Notificar vía NATS para que el servicio de notificaciones envíe push
    let payload = serde_json::json!({
        "type": "payment_sent",
        "user_id": req.user_id,
        "message": "¡Tu pago ha sido enviado!",
        "reference": req.payment_reference,
    });
    if let Err(e) = state
        .nats
        .publish("notifications.payment_sent", serde_json::to_vec(&payload).unwrap_or_default().into())
        .await
    {
        tracing::warn!("Failed to publish notification: {}", e);
    }

    Ok(Json(MarkPaidResponse {
        user_id: req.user_id,
        paid_at,
        message: "Pago marcado como enviado".to_string(),
    }))
}
