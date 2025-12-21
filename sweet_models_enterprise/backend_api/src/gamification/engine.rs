// Módulo de gamificación: Motor de XP y rangos
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, PartialOrd, Ord)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum UserRank {
    Novice,
    RisingStar,
    Elite,
    Queen,
    Goddess,
}

impl UserRank {
    pub fn as_str(&self) -> &'static str {
        match self {
            UserRank::Novice => "NOVICE",
            UserRank::RisingStar => "RISING_STAR",
            UserRank::Elite => "ELITE",
            UserRank::Queen => "QUEEN",
            UserRank::Goddess => "GODDESS",
        }
    }

    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "NOVICE" => Some(UserRank::Novice),
            "RISING_STAR" => Some(UserRank::RisingStar),
            "ELITE" => Some(UserRank::Elite),
            "QUEEN" => Some(UserRank::Queen),
            "GODDESS" => Some(UserRank::Goddess),
            _ => None,
        }
    }

    pub fn min_xp(&self) -> i64 {
        match self {
            UserRank::Novice => 0,
            UserRank::RisingStar => 1000,
            UserRank::Elite => 5000,
            UserRank::Queen => 15000,
            UserRank::Goddess => 50000,
        }
    }

    pub fn next_rank(&self) -> Option<UserRank> {
        match self {
            UserRank::Novice => Some(UserRank::RisingStar),
            UserRank::RisingStar => Some(UserRank::Elite),
            UserRank::Elite => Some(UserRank::Queen),
            UserRank::Queen => Some(UserRank::Goddess),
            UserRank::Goddess => None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserLevel {
    pub user_id: Uuid,
    pub xp: i64,
    pub current_rank: UserRank,
    pub achievements: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LevelUpEvent {
    pub user_id: Uuid,
    pub old_rank: UserRank,
    pub new_rank: UserRank,
    pub total_xp: i64,
    pub reward: Option<String>, // Descripción del premio
}

pub struct GamificationEngine {
    pool: PgPool,
}

impl GamificationEngine {
    pub fn new(pool: PgPool) -> Self {
        GamificationEngine { pool }
    }

    /// Agregar XP al usuario y verificar cambio de rango.
    pub async fn add_xp(
        &self,
        user_id: Uuid,
        amount: i64,
        reason: &str,
    ) -> Result<Option<LevelUpEvent>, sqlx::Error> {
        // Inicializar user_level si no existe
        self.ensure_user_level(user_id).await?;

        // Agregar XP e insertar en histórico
        sqlx::query(
            r#"
            INSERT INTO xp_history (user_id, xp_gained, reason)
            VALUES ($1, $2, $3)
            "#,
        )
        .bind(user_id)
        .bind(amount)
        .bind(reason)
        .execute(&self.pool)
        .await?;

        // Actualizar XP total
        sqlx::query(
            r#"
            UPDATE user_levels
            SET xp = xp + $1
            WHERE user_id = $2
            "#,
        )
        .bind(amount)
        .bind(user_id)
        .execute(&self.pool)
        .await?;

        // Obtener XP actual y rango actual
        let row = sqlx::query_as::<_, (i64, String)>(
            r#"
            SELECT xp, current_rank
            FROM user_levels
            WHERE user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_one(&self.pool)
        .await?;

        let current_xp = row.0;
        let current_rank = UserRank::from_str(&row.1).unwrap_or(UserRank::Novice);

        // Verificar si subió de rango
        if let Some(next_rank) = current_rank.next_rank() {
            if current_xp >= next_rank.min_xp() {
                // Actualizar rango
                sqlx::query(
                    r#"
                    UPDATE user_levels
                    SET current_rank = $1
                    WHERE user_id = $2
                    "#,
                )
                .bind(next_rank.as_str())
                .bind(user_id)
                .execute(&self.pool)
                .await?;

                // Obtener reward
                let reward_row = sqlx::query_as::<_, (Option<String>,)>(
                    r#"
                    SELECT reward_amount
                    FROM rank_thresholds
                    WHERE rank_id = $1
                    "#,
                )
                .bind(next_rank.as_str())
                .fetch_optional(&self.pool)
                .await?;

                let reward = reward_row.and_then(|r| r.0);

                return Ok(Some(LevelUpEvent {
                    user_id,
                    old_rank: current_rank,
                    new_rank: next_rank,
                    total_xp: current_xp,
                    reward,
                }));
            }
        }

        Ok(None)
    }

    /// Inicializar nivel de usuario si no existe.
    async fn ensure_user_level(&self, user_id: Uuid) -> Result<(), sqlx::Error> {
        sqlx::query(
            r#"
            INSERT INTO user_levels (user_id)
            VALUES ($1)
            ON CONFLICT (user_id) DO NOTHING
            "#,
        )
        .bind(user_id)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// Obtener datos de nivel del usuario.
    pub async fn get_user_level(&self, user_id: Uuid) -> Result<UserLevel, sqlx::Error> {
        self.ensure_user_level(user_id).await?;

        let row = sqlx::query_as::<_, (i64, String, serde_json::Value)>(
            r#"
            SELECT xp, current_rank, achievements
            FROM user_levels
            WHERE user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_one(&self.pool)
        .await?;

        let achievements: Vec<String> = serde_json::from_value(row.2).unwrap_or_default();

        Ok(UserLevel {
            user_id,
            xp: row.0,
            current_rank: UserRank::from_str(&row.1).unwrap_or(UserRank::Novice),
            achievements,
        })
    }

    /// Otorgar logro/medalla al usuario.
    pub async fn award_achievement(
        &self,
        user_id: Uuid,
        achievement: &str,
    ) -> Result<(), sqlx::Error> {
        sqlx::query(
            r#"
            UPDATE user_levels
            SET achievements = 
              CASE 
                WHEN achievements @> $2::jsonb THEN achievements
                ELSE achievements || $2::jsonb
              END
            WHERE user_id = $1
            "#,
        )
        .bind(user_id)
        .bind(serde_json::json!([achievement]))
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// Obtener el top 10 de usuarios por XP.
    pub async fn get_leaderboard(&self) -> Result<Vec<UserLevel>, sqlx::Error> {
        let rows = sqlx::query_as::<_, (Uuid, i64, String, serde_json::Value)>(
            r#"
            SELECT user_id, xp, current_rank, achievements
            FROM user_levels
            ORDER BY xp DESC
            LIMIT 10
            "#,
        )
        .fetch_all(&self.pool)
        .await?;

        let leaderboard = rows
            .into_iter()
            .map(|(user_id, xp, rank_str, ach_json)| {
                let achievements: Vec<String> = serde_json::from_value(ach_json).unwrap_or_default();
                UserLevel {
                    user_id,
                    xp,
                    current_rank: UserRank::from_str(&rank_str).unwrap_or(UserRank::Novice),
                    achievements,
                }
            })
            .collect();

        Ok(leaderboard)
    }
}

// ============ XP BURN (FRAGILIDAD) SYSTEM ============

#[derive(Debug, Clone)]
pub struct BurnResult {
    pub user_id: Uuid,
    pub xp_loss: i64,
    pub previous_xp: i64,
    pub new_xp: i64,
    pub percentage: f64,
    pub description: String,
}

/// Fragilidad: Tabla de pérdida de XP por infracciones
pub const FRAGILITY_BURNS: &[(&str, f64, &str)] = &[
    ("STRIKE_1", 10.0, "Perdiste 10% XP por llegar tarde (Strike 1)"),
    ("STRIKE_2", 30.0, "Perdiste 30% XP por reincidencia (Strike 2)"),
    ("STRIKE_3", 100.0, "¡RESETEO! Perdiste 100% XP (Strike 3)"),
    ("DIRTY_ROOM", 20.0, "Perdiste 20% XP por room sucio"),
    ("LOW_PRODUCTION", 5.0, "Perdiste 5% XP por baja producción (<1500 tokens)"),
];

/// Quema XP del usuario por infracciones
pub async fn burn_xp(
    user_id: Uuid,
    reason: &str,
    pool: &PgPool,
) -> Result<BurnResult, String> {
    let (_, burn_percentage, description) = FRAGILITY_BURNS
        .iter()
        .find(|&(r, _, _)| r == &reason)
        .ok_or_else(|| format!("Regla de fragilidad desconocida: {}", reason))?;

    // Obtener XP actual
    let current_xp = sqlx::query_scalar::<_, i64>(
        "SELECT COALESCE(xp, 0) FROM users WHERE id = $1",
    )
    .bind(user_id)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;

    let xp_loss = ((current_xp as f64) * (burn_percentage / 100.0)) as i64;
    let new_xp = (current_xp - xp_loss).max(0);

    // Actualizar base de datos
    sqlx::query(
        r#"
        UPDATE users
        SET xp = $2,
            updated_at = NOW()
        WHERE id = $1
        "#,
    )
    .bind(user_id)
    .bind(new_xp)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    // Registrar evento en audit
    let _ = sqlx::query(
        r#"
        INSERT INTO xp_burn_log (user_id, reason, xp_loss, previous_xp, new_xp, timestamp)
        VALUES ($1, $2, $3, $4, $5, NOW())
        ON CONFLICT DO NOTHING
        "#,
    )
    .bind(user_id)
    .bind(reason)
    .bind(xp_loss)
    .bind(current_xp)
    .bind(new_xp)
    .execute(pool)
    .await;

    tracing::warn!(
        "🔥 XP QUEMADO: {} perdió {} XP ({:.0}%) por {} | {}/{} XP",
        user_id, xp_loss, burn_percentage, reason, new_xp, current_xp
    );

    Ok(BurnResult {
        user_id,
        xp_loss,
        previous_xp: current_xp,
        new_xp,
        percentage: *burn_percentage,
        description: description.to_string(),
    })
}

/// Añade XP al usuario (recompensa)
pub async fn add_xp_reward(
    user_id: Uuid,
    amount: i64,
    reason: &str,
    pool: &PgPool,
) -> Result<i64, String> {
    let new_xp = sqlx::query_scalar::<_, i64>(
        r#"
        UPDATE users
        SET xp = COALESCE(xp, 0) + $2,
            total_xp_earned = COALESCE(total_xp_earned, 0) + $2,
            updated_at = NOW()
        WHERE id = $1
        RETURNING xp
        "#,
    )
    .bind(user_id)
    .bind(amount)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;

    tracing::info!(
        "✅ XP GANADO: {} recibió +{} XP por {} (Total: {} XP)",
        user_id, amount, reason, new_xp
    );

    Ok(new_xp as i64)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rank_progression() {
        assert_eq!(UserRank::Novice.next_rank(), Some(UserRank::RisingStar));
        assert_eq!(UserRank::Novice.min_xp(), 0);
        assert_eq!(UserRank::RisingStar.min_xp(), 1000);
    }
}
