/// God Mode: Dashboard del CEO - "The Pulse"
/// Panel de control en tiempo real del estado completo del estudio
use axum::{extract::State, http::StatusCode, Json};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use chrono::{DateTime, Utc, Timelike};
use std::sync::Arc;

use crate::{state::AppState, middleware::auth::SuperAdminOnly};

// ============================================================================
// DATA MODELS
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemPulse {
    /// Usuarios online en este momento
    pub online_users: i32,
    
    /// Estado de todos los rooms activos
    pub active_rooms: Vec<RoomStatus>,
    
    /// Salud financiera del día
    pub financial_health: FinancialHealth,
    
    /// Alertas de seguridad (Phoenix, intentos de hack)
    pub security_alerts: i32,
    
    /// Canjes de puntos pendientes de aprobación
    pub pending_approvals: i32,
    
    /// Timestamp del snapshot
    pub snapshot_at: DateTime<Utc>,
    
    /// Tiempo de cálculo (ms)
    pub compute_time_ms: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoomStatus {
    pub room_id: i32,
    pub room_name: String,
    pub shift_id: i32,
    pub shift_name: String,
    
    /// Producción actual (tokens del turno)
    pub current_tokens: f64,
    
    /// Meta diaria (cuota grupal)
    pub target_tokens: f64,
    
    /// Progreso (%)
    pub progress_percent: f64,
    
    /// Estado de limpieza
    pub is_clean: bool,
    
    /// Modelos activas en este room
    pub active_models: i32,
    
    /// Tiempo restante del turno (minutos)
    pub minutes_remaining: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FinancialHealth {
    /// Dinero generado HOY (00:00 - ahora)
    pub daily_revenue_cop: f64,
    
    /// Proyección de pago para el martes (semana completa)
    pub projected_payout_cop: f64,
    
    /// Multas recaudadas HOY
    pub penalties_collected_cop: f64,
    
    /// Balance XP del sistema (total ganado - gastado)
    pub total_xp_balance: i64,
    
    /// Canjes de puntos aprobados esta semana
    pub rewards_redeemed_count: i32,
    
    /// Valor total de recompensas canjeadas (COP)
    pub rewards_value_cop: f64,
}

// ============================================================================
// ENDPOINT: GET /api/admin/pulse
// ============================================================================

/// GET /api/admin/pulse
/// Dashboard del CEO: Snapshot en tiempo real del estudio
/// Requiere: Rol SUPER_ADMIN
pub async fn get_system_pulse_handler(
    State(state): State<Arc<AppState>>,
    _admin: SuperAdminOnly,
) -> Result<Json<SystemPulse>, (StatusCode, String)> {
    let start = std::time::Instant::now();
    let pool = &state.db;
    let now = Utc::now();
    
    // Ejecutar todas las consultas en paralelo para máxima velocidad
    let (
        online_users,
        active_rooms,
        financial_health,
        security_alerts,
        pending_approvals,
    ) = tokio::join!(
        count_online_users(pool),
        fetch_active_rooms(pool, &state),
        calculate_financial_health(pool),
        count_security_alerts(pool),
        count_pending_approvals(pool),
    );
    
    let compute_time_ms = start.elapsed().as_millis() as i64;
    
    Ok(Json(SystemPulse {
        online_users: online_users.unwrap_or(0),
        active_rooms: active_rooms.unwrap_or_default(),
        financial_health: financial_health.unwrap_or_default(),
        security_alerts: security_alerts.unwrap_or(0),
        pending_approvals: pending_approvals.unwrap_or(0),
        snapshot_at: now,
        compute_time_ms,
    }))
}

// ============================================================================
// QUERY FUNCTIONS (Optimizadas para <100ms)
// ============================================================================

/// Cuenta usuarios online (check-in reciente sin check-out)
async fn count_online_users(pool: &PgPool) -> Result<i32, String> {
    let count = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(DISTINCT user_id)
        FROM attendance
        WHERE DATE(check_in_time) = CURRENT_DATE
          AND check_out_time IS NULL
        "#,
    )
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    
    Ok(count as i32)
}

/// Obtiene estado de todos los rooms activos
async fn fetch_active_rooms(pool: &PgPool, state: &AppState) -> Result<Vec<RoomStatus>, String> {
    #[derive(sqlx::FromRow)]
    struct RoomRow {
        room_id: i32,
        room_name: String,
        shift_id: i32,
        shift_name: String,
        current_tokens: Option<f64>,
        active_models: i64,
    }
    
    let rows = sqlx::query_as::<_, RoomRow>(
        r#"
        SELECT 
            r.id as room_id,
            r.name as room_name,
            s.id as shift_id,
            s.name as shift_name,
            COALESCE(SUM(t.tokens), 0) as current_tokens,
            COUNT(DISTINCT a.user_id) as active_models
        FROM rooms r
        CROSS JOIN shifts s
        LEFT JOIN attendance a ON DATE(a.check_in_time) = CURRENT_DATE 
                              AND a.check_out_time IS NULL
        LEFT JOIN (
            SELECT user_id, SUM(amount) as tokens
            FROM transactions
            WHERE DATE(created_at) = CURRENT_DATE
            GROUP BY user_id
        ) t ON t.user_id = a.user_id
        WHERE r.is_active = true
        GROUP BY r.id, r.name, s.id, s.name
        ORDER BY r.id, s.id
        "#,
    )
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    
    // Obtener estado de limpieza desde Redis (cache)
    let mut rooms = Vec::new();
    for row in rows {
        let is_clean = check_room_cleanliness(&state.redis, row.room_id).await.unwrap_or(true);
        
        // Calcular tiempo restante del turno (asumiendo turnos de 8 horas)
        let minutes_remaining = calculate_shift_time_remaining(&row.shift_name);
        
        let current = row.current_tokens.unwrap_or(0.0);
        let target = 1500.0; // GROUP_QUOTA
        let progress = if target > 0.0 { (current / target * 100.0).min(100.0) } else { 0.0 };
        
        rooms.push(RoomStatus {
            room_id: row.room_id,
            room_name: row.room_name,
            shift_id: row.shift_id,
            shift_name: row.shift_name,
            current_tokens: current,
            target_tokens: target,
            progress_percent: progress,
            is_clean,
            active_models: row.active_models as i32,
            minutes_remaining,
        });
    }
    
    Ok(rooms)
}

/// Calcula salud financiera del día y semana
async fn calculate_financial_health(pool: &PgPool) -> Result<FinancialHealth, String> {
    // Revenue diario (tokens * rate)
    let daily_revenue: Option<f64> = sqlx::query_scalar(
        r#"
        SELECT COALESCE(SUM(amount * 4000), 0) -- Asumiendo 4000 COP por token
        FROM transactions
        WHERE DATE(created_at) = CURRENT_DATE
          AND transaction_type = 'EARNING'
        "#,
    )
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    
    // Proyección de payout (semana completa)
    let projected_payout: Option<f64> = sqlx::query_scalar(
        r#"
        SELECT COALESCE(SUM(amount_cop), 0)
        FROM payroll_payouts
        WHERE week_id = (
            SELECT TO_CHAR(CURRENT_DATE, 'IYYY-"W"IW')
        )
        AND status = 'pending'
        "#,
    )
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    
    // Multas recaudadas hoy
    let penalties_collected: Option<f64> = sqlx::query_scalar(
        r#"
        SELECT COALESCE(SUM(penalty_amount_cop), 0)
        FROM penalties
        WHERE DATE(created_at) = CURRENT_DATE
        "#,
    )
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    
    // Balance XP del sistema
    let total_xp_balance: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT COALESCE(SUM(xp), 0)
        FROM users
        WHERE role = 'model'
        "#,
    )
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    
    // Canjes aprobados esta semana
    let rewards_redeemed: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT COUNT(*)
        FROM reward_redemptions
        WHERE DATE_TRUNC('week', created_at) = DATE_TRUNC('week', CURRENT_DATE)
          AND status IN ('approved', 'claimed')
        "#,
    )
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    
    // Valor de recompensas (estimado en 1 XP = 200 COP)
    let rewards_value: Option<f64> = sqlx::query_scalar(
        r#"
        SELECT COALESCE(SUM(xp_cost * 200), 0)
        FROM reward_redemptions
        WHERE DATE_TRUNC('week', created_at) = DATE_TRUNC('week', CURRENT_DATE)
          AND status IN ('approved', 'claimed')
        "#,
    )
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    
    Ok(FinancialHealth {
        daily_revenue_cop: daily_revenue.unwrap_or(0.0),
        projected_payout_cop: projected_payout.unwrap_or(0.0),
        penalties_collected_cop: penalties_collected.unwrap_or(0.0),
        total_xp_balance: total_xp_balance.unwrap_or(0),
        rewards_redeemed_count: rewards_redeemed.unwrap_or(0) as i32,
        rewards_value_cop: rewards_value.unwrap_or(0.0),
    })
}

