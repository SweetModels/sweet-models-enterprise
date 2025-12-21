use axum::body::Bytes;
use chrono::{DateTime, Utc};
use pdf_lib::{BuiltinFont, Image, Mm, PdfDocument, ImageTransform};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;
use std::io::BufWriter;
use image::{GenericImageView};

use crate::state::AppState;

/// Tipos de contrato soportados
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ContractType {
    TermsV1,
    Nda,
    PenaltyAgreement,
}

impl ContractType {
    pub fn as_str(&self) -> &'static str {
        match self {
            ContractType::TermsV1 => "TERMS_V1",
            ContractType::Nda => "NDA",
            ContractType::PenaltyAgreement => "PENALTY_AGREEMENT",
        }
    }
}

impl std::fmt::Display for ContractType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

impl std::str::FromStr for ContractType {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_uppercase().as_str() {
            "TERMS_V1" => Ok(ContractType::TermsV1),
            "NDA" => Ok(ContractType::Nda),
            "PENALTY_AGREEMENT" => Ok(ContractType::PenaltyAgreement),
            other => Err(format!("Invalid contract type: {}", other)),
        }
    }
}

/// Registro persistido en la tabla legal_documents
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct LegalDocument {
    pub id: Uuid,
    pub user_id: Uuid,
    pub document_type: String,
    pub signed_at: DateTime<Utc>,
    pub signature_url: String,
    pub pdf_url: String,
    pub ip_address: Option<String>,
    pub created_at: DateTime<Utc>,
}

/// Payload necesario para generar y persistir un contrato
#[derive(Debug, Clone)]
pub struct ContractGenerationPayload {
    pub user_id: Uuid,
    pub full_name: String,
    pub national_id: String,
    pub contract_type: ContractType,
    pub signature_image: Bytes,
    pub ip_address: String,
}

