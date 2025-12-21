use sqlx::PgPool;
use mongodb::Client as MongoClient;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub redis: deadpool_redis::Pool,
    pub nats: async_nats::Client,
    pub mongo: MongoClient,
}
