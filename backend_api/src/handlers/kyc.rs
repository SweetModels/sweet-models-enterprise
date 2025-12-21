use axum::{
    extract::{multipart::MultipartError, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::PgPool;
use tracing::{error, info, warn};
use uuid::Uuid;

use crate::services::{
    jwt::{validate_jwt, JwtError},
    storage::S3Storage,
};

#[derive(Debug, Deserialize)]
pub struct KycUploadRequest {
    pub document_type: String, // cédula, pasaporte, licencia
}

#[derive(Debug, Serialize)]
pub struct KycUploadResponse {
    pub message: String,
    pub document_url: String,
    pub uploaded_at: String,
}

/// POST /api/model/upload-kyc
/// Subir documento KYC (Cédula, Pasaporte, etc.) a S3
/// 
/// # Multipart Form Data:
/// - field "file": archivo de imagen
/// - field "document_type": tipo de documento (cedula, pasaporte, licencia)
pub async fn upload_kyc(
    State(pool): State<PgPool>,
    State(s3_storage): State<S3Storage>,
    headers: axum::http::HeaderMap,
    mut multipart: axum::extract::Multipart,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    // Validar bearer token
    let auth_header = headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Missing Authorization header",
                "message": "Token requerido"
            })),
        ))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .or_else(|| auth_header.strip_prefix("bearer "))
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Invalid Authorization header",
                "message": "Token inválido"
            })),
        ))?;

    let claims = match validate_jwt(token) {
        Ok(c) => c,
        Err(JwtError::TokenExpired) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Token expired",
                    "message": "Tu sesión expiró"
                })),
            ))
        }
        Err(_) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid token",
                    "message": "Token inválido"
                })),
            ))
        }
    };

    let user_id = Uuid::parse_str(&claims.sub).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Invalid user ID",
                "message": "ID de usuario inválido"
            })),
        )
    })?;

    info!(
        "📄 KYC upload request from user: {} ({})",
        user_id, claims.email
    );

    let mut document_type = String::new();
    let mut file_bytes: Option<Vec<u8>> = None;

    // Procesar multipart form data
    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| {
            error!("❌ Multipart error: {}", e);
            (
                StatusCode::BAD_REQUEST,
                Json(json!({
                    "error": "Invalid form data",
                    "message": "Error al procesar el archivo"
                })),
            )
        })?
    {
        let field_name = field.name().unwrap_or("").to_string();

        match field_name.as_str() {
            "document_type" => {
                document_type = field
                    .text()
                    .await
                    .map_err(|_| {
                        (
                            StatusCode::BAD_REQUEST,
                            Json(json!({
                                "error": "Invalid document_type",
                                "message": "Tipo de documento inválido"
                            })),
                        )
                    })?
                    .trim()
                    .to_lowercase();
                info!("📝 Document type: {}", document_type);
            }
            "file" => {
                let bytes = field.bytes().await.map_err(|_| {
                    (
                        StatusCode::BAD_REQUEST,
                        Json(json!({
                            "error": "Invalid file",
                            "message": "Error al leer el archivo"
                        })),
                    )
                })?;

                if bytes.is_empty() {
                    return Err((
                        StatusCode::BAD_REQUEST,
                        Json(json!({
                            "error": "Empty file",
                            "message": "El archivo está vacío"
                        })),
                    ));
                }

                // Validar tamaño (máx 10MB)
                if bytes.len() > 10 * 1024 * 1024 {
                    warn!(
                        "⚠️ File too large: {} bytes (user: {})",
                        bytes.len(),
                        user_id
                    );
                    return Err((
                        StatusCode::BAD_REQUEST,
                        Json(json!({
                            "error": "File too large",
                            "message": "El archivo no puede exceder 10MB"
                        })),
                    ));
                }

                file_bytes = Some(bytes.to_vec());
                info!("📦 File received: {} bytes", bytes.len());
            }
            _ => {
                warn!("⚠️ Unknown field in multipart: {}", field_name);
            }
        }
    }

    // Validar que se recibieron ambos campos
    if document_type.is_empty() {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Missing document_type",
                "message": "Especifica el tipo de documento"
            })),
        ));
    }

    let file_bytes = file_bytes.ok_or((
        StatusCode::BAD_REQUEST,
        Json(json!({
            "error": "Missing file",
            "message": "Selecciona un archivo"
        })),
    ))?;

    // Determinar extensión basada en tipo de documento (validar MIME type)
    let extension = detect_image_extension(&file_bytes).unwrap_or("jpg".to_string());

    // Generar nombre único en S3
    let s3_filename = S3Storage::generate_kyc_filename(user_id, &extension);

    // Subir a S3
    let document_url = match s3_storage
        .upload_file(file_bytes, &s3_filename)
        .await
    {
        Ok(url) => {
            info!("✅ File uploaded to S3: {}", url);
            url
        }
        Err(e) => {
            error!("❌ S3 upload failed: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Upload failed",
                    "message": "Error al subir el archivo a la nube"
                })),
            ));
        }
    };

    // Guardar URL en base de datos
    let now = chrono::Utc::now();
    let query_result = sqlx::query(
        r#"
        UPDATE users 
        SET kyc_document_url = $1, kyc_document_type = $2, kyc_uploaded_at = $3
        WHERE id = $4
        "#,
    )
    .bind(&document_url)
    .bind(&document_type)
    .bind(now)
    .bind(user_id)
    .execute(&pool)
    .await;

    match query_result {
        Ok(result) if result.rows_affected() > 0 => {
            info!(
                "✅ KYC document saved for user {} (type: {})",
                user_id, document_type
            );
            Ok((
                StatusCode::OK,
                Json(KycUploadResponse {
                    message: "Documento enviado a revisión".to_string(),
                    document_url,
                    uploaded_at: now.to_rfc3339(),
                }),
            ))
        }
        Ok(_) => {
            error!("User not found: {}", user_id);
            Err((
                StatusCode::NOT_FOUND,
                Json(json!({
                    "error": "User not found",
                    "message": "Usuario no encontrado"
                })),
            ))
        }
        Err(e) => {
            error!("Database error: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Database error",
                    "message": "Error al guardar el documento"
                })),
            ))
        }
    }
}

