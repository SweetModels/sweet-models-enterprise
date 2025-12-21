use async_openai::{
    types::{ChatCompletionRequestMessage, ChatCompletionRequestSystemMessageArgs, 
            ChatCompletionRequestUserMessageArgs, CreateChatCompletionRequestArgs},
    Client,
};
use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use deadpool_redis::redis::AsyncCommands;

use backend_api::state::AppState;
use crate::ai::beyorder_observer::BeyorderConfig;

#[derive(Debug, Deserialize)]
pub struct BeyorderChatRequest {
    pub user_id: i32,
    pub question: String,
}

#[derive(Debug, Serialize)]
pub struct BeyorderChatResponse {
    pub response: String,
    pub context_used: Vec<String>,
    pub timestamp: i64,
}

/// Contexto de datos de la modelo para enriquecer la respuesta
#[derive(Debug)]
struct ModelContext {
    username: String,
    tokens_today: i32,
    tokens_yesterday: i32,
    avg_last_7_days: i32,
    daily_goal: i32,
    best_platform: String,
    best_time_slot: String,
    total_earnings_month: f64,
}

/// POST /api/ai/chat - Chat interactivo con Beyorder
pub async fn beyorder_chat_handler(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<BeyorderChatRequest>,
) -> Result<(StatusCode, Json<BeyorderChatResponse>), (StatusCode, String)> {
    
    tracing::info!(
        "🤖 Beyorder Chat: user_id={}, pregunta='{}'",
        payload.user_id,
        payload.question
    );

    // 1. Obtener contexto de la modelo
    let context = get_model_context(&state, payload.user_id)
        .await
        .map_err(|e| {
            tracing::error!("Error obteniendo contexto: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Error: {}", e))
        })?;

    // 2. Generar respuesta con IA + datos reales
    let (response, context_used) = generate_ai_response(&state, &payload.question, &context)
        .await
        .map_err(|e| {
            tracing::error!("Error generando respuesta IA: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Error: {}", e))
        })?;

    // 3. Guardar conversación en historial
    save_chat_history(&state, payload.user_id, &payload.question, &response)
        .await
        .ok(); // No bloquear si falla el guardado

    let response_payload = BeyorderChatResponse {
        response,
        context_used,
        timestamp: chrono::Utc::now().timestamp(),
    };

    Ok((StatusCode::OK, Json(response_payload)))
}

