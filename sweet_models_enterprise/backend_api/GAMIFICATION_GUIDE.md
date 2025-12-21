# Sistema de Gamificación - Guía de Integración

## 📋 Base de Datos

### Ejecutar migración
```bash
cd backend_api
sqlx migrate run --database-url "postgresql://user:pass@localhost:5432/sweet_models"
```

Las tablas creadas:
- `user_levels`: Nivel, XP, rango actual, logros
- `xp_history`: Auditoría de ganancias de XP
- `rank_thresholds`: Configuración de umbrales (1000 XP = RISING_STAR, etc.)

## 🚀 Integración en main.rs

En tu función `main()` o router setup, agregar los endpoints:

```rust
use backend_api::gamification::handlers;

// En tu router setup:
let app = Router::new()
    // ... otros endpoints ...
    .route("/gamification/users/:user_id/level", get(handlers::get_user_level))
    .route("/gamification/leaderboard", get(handlers::get_leaderboard))
    .route("/gamification/users/:user_id/award/:achievement", post(handlers::award_achievement))
    .with_state(app_state);
```

## 💰 Integración con Finance

En el módulo `finance/`, después de confirmar un pago:

```rust
use crate::gamification::GamificationHooks;
use crate::gamification::finance_integration::process_payment_with_gamification;

let gamification_hooks = GamificationHooks::new(GamificationEngine::new(pool.clone()));

// Después de procesar el pago
process_payment_with_gamification(&gamification_hooks, user_id, amount_usdt).await?;
```

## 📸 Integración con Social

En el módulo `social/`, después de subir una foto:

```rust
use crate::gamification::GamificationHooks;
use crate::gamification::social_integration::process_photo_upload_with_gamification;

let gamification_hooks = GamificationHooks::new(GamificationEngine::new(pool.clone()));

// Después de confirmar upload a S3
process_photo_upload_with_gamification(&gamification_hooks, user_id, &photo_url).await?;
```

## 🎯 Rangos y Umbrales

| Rango | XP Requerido | Reward (USDT) |
|-------|-------------|---------------|
| NOVICE | 0 | — |
| RISING_STAR | 1,000 | 50 |
| ELITE | 5,000 | 150 |
| QUEEN | 15,000 | 500 |
| GODDESS | 50,000+ | 2,000 |

## 📊 Fuentes de XP

- **Finance**: +10 XP por cada 1 USDT ganado
- **Social**: +5 XP por foto subida
- **Profile**: +20 XP por completar perfil
- **Referral**: +50 XP por referral exitoso

## 🔗 API Endpoints

### GET /gamification/users/{user_id}/level
Obtener datos de nivel del usuario:
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "xp": 5500,
  "current_rank": "ELITE",
  "achievements": ["photographer", "early_adopter"]
}
```

### GET /gamification/leaderboard
Obtener top 10 usuarios por XP (array de UserLevelResponse).

### POST /gamification/users/{user_id}/award/{achievement}
Otorgar logro (admin only):
```json
{
  "achievement": "speedster"
}
```

## 🧪 Testing

```bash
cd backend_api
cargo test --lib gamification
```

## 📝 Ejemplos de Eventos

Cuando un usuario sube de rango, se genera un evento `LevelUpEvent`:

```rust
LevelUpEvent {
    user_id: Uuid,
    old_rank: UserRank::Elite,
    new_rank: UserRank::Queen,
    total_xp: 15500,
    reward: Some("500".to_string()),
}
```

Usar este evento para:
1. Enviar notificación push (FCM)
2. Actualizar chat con mención especial
3. Otorgar reward automático en billetera
4. Registrar en analytics

## 🐛 Debugging

```rust
// Ver información de debug
let level = gamification.get_user_level(user_id).await?;
println!("User level: {:?}", level);

// Ver histórico de XP
SELECT * FROM xp_history WHERE user_id = 'xxx' ORDER BY created_at DESC;
```

## ⚠️ Consideraciones

- El sistema es **idempotente**: llamar `add_xp` varias veces con la misma `reason` creará múltiples registros en `xp_history`.
- Para evitar duplicados, usa razones únicas como `"finance_earnings_transaction_id"`.
- Los rewards se recomiendan manejarse en el endpoint de billetera, no automáticamente.
