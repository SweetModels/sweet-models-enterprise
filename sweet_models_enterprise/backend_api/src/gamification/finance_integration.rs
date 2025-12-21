// Ejemplo de integración de gamificación con finance
// Este código muestra cómo llamar los hooks cuando un usuario gana dinero.

use crate::gamification::GamificationHooks;
use uuid::Uuid;

/// Función auxiliar para procesar pagos con gamificación
/// Llámala después de confirmar una transacción USDT
pub async fn process_payment_with_gamification(
    gamification_hooks: &GamificationHooks,
    user_id: Uuid,
    amount_usdt: f64,
) -> Result<(), Box<dyn std::error::Error>> {
    // Lógica de pago (ya existente en finance/)
    // ...

    // Trigger: +10 XP por cada USDT ganado
    match gamification_hooks.on_user_earnings(user_id, amount_usdt).await {
        Ok(Some(level_up)) => {
            tracing::info!(
                "[GAMIFICATION] User {} leveled up to {:?}!",
                user_id,
                level_up.new_rank
            );
            // TODO: Enviar notificación push, actualizar chat, etc.
        }
        Ok(None) => {
            tracing::debug!("[GAMIFICATION] User {} gained XP but no level up", user_id);
        }
        Err(e) => {
            tracing::error!("[GAMIFICATION] Error awarding XP: {}", e);
            // No fallar el pago si la gamificación falla
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_xp_calculation() {
        assert_eq!((100.0 * 10.0) as i64, 1000); // 100 USDT = 1000 XP
    }
}