/// Obtiene el contexto completo de la modelo desde la BD
async fn get_model_context(
    state: &AppState,
    user_id: i32,
) -> Result<ModelContext, Box<dyn std::error::Error>> {
    
    // Query completa con análisis de rendimiento
    let row = sqlx::query_as::<_, (String, i32, i32, i32, i32, String, String, f64)>(
        r#"
        WITH today_stats AS (
            SELECT 
                user_id,
                SUM(tokens_earned) as tokens_today
            FROM attendance
            WHERE DATE(started_at) = CURRENT_DATE
            AND user_id = $1
            GROUP BY user_id
        ),
        yesterday_stats AS (
            SELECT 
                user_id,
                SUM(tokens_earned) as tokens_yesterday
            FROM attendance
            WHERE DATE(started_at) = CURRENT_DATE - INTERVAL '1 day'
            AND user_id = $1
            GROUP BY user_id
        ),
        last_7_days AS (
            SELECT 
                user_id,
                AVG(daily_tokens) as avg_tokens_7d
            FROM (
                SELECT 
                    user_id,
                    DATE(started_at) as date,
                    SUM(tokens_earned) as daily_tokens
                FROM attendance
                WHERE user_id = $1
                AND started_at >= CURRENT_DATE - INTERVAL '7 days'
                GROUP BY user_id, DATE(started_at)
            ) subq
            GROUP BY user_id
        ),
        best_platform AS (
            SELECT 
                platform,
                SUM(tokens_earned) as total_tokens
            FROM attendance
            WHERE user_id = $1
            AND started_at >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY platform
            ORDER BY total_tokens DESC
            LIMIT 1
        ),
        best_time AS (
            SELECT 
                CASE 
                    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 6 AND 12 THEN 'mañana'
                    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 12 AND 18 THEN 'tarde'
                    ELSE 'noche'
                END as time_slot,
                AVG(tokens_earned) as avg_tokens
            FROM attendance
            WHERE user_id = $1
            AND started_at >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY time_slot
            ORDER BY avg_tokens DESC
            LIMIT 1
        ),
        month_earnings AS (
            SELECT 
                SUM(amount_cop) as total_earnings
            FROM payroll
            WHERE user_id = $1
            AND DATE_TRUNC('month', payment_date) = DATE_TRUNC('month', CURRENT_DATE)
        )
        SELECT 
            u.username,
            COALESCE(ts.tokens_today, 0)::int as tokens_today,
            COALESCE(ys.tokens_yesterday, 0)::int as tokens_yesterday,
            COALESCE(l7.avg_tokens_7d, 0)::int as avg_7d,
            COALESCE(u.daily_goal, 5000)::int as daily_goal,
            COALESCE(bp.platform, 'chaturbate') as best_platform,
            COALESCE(bt.time_slot, 'noche') as best_time,
            COALESCE(me.total_earnings, 0.0) as month_earnings
        FROM users u
        LEFT JOIN today_stats ts ON ts.user_id = u.id
        LEFT JOIN yesterday_stats ys ON ys.user_id = u.id
        LEFT JOIN last_7_days l7 ON l7.user_id = u.id
        LEFT JOIN best_platform bp ON true
        LEFT JOIN best_time bt ON true
        LEFT JOIN month_earnings me ON true
        WHERE u.id = $1
        "#
    )
    .bind(user_id)
    .fetch_one(&state.db)
    .await?;

    Ok(ModelContext {
        username: row.0,
        tokens_today: row.1,
        tokens_yesterday: row.2,
        avg_last_7_days: row.3,
        daily_goal: row.4,
        best_platform: row.5,
        best_time_slot: row.6,
        total_earnings_month: row.7,
    })
}

/// Genera respuesta usando IA con contexto real
async fn generate_ai_response(
    _state: &AppState,
    question: &str,
    context: &ModelContext,
) -> Result<(String, Vec<String>), Box<dyn std::error::Error>> {
    
    let config = BeyorderConfig::from_env();
    let ai_config = async_openai::config::OpenAIConfig::new()
        .with_api_key(&config.api_key)
        .with_api_base("https://api.deepseek.com");
    let client = Client::with_config(ai_config);

    // Construir contexto para la IA
    let mut context_items = vec![];
    let context_text = format!(
        "Datos de la modelo {}:\n\
        - Tokens hoy: {} (Meta diaria: {})\n\
        - Tokens ayer: {}\n\
        - Promedio últimos 7 días: {}\n\
        - Mejor plataforma: {}\n\
        - Mejor horario: {}\n\
        - Ganancias este mes: ${:.2} COP\n",
        context.username,
        context.tokens_today,
        context.daily_goal,
        context.tokens_yesterday,
        context.avg_last_7_days,
        context.best_platform,
        context.best_time_slot,
        context.total_earnings_month
    );

    context_items.push(format!("Tokens hoy: {}", context.tokens_today));
    context_items.push(format!("Meta: {}", context.daily_goal));
    context_items.push(format!("Mejor plataforma: {}", context.best_platform));
    context_items.push(format!("Mejor horario: {}", context.best_time_slot));

    // Prompt del sistema
    let system_prompt = format!(
        "Eres Beyorder, un AI coach estratégico para modelos webcam. \
        Tu trabajo es analizar datos REALES y dar consejos ESPECÍFICOS basados en números.\n\n\
        {}\n\n\
        REGLAS:\n\
        1. Usa los datos arriba para personalizar tu respuesta\n\
        2. Sé directo y práctico (máximo 4 líneas)\n\
        3. Si ves patrones (mejor plataforma, mejor horario), menciónalo\n\
        4. Motiva pero con datos concretos\n\
        5. Usa emojis ocasionales",
        context_text
    );

    let request = CreateChatCompletionRequestArgs::default()
        .model(&config.model)
        .messages(vec![
            ChatCompletionRequestMessage::System(
                ChatCompletionRequestSystemMessageArgs::default()
                    .content(&system_prompt)
                    .build()?
            ),
            ChatCompletionRequestMessage::User(
                ChatCompletionRequestUserMessageArgs::default()
                    .content(question)
                    .build()?
            ),
        ])
        .max_tokens(200_u16)
        .temperature(0.7)
        .build()?;

    let response = client.chat().create(request).await?;

    let message = response
        .choices
        .first()
        .and_then(|choice| choice.message.content.clone())
        .ok_or("No response from AI")?;

    Ok((message, context_items))
}

