use sqlx::PgPool;
use mongodb::Client as MongoClient;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub mongo: MongoClient,
}
