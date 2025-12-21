/// Tienda de Premios: Sistema de canje de XP por recompensas
use axum::{extract::State, http::StatusCode, Json};
use serde::{Deserialize, Serialize};
use sqlx::types::Uuid;

use crate::state::AppState;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RewardItem {
    pub id: String,
    pub name: String,
    pub category: String,
    pub xp_cost: i64,
    pub cash_value_cop: Option<f64>,
    pub description: String,
    pub image_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RedeemRequest {
    pub reward_id: String,
    pub user_id: Uuid,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RedeemResponse {
    pub ticket_id: Uuid,
    pub reward_name: String,
    pub xp_deducted: i64,
    pub remaining_xp: i64,
    pub message: String,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserBalance {
    pub user_id: Uuid,
    pub current_xp: i64,
    pub total_xp_earned: i64,
    pub xp_available: i64,  // XP no en riesgo
    pub xp_at_risk: i64,    // XP pendiente por fragilidad
}

// ============ CATÁLOGO DE PREMIOS ============

pub fn get_reward_catalog() -> Vec<RewardItem> {
    vec![
        // BIENESTAR
        RewardItem {
            id: "peluqueria_premium".to_string(),
            name: "Peluquería Premium".to_string(),
            category: "Bienestar".to_string(),
            xp_cost: 500,
            cash_value_cop: Some(80_000.0),
            description: "Corte y tratamiento en salón 5⭐".to_string(),
            image_url: Some("/rewards/peluqueria.png".to_string()),
        },
        RewardItem {
            id: "masaje_spa".to_string(),
            name: "Masaje Spa 1H".to_string(),
            category: "Bienestar".to_string(),
            xp_cost: 750,
            cash_value_cop: Some(120_000.0),
            description: "Masaje relajante en spa premium".to_string(),
            image_url: Some("/rewards/spa.png".to_string()),
        },
        // LUJO
        RewardItem {
            id: "uber_eats_100k".to_string(),
            name: "Vale Uber Eats $100k".to_string(),
            category: "Lujo".to_string(),
            xp_cost: 300,
            cash_value_cop: Some(100_000.0),
            description: "Crédito para comida a domicilio".to_string(),
            image_url: Some("/rewards/uber_eats.png".to_string()),
        },
        RewardItem {
            id: "uber_rides_50k".to_string(),
            name: "Vale Uber Rides $50k".to_string(),
            category: "Lujo".to_string(),
            xp_cost: 250,
            cash_value_cop: Some(50_000.0),
            description: "Viajes ilimitados en Uber".to_string(),
            image_url: Some("/rewards/uber.png".to_string()),
        },
        RewardItem {
            id: "smartphone_case".to_string(),
            name: "Case Tech Premium".to_string(),
            category: "Tech".to_string(),
            xp_cost: 400,
            cash_value_cop: Some(60_000.0),
            description: "Estuche protector de lujo".to_string(),
            image_url: Some("/rewards/case.png".to_string()),
        },
        // JACKPOT TRIMESTRAL
        RewardItem {
            id: "trip_cartagena".to_string(),
            name: "Viaje Cartagena 3 Noches".to_string(),
            category: "Jackpot Trimestral".to_string(),
            xp_cost: 5_000,
            cash_value_cop: Some(2_000_000.0),
            description: "Hotel 4⭐ + Desayuno incluido".to_string(),
            image_url: Some("/rewards/cartagena.png".to_string()),
        },
        RewardItem {
            id: "room_makeover".to_string(),
            name: "Remodelación Room".to_string(),
            category: "Jackpot Trimestral".to_string(),
            xp_cost: 3_000,
            cash_value_cop: Some(1_500_000.0),
            description: "Decoración y mobiliario para el room".to_string(),
            image_url: Some("/rewards/room.png".to_string()),
        },
        RewardItem {
            id: "surgery_fund".to_string(),
            name: "Fondo Cirugía Estética".to_string(),
            category: "Jackpot Trimestral".to_string(),
            xp_cost: 10_000,
            cash_value_cop: Some(5_000_000.0),
            description: "Crédito para procedimiento estético".to_string(),
            image_url: Some("/rewards/surgery.png".to_string()),
        },
    ]
}

// ============ ENDPOINTS ============

#[axum::debug_handler]
pub async fn get_catalog_handler() -> Result<Json<Vec<RewardItem>>, (StatusCode, String)> {
    let catalog = get_reward_catalog();
    Ok(Json(catalog))
}

#[axum::debug_handler]
pub async fn get_user_balance_handler(
    State(state): State<std::sync::Arc<AppState>>,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Result<Json<UserBalance>, (StatusCode, String)> {
    let user_id = params
        .get("user_id")
        .and_then(|id| uuid::Uuid::parse_str(id).ok())
        .ok_or((StatusCode::BAD_REQUEST, "Invalid user_id".to_string()))?;

    let pool = &state.db;

    #[derive(sqlx::FromRow)]
    struct Row {
        current_xp: Option<i64>,
        total_xp_earned: Option<i64>,
    }

    let row = sqlx::query_as::<_, Row>(
        "SELECT COALESCE(xp, 0) as current_xp, COALESCE(total_xp_earned, 0) as total_xp_earned FROM users WHERE id = $1",
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
    .ok_or((StatusCode::NOT_FOUND, "User not found".to_string()))?;

    let current_xp = row.current_xp.unwrap_or(0);
    let total_xp_earned = row.total_xp_earned.unwrap_or(0);

    // XP en riesgo = total_earned - current (lo quemado)
    let xp_at_risk = (total_xp_earned - current_xp).max(0);

    Ok(Json(UserBalance {
        user_id,
        current_xp,
        total_xp_earned,
        xp_available: current_xp,
        xp_at_risk,
    }))
}

#[axum::debug_handler]
pub async fn redeem_reward_handler(
    State(state): State<std::sync::Arc<AppState>>,
    Json(req): Json<RedeemRequest>,
) -> Result<Json<RedeemResponse>, (StatusCode, String)> {
    let pool = &state.db;
    let catalog = get_reward_catalog();

    // Validar que el reward existe
    let reward = catalog
        .iter()
        .find(|r| r.id == req.reward_id)
        .ok_or((StatusCode::NOT_FOUND, "Reward not found".to_string()))?;

    // Obtener XP actual del usuario
    let current_xp = sqlx::query_scalar::<_, i64>(
        "SELECT COALESCE(xp, 0) FROM users WHERE id = $1",
    )
    .bind(req.user_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
    .ok_or((StatusCode::NOT_FOUND, "User not found".to_string()))?;

    // Validar que tiene suficiente XP
    if current_xp < reward.xp_cost {
        return Err((
            StatusCode::BAD_REQUEST,
            format!(
                "Insufficient XP. Need: {}, Have: {}",
                reward.xp_cost, current_xp
            ),
        ));
    }

    // Generar ticket de canje
    let ticket_id = uuid::Uuid::new_v4();

    // Descontar XP
    let remaining_xp = sqlx::query_scalar::<_, i64>(
        r#"
        UPDATE users
        SET xp = xp - $2,
            updated_at = NOW()
        WHERE id = $1
        RETURNING xp
        "#,
    )
    .bind(req.user_id)
    .bind(reward.xp_cost)
    .fetch_one(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    // Crear ticket de canje
    let _ = sqlx::query(
        r#"
        INSERT INTO reward_redemptions (id, user_id, reward_id, reward_name, xp_cost, status, created_at)
        VALUES ($1, $2, $3, $4, $5, 'PENDING_APPROVAL', NOW())
        "#,
    )
    .bind(ticket_id)
    .bind(req.user_id)
    .bind(&reward.id)
    .bind(&reward.name)
    .bind(reward.xp_cost)
    .execute(pool)
    .await;

    tracing::info!(
        "🎁 CANJE: {} canjeó {} por {} XP | Ticket: {}",
        req.user_id, reward.name, reward.xp_cost, ticket_id
    );

    Ok(Json(RedeemResponse {
        ticket_id,
        reward_name: reward.name.clone(),
        xp_deducted: reward.xp_cost,
        remaining_xp: remaining_xp as i64,
        message: format!("¡Canje exitoso! Tu ticket es: {}", ticket_id),
        status: "PENDING_APPROVAL".to_string(),
    }))
}
