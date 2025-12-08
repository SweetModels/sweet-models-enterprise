// ============================================================================
// Sweet Models Enterprise - Web3 Authentication Module
// Sign-In with Ethereum/Solana - Descentralized Authentication
// ============================================================================

use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use deadpool_redis::{redis::AsyncCommands, Pool as RedisPool};
use ethers_core::{
    types::{Address, Signature},
    utils::hash_message,
};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use std::str::FromStr;
use thiserror::Error;
use uuid::Uuid;

use crate::state::AppState;

// ============================================================================
// ERROR TYPES
// ============================================================================

#[derive(Debug, Error)]
pub enum Web3AuthError {
    #[error("Invalid wallet address format")]
    InvalidAddress,
    
    #[error("Nonce not found or expired")]
    NonceNotFound,
    
    #[error("Invalid signature")]
    InvalidSignature,
    
    #[error("Redis connection error: {0}")]
    RedisError(#[from] deadpool_redis::redis::RedisError),
    
    #[error("Redis pool error: {0}")]
    RedisPoolError(#[from] deadpool_redis::PoolError),
    
    #[error("Database error: {0}")]
    DatabaseError(#[from] sqlx::Error),
    
    #[error("JWT generation error: {0}")]
    JwtError(String),
    
    #[error("Unsupported blockchain: {0}")]
    UnsupportedBlockchain(String),
}

impl axum::response::IntoResponse for Web3AuthError {
    fn into_response(self) -> axum::response::Response {
        let (status, message) = match self {
            Web3AuthError::InvalidAddress => (StatusCode::BAD_REQUEST, self.to_string()),
            Web3AuthError::NonceNotFound => (StatusCode::UNAUTHORIZED, self.to_string()),
            Web3AuthError::InvalidSignature => (StatusCode::UNAUTHORIZED, self.to_string()),
            Web3AuthError::UnsupportedBlockchain(_) => (StatusCode::BAD_REQUEST, self.to_string()),
            _ => (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error".to_string()),
        };
        
        let body = Json(serde_json::json!({
            "error": message,
            "status": status.as_u16(),
        }));
        
        (status, body).into_response()
    }
}

// ============================================================================
// DATA STRUCTURES
// ============================================================================

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum BlockchainType {
    Ethereum,
    Polygon,
    Solana,
    Binance,
}

impl FromStr for BlockchainType {
    type Err = Web3AuthError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "ethereum" | "eth" => Ok(BlockchainType::Ethereum),
            "polygon" | "matic" => Ok(BlockchainType::Polygon),
            "solana" | "sol" => Ok(BlockchainType::Solana),
            "binance" | "bsc" | "bnb" => Ok(BlockchainType::Binance),
            _ => Err(Web3AuthError::UnsupportedBlockchain(s.to_string())),
        }
    }
}

#[derive(Debug, Serialize)]
pub struct NonceResponse {
    pub nonce: String,
    pub message: String,
    pub expires_in: u64,
}

#[derive(Debug, Deserialize)]
pub struct VerifySignatureRequest {
    pub wallet_address: String,
    pub signature: String,
    pub blockchain: BlockchainType,
    #[serde(default)]
    pub chain_id: Option<u64>,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub user_id: Uuid,
    pub wallet_address: String,
    pub is_new_user: bool,
}

#[derive(Debug, sqlx::FromRow)]
struct UserRecord {
    id: Uuid,
    wallet_address: String,
    blockchain_type: String,
}

// ============================================================================
// CONSTANTS
// ============================================================================

const NONCE_EXPIRATION_SECONDS: u64 = 300; // 5 minutes
const NONCE_PREFIX: &str = "web3_nonce:";
const MESSAGE_TEMPLATE: &str = "Sign this message to authenticate with Sweet Models Enterprise.\n\nNonce: {}\nTimestamp: {}";

// ============================================================================
// PUBLIC FUNCTIONS - ENDPOINTS
// ============================================================================

/// Generate authentication nonce for wallet
/// 
/// Endpoint: GET /auth/web3/nonce/{wallet_address}
pub async fn generate_nonce(
    State(state): State<AppState>,
    Path(wallet_address): Path<String>,
) -> Result<Json<NonceResponse>, Web3AuthError> {
    // Validate wallet address format
    validate_wallet_address(&wallet_address)?;
    
    // Generate cryptographically secure nonce
    let nonce = generate_secure_nonce();
    let timestamp = chrono::Utc::now().timestamp();
    
    // Create message to sign
    let message = MESSAGE_TEMPLATE
        .replace("{}", &nonce)
        .replace("{}", &timestamp.to_string());
    
    // Store nonce in Redis with expiration
    let redis_key = format!("{}{}", NONCE_PREFIX, wallet_address.to_lowercase());
    let mut conn = state.redis
        .get()
        .await?;
    
    conn.set_ex(
        redis_key,
        nonce.clone(),
        NONCE_EXPIRATION_SECONDS as u64,
    )
    .await?;
    
    tracing::info!("Generated nonce for wallet: {}", wallet_address);
    
    Ok(Json(NonceResponse {
        nonce,
        message,
        expires_in: NONCE_EXPIRATION_SECONDS,
    }))
}

/// Verify wallet signature and authenticate user
/// 
/// Endpoint: POST /auth/web3/verify
pub async fn verify_signature(
    State(state): State<AppState>,
    Json(payload): Json<VerifySignatureRequest>,
) -> Result<Json<AuthResponse>, Web3AuthError> {
    let wallet_address = payload.wallet_address.to_lowercase();
    
    // Validate wallet address
    validate_wallet_address(&wallet_address)?;
    
    // Retrieve nonce from Redis
    let redis_key = format!("{}{}", NONCE_PREFIX, wallet_address);
    let mut conn = state.redis
        .get()
        .await?;
    
    let nonce: Option<String> = conn.get(&redis_key).await?;
    let nonce = nonce.ok_or(Web3AuthError::NonceNotFound)?;
    
    // Verify signature based on blockchain type
    let is_valid = match payload.blockchain {
        BlockchainType::Ethereum | BlockchainType::Polygon | BlockchainType::Binance => {
            verify_evm_signature(&wallet_address, &payload.signature, &nonce)?
        }
        BlockchainType::Solana => {
            verify_solana_signature(&wallet_address, &payload.signature, &nonce)?
        }
    };
    
    if !is_valid {
        tracing::warn!("Invalid signature for wallet: {}", wallet_address);
        return Err(Web3AuthError::InvalidSignature);
    }
    
    // Delete used nonce (prevent replay attacks)
    let _: () = conn.del(&redis_key).await?;
    
    // Get or create user
    let (user_id, is_new_user) = get_or_create_user(
        &state.db,
        &wallet_address,
        &payload.blockchain,
    ).await?;
    
    // Generate JWT tokens
    let (access_token, refresh_token) = generate_jwt_tokens(
        user_id,
        &wallet_address,
        &payload.blockchain,
    )?;
    
    tracing::info!(
        "Authenticated wallet: {} (user_id: {}, new: {})",
        wallet_address,
        user_id,
        is_new_user
    );
    
    Ok(Json(AuthResponse {
        access_token,
        refresh_token,
        user_id,
        wallet_address,
        is_new_user,
    }))
}

/// Refresh access token
/// 
/// Endpoint: POST /auth/web3/refresh
pub async fn refresh_token(
    State(state): State<AppState>,
    Json(payload): Json<serde_json::Value>,
) -> Result<Json<serde_json::Value>, Web3AuthError> {
    let refresh_token = payload["refresh_token"]
        .as_str()
        .ok_or_else(|| Web3AuthError::JwtError("Missing refresh_token".to_string()))?;
    
    // Verify and decode refresh token
    let claims = verify_jwt_token(refresh_token)?;
    
    // Generate new access token
    let user_id = Uuid::parse_str(&claims["sub"].as_str().unwrap())
        .map_err(|e| Web3AuthError::JwtError(e.to_string()))?;
    
    let wallet = claims["wallet"].as_str().unwrap();
    let blockchain: BlockchainType = serde_json::from_value(claims["blockchain"].clone())
        .map_err(|e| Web3AuthError::JwtError(e.to_string()))?;
    
    let (new_access_token, new_refresh_token) = generate_jwt_tokens(
        user_id,
        wallet,
        &blockchain,
    )?;
    
    Ok(Json(serde_json::json!({
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
    })))
}

/// Disconnect wallet (logout)
/// 
/// Endpoint: POST /auth/web3/disconnect
pub async fn disconnect_wallet(
    State(state): State<AppState>,
    Json(payload): Json<serde_json::Value>,
) -> Result<StatusCode, Web3AuthError> {
    let wallet_address = payload["wallet_address"]
        .as_str()
        .ok_or(Web3AuthError::InvalidAddress)?
        .to_lowercase();
    
    // Invalidate any pending nonces
    let redis_key = format!("{}{}", NONCE_PREFIX, wallet_address);
    let mut conn = state.redis
        .get()
        .await?;
    
    let _: () = conn.del(&redis_key).await?;
    
    tracing::info!("Disconnected wallet: {}", wallet_address);
    
    Ok(StatusCode::NO_CONTENT)
}

// ============================================================================
// PRIVATE HELPER FUNCTIONS
// ============================================================================

/// Validate wallet address format
fn validate_wallet_address(address: &str) -> Result<(), Web3AuthError> {
    // Basic validation
    if address.is_empty() {
        return Err(Web3AuthError::InvalidAddress);
    }
    
    // Ethereum-style addresses (0x + 40 hex chars)
    if address.starts_with("0x") {
        if address.len() != 42 {
            return Err(Web3AuthError::InvalidAddress);
        }
        // Validate hex
        if !address[2..].chars().all(|c| c.is_ascii_hexdigit()) {
            return Err(Web3AuthError::InvalidAddress);
        }
        return Ok(());
    }
    
    // Solana addresses (base58, 32-44 chars typically)
    if address.len() >= 32 && address.len() <= 44 {
        // Basic base58 check
        if address.chars().all(|c| {
            c.is_ascii_alphanumeric() && c != '0' && c != 'O' && c != 'I' && c != 'l'
        }) {
            return Ok(());
        }
    }
    
    Err(Web3AuthError::InvalidAddress)
}

/// Generate cryptographically secure nonce
fn generate_secure_nonce() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();
    let bytes: Vec<u8> = (0..32).map(|_| rng.gen()).collect();
    hex::encode(bytes)
}

/// Verify EVM-compatible signature (Ethereum, Polygon, BSC)
fn verify_evm_signature(
    wallet_address: &str,
    signature: &str,
    nonce: &str,
) -> Result<bool, Web3AuthError> {
    // Parse wallet address
    let address = Address::from_str(wallet_address)
        .map_err(|_| Web3AuthError::InvalidAddress)?;
    
    // Parse signature
    let sig = Signature::from_str(signature)
        .map_err(|_| Web3AuthError::InvalidSignature)?;
    
    // Reconstruct the message that was signed
    let timestamp = chrono::Utc::now().timestamp();
    let message = MESSAGE_TEMPLATE
        .replace("{}", nonce)
        .replace("{}", &timestamp.to_string());
    
    // Hash the message (Ethereum signed message format)
    let message_hash = hash_message(message);
    
    // Recover the signer address from signature
    let recovered = sig.recover(message_hash)
        .map_err(|_| Web3AuthError::InvalidSignature)?;
    
    // Compare recovered address with claimed address
    Ok(recovered == address)
}

/// Verify Solana signature
fn verify_solana_signature(
    wallet_address: &str,
    signature: &str,
    nonce: &str,
) -> Result<bool, Web3AuthError> {
    use ed25519_dalek::{VerifyingKey, Signature as Ed25519Signature, Verifier};
    
    // Decode base58 public key (Solana address)
    let pubkey_bytes = bs58::decode(wallet_address)
        .into_vec()
        .map_err(|_| Web3AuthError::InvalidAddress)?;
    
    if pubkey_bytes.len() != 32 {
        return Err(Web3AuthError::InvalidAddress);
    }
    
    // Convert to array
    let pubkey_array: [u8; 32] = pubkey_bytes.try_into()
        .map_err(|_| Web3AuthError::InvalidAddress)?;
    
    let public_key = VerifyingKey::from_bytes(&pubkey_array)
        .map_err(|_| Web3AuthError::InvalidAddress)?;
    
    // Decode signature
    let sig_bytes = bs58::decode(signature)
        .into_vec()
        .map_err(|_| Web3AuthError::InvalidSignature)?;
    
    if sig_bytes.len() != 64 {
        return Err(Web3AuthError::InvalidSignature);
    }
    
    // Convert Vec to array
    let sig_array: [u8; 64] = sig_bytes.try_into()
        .map_err(|_| Web3AuthError::InvalidSignature)?;
    
    let signature = Ed25519Signature::from_bytes(&sig_array);
    
    // Reconstruct message
    let timestamp = chrono::Utc::now().timestamp();
    let message = MESSAGE_TEMPLATE
        .replace("{}", nonce)
        .replace("{}", &timestamp.to_string());
    
    // Verify signature
    Ok(public_key.verify(message.as_bytes(), &signature).is_ok())
}

/// Get existing user or create new one
async fn get_or_create_user(
    db: &PgPool,
    wallet_address: &str,
    blockchain: &BlockchainType,
) -> Result<(Uuid, bool), Web3AuthError> {
    // Try to find existing user
    let existing: Option<UserRecord> = sqlx::query_as(
        "SELECT id, wallet_address, blockchain_type 
         FROM users 
         WHERE LOWER(wallet_address) = LOWER($1)"
    )
    .bind(wallet_address)
    .fetch_optional(db)
    .await?;
    
    if let Some(user) = existing {
        return Ok((user.id, false));
    }
    
    // Create new user
    let user_id = Uuid::new_v4();
    let blockchain_str = format!("{:?}", blockchain).to_lowercase();
    
    sqlx::query(
        "INSERT INTO users (id, wallet_address, blockchain_type, role, created_at)
         VALUES ($1, $2, $3, 'Model', NOW())"
    )
    .bind(user_id)
    .bind(wallet_address)
    .bind(&blockchain_str)
    .execute(db)
    .await?;
    
    tracing::info!("Created new Web3 user: {} ({})", wallet_address, blockchain_str);
    
    Ok((user_id, true))
}

/// Generate JWT access and refresh tokens
fn generate_jwt_tokens(
    user_id: Uuid,
    wallet_address: &str,
    blockchain: &BlockchainType,
) -> Result<(String, String), Web3AuthError> {
    use jsonwebtoken::{encode, EncodingKey, Header};
    use serde_json::json;
    
    let secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "your-secret-key-change-in-production".to_string());
    
