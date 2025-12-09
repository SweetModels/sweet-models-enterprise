//! Authentication Module
//! Handles Web3 and traditional JWT authentication

pub mod web3;
pub mod zk;
pub mod jwt;

// Re-export main functions
pub use web3::{
    generate_nonce,
    verify_signature,
    refresh_token,
    disconnect_wallet,
    web3_routes,
};

pub use jwt::{generate_token, validate_token, extract_bearer_token, Claims};
