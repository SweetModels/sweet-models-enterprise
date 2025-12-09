use std::sync::Arc;

use axum::{Json, Router, routing::post, extract::State, middleware};
use crate::state::AppState;
use crate::middleware::rate_limit_middleware;
use deadpool_redis::redis::AsyncCommands;
use k256::{EncodedPoint, FieldBytes, ProjectivePoint, Scalar};
use k256::elliptic_curve::sec1::FromEncodedPoint;
use k256::elliptic_curve::PrimeField;
use rand::{rngs::OsRng, RngCore};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;

pub fn router(state: Arc<AppState>) -> Router<Arc<AppState>> {
    Router::new()
        .route("/login", post(login_challenge))
        .layer(middleware::from_fn_with_state(state.clone(), rate_limit_middleware))
        .route("/verify", post(verify_solution))
        .with_state(state)
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub user_id: Uuid,
}

#[derive(Debug, Serialize)]
pub struct ChallengeResponse {
    pub challenge: String,
}

#[derive(Debug, Deserialize)]
pub struct VerifyRequest {
    pub user_id: Uuid,
    pub r: String,
    pub s: String,
}

#[derive(Debug, Serialize)]
pub struct VerifyResponse {
    pub token: String,
}

#[derive(Debug, Error)]
pub enum ZkError {
    #[error("Usuario no encontrado")]
    NotFound,
    #[error("Desafío expirado")]
    ChallengeExpired,
    #[error("Prueba inválida")]
    InvalidProof,
    #[error("Error interno")] 
    Internal,
}

impl axum::response::IntoResponse for ZkError {
    fn into_response(self) -> axum::response::Response {
        (axum::http::StatusCode::BAD_REQUEST, self.to_string()).into_response()
    }
}

async fn login_challenge(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<ChallengeResponse>, ZkError> {
    let mut rng = OsRng;
    let mut buf = [0u8; 32];
    rng.fill_bytes(&mut buf);
    let challenge = hex::encode(buf);

    let mut conn = state.redis.get().await.map_err(|_| ZkError::Internal)?;
    let key = format!("zk:challenge:{}", payload.user_id);
    let _: () = conn.set_ex(key, &challenge, 30).await.map_err(|_| ZkError::Internal)?;

    Ok(Json(ChallengeResponse { challenge }))
}

async fn verify_solution(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<VerifyRequest>,
) -> Result<Json<VerifyResponse>, ZkError> {
    // load challenge
    let mut conn = state.redis.get().await.map_err(|_| ZkError::Internal)?;
    let key = format!("zk:challenge:{}", payload.user_id);
    let challenge: Option<String> = conn.get(&key).await.map_err(|_| ZkError::Internal)?;
    let challenge = challenge.ok_or(ZkError::ChallengeExpired)?;
    let _: () = conn.del(&key).await.unwrap_or(());

    // load public commitment
    #[derive(sqlx::FromRow)]
    struct IdentityRow { public_commitment: Vec<u8> }
    let row: IdentityRow = sqlx::query_as(
        "SELECT public_commitment FROM zk_identities WHERE user_id = $1"
    )
    .bind(payload.user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| ZkError::Internal)?
    .ok_or(ZkError::NotFound)?;

    let y_bytes = EncodedPoint::from_bytes(&row.public_commitment).map_err(|_| ZkError::InvalidProof)?;
    let y = ProjectivePoint::from_encoded_point(&y_bytes)
        .into_option()
        .ok_or(ZkError::InvalidProof)?;

    let challenge_bytes: [u8; 32] = hex::decode(challenge).map_err(|_| ZkError::InvalidProof)?.try_into().map_err(|_| ZkError::InvalidProof)?;
    let c_scalar = Scalar::from_repr(FieldBytes::from(challenge_bytes))
        .into_option()
        .ok_or(ZkError::InvalidProof)?;

    let r_bytes = EncodedPoint::from_bytes(&hex::decode(&payload.r).map_err(|_| ZkError::InvalidProof)?).map_err(|_| ZkError::InvalidProof)?;
    let r_point = ProjectivePoint::from_encoded_point(&r_bytes)
        .into_option()
        .ok_or(ZkError::InvalidProof)?;

    let s_bytes: [u8; 32] = hex::decode(&payload.s).map_err(|_| ZkError::InvalidProof)?.try_into().map_err(|_| ZkError::InvalidProof)?;
    let s_scalar = Scalar::from_repr(FieldBytes::from(s_bytes))
        .into_option()
        .ok_or(ZkError::InvalidProof)?;

    // Verify: g^s ?= R * Y^c
    let g_s = ProjectivePoint::GENERATOR * s_scalar;
    let rhs = r_point + (y * c_scalar);
    if g_s != rhs {
        return Err(ZkError::InvalidProof);
    }

    // Generate real JWT token
    let token = crate::auth::jwt::generate_token(payload.user_id, "zk")
        .map_err(|_| ZkError::Internal)?;
    
    Ok(Json(VerifyResponse { token }))
}
