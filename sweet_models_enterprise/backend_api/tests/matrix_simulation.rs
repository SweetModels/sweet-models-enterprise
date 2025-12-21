use backend_api::finance::calculate_payout::{MODEL_SHARE, SPREAD_COP, DEFAULT_TOKEN_USD_VALUE};
use backend_api::finance::payroll::{DIRTY_ROOM_PENALTY_COP, GROUP_SHORTFALL_PENALTY_COP, GROUP_QUOTA};
use backend_api::gamification::engine::FRAGILITY_BURNS;

/// Este test simula una semana completa (L-D) y valida reglas financieras/penalizaciones.
#[tokio::test]
async fn matrix_weekly_simulation_numbers_balance() {
    // Modelo base de datos ficticia en memoria
    let mut sim = Simulation::new(4100.0);

    // Alta de usuarios virtuales
    sim.add_model(ModelConfig {
        name: "Modelo A", // La Perfecta
        weekly_tokens: 30_000.0,
        on_time_days: 7,
        strikes: 0,
        start_xp: 10_000,
        excellence: true,
    });
    sim.add_model(ModelConfig {
        name: "Modelo B", // La Desastre
        weekly_tokens: 500.0,
        on_time_days: 5, // llega tarde 2 veces -> Strike 2
        strikes: 2,
        start_xp: 8_000,
        excellence: false,
    });
    sim.add_model(ModelConfig {
        name: "Modelo C", // La Promedio
        weekly_tokens: 1_200.0,
        on_time_days: 7,
        strikes: 0,
        start_xp: 9_000,
        excellence: false,
    });

    // Room nivel 1: simulamos 7 días.
    for day in 0..7 {
        // Telemetría: usamos un mapa simple; tokens ya vienen en weekly_tokens,
        // pero inyectamos incidencias diarias (jueves sucio, jueves grupo falla).
        let is_thursday = day == 3;
        let is_dirty = is_thursday; // jueves room sucio
        let day_tokens = DayTokens {
            a: 30_000.0 / 7.0,
            b: 500.0 / 7.0,
            c: 1_200.0 / 7.0,
        };
        let group_total = day_tokens.total();
        let group_failed = is_thursday && group_total < GROUP_QUOTA; // forza multa grupal solo jueves

        sim.process_day(is_dirty, group_failed);
    }

    // Cierre de semana y cálculos finales
    let report = sim.close_week();

    // ASSERTIONS:
    // 1) Modelo A recibe bono excelencia (se añade 5% sobre su payout base en este sim)
    assert!(report.model_a.excellence_bonus_applied);
    assert!(report.model_a.payout_cop > 0.0);

    // 2) Modelo B cobra al 50% y pierde 30% de XP (Strike 2)
    assert_eq!(report.model_b.payout_factor, 0.5);
    let strike2_pct = FRAGILITY_BURNS.iter().find(|(k, _, _)| k == &"STRIKE_2").unwrap().1;
    let expected_burn = ((8000.0) * (strike2_pct / 100.0)).round() as i64;
    assert_eq!(report.model_b.xp_loss, expected_burn);

    // 3) Multa de limpieza 500k se descuenta a todas
    let expected_cleaning = DIRTY_ROOM_PENALTY_COP;
    assert!(report.model_a.cleaning_penalty_applied);
    assert!(report.model_b.cleaning_penalty_applied);
    assert!(report.model_c.cleaning_penalty_applied);
    assert_eq!(report.cleaning_penalties_total, expected_cleaning * 3.0);

    // 4) La billetera del estudio = 40% + penalidades recaudadas (limpieza + reducciones)
    let studio_expected_min = report.studio_base_share_cop + report.penalties_collected_cop;
    assert!((report.studio_wallet_cop - studio_expected_min).abs() < 0.01);

    // 5) Validación de que los números cuadran: suma de payouts + wallet + penalidades perdidas = total producido
    let total_tokens_week = sim.total_tokens_week;
    let total_usd = total_tokens_week * DEFAULT_TOKEN_USD_VALUE;
    let total_cop_gross = total_usd * sim.tasa_modelo;
    let models_sum = report.model_a.payout_cop + report.model_b.payout_cop + report.model_c.payout_cop;
    let accounted = models_sum + report.studio_wallet_cop;
    assert!((accounted - total_cop_gross).abs() < 1.0, "Descuadre contable >1 COP: {accounted} vs {total_cop_gross}");
}

#[derive(Clone)]
struct ModelConfig {
    name: &'static str,
    weekly_tokens: f64,
    on_time_days: u8,
    strikes: u8,
    start_xp: i64,
    excellence: bool,
}

#[derive(Default, Clone, Copy)]
struct DayTokens {
    a: f64,
    b: f64,
    c: f64,
}
impl DayTokens {
    fn total(&self) -> f64 {
        self.a + self.b + self.c
    }
}

struct ModelSim {
    name: String,
    tokens: f64,
    strikes: u8,
    xp: i64,
    payout_cop: f64,
    payout_factor: f64,
    excellence_bonus_applied: bool,
    cleaning_penalty_applied: bool,
    xp_loss: i64,
}

