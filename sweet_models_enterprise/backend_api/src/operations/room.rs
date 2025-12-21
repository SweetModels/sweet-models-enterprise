use axum::{extract::State, http::StatusCode, Json};
use serde::{Deserialize, Serialize};
use sqlx::types::Uuid;
use chrono::{Utc, Datelike};

use crate::{state::AppState, finance, gamification};

#[derive(Debug, Deserialize)]
pub struct CloseShiftRequest {
    pub room_id: i32,
    pub shift_id: i32,
    pub total_tokens: f64,
    pub is_dirty: bool,
}

#[derive(Debug, Serialize)]
pub struct CloseShiftResponse {
    pub message: String,
    pub penalty_applied: bool,
    pub penalty_type: Option<String>,
}

/// POST /api/operations/room/close-shift
/// Cierra un turno de room: aplica multas por cuota grupal o limpieza.
pub async fn close_shift_handler(
    State(state): State<std::sync::Arc<AppState>>,
    Json(req): Json<CloseShiftRequest>,
) -> Result<Json<CloseShiftResponse>, (StatusCode, String)> {
    let pool = &state.db;

    // Obtener integrantes del room en este turno (semana actual)
    let today = Utc::now().date_naive();
    let week_id = format!("{}-W{:02}", today.iso_week().year(), today.iso_week().week());

    let members = sqlx::query_scalar::<_, Uuid>(
        r#"
        SELECT user_id
        FROM user_shifts
        WHERE assigned_room = $1 AND assigned_shift = $2 AND week_id = $3
        "#,
    )
    .bind(req.room_id)
    .bind(req.shift_id)
    .bind(&week_id)
    .fetch_all(pool)
    .await
    .map_err(|e| {
        tracing::error!("DB error fetching room members: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    if members.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "No hay miembros asignados a este room/shift".to_string()));
    }

    let mut penalty_applied = false;
    let mut penalty_type = None;

    // 1. Revisar cuota grupal
    if req.total_tokens < finance::payroll::GROUP_QUOTA {
        if let Err(e) = finance::apply_group_shortfall_penalty(&members, req.total_tokens, pool).await {
            tracing::error!("Error aplicando multa grupal: {}", e);
        } else {
            penalty_applied = true;
            penalty_type = Some("group_shortfall".to_string());
        }
    }

    // 2. Revisar limpieza
    if req.is_dirty {
        if let Err(e) = finance::apply_dirty_room_penalty(&members, req.room_id, pool).await {
            tracing::error!("Error aplicando multa por room sucio: {}", e);
        } else {
            penalty_applied = true;
            penalty_type = Some(if penalty_type.is_some() { "both".to_string() } else { "dirty_room".to_string() });
            
            // Burn 20% XP for dirty room penalty
            for member_id in &members {
                if let Err(e) = gamification::burn_xp(*member_id, "DIRTY_ROOM", pool).await {
                    tracing::warn!("XP burn failed for dirty room penalty: {}", e);
                }
            }
        }
    }

    let message = if penalty_applied {
        "Turno cerrado con multa(s) aplicada(s)".to_string()
    } else {
        "Turno cerrado exitosamente".to_string()
    };

    Ok(Json(CloseShiftResponse {
        message,
        penalty_applied,
        penalty_type,
    }))
}
