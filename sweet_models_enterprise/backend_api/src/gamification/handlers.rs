// Endpoints HTTP para gamificación
use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use uuid::Uuid;
use serde::{Deserialize, Serialize};

use crate::gamification::engine::{GamificationEngine, UserLevel};
use crate::state::AppState;

#[derive(Debug, Serialize, Deserialize)]
pub struct UserLevelResponse {
    pub user_id: Uuid,
    pub xp: i64,
    pub current_rank: String,
    pub achievements: Vec<String>,
}

impl From<UserLevel> for UserLevelResponse {
    fn from(level: UserLevel) -> Self {
        UserLevelResponse {
            user_id: level.user_id,
            xp: level.xp,
            current_rank: level.current_rank.as_str().to_string(),
            achievements: level.achievements,
        }
    }
}

/// GET /gamification/users/:user_id/level
/// Obtener información de nivel del usuario
pub async fn get_user_level(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
) -> Result<Json<UserLevelResponse>, (StatusCode, String)> {
    let gamification = GamificationEngine::new(state.db.clone());
    
    let level = gamification
        .get_user_level(user_id)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(level.into()))
}

/// GET /gamification/leaderboard
/// Obtener top 10 de usuarios
pub async fn get_leaderboard(
    State(state): State<AppState>,
) -> Result<Json<Vec<UserLevelResponse>>, (StatusCode, String)> {
    let gamification = GamificationEngine::new(state.db.clone());
    
    let leaderboard = gamification
        .get_leaderboard()
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let response: Vec<UserLevelResponse> = leaderboard.into_iter().map(|l| l.into()).collect();
    Ok(Json(response))
}

/// POST /gamification/users/:user_id/award/:achievement
/// Otorgar logro/medalla (solo admin)
#[derive(Debug, Serialize, Deserialize)]
pub struct AwardAchievementRequest {
    pub achievement: String,
}

pub async fn award_achievement(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
    Json(payload): Json<AwardAchievementRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let gamification = GamificationEngine::new(state.db.clone());
    
    gamification
        .award_achievement(user_id, &payload.achievement)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::OK)
}
