use serde::{Deserialize, Serialize};

/// Spread fijo para cubrir riesgo y costos operativos (COP por USD)
pub const SPREAD_COP: f64 = 300.0;
/// Participación del modelo sobre los ingresos
pub const MODEL_SHARE: f64 = 0.60;
/// Valor del token en USD (configurable si el caller provee override)
pub const DEFAULT_TOKEN_USD_VALUE: f64 = 0.05;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum PaymentMethod {
    Nequi,
    Bancolombia,
    Daviplata,
    Efectivo,
    Usdt,
}

impl PaymentMethod {
    pub fn prefers_usdt(&self) -> bool {
        matches!(self, PaymentMethod::Usdt)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PayoutInput {
    pub total_tokens_week: f64,
    pub admin_base_rate: f64,
    #[serde(default)]
    pub token_usd_value: Option<f64>,
    pub payment_method: PaymentMethod,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PayoutResult {
    pub total_usd: f64,
    pub tasa_modelo: f64,
    pub payout_cop: Option<f64>,
    pub payout_usdt: Option<f64>,
    pub model_share: f64,
}

/// Calcula el pago semanal en COP o USDT según la preferencia del modelo.
/// Fórmula: pago_cop = (total_usd * MODEL_SHARE) * tasa_modelo
pub fn calculate_payout(input: PayoutInput) -> PayoutResult {
    let token_usd_value = input.token_usd_value.unwrap_or(DEFAULT_TOKEN_USD_VALUE);
    let tasa_modelo = (input.admin_base_rate - SPREAD_COP).max(0.0);
    let total_usd = input.total_tokens_week.max(0.0) * token_usd_value;
    let share_usd = total_usd * MODEL_SHARE;

    if input.payment_method.prefers_usdt() {
        PayoutResult {
            total_usd,
            tasa_modelo,
            payout_cop: None,
            payout_usdt: Some(share_usd),
            model_share: MODEL_SHARE,
        }
    } else {
        PayoutResult {
            total_usd,
            tasa_modelo,
            payout_cop: Some(share_usd * tasa_modelo),
            payout_usdt: None,
            model_share: MODEL_SHARE,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn calculates_cop_payout() {
        let input = PayoutInput {
            total_tokens_week: 1000.0,
            admin_base_rate: 4100.0,
            token_usd_value: Some(0.05),
            payment_method: PaymentMethod::Nequi,
        };

        let result = calculate_payout(input);
        assert_eq!(result.tasa_modelo, 3800.0);
        assert!(result.payout_cop.is_some());
        assert!((result.payout_cop.unwrap() - 114000.0).abs() < 0.1);
    }

    #[test]
    fn calculates_usdt_payout_when_crypto() {
        let input = PayoutInput {
            total_tokens_week: 500.0,
            admin_base_rate: 4000.0,
            token_usd_value: None,
            payment_method: PaymentMethod::Usdt,
        };

        let result = calculate_payout(input);
        assert!(result.payout_usdt.is_some());
        assert!(result.payout_cop.is_none());
        assert!((result.payout_usdt.unwrap() - (500.0 * DEFAULT_TOKEN_USD_VALUE * MODEL_SHARE)).abs() < 0.0001);
    }
}
