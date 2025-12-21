use sqlx::types::Uuid;
use sqlx::PgPool;
use chrono::Utc;
use super::payroll::{GROUP_QUOTA, GROUP_SHORTFALL_PENALTY_COP, DIRTY_ROOM_PENALTY_COP};

/// Marca una degradación semanal (ej. 50%) - reduce comisión en payroll_payouts pendientes.
pub async fn downgrade_user_week(user_id: Uuid, factor: f64, pool: &PgPool) -> Result<(), String> {
    let updated = sqlx::query(
        r#"
        UPDATE payroll_payouts
        SET amount_cop = amount_cop * $2,
            amount_usdt = amount_usdt * $2,
            notes = COALESCE(notes || ' ', '') || 'Degradado ' || ($2 * 100)::TEXT || '% por tardanzas'
        WHERE user_id = $1 AND status = 'PENDING' AND paid_at IS NULL
        "#,
    )
    .bind(user_id)
    .bind(factor)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    tracing::info!("Downgrade semanal aplicado: {} filas actualizadas con factor {}", updated.rows_affected(), factor);
    Ok(())
}

/// Crea una multa directa (inserción en payroll_payouts como descuento negativo).
pub async fn create_penalty(user_id: Uuid, amount_cop: f64, pool: &PgPool) -> Result<(), String> {
    let week_start = Utc::now().date_naive();
    let week_end = week_start + chrono::Duration::days(6);

    sqlx::query(
        r#"
        INSERT INTO payroll_payouts (user_id, week_start, week_end, amount_cop, amount_usdt, payment_method, account_number, status, notes)
        VALUES ($1, $2, $3, $4, 0, 'EFECTIVO', 'N/A', 'PENALTY', 'Multa por 3+ tardanzas')
        "#,
    )
    .bind(user_id)
    .bind(week_start)
    .bind(week_end)
    .bind(-amount_cop)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    tracing::info!("Multa creada para {} por {} COP", user_id, amount_cop);
    Ok(())
}

/// Aplica multa grupal por no alcanzar la cuota de producción del room (1500 tokens).
pub async fn apply_group_shortfall_penalty(room_members: &[Uuid], total_tokens: f64, pool: &PgPool) -> Result<(), String> {
    if total_tokens >= GROUP_QUOTA {
        return Ok(()); // No hay multa si alcanzaron la meta
    }

    let week_start = Utc::now().date_naive();
    let week_end = week_start + chrono::Duration::days(6);

    for user_id in room_members {
        sqlx::query(
            r#"
            INSERT INTO payroll_payouts (user_id, week_start, week_end, amount_cop, amount_usdt, payment_method, account_number, status, notes)
            VALUES ($1, $2, $3, $4, 0, 'EFECTIVO', 'N/A', 'PENALTY', 'Multa: room no alcanzó cuota grupal')
            "#,
        )
        .bind(user_id)
        .bind(week_start)
        .bind(week_end)
        .bind(-GROUP_SHORTFALL_PENALTY_COP)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    }

    tracing::warn!("Multa grupal aplicada: {} miembros multados con {} COP (total room: {} < {})",
        room_members.len(), GROUP_SHORTFALL_PENALTY_COP, total_tokens, GROUP_QUOTA);
    Ok(())
}

/// Aplica multa por room sucio a todos los integrantes del turno.
pub async fn apply_dirty_room_penalty(room_members: &[Uuid], room_id: i32, pool: &PgPool) -> Result<(), String> {
    let week_start = Utc::now().date_naive();
    let week_end = week_start + chrono::Duration::days(6);

    for user_id in room_members {
        sqlx::query(
            r#"
            INSERT INTO payroll_payouts (user_id, week_start, week_end, amount_cop, amount_usdt, payment_method, account_number, status, notes)
            VALUES ($1, $2, $3, $4, 0, 'EFECTIVO', 'N/A', 'PENALTY', $5)
            "#,
        )
        .bind(user_id)
        .bind(week_start)
        .bind(week_end)
        .bind(-DIRTY_ROOM_PENALTY_COP)
        .bind(format!("Multa: Room {} dejado sucio", room_id))
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    }

    tracing::warn!("Multa por room sucio aplicada: {} miembros de Room {} multados con {} COP",
        room_members.len(), room_id, DIRTY_ROOM_PENALTY_COP);
    Ok(())
}
