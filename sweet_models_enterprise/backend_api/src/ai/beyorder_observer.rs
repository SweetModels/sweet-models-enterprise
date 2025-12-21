use async_openai::{
    types::{ChatCompletionRequestMessage, ChatCompletionRequestSystemMessageArgs, 
            ChatCompletionRequestUserMessageArgs, CreateChatCompletionRequestArgs},
    Client,
};
use chrono::Utc;
use deadpool_redis::redis::AsyncCommands;
use std::sync::Arc;
use tokio::time::{interval, Duration};

use backend_api::state::AppState;

/// Configuración de Beyorder AI Coach
#[derive(Debug, Clone)]
pub struct BeyorderConfig {
    pub api_key: String,
    pub model: String,
    pub observation_interval_mins: u64,
    pub underperformance_threshold: f64, // -20% por defecto
    pub enabled: bool,
}

impl BeyorderConfig {
    pub fn from_env() -> Self {
        Self {
            api_key: std::env::var("OPENAI_API_KEY")
                .or_else(|_| std::env::var("DEEPSEEK_API_KEY"))
                .unwrap_or_else(|_| "sk-test".to_string()),
            model: std::env::var("AI_MODEL")
                .unwrap_or_else(|_| "deepseek-chat".to_string()),
            observation_interval_mins: std::env::var("BEYORDER_INTERVAL_MINS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(30),
            underperformance_threshold: -0.20, // -20%
            enabled: std::env::var("BEYORDER_ENABLED")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(true),
        }
    }
}

/// Estadísticas de una modelo para análisis
#[derive(Debug, Clone)]
pub struct ModelStats {
    pub user_id: i32,
    pub username: String,
    pub tokens_today: i32,
    pub tokens_average_last_7_days: i32,
    pub daily_goal: i32,
    pub platform: String,
    pub hours_streamed_today: f64,
}

/// Resultado del análisis de Beyorder
#[derive(Debug)]
pub enum CoachingAction {
    Motivate { user_id: i32, message: String },
    Congratulate { user_id: i32, message: String },
    NoAction,
}

/// Servicio de observación automática de Beyorder
pub struct BeyorderObserver {
    config: BeyorderConfig,
    state: Arc<AppState>,
    ai_client: Client<async_openai::config::OpenAIConfig>,
}

impl BeyorderObserver {
    pub fn new(state: Arc<AppState>) -> Self {
        let config = BeyorderConfig::from_env();
        
        // Configurar cliente de IA para DeepSeek
        let ai_config = async_openai::config::OpenAIConfig::new()
            .with_api_key(&config.api_key)
            .with_api_base("https://api.deepseek.com");
        
        let ai_client = Client::with_config(ai_config);

        Self {
            config,
            state,
            ai_client,
        }
    }

    /// Inicia el servicio de observación periódica
    pub async fn start_observation_loop(self: Arc<Self>) {
        if !self.config.enabled {
            tracing::info!("🤖 Beyorder Observer DESHABILITADO por configuración");
            return;
        }

        tracing::info!(
            "🤖 Beyorder Observer iniciado - Intervalo: {} minutos",
            self.config.observation_interval_mins
        );

        let mut ticker = interval(Duration::from_secs(
            self.config.observation_interval_mins * 60,
        ));

        loop {
            ticker.tick().await;
            
            if let Err(e) = self.observe_and_coach().await {
                tracing::error!("❌ Error en ciclo de observación Beyorder: {}", e);
            }
        }
    }

