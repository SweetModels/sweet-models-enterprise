use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Obtiene la clave secreta JWT desde variable de entorno
/// Si no está definida, usa un valor por defecto para desarrollo
fn get_jwt_secret() -> Vec<u8> {
    std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| {
            tracing::warn!("⚠️  JWT_SECRET no configurado, usando valor por defecto (SOLO DESARROLLO)");
            "your-secret-key-change-in-production-minimum-32-chars-12345".to_string()
        })
        .into_bytes()
}

/// Duración de expiración del token (24 horas)
const JWT_EXPIRATION_HOURS: i64 = 24;

/// Claims (datos) almacenados en el JWT
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    /// Subject: ID del usuario
    pub sub: String,
    
    /// Email del usuario
    pub email: String,
    
    /// Rol del usuario (ADMIN, MODEL, MONITOR, etc.)
    pub role: String,
    
    /// Nombre completo del usuario
    pub name: Option<String>,
    
    /// Timestamp de expiración (Unix timestamp)
    pub exp: i64,
    
    /// Timestamp de emisión (Unix timestamp)
    pub iat: i64,
}

/// Error personalizado para operaciones JWT
#[derive(Debug)]
pub enum JwtError {
    TokenCreationFailed(String),
    TokenValidationFailed(String),
    TokenExpired,
    InvalidToken,
}

impl std::fmt::Display for JwtError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            JwtError::TokenCreationFailed(msg) => write!(f, "JWT creation failed: {}", msg),
            JwtError::TokenValidationFailed(msg) => write!(f, "JWT validation failed: {}", msg),
            JwtError::TokenExpired => write!(f, "JWT token has expired"),
            JwtError::InvalidToken => write!(f, "Invalid JWT token"),
        }
    }
}

impl std::error::Error for JwtError {}

/// Genera un nuevo JWT token
/// 
/// # Argumentos
/// * `user_id` - UUID del usuario
/// * `email` - Email del usuario
/// * `role` - Rol del usuario (ADMIN, MODEL, MONITOR)
/// * `name` - Nombre completo del usuario (opcional)
/// 
/// # Retorna
/// * `Ok(String)` - El token JWT firmado
/// * `Err(JwtError)` - Si la creación del token falla
/// 
/// # Ejemplo
/// ```rust
/// let token = generate_jwt(
///     Uuid::new_v4(),
///     "admin@sweetmodels.com",
///     "ADMIN",
///     Some("Isaias")
/// ).unwrap();
/// ```
pub fn generate_jwt(
    user_id: Uuid,
    email: &str,
    role: &str,
    name: Option<String>,
) -> Result<String, JwtError> {
    let now = Utc::now();
    let expiration = now + Duration::hours(JWT_EXPIRATION_HOURS);
    
    let claims = Claims {
        sub: user_id.to_string(),
        email: email.to_string(),
        role: role.to_string(),
        name,
        exp: expiration.timestamp(),
        iat: now.timestamp(),
    };
    
    let secret = get_jwt_secret();
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(&secret),
    )
    .map_err(|e| JwtError::TokenCreationFailed(e.to_string()))
}

/// Valida y decodifica un JWT token
/// 
/// # Argumentos
/// * `token` - El token JWT a validar
/// 
/// # Retorna
/// * `Ok(Claims)` - Los claims decodificados si el token es válido
/// * `Err(JwtError)` - Si el token es inválido o expiró
/// 
/// # Ejemplo
/// ```rust
/// match validate_jwt(&token) {
///     Ok(claims) => {
///         println!("User ID: {}", claims.sub);
///         println!("Role: {}", claims.role);
///     },
///     Err(JwtError::TokenExpired) => println!("Token expiró"),
///     Err(_) => println!("Token inválido"),
/// }
/// ```
pub fn validate_jwt(token: &str) -> Result<Claims, JwtError> {
    let validation = Validation::default();
    let secret = get_jwt_secret();
    
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(&secret),
        &validation,
    )
    .map(|data| data.claims)
    .map_err(|e| {
        // Determinar el tipo de error específico
        let error_msg = e.to_string();
        if error_msg.contains("ExpiredSignature") {
            JwtError::TokenExpired
        } else {
            JwtError::TokenValidationFailed(error_msg)
        }
    })
}

/// Extrae el user_id de un token JWT sin validar completamente
/// (útil para logs, pero NO para autenticación)
pub fn extract_user_id(token: &str) -> Option<String> {
    // Intentar decodificar sin validar la firma (solo para debugging)
    let validation = Validation::default();
    let secret = get_jwt_secret();
    
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(&secret),
        &validation,
    )
    .ok()
    .map(|data| data.claims.sub)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_and_validate_jwt() {
        let user_id = Uuid::new_v4();
        let email = "test@example.com";
        let role = "ADMIN";
        let name = Some("Test User".to_string());
        
        // Generar token
        let token = generate_jwt(user_id, email, role, name.clone()).unwrap();
        
        // Validar token
        let claims = validate_jwt(&token).unwrap();
        
        assert_eq!(claims.sub, user_id.to_string());
        assert_eq!(claims.email, email);
        assert_eq!(claims.role, role);
        assert_eq!(claims.name, name);
    }

    #[test]
    fn test_invalid_token() {
        let result = validate_jwt("invalid_token");
        assert!(result.is_err());
    }

    #[test]
    fn test_extract_user_id() {
        let user_id = Uuid::new_v4();
        let token = generate_jwt(user_id, "test@example.com", "MODEL", None).unwrap();
        
        let extracted_id = extract_user_id(&token).unwrap();
        assert_eq!(extracted_id, user_id.to_string());
    }
}
