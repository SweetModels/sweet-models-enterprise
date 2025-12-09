use jsonwebtoken::{encode, decode, Header, Algorithm, Validation, EncodingKey, DecodingKey};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,      // Subject (user_id)
    pub exp: u64,         // Expiration time
    pub iat: u64,         // Issued at
    pub user_id: Uuid,    // User UUID
    pub auth_type: String, // "zk" | "web3" | "traditional"
}

impl Claims {
    pub fn new(user_id: Uuid, auth_type: &str, expires_in_seconds: u64) -> Self {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
        
        Self {
            sub: user_id.to_string(),
            exp: now + expires_in_seconds,
            iat: now,
            user_id,
            auth_type: auth_type.to_string(),
        }
    }
}

/// Generate JWT token using HS256 (symmetric key from env)
pub fn generate_token(user_id: Uuid, auth_type: &str) -> Result<String, jsonwebtoken::errors::Error> {
    let secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "dev_secret_key_change_in_production".to_string());
    
    // Token expires in 24 hours
    let claims = Claims::new(user_id, auth_type, 86400);
    
    encode(
        &Header::new(Algorithm::HS256),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
}

/// Validate and decode JWT token
pub fn validate_token(token: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "dev_secret_key_change_in_production".to_string());
    
    let validation = Validation::new(Algorithm::HS256);
    
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &validation,
    )
    .map(|data| data.claims)
}

/// Extract token from Authorization header
pub fn extract_bearer_token(auth_header: &str) -> Option<&str> {
    auth_header.strip_prefix("Bearer ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_and_validate_token() {
        std::env::set_var("JWT_SECRET", "test_secret_key_12345");
        
        let user_id = Uuid::new_v4();
        let token = generate_token(user_id, "zk").unwrap();
        
        assert!(!token.is_empty());
        
        let claims = validate_token(&token).unwrap();
        assert_eq!(claims.user_id, user_id);
        assert_eq!(claims.auth_type, "zk");
    }

    #[test]
    fn test_extract_bearer_token() {
        let header = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
        let token = extract_bearer_token(header).unwrap();
        assert_eq!(token, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...");
    }

    #[test]
    fn test_invalid_token() {
        std::env::set_var("JWT_SECRET", "test_secret_key_12345");
        
        let result = validate_token("invalid_token");
        assert!(result.is_err());
    }
}