    let now = chrono::Utc::now().timestamp() as usize;
    
    // Access token (24 hours)
    let access_claims = json!({
        "sub": user_id.to_string(),
        "wallet": wallet_address,
        "blockchain": blockchain,
        "iat": now,
        "exp": now + 86400, // 24 hours
    });
    
    let access_token = encode(
        &Header::default(),
        &access_claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| Web3AuthError::JwtError(e.to_string()))?;
    
    // Refresh token (30 days)
    let refresh_claims = json!({
        "sub": user_id.to_string(),
        "wallet": wallet_address,
        "blockchain": blockchain,
        "iat": now,
        "exp": now + 2592000, // 30 days
    });
    
    let refresh_token = encode(
        &Header::default(),
        &refresh_claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| Web3AuthError::JwtError(e.to_string()))?;
    
    Ok((access_token, refresh_token))
}

/// Verify JWT token
fn verify_jwt_token(token: &str) -> Result<serde_json::Value, Web3AuthError> {
    use jsonwebtoken::{decode, DecodingKey, Validation};
    
    let secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "your-secret-key-change-in-production".to_string());
    
    let token_data = decode::<serde_json::Value>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )
    .map_err(|e| Web3AuthError::JwtError(e.to_string()))?;
    
    Ok(token_data.claims)
}

// ============================================================================
// TESTS
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_ethereum_address() {
        assert!(validate_wallet_address("0x742d35Cc6634C0532925a3b844Bc454e4438f44e").is_ok());
        assert!(validate_wallet_address("0xinvalid").is_err());
        assert!(validate_wallet_address("not_an_address").is_err());
    }

    #[test]
    fn test_generate_nonce() {
        let nonce1 = generate_secure_nonce();
        let nonce2 = generate_secure_nonce();
        
        assert_eq!(nonce1.len(), 64); // 32 bytes = 64 hex chars
        assert_ne!(nonce1, nonce2); // Should be random
    }

    #[test]
    fn test_blockchain_type_parsing() {
        assert_eq!("ethereum".parse::<BlockchainType>().unwrap(), BlockchainType::Ethereum);
        assert_eq!("solana".parse::<BlockchainType>().unwrap(), BlockchainType::Solana);
        assert_eq!("polygon".parse::<BlockchainType>().unwrap(), BlockchainType::Polygon);
        assert!("invalid".parse::<BlockchainType>().is_err());
    }
}
