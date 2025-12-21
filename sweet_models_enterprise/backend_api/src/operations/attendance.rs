use axum::{extract::State, http::StatusCode, Json};
use chrono::{DateTime, Duration, NaiveDate, NaiveTime, Utc, Datelike};
use serde::{Deserialize, Serialize};
use sqlx::types::Uuid;
use crate::{state::AppState, finance, gamification};

// Config del estudio
const STUDIO_LAT: f64 = 4.7010; // ejemplo Bogotá
const STUDIO_LON: f64 = -74.0420;
const STUDIO_RADIUS_METERS: f64 = 50.0;
const GRACE_MINUTES: i64 = 15;

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum Shift {
    Shift1, // 02:00-08:00
    Shift2, // 08:00-14:00
    Shift3, // 14:00-20:00
    Shift4, // 20:00-02:00 (cruza medianoche)
}

impl Shift {
    pub fn from_int(v: i32) -> Option<Self> {
        match v {
            1 => Some(Shift::Shift1),
            2 => Some(Shift::Shift2),
            3 => Some(Shift::Shift3),
            4 => Some(Shift::Shift4),
            _ => None,
        }
    }

    pub fn start_time(&self) -> NaiveTime {
        match self {
            Shift::Shift1 => NaiveTime::from_hms_opt(2, 0, 0).unwrap(),
            Shift::Shift2 => NaiveTime::from_hms_opt(8, 0, 0).unwrap(),
            Shift::Shift3 => NaiveTime::from_hms_opt(14, 0, 0).unwrap(),
            Shift::Shift4 => NaiveTime::from_hms_opt(20, 0, 0).unwrap(),
        }
    }

    pub fn window_utc(&self, day: chrono::NaiveDate) -> (DateTime<Utc>, DateTime<Utc>) {
        let start_local = match self {
            Shift::Shift1 => day.and_hms_opt(2, 0, 0).unwrap(),
            Shift::Shift2 => day.and_hms_opt(8, 0, 0).unwrap(),
            Shift::Shift3 => day.and_hms_opt(14, 0, 0).unwrap(),
            Shift::Shift4 => day.and_hms_opt(20, 0, 0).unwrap(),
        };
        let end_local = match self {
            Shift::Shift1 => day.and_hms_opt(8, 0, 0).unwrap(),
            Shift::Shift2 => day.and_hms_opt(14, 0, 0).unwrap(),
            Shift::Shift3 => day.and_hms_opt(20, 0, 0).unwrap(),
            Shift::Shift4 => day.succ_opt().unwrap().and_hms_opt(2, 0, 0).unwrap(),
        };
        // Suponiendo servidor en UTC; si hay TZ distinta, ajustar con chrono_tz.
        (DateTime::<Utc>::from_naive_utc_and_offset(start_local, Utc), DateTime::<Utc>::from_naive_utc_and_offset(end_local, Utc))
    }

    pub fn start_with_grace(&self, day: chrono::NaiveDate) -> DateTime<Utc> {
        let (start, _) = self.window_utc(day);
        start + chrono::Duration::minutes(GRACE_MINUTES)
    }
}

