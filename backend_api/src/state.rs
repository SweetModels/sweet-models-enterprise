use sqlx::PgPool;
use mongodb::Client as MongoClient;
use deadpool_redis::Pool as RedisPool;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub mongo: MongoClient,
    pub redis: RedisPool,
}
