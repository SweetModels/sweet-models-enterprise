use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;
use tracing::{error, info};
use super::AppState;
use serde_json::json;
use chrono::Utc;

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct Product {
    pub id: String,
    pub name: String,
    pub price_cop: f64,
    pub stock: i32,
    pub image_url: Option<String>,
    pub is_active: bool,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct Order {
    pub id: String,
    pub user_id: String,
    pub product_id: String,
    pub status: String,
    pub quantity: i32,
    pub total_price_cop: f64,
}

#[derive(Debug, Deserialize)]
pub struct BuyRequest {
    pub product_id: String,
}

#[derive(Debug, Serialize)]
pub struct BuyResponse {
    pub message: String,
    pub order_id: String,
}

/// GET /api/market/products
/// Obtener lista de productos activos con stock disponible
pub async fn get_products(
    State(state): State<AppState>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let products: Vec<Product> = sqlx::query_as(
        "SELECT id::TEXT, name, price_cop, stock, image_url, is_active 
         FROM products 
         WHERE is_active = TRUE AND stock > 0 
         ORDER BY name ASC"
    )
    .fetch_all(&state.db)
    .await
    .map_err(|e| {
        error!("Error fetching products: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Failed to fetch products"}))
        )
    })?;

    info!("📦 Fetched {} products", products.len());

    Ok((StatusCode::OK, Json(products)))
}

/// POST /api/market/buy
/// Comprar un producto (transacción ACID con descuento automático)
pub async fn buy_product(
    State(state): State<AppState>,
    axum::extract::Path(user_id): axum::extract::Path<String>,
    Json(payload): Json<BuyRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let user_uuid = Uuid::parse_str(&user_id).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "Invalid user ID"}))
        )
    })?;

    let product_uuid = Uuid::parse_str(&payload.product_id).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "Invalid product ID"}))
        )
    })?;

    info!("🛍️  Purchase attempt: user={}, product={}", user_id, payload.product_id);

    // Iniciar transacción
    let mut tx = state.db.begin().await.map_err(|e| {
        error!("Transaction error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Database error"}))
        )
    })?;

    // 1. Verificar stock y obtener precio
    let product: (i32, f64) = sqlx::query_as(
        "SELECT stock, price_cop FROM products WHERE id = $1 AND is_active = TRUE FOR UPDATE"
    )
    .bind(product_uuid)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| {
        error!("Error checking product: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Product error"}))
        )
    })?
    .ok_or((
        StatusCode::NOT_FOUND,
        Json(json!({"error": "Product not found"}))
    ))?;

    let (stock, price_cop) = product;
    if stock <= 0 {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "Product out of stock"}))
        ));
    }

    // 2. Restar stock
    sqlx::query("UPDATE products SET stock = stock - 1, updated_at = NOW() WHERE id = $1")
        .bind(product_uuid)
        .execute(&mut *tx)
        .await
        .map_err(|e| {
            error!("Error updating stock: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Failed to update stock"}))
            )
        })?;

    // 3. Crear orden
    let order_id = Uuid::new_v4();
    sqlx::query(
        "INSERT INTO orders (id, user_id, product_id, status, quantity, total_price_cop, created_at) 
         VALUES ($1, $2, $3, 'PENDING_DELIVERY', 1, $4, CURRENT_TIMESTAMP)"
    )
    .bind(order_id)
    .bind(user_uuid)
    .bind(product_uuid)
    .bind(price_cop)
    .execute(&mut *tx)
    .await
    .map_err(|e| {
        error!("Error creating order: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Failed to create order"}))
        )
    })?;

    // 4. ¡TRUCO MAESTRO! Insertar descuento en daily_production (valor NEGATIVO)
    let today = Utc::now().date_naive();
    sqlx::query(
        r#"
        INSERT INTO daily_production (model_id, "date", platform, token_amount, token_value_cop)
        VALUES ($1, $2, 'STORE_PURCHASE', 0, $3)
        ON CONFLICT (model_id, "date", platform)
        DO UPDATE SET token_value_cop = daily_production.token_value_cop + EXCLUDED.token_value_cop
        "#
    )
    .bind(user_uuid)
    .bind(today)
    .bind(-price_cop)  // Precio NEGATIVO = descuento
    .execute(&mut *tx)
    .await
    .map_err(|e| {
        error!("Error recording purchase deduction: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Failed to record purchase"}))
        )
    })?;

    // Commit transacción
    tx.commit().await.map_err(|e| {
        error!("Commit error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Transaction failed"}))
        )
    })?;

    info!(
        "✅ Purchase successful: user={}, product={}, price=${}, order={}",
        user_id, payload.product_id, price_cop, order_id
    );

    Ok((
        StatusCode::OK,
        Json(BuyResponse {
            message: format!(
                "¡Compra exitosa! 🎉 Se descontará ${:.0} de tu nómina.",
                price_cop
            ),
            order_id: order_id.to_string(),
        })
    ))
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct PendingOrder {
    pub id: String,
    pub user_id: String,
    pub product_id: String,
    pub product_name: String,
    pub user_email: String,
    pub status: String,
    pub quantity: i32,
    pub total_price_cop: f64,
    pub created_at: String,
}

/// GET /api/admin/pending-orders
/// Obtener órdenes pendientes de entrega
pub async fn get_pending_orders(
    State(state): State<AppState>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let orders: Vec<PendingOrder> = sqlx::query_as(
        r#"
        SELECT 
            o.id::TEXT,
            o.user_id::TEXT,
            o.product_id::TEXT,
            p.name as product_name,
            u.email as user_email,
            o.status,
            o.quantity,
            o.total_price_cop,
            o.created_at::TEXT
        FROM orders o
        JOIN products p ON o.product_id = p.id
        JOIN users u ON o.user_id = u.id
        WHERE o.status = 'PENDING_DELIVERY'
        ORDER BY o.created_at DESC
        "#
    )
    .fetch_all(&state.db)
    .await
    .map_err(|e| {
        error!("Error fetching pending orders: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Failed to fetch orders"}))
        )
    })?;

    info!("📦 Fetched {} pending orders", orders.len());

    Ok((StatusCode::OK, Json(orders)))
}

#[derive(Debug, Deserialize)]
pub struct MarkDeliveredRequest {
    pub order_id: String,
}

/// POST /api/admin/mark-delivered
/// Marcar una orden como entregada
pub async fn mark_delivered(
    State(state): State<AppState>,
    Json(payload): Json<MarkDeliveredRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let order_uuid = Uuid::parse_str(&payload.order_id).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "Invalid order ID"}))
        )
    })?;

    let result = sqlx::query(
        "UPDATE orders SET status = 'DELIVERED', updated_at = CURRENT_TIMESTAMP WHERE id = $1"
    )
    .bind(order_uuid)
    .execute(&state.db)
    .await
    .map_err(|e| {
        error!("Error marking delivered: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Failed to update order"}))
        )
    })?;

    if result.rows_affected() == 0 {
        return Err((
            StatusCode::NOT_FOUND,
            Json(json!({"error": "Order not found"}))
        ));
    }

    info!("✅ Order marked as delivered: {}", payload.order_id);

    Ok((
        StatusCode::OK,
        Json(json!({"message": "Orden entregada exitosamente"}))
    ))
}