/// Guarda el historial de conversación
async fn save_chat_history(
    state: &AppState,
    user_id: i32,
    question: &str,
    response: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    
    // Guardar en base de datos
    sqlx::query(
        r#"
        INSERT INTO chat_messages (sender_id, receiver_id, content, created_at)
        VALUES 
            ($1, (SELECT id FROM users WHERE username = 'beyorder' LIMIT 1), $2, NOW()),
            ((SELECT id FROM users WHERE username = 'beyorder' LIMIT 1), $1, $3, NOW())
        "#
    )
    .bind(user_id)
    .bind(question)
    .bind(response)
    .execute(&state.db)
    .await?;

    // Guardar en Redis para histórico rápido
    if let Ok(mut conn) = state.redis.get().await {
        let history_key = format!("beyorder:chat:history:{}", user_id);
        let chat_entry = serde_json::json!({
            "question": question,
            "response": response,
            "timestamp": chrono::Utc::now().timestamp()
        }).to_string();
        
        let _: () = conn.lpush(&history_key, chat_entry).await?;
        let _: () = conn.ltrim(&history_key, 0, 49).await?; // Mantener solo últimas 50
        let _: () = conn.expire(&history_key, 604800).await?; // 7 días
    }

    Ok(())
}

/// GET /api/ai/chat/history/:user_id - Historial de conversaciones
pub async fn beyorder_chat_history_handler(
    State(state): State<Arc<AppState>>,
    axum::extract::Path(user_id): axum::extract::Path<i32>,
) -> Result<Json<Vec<serde_json::Value>>, (StatusCode, String)> {
    
    // Intentar primero desde Redis
    if let Ok(mut conn) = state.redis.get().await {
        let history_key = format!("beyorder:chat:history:{}", user_id);
        
        if let Ok(items) = conn.lrange::<_, Vec<String>>(&history_key, 0, 49).await {
            let parsed: Vec<serde_json::Value> = items
                .into_iter()
                .filter_map(|s| serde_json::from_str(s.as_str()).ok())
                .collect();
            
            if !parsed.is_empty() {
                return Ok(Json(parsed));
            }
        }
    }

    // Fallback a base de datos
    let rows = sqlx::query_as::<_, (String, i64)>(
        r#"
        SELECT content, EXTRACT(EPOCH FROM created_at)::bigint as timestamp
        FROM chat_messages
        WHERE (sender_id = $1 AND receiver_id = (SELECT id FROM users WHERE username = 'beyorder'))
           OR (sender_id = (SELECT id FROM users WHERE username = 'beyorder') AND receiver_id = $1)
        ORDER BY created_at DESC
        LIMIT 50
        "#
    )
    .bind(user_id)
    .fetch_all(&state.db)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("DB error: {}", e)))?;

    let history: Vec<serde_json::Value> = rows
        .into_iter()
        .map(|(content, timestamp)| {
            serde_json::json!({
                "message": content,
                "timestamp": timestamp
            })
        })
        .collect();

    Ok(Json(history))
}
