use sqlx::{Pool, Postgres, MySql};
use mongodb::Client as MongoClient;
use deadpool_redis::Pool as RedisPool;
use aws_sdk_s3::Client as S3Client;

#[derive(Clone)]
pub struct AppState {
    pub db: Pool<Postgres>,      // DB Principal (Usuarios/Dinero)
    pub mongo: MongoClient,      // Logs/Chats
    pub redis: RedisPool,        // Caché/Sesiones
    pub mysql: Pool<MySql>,      // Respaldo/Legacy
    pub s3: S3Client,            // Cliente único para los 4 buckets
}
