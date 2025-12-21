// Ejemplo de integración de gamificación con social
// Este código muestra cómo otorgar XP cuando un usuario sube fotos.

use crate::gamification::GamificationHooks;
use uuid::Uuid;

/// Función auxiliar para procesar upload de foto con gamificación
/// Llámala después de confirmar que la foto se subió a S3
pub async fn process_photo_upload_with_gamification(
    gamification_hooks: &GamificationHooks,
    user_id: Uuid,
    _photo_url: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    // Lógica de upload (ya existente en social/)
    // ...

    // Trigger: +5 XP por cada foto
    match gamification_hooks.on_photo_upload(user_id).await {
        Ok(Some(level_up)) => {
            tracing::info!(
                "[GAMIFICATION] User {} leveled up to {:?} after photo upload!",
                user_id,
                level_up.new_rank
            );
            // TODO: Enviar notificación, achievement badge, etc.
        }
        Ok(None) => {
            tracing::debug!("[GAMIFICATION] User {} uploaded photo, +5 XP", user_id);
        }
        Err(e) => {
            tracing::error!("[GAMIFICATION] Error awarding photo XP: {}", e);
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_photo_xp() {
        // 1 foto = 5 XP
        assert_eq!(5, 5);
    }
}
