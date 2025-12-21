use std::sync::Arc;

use axum::{body::Bytes, extract::Multipart, http::StatusCode, Json};
use mime_guess::mime;
use s3::{creds::Credentials, error::S3Error, Bucket, Region};
use serde::Serialize;
use thiserror::Error;
use uuid::Uuid;

use crate::state::AppState;

const DEFAULT_BUCKET: &str = "sweet-media";

#[derive(Clone)]
pub struct StorageService {
    bucket: Bucket,
    public_base: String,
}

#[derive(Debug, Error)]
pub enum StorageError {
    #[error("storage configuration error: {0}")]
    Config(String),
    #[error(transparent)]
    S3(#[from] S3Error),
}

impl StorageService {
    pub fn from_env() -> Result<Self, StorageError> {
        let endpoint = std::env::var("MINIO_ENDPOINT")
            .unwrap_or_else(|_| "http://localhost:9000".to_string());
        let access_key = std::env::var("MINIO_ROOT_USER").unwrap_or_else(|_| "admin".to_string());
        let secret_key = std::env::var("MINIO_ROOT_PASSWORD")
            .unwrap_or_else(|_| "password_super_seguro".to_string());

        let public_base = std::env::var("MINIO_PUBLIC_BASE")
            .unwrap_or_else(|_| format!("{}/{DEFAULT_BUCKET}", endpoint.trim_end_matches('/')));

        let region = Region::Custom {
            region: "us-east-1".to_string(),
            endpoint: endpoint.clone(),
        };

        let credentials = Credentials::new(Some(&access_key), Some(&secret_key), None, None, None)
            .map_err(|e| StorageError::Config(e.to_string()))?;

        let mut bucket = Bucket::new(DEFAULT_BUCKET, region, credentials).map_err(StorageError::S3)?;
        bucket.set_path_style(); // MinIO necesita path-style

        Ok(Self { bucket, public_base })
    }

    pub async fn upload_file(&self, file_data: Bytes, extension: &str) -> Result<String, StorageError> {
        let safe_ext = extension.trim_start_matches('.').to_ascii_lowercase();
        let file_name = if safe_ext.is_empty() {
            Uuid::new_v4().to_string()
        } else {
            format!("{}.{}", Uuid::new_v4(), safe_ext)
        };

        // Mejor esfuerzo de content-type
        let content_type = mime_guess::from_ext(&safe_ext)
            .first_or(mime::APPLICATION_OCTET_STREAM)
            .essence_str()
            .to_string();

        self.bucket
            .put_object_with_content_type(&file_name, &file_data, content_type.as_str())
            .await
            .map_err(StorageError::S3)?;

        let url = format!("{}/{}", self.public_base.trim_end_matches('/'), file_name);
        Ok(url)
    }
}

#[derive(Serialize)]
pub struct UploadResponse {
    pub url: String,
}

pub async fn upload_handler(
    axum::extract::State(state): axum::extract::State<Arc<AppState>>,
    mut multipart: Multipart,
) -> Result<Json<UploadResponse>, (StatusCode, String)> {
    while let Some(field) = multipart.next_field().await.map_err(internal_error)? {
        let field = field;
        if field.name() == Some("file") {
            let file_name = field.file_name().unwrap_or("upload").to_string();
            let ext = std::path::Path::new(&file_name)
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("");

            let data = field.bytes().await.map_err(internal_error)?;
            let url = state
                .storage
                .upload_file(data, ext)
                .await
                .map_err(internal_error)?;

            return Ok(Json(UploadResponse { url }));
        }
    }

    Err((StatusCode::BAD_REQUEST, "file field is required".to_string()))
}

fn internal_error<E: std::fmt::Display>(err: E) -> (StatusCode, String) {
    (StatusCode::INTERNAL_SERVER_ERROR, err.to_string())
}