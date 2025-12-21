use axum::{extract::{State, Query}, http::StatusCode, Json};
use serde::{Deserialize, Serialize};
use sqlx::types::Uuid;
use chrono::{DateTime, Utc, Datelike};

use crate::state::AppState;

#[derive(Debug, Deserialize)]
pub struct StatusQuery {
    pub user_id: Uuid,
}

#[derive(Debug, Serialize)]
pub struct AttendanceStatusResponse {
    pub strikes: i32,
    pub penalty_active: bool,
    pub last_late_at: Option<DateTime<Utc>>,
    pub last_late_shift: Option<String>,
    pub note: Option<String>,
}

/// GET /api/attendance/status?user_id=xxx
/// Retorna el estado disciplinario del usuario (strikes semanales)
pub async fn attendance_status_handler(
    State(state): State<std::sync::Arc<AppState>>,
    Query(params): Query<StatusQuery>,
) -> Result<Json<AttendanceStatusResponse>, (StatusCode, String)> {
    let pool = &state.db;
    let user_id = params.user_id;
    let now = Utc::now();
    let week_start = now - chrono::Duration::days((now.weekday().num_days_from_monday()) as i64);

    // Contar tardanzas esta semana
    let late_count = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*)
        FROM attendance_logs
        WHERE user_id = $1
          AND is_late = TRUE
          AND date_trunc('week', check_in) = date_trunc('week', $2)
        "#,
    )
    .bind(user_id)
    .bind(week_start)
    .fetch_one(pool)
    .await
    .map_err(|e| {
        tracing::error!("DB error counting lates: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    // Obtener última tardanza
    let last_late = sqlx::query_as::<_, (DateTime<Utc>, i32)>(
        r#"
        SELECT al.check_in, us.assigned_shift
        FROM attendance_logs al
        JOIN user_shifts us ON us.user_id = al.user_id
        WHERE al.user_id = $1 AND al.is_late = TRUE
        ORDER BY al.check_in DESC
        LIMIT 1
        "#,
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let (last_late_at, last_late_shift) = if let Some((dt, shift)) = last_late {
        (Some(dt), Some(format!("Shift {}", shift)))
    } else {
        (None, None)
    };

    // Revisar si tiene multa activa (PENALTY status en payroll)
    let penalty_active = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM payroll_payouts
            WHERE user_id = $1 AND status = 'PENALTY' AND paid_at IS NULL
        )
        "#,
    )
    .bind(user_id)
    .fetch_one(pool)
    .await
    .unwrap_or(false);

    let note = if late_count >= 3 {
        Some("Multa aplicada por 3+ tardanzas".to_string())
    } else if late_count == 2 {
        Some("Semana degradada al 50%".to_string())
    } else if late_count == 1 {
        Some("Hoy cobras al 50%".to_string())
    } else {
        None
    };

    Ok(Json(AttendanceStatusResponse {
        strikes: late_count as i32,
        penalty_active,
        last_late_at,
        last_late_shift,
        note,
    }))
}
