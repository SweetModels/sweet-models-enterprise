use tracing::{debug, error, info};
use uuid::Uuid;
use aws_sdk_s3::Client as S3Client;
use aws_sdk_s3::primitives::ByteStream;

/// Tipos de bucket soportados
#[derive(Clone, Copy, Debug)]
pub enum BucketType {
    Public,   // BUCKET_PUBLIC
    Kyc,      // BUCKET_KYC
    Evidence, // BUCKET_EVIDENCE
    Backup,   // BUCKET_BACKUP
}

/// Obtiene el nombre del bucket según el tipo usando variables de entorno
pub fn get_bucket_name(bucket: BucketType) -> String {
    match bucket {
        BucketType::Public => std::env::var("BUCKET_PUBLIC").unwrap_or_else(|_| "sme-public".to_string()),
        BucketType::Kyc => std::env::var("BUCKET_KYC").unwrap_or_else(|_| "sme-kyc".to_string()),
        BucketType::Evidence => std::env::var("BUCKET_EVIDENCE").unwrap_or_else(|_| "sme-evidence".to_string()),
        BucketType::Backup => std::env::var("BUCKET_BACKUP").unwrap_or_else(|_| "sme-backup".to_string()),
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
        bucket: BucketType,
        key: &str,
        bytes: Vec<u8>,
        content_type: Option<&str>,
    ) -> Result<String, String> {
        let bucket_name = get_bucket_name(bucket);
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
    pub async fn delete_file(&self, bucket: BucketType, key: &str) -> Result<(), String> {
        let bucket_name = get_bucket_name(bucket);
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