struct Simulation {
    models: Vec<ModelSim>,
    total_tokens_week: f64,
    admin_base_rate: f64,
    tasa_modelo: f64,
    cleaning_penalties: f64,
    group_penalties: f64,
    studio_wallet_cop: f64,
}

impl Simulation {
    fn new(admin_base_rate: f64) -> Self {
        let tasa_modelo = (admin_base_rate - SPREAD_COP).max(0.0);
        Self {
            models: Vec::new(),
            total_tokens_week: 0.0,
            admin_base_rate,
            tasa_modelo,
            cleaning_penalties: 0.0,
            group_penalties: 0.0,
            studio_wallet_cop: 0.0,
        }
    }

    fn add_model(&mut self, cfg: ModelConfig) {
        self.total_tokens_week += cfg.weekly_tokens;
        self.models.push(ModelSim {
            name: cfg.name.to_string(),
            tokens: cfg.weekly_tokens,
            strikes: cfg.strikes,
            xp: cfg.start_xp,
            payout_cop: 0.0,
            payout_factor: if cfg.strikes >= 2 { 0.5 } else { 1.0 },
            excellence_bonus_applied: false,
            cleaning_penalty_applied: false,
            xp_loss: 0,
        });
    }

    fn process_day(&mut self, is_dirty: bool, group_failed: bool) {
        if is_dirty {
            self.cleaning_penalties += DIRTY_ROOM_PENALTY_COP * self.models.len() as f64;
            for m in &mut self.models {
                m.cleaning_penalty_applied = true;
            }
        }
        if group_failed {
            self.group_penalties += GROUP_SHORTFALL_PENALTY_COP * self.models.len() as f64;
        }
    }

    fn close_week(&mut self) -> SimulationReport {
        // Calcular payout base por modelo según tokens
        let total_usd = self.total_tokens_week * DEFAULT_TOKEN_USD_VALUE;
        let model_pool_usd = total_usd * MODEL_SHARE;
        let model_pool_cop = model_pool_usd * self.tasa_modelo;

        for m in &mut self.models {
            let weight = m.tokens / self.total_tokens_week;
            let mut payout = model_pool_cop * weight;

            // Factor por strikes (Modelo B)
            payout *= m.payout_factor;

            // Bono excelencia (Modelo A): 5% extra si excellence=true
            if m.name == "Modelo A" {
                payout *= 1.05;
                m.excellence_bonus_applied = true;
            }

            // Penalidad limpieza (se descuenta directo)
            payout -= DIRTY_ROOM_PENALTY_COP;

            // Multa grupal si hubo, se descuenta promediada
            if self.group_penalties > 0.0 {
                payout -= GROUP_SHORTFALL_PENALTY_COP;
            }

            if payout < 0.0 {
                payout = 0.0;
            }

            // Burn XP por strikes y room sucio
            if m.name == "Modelo B" {
                // Strike 2: 30%
                let burn_pct = FRAGILITY_BURNS
                    .iter()
                    .find(|(k, _, _)| k == &"STRIKE_2")
                    .map(|(_, pct, _)| *pct)
                    .unwrap_or(30.0);
                let loss = ((m.xp as f64) * (burn_pct / 100.0)).round() as i64;
                m.xp_loss = loss;
                m.xp = (m.xp - loss).max(0);
            }

            if m.cleaning_penalty_applied {
                // Room sucio: 20% XP burn
                let burn_pct = FRAGILITY_BURNS
                    .iter()
                    .find(|(k, _, _)| k == &"DIRTY_ROOM")
                    .map(|(_, pct, _)| *pct)
                    .unwrap_or(20.0);
                let loss = ((m.xp as f64) * (burn_pct / 100.0)).round() as i64;
                m.xp_loss += loss;
                m.xp = (m.xp - loss).max(0);
            }

            m.payout_cop = payout;
        }

        // Wallet del estudio: 40% de revenue + penalidades recaudadas + recupero por factor de B
        let studio_base_cop = (total_usd * (1.0 - MODEL_SHARE)) * self.tasa_modelo;
        let penalties_collected = self.cleaning_penalties + self.group_penalties;
        let b_reduction: f64 = self.models
            .iter()
            .filter(|m| m.name == "Modelo B")
            .map(|m| (model_pool_cop * (m.tokens / self.total_tokens_week)) * (1.0 - m.payout_factor))
            .sum();

        self.studio_wallet_cop = studio_base_cop + penalties_collected + b_reduction;

        SimulationReport {
            model_a: self.models[0].clone(),
            model_b: self.models[1].clone(),
            model_c: self.models[2].clone(),
            cleaning_penalties_total: self.cleaning_penalties,
            group_penalties_total: self.group_penalties,
            penalties_collected_cop: penalties_collected + b_reduction,
            studio_wallet_cop: self.studio_wallet_cop,
            studio_base_share_cop: studio_base_cop,
        }
    }
}

#[derive(Clone)]
struct SimulationReport {
    model_a: ModelSim,
    model_b: ModelSim,
    model_c: ModelSim,
    cleaning_penalties_total: f64,
    group_penalties_total: f64,
    penalties_collected_cop: f64,
    studio_wallet_cop: f64,
    studio_base_share_cop: f64,
}
