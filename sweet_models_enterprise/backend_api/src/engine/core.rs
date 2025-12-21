use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Entrada de telemetría recibida desde el Room.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProductionInput {
    pub room_id: i32,
    pub room_name: Option<String>,
    /// Indica si el room fue marcado como sucio al cierre del turno
    pub room_dirty: bool,
    /// Producción bruta por página (tokens)
    pub pages: HashMap<String, f64>,
    /// Modelos activas en el turno
    pub members: Vec<MemberInput>,
    /// Tasa de conversión COP por token (precio Binance). Si es <= 0, se usa el parámetro por defecto.
    pub binance_rate_cop: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemberInput {
    pub model_id: i32,
    pub name: String,
    /// Número de strikes acumulados en el turno (0-3)
    pub strikes: u8,
    /// XP actual antes de aplicar ganancias y quemas
    pub current_xp: i64,
}

/// Resultado procesado del reporte
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProcessedReport {
    pub room_id: i32,
    pub room_name: Option<String>,
    pub gross_tokens: f64,
    pub studio_tokens: f64,
    pub group_pool_tokens: f64,
    pub studio_revenue_cop: f64,
    pub members: Vec<MemberPayout>,
    pub low_production_penalty: bool,
    pub room_dirty_penalty: bool,
    pub total_penalties_cop: f64,
}

/// Pago y ajustes por modelo
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemberPayout {
    pub model_id: i32,
    pub name: String,
    pub strikes_applied: u8,
    pub tokens_net: f64,
    pub money_cop: f64,
    pub xp_gained: i64,
    pub xp_burned: i64,
    pub xp_after_burn: i64,
    pub penalties_cop: f64,
    pub net_money_cop: f64,
}

#[derive(Debug, thiserror::Error)]
pub enum EngineError {
    #[error("invalid json: {0}")]
    InvalidJson(String),
    #[error("no members in report")]
    NoMembers,
    #[error("invalid binance rate")]
    InvalidRate,
}

/// Procesa el reporte de producción aplicando las reglas supremas.
///
/// - Split 40/60 (estudio / bolsa de grupo)
/// - XP 1:1 con tokens netos
/// - Penalización por baja producción (< 1500 tokens): multa $50,000 COP por modelo
/// - Penalización por room sucio: multa $500,000 COP por modelo
/// - Quemado de XP por strikes y room sucio (20% global si está sucio)
pub fn process_production_report(
    input_json: &str,
    default_binance_rate_cop: f64,
) -> Result<ProcessedReport, EngineError> {
    let input: ProductionInput = serde_json::from_str(input_json)
        .map_err(|e| EngineError::InvalidJson(e.to_string()))?;

    if input.members.is_empty() {
        return Err(EngineError::NoMembers);
    }

    let binance_rate = input
        .binance_rate_cop
        .unwrap_or(default_binance_rate_cop);

    if binance_rate <= 0.0 {
        return Err(EngineError::InvalidRate);
    }

    let gross_tokens: f64 = input.pages.values().copied().sum();
    let studio_tokens = gross_tokens * 0.40;
    let group_pool_tokens = gross_tokens * 0.60;
    let per_member_tokens = group_pool_tokens / input.members.len() as f64;

    // Penalizaciones monetarias
    let low_production_penalty = gross_tokens < 1500.0;
    let room_dirty_penalty = input.room_dirty;

    let mut members = Vec::with_capacity(input.members.len());
    let mut total_penalties_cop = 0.0_f64;

    for member in input.members.into_iter() {
        let tokens_net = per_member_tokens;
        let money_cop = tokens_net * (binance_rate - 300.0);
        let xp_gained = tokens_net.round() as i64; // relación 1:1

        let mut total_xp = member.current_xp + xp_gained;
        let mut xp_burned: i64 = 0;

        // Quemado por strikes
        let strike_rate = match member.strikes {
            1 => 0.10,
            2 => 0.30,
            3..=u8::MAX => 1.0,
            _ => 0.0,
        };
        if strike_rate > 0.0 {
            let burn = ((total_xp as f64) * strike_rate).round() as i64;
            xp_burned += burn;
            total_xp = (total_xp - burn).max(0);
        }

        // Quemado por room sucio (20%)
        if room_dirty_penalty && total_xp > 0 {
            let burn = ((total_xp as f64) * 0.20).round() as i64;
            xp_burned += burn;
            total_xp = (total_xp - burn).max(0);
        }

        // Multas monetarias
        let mut penalties_cop = 0.0;
        if low_production_penalty {
            penalties_cop += 50_000.0;
        }
        if room_dirty_penalty {
            penalties_cop += 500_000.0;
        }
        total_penalties_cop += penalties_cop;

        let net_money_cop = money_cop - penalties_cop;

        members.push(MemberPayout {
            model_id: member.model_id,
            name: member.name,
            strikes_applied: member.strikes,
            tokens_net,
            money_cop,
            xp_gained,
            xp_burned,
            xp_after_burn: total_xp,
            penalties_cop,
            net_money_cop,
        });
    }

    let studio_revenue_cop = studio_tokens * (binance_rate - 300.0);

    Ok(ProcessedReport {
        room_id: input.room_id,
        room_name: input.room_name,
        gross_tokens,
        studio_tokens,
        group_pool_tokens,
        studio_revenue_cop,
        members,
        low_production_penalty,
        room_dirty_penalty,
        total_penalties_cop,
    })
}
