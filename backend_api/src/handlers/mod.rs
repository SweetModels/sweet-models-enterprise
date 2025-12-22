pub mod auth;
pub mod admin;
pub mod kyc;
pub mod attendance;
pub mod market;

// Re-export AppState for all handlers to use
pub use crate::state::AppState;
