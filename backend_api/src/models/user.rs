use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc};

/// Modelo de usuario que coincide con la tabla `users` en PostgreSQL
/// 
/// Esta estructura representa el esquema completo de la tabla users,
/// incluyendo todos los campos necesarios para autenticación, perfil,
/// y gestión de plataformas.
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct User {
    /// ID único del usuario (UUID v4)
    pub id: Uuid,
    
    /// Email del usuario (único, usado para login)
    pub email: String,
    
    /// Hash de la contraseña (Argon2)
    pub password_hash: String,
    
    /// Rol del usuario (user, admin, model, monitor)
    pub role: String,
    
    /// Fecha de creación del usuario
    pub created_at: DateTime<Utc>,
    
    /// Fecha de última actualización
    pub updated_at: DateTime<Utc>,
    
    /// Teléfono del usuario (opcional)
    pub phone: Option<String>,
    
    /// Dirección del usuario (opcional)
    pub address: Option<String>,
    
    /// Cédula/DNI del usuario (opcional, único)
    pub national_id: Option<String>,
    
    /// Si el usuario está verificado
    #[serde(default)]
    pub is_verified: bool,
    
    /// Si el usuario tiene biometría habilitada
    #[serde(default)]
    pub biometric_enabled: bool,
    
    /// Si el teléfono está verificado
    #[serde(default)]
    pub phone_verified: bool,
    
    /// Estado del proceso KYC (pending, approved, rejected)
    pub kyc_status: Option<String>,
    
    /// Fecha de verificación KYC
    pub kyc_verified_at: Option<DateTime<Utc>>,
    
    /// Nombre completo del usuario
    pub full_name: Option<String>,
    
    /// Usernames en diferentes plataformas (JSON)
    /// Ejemplo: {"chaturbate": "model1", "stripchat": "model2"}
    pub platform_usernames: Option<serde_json::Value>,
    
    /// Si la cuenta está activa (para soft delete)
    #[serde(default = "default_true")]
    pub is_active: bool,
}

fn default_true() -> bool {
    true
}

/// Estructura simplificada para respuestas de autenticación
/// No incluye información sensible como password_hash
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub role: String,
    pub full_name: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        UserResponse {
            id: user.id,
            email: user.email,
            role: user.role,
            full_name: user.full_name,
            is_active: user.is_active,
            created_at: user.created_at,
        }
    }
}

/// Estructura para crear un nuevo usuario
#[derive(Debug, Deserialize)]
pub struct CreateUser {
    pub email: String,
    pub password: String,
    pub role: Option<String>,
    pub full_name: Option<String>,
}

/// Estructura para login
#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

/// Respuesta de login exitoso
#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub role: String,
    pub name: Option<String>,
    pub user_id: Uuid,
}
