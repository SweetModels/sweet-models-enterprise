// Integraciones de gamificación con otros módulos
use crate::gamification::engine::{GamificationEngine, LevelUpEvent};
use uuid::Uuid;

pub struct GamificationHooks {
    gamification: GamificationEngine,
}

impl GamificationHooks {
    pub fn new(gamification: GamificationEngine) -> Self {
        GamificationHooks { gamification }
    }

    /// Hook: Usuario gana dinero en finance (1 USDT = +10 XP)
    pub async fn on_user_earnings(
        &self,
        user_id: Uuid,
        usdt_amount: f64,
    ) -> Result<Option<LevelUpEvent>, Box<dyn std::error::Error>> {
        let xp_gained = (usdt_amount * 10.0) as i64;
        let level_up = self
            .gamification
            .add_xp(user_id, xp_gained, &format!("finance_earnings_{}_usdt", usdt_amount))
            .await?;

        if let Some(event) = &level_up {
            tracing::info!(
                "[GAMIFICATION] {} leveled up: {:?} -> {:?}",
                user_id,
                event.old_rank,
                event.new_rank
            );
        }

        Ok(level_up)
    }

    /// Hook: Usuario sube una foto en social (+5 XP)
    pub async fn on_photo_upload(
        &self,
        user_id: Uuid,
    ) -> Result<Option<LevelUpEvent>, Box<dyn std::error::Error>> {
        let level_up = self
            .gamification
            .add_xp(user_id, 5, "photo_upload")
            .await?;

        if let Some(_event) = &level_up {
            // Otorgar logro si es la primera foto, etc.
            let _ = self
                .gamification
                .award_achievement(user_id, "photographer")
                .await;
        }

        Ok(level_up)
    }

    /// Hook: Usuario completa perfil (+20 XP)
    pub async fn on_profile_completion(
        &self,
        user_id: Uuid,
    ) -> Result<Option<LevelUpEvent>, Box<dyn std::error::Error>> {
        self.gamification
            .add_xp(user_id, 20, "profile_completion")
            .await
            .map_err(|e| Box::new(e) as Box<dyn std::error::Error>)
    }

    /// Hook: Usuario hace referral (+50 XP)
    pub async fn on_referral_success(
        &self,
        user_id: Uuid,
    ) -> Result<Option<LevelUpEvent>, Box<dyn std::error::Error>> {
        self.gamification
            .add_xp(user_id, 50, "referral_success")
            .await
            .map_err(|e| Box::new(e) as Box<dyn std::error::Error>)
    }
}
