use std::{str::FromStr, sync::Arc};

use axum::{routing::post, http::StatusCode, Json, Router};
use ethers_core::types::Address;
use rand::{distributions::Alphanumeric, thread_rng, Rng};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use k256::ecdsa::{RecoveryId, Signature as K256Signature, VerifyingKey};
use sha3::{Digest, Keccak256};

#[derive(Debug, Deserialize)]
pub struct Web3LoginRequest {
    pub wallet_address: String,
    pub signature: String,
    #[serde(default)]
    pub user_id: Option<Uuid>, // Optional: link to existing user
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub token: String,
    pub message: String,
}

#[derive(Debug, Serialize)]
pub struct NonceResponse {
    pub nonce: String,
}

use crate::state::AppState;

pub fn web3_routes() -> Router<Arc<AppState>> {
    Router::<Arc<AppState>>::new()
        .route("/nonce", post(generate_nonce))
        .route("/verify", post(verify_signature))
        .route("/refresh", post(refresh_token))
        .route("/disconnect", post(disconnect_wallet))
}

pub async fn generate_nonce() -> Json<NonceResponse> {
    let nonce: String = thread_rng()
        .sample_iter(&Alphanumeric)
        .take(32)
        .map(char::from)
        .collect();

    Json(NonceResponse { nonce })
}

pub async fn verify_signature(Json(payload): Json<Web3LoginRequest>) -> Result<Json<AuthResponse>, StatusCode> {
    let addr = payload.wallet_address.trim();
    if addr.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    // Validate EVM address format
    let expected_address = Address::from_str(addr)
        .map_err(|_| StatusCode::BAD_REQUEST)?;

    // Decode signature (hex format: 0x + 130 chars for 65 bytes)
    let sig_bytes = decode_signature(&payload.signature)
        .map_err(|_| StatusCode::BAD_REQUEST)?;
    
    if sig_bytes.len() != 65 {
        return Err(StatusCode::BAD_REQUEST);
    }

    // Extract r, s, v components (Ethereum signature format)
    let r = &sig_bytes[0..32];
    let s = &sig_bytes[32..64];
    let v = sig_bytes[64];

    // Reconstruct the signed message (Ethereum personal_sign format)
    let nonce_message = format!("Sign this nonce to authenticate: {}", payload.signature);
    let message_hash = eth_message_hash(nonce_message.as_bytes());

    // Parse signature
    let mut sig_data = [0u8; 64];
    sig_data[..32].copy_from_slice(r);
    sig_data[32..].copy_from_slice(s);
    
    let signature = K256Signature::from_bytes(&sig_data.into())
        .map_err(|_| StatusCode::BAD_REQUEST)?;

    // Recovery ID (v - 27 for legacy, or v for EIP-155)
    let recovery_id = if v >= 27 { v - 27 } else { v };
    let recovery_id = RecoveryId::try_from(recovery_id)
        .map_err(|_| StatusCode::BAD_REQUEST)?;

    // Recover public key from signature
    let recovered_key = VerifyingKey::recover_from_prehash(&message_hash, &signature, recovery_id)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    // Derive Ethereum address from public key
    let recovered_address = pubkey_to_address(&recovered_key);

    // Verify address matches
    if recovered_address != expected_address {
        tracing::warn!(
            "Address mismatch: expected {}, recovered {}",
            expected_address,
            recovered_address
        );
        return Err(StatusCode::UNAUTHORIZED);
    }

    // Signature verified! Generate or use existing user_id
    let user_id = payload.user_id.unwrap_or_else(Uuid::new_v4);
    
    let token = crate::auth::jwt::generate_token(user_id, "web3")
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let response = AuthResponse {
        token,
        message: "Web3 authentication successful".to_string(),
    };

    Ok(Json(response))
}

/// Decodes hex signature (with or without 0x prefix)
fn decode_signature(sig: &str) -> Result<Vec<u8>, hex::FromHexError> {
    let sig = sig.strip_prefix("0x").unwrap_or(sig);
    hex::decode(sig)
}

/// Creates Ethereum personal_sign message hash
/// Format: keccak256("\x19Ethereum Signed Message:\n" + len(message) + message)
fn eth_message_hash(message: &[u8]) -> [u8; 32] {
    let prefix = format!("\x19Ethereum Signed Message:\n{}", message.len());
    let mut hasher = Keccak256::new();
    hasher.update(prefix.as_bytes());
    hasher.update(message);
    hasher.finalize().into()
}

/// Derives Ethereum address from secp256k1 public key
/// Address = keccak256(pubkey)[12..32] (last 20 bytes)
fn pubkey_to_address(key: &VerifyingKey) -> Address {
    let pubkey_bytes = key.to_encoded_point(false); // Uncompressed format
    let pubkey_uncompressed = &pubkey_bytes.as_bytes()[1..]; // Skip 0x04 prefix
    
    let mut hasher = Keccak256::new();
    hasher.update(pubkey_uncompressed);
    let hash = hasher.finalize();
    
    // Take last 20 bytes as Ethereum address
    let mut addr_bytes = [0u8; 20];
    addr_bytes.copy_from_slice(&hash[12..]);
    
    Address::from(addr_bytes)
}

/// Simulated refresh endpoint
pub async fn refresh_token() -> Result<Json<AuthResponse>, StatusCode> {
    // TODO: Extract and validate existing token, issue new one
    let token = crate::auth::jwt::generate_token(Uuid::new_v4(), "web3")
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    let response = AuthResponse {
        token,
        message: "Token refreshed".to_string(),
    };
    Ok(Json(response))
}

/// Simulated disconnect endpoint
pub async fn disconnect_wallet() -> StatusCode {
    StatusCode::NO_CONTENT
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_decode_signature_with_prefix() {
        let sig = "0x1234abcd";
        let result = decode_signature(sig).unwrap();
        assert_eq!(result, vec![0x12, 0x34, 0xab, 0xcd]);
    }

    #[test]
    fn test_decode_signature_without_prefix() {
        let sig = "1234abcd";
        let result = decode_signature(sig).unwrap();
        assert_eq!(result, vec![0x12, 0x34, 0xab, 0xcd]);
    }

    #[test]
    fn test_eth_message_hash() {
        let message = b"Hello, Ethereum!";
        let hash = eth_message_hash(message);
        
        // Verify hash is 32 bytes
        assert_eq!(hash.len(), 32);
        
        // Hash should be deterministic
        let hash2 = eth_message_hash(message);
        assert_eq!(hash, hash2);
    }

    #[test]
    fn test_pubkey_to_address_format() {
        // Generate a test key
        use k256::ecdsa::SigningKey;
        let secret = SigningKey::random(&mut rand::thread_rng());
        let verifying_key = VerifyingKey::from(&secret);
        
        let address = pubkey_to_address(&verifying_key);
        
        // Ethereum addresses are 20 bytes (40 hex chars)
        let addr_str = format!("{:?}", address);
        assert!(addr_str.starts_with("0x"));
    }
}
