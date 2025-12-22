use tracing::{debug, error, info};
use uuid::Uuid;
use aws_sdk_s3::Client as S3Client;
use aws_sdk_s3::types::ByteStream;

/// Buckets soportados (configurados por variables de entorno)
#[derive(Clone, Copy, Debug)]
pub enum StorageBucket {
    Public,
    Kyc,
    Evidence,
    Backup,
}

impl StorageBucket {
    /// Devuelve el nombre del bucket según el tipo y variables de entorno
    pub fn resolve_name(self) -> String {
        match self {
            StorageBucket::Public => std::env::var("BUCKET_PUBLIC").unwrap_or_else(|_| "sme-public".to_string()),
            StorageBucket::Kyc => std::env::var("BUCKET_KYC").unwrap_or_else(|_| "sme-kyc".to_string()),
            StorageBucket::Evidence => std::env::var("BUCKET_EVIDENCE").unwrap_or_else(|_| "sme-evidence".to_string()),
            StorageBucket::Backup => std::env::var("BUCKET_BACKUP").unwrap_or_else(|_| "sme-backup".to_string()),
        }
    }
}

/// Servicio de almacenamiento con S3
#[derive(Clone)]
pub struct StorageService {
    pub s3: S3Client,
}

impl StorageService {
    pub fn new(s3: S3Client) -> Self { Self { s3 } }

    /// Subir archivo al bucket indicado. Retorna URL pública o del objeto.
    pub async fn upload_file(
        &self,
        bucket: StorageBucket,
        key: &str,
        bytes: Vec<u8>,
        content_type: Option<&str>,
    ) -> Result<String, String> {
        let bucket_name = bucket.resolve_name();
        debug!("📤 Uploading to bucket={}, key={}", bucket_name, key);

        let body = ByteStream::from(bytes.into());
        let mut req = self.s3.put_object()
            .bucket(bucket_name.clone())
            .key(key.to_string())
            .body(body);

        if let Some(ct) = content_type { req = req.content_type(ct.to_string()); }

        req.send().await.map_err(|e| {
            error!("S3 put_object error: {}", e);
            format!("S3 upload failed: {}", e)
        })?;

        let url = format!("https://{}.s3.amazonaws.com/{}", bucket_name, key);
        info!("✅ Uploaded: {}", url);
        Ok(url)
    }

    /// Borrar archivo del bucket correspondiente
    pub async fn delete_file(&self, bucket: StorageBucket, key: &str) -> Result<(), String> {
        let bucket_name = bucket.resolve_name();
        debug!("🗑️ Deleting from bucket={}, key={}", bucket_name, key);
        self.s3.delete_object()
            .bucket(bucket_name)
            .key(key.to_string())
            .send().await
            .map_err(|e| format!("S3 delete failed: {}", e))?;
        Ok(())
    }

    /// Generar nombre de archivo único para KYC
    pub fn generate_kyc_filename(user_id: Uuid, extension: &str) -> String {
        let file_id = Uuid::new_v4();
        format!("kyc/{}/{}.{}", user_id, file_id, extension)
    }
}