/// Cuenta alertas de seguridad (Phoenix logs, intentos de hack)
async fn count_security_alerts(pool: &PgPool) -> Result<i32, String> {
    let count: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT COUNT(*)
        FROM security_logs
        WHERE DATE(created_at) = CURRENT_DATE
          AND (
              event_type = 'PHOENIX_ACTIVATION' 
              OR event_type = 'UNAUTHORIZED_ACCESS'
              OR event_type = 'FAILED_LOGIN_ATTEMPTS'
              OR event_type = 'SUSPICIOUS_TRANSACTION'
          )
        "#,
    )
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    
    Ok(count.unwrap_or(0) as i32)
}

/// Cuenta canjes de puntos pendientes de aprobación
async fn count_pending_approvals(pool: &PgPool) -> Result<i32, String> {
    let count: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT COUNT(*)
        FROM reward_redemptions
        WHERE status = 'pending'
        "#,
    )
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;
    
    Ok(count.unwrap_or(0) as i32)
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Verifica limpieza de room desde Redis cache
async fn check_room_cleanliness(
    redis: &deadpool_redis::Pool,
    room_id: i32,
) -> Result<bool, String> {
    let mut conn = redis.get().await.map_err(|e| e.to_string())?;
    let key = format!("room:{}:clean", room_id);
    
    let is_clean: Option<String> = deadpool_redis::redis::cmd("GET")
        .arg(&key)
        .query_async(&mut conn)
        .await
        .map_err(|e| e.to_string())?;
    
    // Si no hay registro en cache, asumir limpio
    Ok(is_clean.unwrap_or_else(|| "true".to_string()) == "true")
}