    /// Ciclo principal de observación y coaching
    async fn observe_and_coach(&self) -> Result<(), Box<dyn std::error::Error>> {
        tracing::info!("🔍 Beyorder: Iniciando análisis de modelos activas...");

        // 1. Obtener modelos activas hoy
        let active_models = self.get_active_models_today().await?;
        
        tracing::info!("📊 Modelos activas encontradas: {}", active_models.len());

        // 2. Analizar cada modelo
        for model_stats in active_models {
            match self.analyze_model_performance(&model_stats).await {
                CoachingAction::Motivate { user_id, message } => {
                    self.send_coaching_message(user_id, &message).await?;
                    tracing::info!(
                        "💪 Beyorder: Mensaje motivacional enviado a user_id={}",
                        user_id
                    );
                }
                CoachingAction::Congratulate { user_id, message } => {
                    self.send_coaching_message(user_id, &message).await?;
                    tracing::info!(
                        "🎉 Beyorder: Felicitación enviada a user_id={}",
                        user_id
                    );
                }
                CoachingAction::NoAction => {
                    // Modelo en rango normal, no requiere intervención
                }
            }
        }

        tracing::info!("✅ Beyorder: Ciclo de observación completado");
        Ok(())
    }

    /// Obtiene estadísticas de modelos activas hoy
    async fn get_active_models_today(&self) -> Result<Vec<ModelStats>, Box<dyn std::error::Error>> {
        let _today_start = Utc::now().date_naive().and_hms_opt(0, 0, 0).unwrap();

        // Query que obtiene modelos con actividad hoy + promedio 7 días
        let stats = sqlx::query_as::<_, (i32, String, i32, i32, i32, String, f64)>(
            r#"
            WITH today_stats AS (
                SELECT 
                    user_id,
                    SUM(tokens_earned) as tokens_today,
                    SUM(EXTRACT(EPOCH FROM (ended_at - started_at)) / 3600.0) as hours_today
                FROM attendance
                WHERE DATE(started_at) = CURRENT_DATE
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
                    WHERE started_at >= CURRENT_DATE - INTERVAL '7 days'
                    AND started_at < CURRENT_DATE
                    GROUP BY user_id, DATE(started_at)
                ) subq
                GROUP BY user_id
            )
            SELECT 
                u.id,
                u.username,
                COALESCE(ts.tokens_today, 0)::int as tokens_today,
                COALESCE(l7.avg_tokens_7d, 0)::int as avg_7d,
                COALESCE(u.daily_goal, 5000)::int as daily_goal,
                COALESCE(u.primary_platform, 'chaturbate') as platform,
                COALESCE(ts.hours_today, 0.0) as hours_today
            FROM users u
            LEFT JOIN today_stats ts ON ts.user_id = u.id
            LEFT JOIN last_7_days l7 ON l7.user_id = u.id
            WHERE u.role = 'model'
            AND ts.tokens_today IS NOT NULL
            ORDER BY ts.tokens_today DESC
            "#
        )
        .fetch_all(&self.state.db)
        .await?;

        Ok(stats
            .into_iter()
            .map(|(user_id, username, tokens_today, avg_7d, goal, platform, hours)| ModelStats {
                user_id,
                username,
                tokens_today,
                tokens_average_last_7_days: avg_7d,
                daily_goal: goal,
                platform,
                hours_streamed_today: hours,
            })
            .collect())
    }

    /// Analiza el desempeño de una modelo y decide la acción
    async fn analyze_model_performance(&self, stats: &ModelStats) -> CoachingAction {
        // 1. Verificar si superó la meta
        if stats.tokens_today >= stats.daily_goal {
            let message = self
                .generate_congratulation_message(stats)
                .await
                .unwrap_or_else(|_| {
                    format!(
                        "🎉 ¡Felicitaciones {}! Rompiste tu meta de {} tokens hoy. ¡Sigue así! 💪",
                        stats.username, stats.daily_goal
                    )
                });

            return CoachingAction::Congratulate {
                user_id: stats.user_id,
                message,
            };
        }

        // 2. Verificar underperformance (solo si hay histórico)
        if stats.tokens_average_last_7_days > 0 {
            let expected_tokens =
                (stats.tokens_average_last_7_days as f64 * (1.0 + self.config.underperformance_threshold)) as i32;

            if stats.tokens_today < expected_tokens {
                let message = self
                    .generate_motivation_message(stats)
                    .await
                    .unwrap_or_else(|_| {
                        format!(
                            "💪 Hey {}! Veo que hoy ha sido más lento de lo usual. Recuerda que cada día es una nueva oportunidad. ¡Tú puedes! 🌟",
                            stats.username
                        )
                    });

                return CoachingAction::Motivate {
                    user_id: stats.user_id,
                    message,
                };
            }
        }

        CoachingAction::NoAction
    }

