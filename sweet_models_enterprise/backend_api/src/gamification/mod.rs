// Módulo principal de gamificación
pub mod engine;
pub mod handlers;
pub mod hooks;
pub mod finance_integration;
pub mod social_integration;
pub mod config;
pub mod store;

pub use engine::GamificationEngine;
pub use hooks::GamificationHooks;
pub use engine::{burn_xp, add_xp_reward};
pub use store::{get_catalog_handler, get_user_balance_handler, redeem_reward_handler, get_reward_catalog};