/// Calcula minutos restantes del turno actual
fn calculate_shift_time_remaining(shift_name: &str) -> Option<i32> {
    let now = Utc::now();
    let current_hour = now.hour();
    
    // Turnos típicos: Morning (6-14), Afternoon (14-22), Night (22-6)
    let end_hour = match shift_name.to_lowercase().as_str() {
        name if name.contains("morning") || name.contains("mañana") => 14,
        name if name.contains("afternoon") || name.contains("tarde") => 22,
        name if name.contains("night") || name.contains("noche") => 6,
        _ => return None,
    };
    
    let minutes_remaining = if current_hour < end_hour {
        ((end_hour - current_hour) * 60) as i32 - now.minute() as i32
    } else if shift_name.to_lowercase().contains("night") && current_hour >= 22 {
        // Turno nocturno cruza medianoche
        ((24 - current_hour + 6) * 60) as i32 - now.minute() as i32
    } else {
        0 // Turno ya terminó
    };
    
    Some(minutes_remaining.max(0))
}

impl Default for FinancialHealth {
    fn default() -> Self {
        Self {
            daily_revenue_cop: 0.0,
            projected_payout_cop: 0.0,
            penalties_collected_cop: 0.0,
            total_xp_balance: 0,
            rewards_redeemed_count: 0,
            rewards_value_cop: 0.0,
        }
    }
}