    /// Genera mensaje motivacional usando IA
    async fn generate_motivation_message(
        &self,
        stats: &ModelStats,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let prompt = format!(
            "Eres Beyorder, un coach motivacional de modelos webcam profesional y empático. \
            La modelo {} está teniendo un día más lento de lo usual.\n\
            - Tokens hoy: {}\n\
            - Promedio últimos 7 días: {}\n\
            - Horas transmitidas hoy: {:.1}\n\
            - Plataforma: {}\n\n\
            Dale un consejo corto (máximo 2 líneas), estratégico y motivador. \
            Sé empático pero energizante. Usa emojis ocasionales.",
            stats.username,
            stats.tokens_today,
            stats.tokens_average_last_7_days,
            stats.hours_streamed_today,
            stats.platform
        );

        self.call_ai_api(&prompt).await
    }

    /// Genera mensaje de felicitación usando IA
    async fn generate_congratulation_message(
        &self,
        stats: &ModelStats,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let prompt = format!(
            "Eres Beyorder, un coach energético de modelos webcam. \
            La modelo {} acaba de ROMPER su meta diaria!\n\
            - Tokens hoy: {} (Meta era: {})\n\
            - Plataforma: {}\n\n\
            Escribe una felicitación corta (1-2 líneas), enérgica y celebratoria. \
            Usa emojis para celebrar.",
            stats.username, stats.tokens_today, stats.daily_goal, stats.platform
        );

        self.call_ai_api(&prompt).await
    }

    /// Llamada genérica a la API de IA (OpenAI/DeepSeek compatible)
    async fn call_ai_api(&self, prompt: &str) -> Result<String, Box<dyn std::error::Error>> {
        let request = CreateChatCompletionRequestArgs::default()
            .model(&self.config.model)
            .messages(vec![
                ChatCompletionRequestMessage::System(
                    ChatCompletionRequestSystemMessageArgs::default()
                        .content("Eres Beyorder, un AI coach profesional para modelos webcam. Siempre respondes en español de forma concisa y motivadora.")
                        .build()?
                ),
                ChatCompletionRequestMessage::User(
                    ChatCompletionRequestUserMessageArgs::default()
                        .content(prompt)
                        .build()?
                ),
            ])
            .max_tokens(150_u16)
            .temperature(0.8)
            .build()?;

        let response = self.ai_client.chat().create(request).await?;

        let message = response
            .choices
            .first()
            .and_then(|choice| choice.message.content.clone())
            .ok_or("No response from AI")?;

        Ok(message)
    }

    /// Envía mensaje de coaching a la modelo vía chat
    async fn send_coaching_message(
        &self,
        user_id: i32,
        message: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Insertar mensaje en la tabla de chat con sender = Beyorder
        sqlx::query(
            r#"
            INSERT INTO chat_messages (sender_id, receiver_id, content, created_at)
            VALUES (
                (SELECT id FROM users WHERE username = 'beyorder' LIMIT 1),
                $1,
                $2,
                NOW()
            )
            "#,
        )
        .bind(user_id)
        .bind(message)
        .execute(&self.state.db)
        .await?;

        // Opcional: Guardar en Redis para notificación push
        if let Ok(mut conn) = self.state.redis.get().await {
            let notification_key = format!("notification:user:{}:beyorder", user_id);
            let _: () = conn.set(&notification_key, message).await?;
            let _: () = conn.expire(&notification_key, 86400).await?; // 24h
        }

        Ok(())
    }
}

/// Función helper para iniciar el observer en el main
pub async fn spawn_beyorder_observer(state: Arc<AppState>) {
    let observer = Arc::new(BeyorderObserver::new(state));
    
    tokio::spawn(async move {
        observer.start_observation_loop().await;
    });
}
