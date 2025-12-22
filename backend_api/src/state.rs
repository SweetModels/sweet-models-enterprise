use sqlx::{Pool, Postgres, MySql};
use mongodb::Client as MongoClient;
use deadpool_redis::Pool as RedisPool;
use aws_sdk_s3::Client as S3Client;

#[derive(Clone)]
pub struct AppState {
    pub db: Pool<Postgres>,
    pub mongo: MongoClient,
    pub redis: RedisPool,
    pub mysql: Pool<MySql>,
    pub s3: S3Client,
}
