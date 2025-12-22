use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use serde_json::json;
use sqlx::PgPool;
use tracing::{error, info, warn};
use super::AppState;

use crate::models::user::{LoginRequest, LoginResponse, User};
use crate::services::{jwt::generate_jwt, password::verify_password};

/// Handler para el endpoint POST /api/auth/login
/// 
/// # Flujo de autenticación:
/// 1. Recibe email y password en JSON
/// 2. Busca el usuario en la base de datos por email
/// 3. Verifica que el usuario exista y esté activo
/// 4. Verifica el hash de la contraseña con Argon2
/// 5. Genera un JWT token válido por 24 horas
/// 6. Retorna el token y datos del usuario
/// 
/// # Request Body:
/// ```json
/// {
///   "email": "admin@sweetmodels.com",
///   "password": "mi_contraseña"
/// }
/// ```
/// 
/// # Response (200 OK):
/// ```json
/// {
///   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
///   "role": "ADMIN",
///   "name": "Isaias",
///   "user_id": "550e8400-e29b-41d4-a716-446655440000"
/// }
/// ```
/// 
/// # Errores:
/// - 400 Bad Request: Email o password faltantes
/// - 401 Unauthorized: Credenciales inválidas o usuario inactivo
/// - 500 Internal Server Error: Error en la base de datos
pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, (StatusCode, Json<serde_json::Value>)> {
    // Validar que los campos no estén vacíos
    if payload.email.is_empty() || payload.password.is_empty() {
        warn!("Login attempt with empty credentials");
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Email and password are required",
                "message": "El email y la contraseña son obligatorios"
            })),
        ));
    }

    info!("Login attempt for email: {}", payload.email);

    // Buscar usuario en la base de datos
    let user = match sqlx::query_as::<_, User>(
        r#"
        SELECT 
            id, email, password_hash, role, created_at, updated_at,
            phone, address, national_id, is_verified, biometric_enabled,
            phone_verified, kyc_status, kyc_verified_at, full_name,
            platform_usernames, is_active
        FROM users 
        WHERE email = $1
        "#,
    )
    .bind(&payload.email)
    .fetch_optional(&state.db)
    .await
    {
        Ok(Some(user)) => user,
        Ok(None) => {
            warn!("Login failed: user not found for email {}", payload.email);
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid credentials",
                    "message": "Email o contraseña incorrectos"
                })),
            ));
        }
        Err(e) => {
            error!("Database error during login: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Internal server error",
                    "message": "Error interno del servidor"
                })),
            ));
        }
    };

    // Verificar que la cuenta esté activa
    if !user.is_active {
        warn!("Login attempt for inactive user: {}", payload.email);
        return Err((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Account disabled",
                "message": "La cuenta está desactivada. Contacta al administrador."
            })),
        ));
    }

    // Verificar la contraseña usando Argon2
    let password_valid = match verify_password(&payload.password, &user.password_hash) {
        Ok(valid) => valid,
        Err(e) => {
            error!("Password verification error: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Internal server error",
                    "message": "Error al verificar la contraseña"
                })),
            ));
        }
    };

    if !password_valid {
        warn!("Login failed: invalid password for user {}", payload.email);
        return Err((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Invalid credentials",
                "message": "Email o contraseña incorrectos"
            })),
        ));
    }

    // Generar JWT token
    let token = match generate_jwt(
        user.id,
        &user.email,
        &user.role,
        user.full_name.clone(),
    ) {
        Ok(token) => token,
        Err(e) => {
            error!("JWT generation error: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Internal server error",
                    "message": "Error al generar el token de autenticación"
                })),
            ));
        }
    };

    info!("Login successful for user: {} ({})", user.email, user.role);

    // Retornar respuesta exitosa
    Ok(Json(LoginResponse {
        token,
        role: user.role.clone(),
        name: user.full_name,
        user_id: user.id,
    }))
}

/// Handler para verificar si un token es válido
/// 
/// Este endpoint puede usarse para verificar si un JWT token
/// sigue siendo válido antes de hacer una operación importante.
/// 
/// # Request Header:
/// ```
/// Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
/// ```
/// 
/// # Response (200 OK):
/// ```json
/// {
///   "valid": true,
///   "user_id": "550e8400-e29b-41d4-a716-446655440000",
///   "email": "admin@sweetmodels.com",
///   "role": "ADMIN"
/// }
/// ```
pub async fn verify_token(
    token: String,
) -> Result<Json<serde_json::Value>, (StatusCode, Json<serde_json::Value>)> {
    use crate::services::jwt::validate_jwt;

    match validate_jwt(&token) {
        Ok(claims) => Ok(Json(json!({
            "valid": true,
            "user_id": claims.sub,
            "email": claims.email,
            "role": claims.role,
            "name": claims.name,
        }))),
        Err(e) => Err((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "valid": false,
                "error": e.to_string()
            })),
        )),
    }
}




