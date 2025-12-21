use std::sync::Arc;

use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

use crate::state::AppState;

// ============================================================================
// TIPOS
// ============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatePostRequest {
    pub content: String,
    pub media_url: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct PostResponse {
    pub id: Uuid,
    pub user_id: Uuid,
    pub content: String,
    pub media_url: Option<String>,
    pub likes_count: i32,
    pub created_at: DateTime<Utc>,
    // Usuario que hizo el post
    pub user_name: String,
    pub user_avatar: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FeedResponse {
    pub posts: Vec<PostResponse>,
    pub total: i32,
}

// ============================================================================
// ENDPOINTS
// ============================================================================

/// POST /api/social/posts
/// Crear un nuevo post
pub async fn create_post(
    State(state): State<Arc<AppState>>,
    Json(req): Json<CreatePostRequest>,
) -> Result<(StatusCode, Json<PostResponse>), (StatusCode, String)> {
    let user_id = Uuid::new_v4(); // En producción, obtener del JWT

    if req.content.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "content is required".to_string()));
    }

    if req.content.len() > 5000 {
        return Err((
            StatusCode::BAD_REQUEST,
            "content must be <= 5000 characters".to_string(),
        ));
    }

    let post = sqlx::query_as::<_, PostResponse>(
        r#"
        INSERT INTO posts (user_id, content, media_url, likes_count, created_at)
        VALUES ($1, $2, $3, 0, NOW())
        RETURNING 
            posts.id, 
            posts.user_id, 
            posts.content, 
            posts.media_url,
            posts.likes_count,
            posts.created_at,
            COALESCE(users.name, 'Unknown') as user_name,
            users.avatar as user_avatar
        FROM posts
        LEFT JOIN users ON posts.user_id = users.id
        WHERE posts.user_id = $1
        ORDER BY posts.created_at DESC
        LIMIT 1
        "#,
    )
    .bind(user_id)
    .bind(&req.content)
    .bind(&req.media_url)
    .fetch_one(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("DB error creating post: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            "Failed to create post".to_string(),
        )
    })?;

    Ok((StatusCode::CREATED, Json(post)))
}

/// GET /api/social/feed
/// Obtener feed de los últimos 50 posts
pub async fn get_feed(
    State(state): State<Arc<AppState>>,
) -> Result<Json<FeedResponse>, (StatusCode, String)> {
    let posts = sqlx::query_as::<_, PostResponse>(
        r#"
        SELECT 
            posts.id,
            posts.user_id,
            posts.content,
            posts.media_url,
            posts.likes_count,
            posts.created_at,
            COALESCE(users.name, 'Unknown') as user_name,
            users.avatar as user_avatar
        FROM posts
        LEFT JOIN users ON posts.user_id = users.id
        ORDER BY posts.created_at DESC
        LIMIT 50
        "#,
    )
    .fetch_all(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("DB error fetching feed: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            "Failed to fetch feed".to_string(),
        )
    })?;

    let total = posts.len() as i32;

    Ok(Json(FeedResponse { posts, total }))
}

/// POST /api/social/posts/{id}/like
/// Incrementar likes en un post
pub async fn like_post(
    State(state): State<Arc<AppState>>,
    Path(post_id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let user_id = Uuid::new_v4(); // En producción, obtener del JWT

    // Intentar insertar el like (constraint unique evita duplicados)
    let result = sqlx::query(
        r#"
        INSERT INTO likes (post_id, user_id, created_at)
        VALUES ($1, $2, NOW())
        ON CONFLICT (post_id, user_id) DO NOTHING
        "#,
    )
    .bind(post_id)
    .bind(user_id)
    .execute(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("DB error adding like: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            "Failed to like post".to_string(),
        )
    })?;

    if result.rows_affected() == 0 {
        return Err((
            StatusCode::CONFLICT,
            "User already liked this post".to_string(),
        ));
    }

    // Actualizar contador
    sqlx::query(
        r#"
        UPDATE posts
        SET likes_count = (SELECT COUNT(*) FROM likes WHERE post_id = $1)
        WHERE id = $1
        "#,
    )
    .bind(post_id)
    .execute(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("DB error updating likes count: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            "Failed to update likes count".to_string(),
        )
    })?;

    Ok(Json(serde_json::json!({
        "status": "ok",
        "message": "Post liked successfully"
    })))
}
