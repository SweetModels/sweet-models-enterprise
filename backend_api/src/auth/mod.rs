//! Authentication Module
//! Handles Web3 and traditional JWT authentication

pub mod web3;

// Re-export main functions
pub use web3::{
    generate_nonce,
    verify_signature,
    refresh_token,
    disconnect_wallet,
};
