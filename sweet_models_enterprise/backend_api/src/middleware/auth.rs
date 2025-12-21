/// Authentication middleware para proteger endpoints
use axum::{
    async_trait,
    extract::FromRequestParts,
    http::{request::Parts, StatusCode},
};
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use sqlx::Row;
use uuid::Uuid;

use crate::state::AppState;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub email: String,
    pub role: String,
    pub exp: usize,
}

// ============================================================================
// SUPER ADMIN GUARD
// ============================================================================

/// Extractor que valida que el usuario es SUPER_ADMIN
pub struct SuperAdminOnly {
    pub user_id: String,
    pub email: String,
}

#[async_trait]
impl<S> FromRequestParts<S> for SuperAdminOnly
where
    S: Send + Sync,
{
    type Rejection = (StatusCode, String);

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let auth_header = parts
            .headers
            .get("authorization")
            .and_then(|h| h.to_str().ok())
            .ok_or_else(|| (
                StatusCode::UNAUTHORIZED,
                "Missing Authorization header".to_string(),
            ))?;

        let token = auth_header
            .strip_prefix("Bearer ")
            .ok_or_else(|| (
                StatusCode::UNAUTHORIZED,
                "Invalid Authorization format".to_string(),
            ))?;

        let jwt_secret = std::env::var("JWT_SECRET")
            .expect("JWT_SECRET environment variable must be set");
        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(jwt_secret.as_bytes()),
            &Validation::default(),
        )
        .map_err(|e| (
            StatusCode::UNAUTHORIZED,
            format!("Invalid token: {}", e),
        ))?;

        let claims = token_data.claims;

        if claims.role.to_uppercase() != "SUPER_ADMIN" {
            return Err((
                StatusCode::FORBIDDEN,
                format!(
                    "Access denied: SUPER_ADMIN role required (found: {})",
                    claims.role
                ),
            ));
        }

        Ok(SuperAdminOnly {
            user_id: claims.sub,
            email: claims.email,
        })
    }
}

// ============================================================================
// ADMIN GUARD (admin o super_admin)
// ============================================================================

/// Extractor que valida que el usuario es ADMIN o SUPER_ADMIN
pub struct AdminOnly {
    pub user_id: String,
    pub email: String,
    pub role: String,
}

#[async_trait]
impl<S> FromRequestParts<S> for AdminOnly
where
    S: Send + Sync,
{
    type Rejection = (StatusCode, String);

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let auth_header = parts
            .headers
            .get("authorization")
            .and_then(|h| h.to_str().ok())
            .ok_or_else(|| (
                StatusCode::UNAUTHORIZED,
                "Missing Authorization header".to_string(),
            ))?;

        let token = auth_header
            .strip_prefix("Bearer ")
            .ok_or_else(|| (
                StatusCode::UNAUTHORIZED,
                "Invalid Authorization format".to_string(),
            ))?;

        let jwt_secret = std::env::var("JWT_SECRET")
            .expect("JWT_SECRET environment variable must be set");
        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(jwt_secret.as_bytes()),
            &Validation::default(),
        )
        .map_err(|e| (
            StatusCode::UNAUTHORIZED,
            format!("Invalid token: {}", e),
        ))?;

        let claims = token_data.claims;
        let role_upper = claims.role.to_uppercase();

        if role_upper != "ADMIN" && role_upper != "SUPER_ADMIN" {
            return Err((
                StatusCode::FORBIDDEN,
                format!(
                    "Access denied: ADMIN role required (found: {})",
                    claims.role
                ),
            ));
        }

        Ok(AdminOnly {
            user_id: claims.sub,
            email: claims.email,
            role: claims.role,
        })
    }
}

// ============================================================================
// AUTHENTICATED USER (cualquier usuario autenticado)
// ============================================================================

/// Extractor que valida que el usuario está autenticado (cualquier rol)
pub struct AuthenticatedUser {
    pub user_id: String,
    pub email: String,
    pub role: String,
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthenticatedUser
where
    S: Send + Sync + AsRef<AppState>,
{
    type Rejection = (StatusCode, String);

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let auth_header = parts
            .headers
            .get("authorization")
            .and_then(|h| h.to_str().ok())
            .ok_or_else(|| (
                StatusCode::UNAUTHORIZED,
                "Missing Authorization header".to_string(),
            ))?;

        let token = auth_header
            .strip_prefix("Bearer ")
            .ok_or_else(|| (
                StatusCode::UNAUTHORIZED,
                "Invalid Authorization format".to_string(),
            ))?;

        let jwt_secret = std::env::var("JWT_SECRET")
            .expect("JWT_SECRET environment variable must be set");
        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(jwt_secret.as_bytes()),
            &Validation::default(),
        )
        .map_err(|e| (
            StatusCode::UNAUTHORIZED,
            format!("Invalid token: {}", e),
        ))?;

        let claims = token_data.claims;

        // Bloqueo legal: si el usuario no ha firmado términos, solo permitimos /api/legal/sign
        let path = parts.uri.path();
        if !path.starts_with("/api/legal/sign") {
            let user_id = Uuid::parse_str(&claims.sub).map_err(|_| {
                (
                    StatusCode::UNAUTHORIZED,
                    "Invalid user id in token".to_string(),
                )
            })?;

            let state_ref: &AppState = state.as_ref();
            let row = sqlx::query("SELECT has_signed_terms FROM users WHERE id = $1")
                .bind(user_id)
                .fetch_optional(&state_ref.db)
                .await
                .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

            match row {
                Some(record) => {
                    let has_signed: bool = record.try_get("has_signed_terms").unwrap_or(false);
                    if !has_signed {
                        return Err((StatusCode::FORBIDDEN, "MUST_SIGN_CONTRACT".to_string()));
                    }
                }
                None => {
                    return Err((StatusCode::UNAUTHORIZED, "User not found".to_string()));
                }
            }
        }

        Ok(AuthenticatedUser {
            user_id: claims.sub,
            email: claims.email,
            role: claims.role,
        })
    }
}
