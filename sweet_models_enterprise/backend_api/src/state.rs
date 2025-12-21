use sqlx::PgPool;
use crate::storage::StorageService;
use crate::realtime::RealtimeHub;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub redis: deadpool_redis::Pool,
    pub nats: async_nats::Client,
    pub storage: StorageService,
    pub realtime_hub: Arc<RealtimeHub>,
}
