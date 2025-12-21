/// Configuración completa del sistema de gamificación
/// Incluye escaleras individuales, grupales y tabla de fragilidad

// ============ ESCALERA INDIVIDUAL ============
pub struct IndividualRankGoal {
    pub rank: &'static str,
    pub min_xp: i64,
    pub weekly_token_goal: f64,
    pub bonus_percentage: f64,      // % extra en pago
    pub reward_xp: i64,             // XP ganado al cumplir
    pub reward_description: &'static str,
}

pub const INDIVIDUAL_RANKS: &[IndividualRankGoal] = &[
    IndividualRankGoal {
        rank: "NOVICE",
        min_xp: 0,
        weekly_token_goal: 5_000.0,
        bonus_percentage: 0.0,
        reward_xp: 100,
        reward_description: "Habilita Adelantos",
    },
    IndividualRankGoal {
        rank: "RISING STAR",
        min_xp: 100,
        weekly_token_goal: 10_000.0,
        bonus_percentage: 0.0,
        reward_xp: 250,
        reward_description: "1 Tarjeta Inmunidad",
    },
    IndividualRankGoal {
        rank: "ELITE",
        min_xp: 350,
        weekly_token_goal: 20_000.0,
        bonus_percentage: 2.0,  // Paga al 62%
        reward_xp: 500,
        reward_description: "Bono +2%",
    },
    IndividualRankGoal {
        rank: "QUEEN",
        min_xp: 850,
        weekly_token_goal: 40_000.0,
        bonus_percentage: 5.0,  // Paga al 65%
        reward_xp: 1_000,
        reward_description: "Bono +5%",
    },
    IndividualRankGoal {
        rank: "GODDESS",
        min_xp: 1_850,
        weekly_token_goal: 80_000.0,
        bonus_percentage: 10.0, // Paga al 70%
        reward_xp: 2_500,
        reward_description: "Bono +10%",
    },
];

// ============ ESCALERA GRUPAL ============
pub struct GroupRankGoal {
    pub level: i32,
    pub weekly_token_goal: f64,
    pub bonus_cash_cop: f64,
    pub reward_xp: i64,
    pub reward_description: &'static str,
}

pub const GROUP_RANKS: &[GroupRankGoal] = &[
    GroupRankGoal {
        level: 1,
        weekly_token_goal: 30_000.0,
        bonus_cash_cop: 100_000.0,
        reward_xp: 500,
        reward_description: "Bono Room: $100k COP",
    },
    GroupRankGoal {
        level: 2,
        weekly_token_goal: 60_000.0,
        bonus_cash_cop: 250_000.0,
        reward_xp: 1_000,
        reward_description: "Bono Room: $250k COP",
    },
    GroupRankGoal {
        level: 3,
        weekly_token_goal: 120_000.0,
        bonus_cash_cop: 600_000.0,
        reward_xp: 2_500,
        reward_description: "Bono Room: $600k COP",
    },
    GroupRankGoal {
        level: 4,
        weekly_token_goal: 250_000.0,
        bonus_cash_cop: 1_500_000.0,
        reward_xp: 5_000,
        reward_description: "Bono Room: $1.5M COP",
    },
    GroupRankGoal {
        level: 5,
        weekly_token_goal: 500_000.0,
        bonus_cash_cop: 4_000_000.0,
        reward_xp: 10_000,
        reward_description: "OLIMPO: Bono Room: $4M COP",
    },
];

// ============ TABLA DE FRAGILIDAD (XP BURN) ============
pub struct FragilityRule {
    pub reason: &'static str,
    pub xp_burn_percentage: f64,
    pub description: &'static str,
}

pub const FRAGILITY_RULES: &[FragilityRule] = &[
    FragilityRule {
        reason: "STRIKE_1",
        xp_burn_percentage: 10.0,
        description: "Perdiste 10% XP por llegar tarde (Strike 1)",
    },
    FragilityRule {
        reason: "STRIKE_2",
        xp_burn_percentage: 30.0,
        description: "Perdiste 30% XP por reincidencia (Strike 2)",
    },
    FragilityRule {
        reason: "STRIKE_3",
        xp_burn_percentage: 100.0,
        description: "¡RESETEO! Perdiste 100% XP (Strike 3)",
    },
    FragilityRule {
        reason: "DIRTY_ROOM",
        xp_burn_percentage: 20.0,
        description: "Perdiste 20% XP por room sucio",
    },
    FragilityRule {
        reason: "LOW_PRODUCTION",
        xp_burn_percentage: 5.0,
        description: "Perdiste 5% XP por baja producción (<1500 tokens)",
    },
];

// ============ HELPER FUNCTIONS ============

/// Obtiene el rango individual actual según XP
pub fn get_individual_rank_by_xp(xp: i64) -> &'static IndividualRankGoal {
    INDIVIDUAL_RANKS
        .iter()
        .rev()
        .find(|r| xp >= r.min_xp)
        .unwrap_or(&INDIVIDUAL_RANKS[0])
}

/// Obtiene la regla de fragilidad
pub fn get_fragility_rule(reason: &str) -> Option<&'static FragilityRule> {
    FRAGILITY_RULES.iter().find(|r| r.reason == reason)
}

/// Calcula la pérdida de XP
pub fn calculate_xp_loss(current_xp: i64, percentage: f64) -> i64 {
    ((current_xp as f64) * (percentage / 100.0)) as i64
}