pub async fn get_assigned_shift_start(
    user_id: Uuid,
    check_in_date: NaiveDate,
    pool: &sqlx::PgPool,
) -> Result<(Shift, NaiveTime), (StatusCode, String)> {
    let week_id = format!("{}-W{:02}", check_in_date.iso_week().year(), check_in_date.iso_week().week());
    let shift_int = sqlx::query_scalar::<_, i32>(
        "SELECT assigned_shift FROM user_shifts WHERE user_id = $1 AND week_id = $2 LIMIT 1",
    )
    .bind(user_id)
    .bind(&week_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| {
        tracing::error!("DB error fetching user shift: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    let Some(shift_int) = shift_int else {
        return Err((StatusCode::BAD_REQUEST, "No shift assigned for this week".to_string()));
    };

    let Some(shift) = Shift::from_int(shift_int) else {
        return Err((StatusCode::BAD_REQUEST, "Shift inválido".to_string()));
    };

    Ok((shift, shift.start_time()))
}

pub async fn process_check_in(
    state: &std::sync::Arc<AppState>,
    user_id: Uuid,
    check_in_time: DateTime<Utc>,
) -> Result<bool, (StatusCode, String)> {
    let pool = &state.db;
    let check_date = check_in_time.date_naive();
    let (shift, shift_start_time) = get_assigned_shift_start(user_id, check_date, pool).await?;

    // Manejo de turno cruzando medianoche: si shift4 y check_in < 06:00, usar el día anterior como inicio.
    let effective_day = if shift == Shift::Shift4 && check_in_time.time() < NaiveTime::from_hms_opt(6, 0, 0).unwrap() {
        check_date.pred_opt().unwrap_or(check_date)
    } else {
        check_date
    };

    let shift_start_naive = effective_day.and_time(shift_start_time);
    let shift_start = DateTime::<Utc>::from_naive_utc_and_offset(shift_start_naive, Utc);
    let start_with_grace = shift_start + Duration::minutes(GRACE_MINUTES);

    Ok(check_in_time > start_with_grace)
}

#[derive(Debug, Deserialize)]
pub struct ClockInRequest {
    pub user_id: Uuid,
    pub latitude: f64,
    pub longitude: f64,
    pub photo_url: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ClockInResponse {
    pub id: Uuid,
    pub is_late: bool,
    pub message: String,
}

fn haversine_distance_m(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> f64 {
    let r = 6371000.0_f64;
    let dlat = (lat2 - lat1).to_radians();
    let dlon = (lon2 - lon1).to_radians();
    let a = (dlat / 2.0).sin().powi(2)
        + lat1.to_radians().cos() * lat2.to_radians().cos() * (dlon / 2.0).sin().powi(2);
    let c = 2.0 * a.sqrt().atan2((1.0 - a).sqrt());
    r * c
}

/// POST /api/operations/attendance/clock-in
pub async fn clock_in_handler(
    State(state): State<std::sync::Arc<AppState>>,
    Json(req): Json<ClockInRequest>,
) -> Result<Json<ClockInResponse>, (StatusCode, String)> {
    // GPS validation
    let dist = haversine_distance_m(req.latitude, req.longitude, STUDIO_LAT, STUDIO_LON);
    if dist > STUDIO_RADIUS_METERS {
        return Err((StatusCode::FORBIDDEN, "Estás fuera del estudio".to_string()));
    }

    let now = Utc::now();

    let is_late = process_check_in(&state, req.user_id, now).await?;

    let pool = &state.db;
    let row = sqlx::query_scalar::<_, Uuid>(
        r#"
        INSERT INTO attendance_logs (user_id, check_in, is_late, photo_url)
        VALUES ($1, NOW(), $2, $3)
        RETURNING id
        "#,
    )
    .bind(req.user_id)
    .bind(is_late)
    .bind(&req.photo_url)
    .fetch_one(pool)
    .await
    .map_err(|e| {
        tracing::error!("DB error inserting attendance: {}", e);
        (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
    })?;

    if is_late {
        apply_strike(&state, req.user_id, now).await?;
    }

    Ok(Json(ClockInResponse {
        id: row,
        is_late,
        message: if is_late { "Llegaste tarde".to_string() } else { "Check-in registrado".to_string() },
    }))
}

async fn apply_strike(
    state: &std::sync::Arc<AppState>,
    user_id: Uuid,
    check_in_time: DateTime<Utc>,
) -> Result<(), (StatusCode, String)> {
    let pool = &state.db;
    let week_start = check_in_time - Duration::days((check_in_time.weekday().num_days_from_monday()) as i64);

    let late_count: i64 = sqlx::query_scalar(
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

    if late_count == 1 {
        // Strike 1: 10% XP burn + mark 50% pay today
        let mut conn = state.redis.get().await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
        let key = format!("penalty:half_today:{}", user_id);
        let ttl = 24 * 3600;
        let _: () = deadpool_redis::redis::cmd("SETEX")
            .arg(&key)
            .arg(ttl)
            .arg("1")
            .query_async(&mut conn)
            .await
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
        
        // Burn 10% XP
        if let Err(e) = gamification::burn_xp(user_id, "STRIKE_1", pool).await {
            tracing::warn!("XP burn failed for strike 1: {}", e);
        }
        tracing::info!("Strike 1 aplicado: {} cobra al 50% hoy", user_id);
    } else if late_count == 2 {
        // Strike 2: 30% XP burn + degrade week
        if let Err(e) = gamification::burn_xp(user_id, "STRIKE_2", pool).await {
            tracing::warn!("XP burn failed for strike 2: {}", e);
        }
        if let Err(e) = finance::penalties::downgrade_user_week(user_id, 0.50, pool).await {
            tracing::warn!("No se pudo aplicar downgrade semanal: {}", e);
        }
    } else if late_count >= 3 {
        // Strike 3: 100% XP burn + penalty
        if let Err(e) = gamification::burn_xp(user_id, "STRIKE_3", pool).await {
            tracing::warn!("XP burn failed for strike 3: {}", e);
        }
        if let Err(e) = finance::penalties::create_penalty(user_id, finance::payroll::STRIKE3_PENALTY_COP, pool).await {
            tracing::warn!("No se pudo crear multa: {}", e);
        }
    }

    Ok(())
}