#[derive(Debug, Error)]
pub enum ContractError {
    #[error("storage error: {0}")]
    Storage(#[from] crate::storage::StorageError),
    #[error("db error: {0}")]
    Db(#[from] sqlx::Error),
    #[error("image decode error: {0}")]
    Image(#[from] image::ImageError),
    #[error("pdf generation error: {0}")]
    Pdf(String),
}

const REGLAS_DE_HIERRO: &str = "1. Puntualidad: La modelo debe iniciar su turno a la hora pactada.\n\
2. Horarios: Respeto estricto del horario asignado y coordinado con Operaciones.\n\
3. Multas: Retrasos o ausencias no justificadas podrán implicar multas.\n\
4. Porcentajes: Participación sobre ingresos según contrato vigente.\n\
5. Confidencialidad: Prohibida la divulgación de información interna o de clientes.\n\
6. Conducta: Respeto absoluto a políticas de seguridad y buenas prácticas.\n\
7. Penalidades: Conductas graves podrán derivar en terminación inmediata del contrato.";

/// Genera el PDF, guarda firma + PDF en MinIO y persiste el registro en la BD
pub async fn generate_contract_pdf(
    state: &AppState,
    payload: ContractGenerationPayload,
) -> Result<LegalDocument, ContractError> {
    // 1) Subir la firma a MinIO (para trazabilidad)
    let signature_url = state
        .storage
        .upload_file(payload.signature_image.clone(), "png")
        .await?;

    // 2) Construir el PDF en memoria
    let pdf_bytes = build_pdf_bytes(&payload).map_err(ContractError::Pdf)?;

    // 3) Subir el PDF final a MinIO
    let pdf_url = state
        .storage
        .upload_file(Bytes::from(pdf_bytes.clone()), "pdf")
        .await?;

    let now = Utc::now();

    // 4) Persistir registro
    let document = sqlx::query_as::<_, LegalDocument>(
        r#"INSERT INTO legal_documents
        (user_id, document_type, signed_at, signature_url, pdf_url, ip_address)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id, user_id, document_type, signed_at, signature_url, pdf_url, ip_address, created_at"#,
    )
    .bind(payload.user_id)
    .bind(payload.contract_type.as_str())
    .bind(now)
    .bind(&signature_url)
    .bind(&pdf_url)
    .bind(&payload.ip_address)
    .fetch_one(&state.db)
    .await?;

    // 5) Flag para middleware: si firma los términos marcamos el flag
    if matches!(payload.contract_type, ContractType::TermsV1) {
        let _ = sqlx::query("UPDATE users SET has_signed_terms = TRUE WHERE id = $1")
            .bind(payload.user_id)
            .execute(&state.db)
            .await?;
    }

    Ok(document)
}

fn build_pdf_bytes(payload: &ContractGenerationPayload) -> Result<Vec<u8>, String> {
    let (doc, page1, layer1) =
        PdfDocument::new("Contrato Sweet Models", Mm(210.0_f32), Mm(297.0_f32), "Layer 1");

    let font = doc
        .add_builtin_font(BuiltinFont::Helvetica)
        .map_err(|e| format!("Font error: {e}"))?;

    let current_layer = doc.get_page(page1).get_layer(layer1);

    // Header
    let mut cursor_y: f32 = 280.0;
    write_line(&current_layer, &font, 16.0, 20.0, cursor_y, "Contrato de Vinculación");
    cursor_y -= 10.0;
    write_line(
        &current_layer,
        &font,
        11.0,
        20.0,
        cursor_y,
        &format!("Tipo: {}", payload.contract_type),
    );
    cursor_y -= 8.0;
    write_line(
        &current_layer,
        &font,
        11.0,
        20.0,
        cursor_y,
        &format!("Modelo: {}", payload.full_name),
    );
    cursor_y -= 8.0;
    write_line(
        &current_layer,
        &font,
        11.0,
        20.0,
        cursor_y,
        &format!("Documento: {}", payload.national_id),
    );
    cursor_y -= 8.0;
    write_line(
        &current_layer,
        &font,
        10.0,
        20.0,
        cursor_y,
        &format!("Fecha de firma: {}", Utc::now().format("%Y-%m-%d %H:%M UTC")),
    );
    cursor_y -= 14.0;

    // Reglas de hierro
    write_multiline(
        &current_layer,
        &font,
        11.0,
        20.0,
        &mut cursor_y,
        "Reglas de Hierro",
    );
    cursor_y -= 6.0;
    write_paragraph(
        &current_layer,
        &font,
        10.5,
        20.0,
        &mut cursor_y,
        REGLAS_DE_HIERRO,
    );

    cursor_y -= 10.0;
    write_multiline(
        &current_layer,
        &font,
        11.0,
        20.0,
        &mut cursor_y,
        "Declaración",
    );
    cursor_y -= 6.0;
    let declaration = format!(
        "Yo, {name} (CC {doc}), acepto las Reglas de Hierro, porcentajes y penalidades.\nAutorizo a Sweet Models Enterprise a custodiar este documento y a usar mi firma para su validez legal.",
        name = payload.full_name,
        doc = payload.national_id,
    );
    write_paragraph(
        &current_layer,
        &font,
        10.0,
        20.0,
        &mut cursor_y,
        &declaration,
    );

    // Firma
    cursor_y -= 20.0;
    add_signature_image(&current_layer, &payload.signature_image, &font, cursor_y)?;

    let mut writer = BufWriter::new(Vec::<u8>::new());
    doc.save(&mut writer)
        .map_err(|e| format!("Error saving PDF: {e}"))?;
    writer
        .into_inner()
        .map_err(|e| format!("Buffer error: {e}"))
}

fn write_line(layer: &pdf_lib::PdfLayerReference, font: &pdf_lib::IndirectFontRef, size: f32, x: f32, y: f32, text: &str) {
    layer.use_text(text, size, Mm(x), Mm(y), font);
}

fn write_multiline(
    layer: &pdf_lib::PdfLayerReference,
    font: &pdf_lib::IndirectFontRef,
    size: f32,
    x: f32,
    cursor_y: &mut f32,
    text: &str,
) {
    for line in text.lines() {
        layer.use_text(line, size, Mm(x), Mm(*cursor_y), font);
        *cursor_y -= 6.0;
    }
}

fn write_paragraph(
    layer: &pdf_lib::PdfLayerReference,
    font: &pdf_lib::IndirectFontRef,
    size: f32,
    x: f32,
    cursor_y: &mut f32,
    text: &str,
) {
    for line in text.split('\n') {
        layer.use_text(line, size, Mm(x), Mm(*cursor_y), font);
        *cursor_y -= 5.5;
    }
}

fn add_signature_image(
    layer: &pdf_lib::PdfLayerReference,
    signature_image: &Bytes,
    font: &pdf_lib::IndirectFontRef,
    cursor_y: f32,
) -> Result<(), String> {
    let dyn_img = image::load_from_memory(signature_image)
        .map_err(|e| format!("Signature decode error: {e}"))?;
    let (width, _height) = dyn_img.dimensions();

    let target_width_mm = 80.0;
    let scale = target_width_mm / width as f32;

    let image = Image::from_dynamic_image(&dyn_img);

    let transform = ImageTransform {
        translate_x: Some(Mm(20.0)),
        translate_y: Some(Mm(cursor_y)),
        scale_x: Some(scale),
        scale_y: Some(scale),
        ..Default::default()
    };

    image.add_to_layer(layer.clone(), transform);

    layer.use_text("Firma de la modelo", 9.0, Mm(20.0), Mm(cursor_y - 6.0), font);
    Ok(())
}