/// Detectar extensión de imagen basada en magic bytes
fn detect_image_extension(file_bytes: &[u8]) -> Option<String> {
    if file_bytes.len() < 4 {
        return None;
    }

    match &file_bytes[0..4] {
        [0xFF, 0xD8, 0xFF, ..] => Some("jpg".to_string()),  // JPEG
        [0x89, 0x50, 0x4E, 0x47] => Some("png".to_string()), // PNG
        [0x47, 0x49, 0x46, ..] => Some("gif".to_string()),    // GIF
        [0x42, 0x4D, ..] => Some("bmp".to_string()),           // BMP
        _ => Some("jpg".to_string()),                          // Default
    }
}

/// GET /api/model/kyc-status
/// Obtener estado de verificación KYC
pub async fn get_kyc_status(
    State(pool): State<PgPool>,
    headers: axum::http::HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let auth_header = headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Missing Authorization header"
            })),
        ))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .or_else(|| auth_header.strip_prefix("bearer "))
        .ok_or((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Invalid Authorization header"
            })),
        ))?;

    let claims = match validate_jwt(token) {
        Ok(c) => c,
        Err(_) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid token"
                })),
            ))
        }
    };

    let user_id = Uuid::parse_str(&claims.sub).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Invalid user ID"
            })),
        )
    })?;

    #[derive(sqlx::FromRow)]
    struct KycStatus {
        kyc_document_url: Option<String>,
        kyc_verified_at: Option<chrono::DateTime<chrono::Utc>>,
        kyc_status: String,
    }

    let kyc_status: KycStatus = sqlx::query_as(
        r#"
        SELECT kyc_document_url, kyc_verified_at, kyc_status
        FROM users
        WHERE id = $1
        "#,
    )
    .bind(user_id)
    .fetch_one(&pool)
    .await
    .map_err(|e| {
        error!("Database error: {}", e);
        (
            StatusCode::NOT_FOUND,
            Json(json!({
                "error": "User not found"
            })),
        )
    })?;

    Ok(Json(json!({
        "has_document": kyc_status.kyc_document_url.is_some(),
        "document_url": kyc_status.kyc_document_url,
        "verified": kyc_status.kyc_status == "verified",
        "verified_at": kyc_status.kyc_verified_at,
        "status": kyc_status.kyc_status,
    })))
}
