-- Create table for legal documents and signature tracking
CREATE TABLE IF NOT EXISTS legal_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type VARCHAR(32) NOT NULL,
    signed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    signature_url TEXT NOT NULL,
    pdf_url TEXT NOT NULL,
    ip_address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT legal_documents_document_type_chk CHECK (document_type IN ('TERMS_V1', 'NDA', 'PENALTY_AGREEMENT')),
    CONSTRAINT legal_documents_user_document_unique UNIQUE (user_id, document_type)
);

-- Tracking flag to short-circuit middleware when the user already signed
ALTER TABLE users
ADD COLUMN IF NOT EXISTS has_signed_terms BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON TABLE legal_documents IS 'Stores immutable records of signed legal contracts and their PDF/signature artifacts.';
COMMENT ON COLUMN legal_documents.signature_url IS 'S3/MinIO URL pointing to the uploaded signature image used in the PDF.';
COMMENT ON COLUMN legal_documents.pdf_url IS 'S3/MinIO URL pointing to the generated PDF with the embedded signature.';
COMMENT ON COLUMN legal_documents.ip_address IS 'IP address captured at signing time to strengthen legal validity.';
