use axum::{
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
};
use deadpool_redis::redis::AsyncCommands;
use std::sync::Arc;
use crate::state::AppState;

/// Rate limiting configuration
const MAX_REQUESTS_PER_WINDOW: i32 = 10;
const WINDOW_SECONDS: u64 = 60;

/// Rate limit error response
pub struct RateLimitExceeded;

impl IntoResponse for RateLimitExceeded {
    fn into_response(self) -> Response {
        (
            StatusCode::TOO_MANY_REQUESTS,
            "Rate limit exceeded. Try again later.",
        )
            .into_response()
    }
}

/// Middleware to check rate limits based on IP address
pub async fn rate_limit_middleware(
    State(state): State<Arc<AppState>>,
    request: Request,
    next: Next,
) -> Result<Response, RateLimitExceeded> {
    // Extract IP from request
    let ip = request
        .headers()
        .get("x-forwarded-for")
        .and_then(|h| h.to_str().ok())
        .and_then(|s| s.split(',').next())
        .unwrap_or("unknown");

    // Check rate limit
    if !check_rate_limit(&state, ip).await {
        tracing::warn!("Rate limit exceeded for IP: {}", ip);
        return Err(RateLimitExceeded);
    }

    Ok(next.run(request).await)
}

/// Check if IP is within rate limit
async fn check_rate_limit(state: &AppState, ip: &str) -> bool {
    let key = format!("rate_limit:{}", ip);
    
    let mut conn = match state.redis.get().await {
        Ok(c) => c,
        Err(e) => {
            tracing::error!("Redis connection error: {}", e);
            return true; // Fail open - allow request if Redis is down
        }
    };

    // Increment counter
    let count: Result<i32, _> = conn.incr(&key, 1).await;
    
    match count {
        Ok(c) => {
            // Set expiry on first request
            if c == 1 {
                let _: Result<(), _> = conn.expire(&key, WINDOW_SECONDS as i64).await;
            }
            
            c <= MAX_REQUESTS_PER_WINDOW
        }
        Err(e) => {
            tracing::error!("Redis incr error: {}", e);
            true // Fail open
        }
    }
}

/// Get remaining requests for IP
pub async fn get_rate_limit_info(state: &AppState, ip: &str) -> (i32, i32) {
    let key = format!("rate_limit:{}", ip);
    
    let mut conn = match state.redis.get().await {
        Ok(c) => c,
        Err(_) => return (MAX_REQUESTS_PER_WINDOW, MAX_REQUESTS_PER_WINDOW),
    };

    let count: i32 = conn.get(&key).await.unwrap_or(0);
    let remaining = (MAX_REQUESTS_PER_WINDOW - count).max(0);
    
    (remaining, MAX_REQUESTS_PER_WINDOW)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rate_limit_constants() {
        assert_eq!(MAX_REQUESTS_PER_WINDOW, 10);
        assert_eq!(WINDOW_SECONDS, 60);
    }
}
