-- Sistema de verificación KYC (Know Your Customer)
CREATE TABLE IF NOT EXISTS kyc_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INTEGER NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    rejection_reason TEXT,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(id),
    UNIQUE(user_id, document_type)
);

-- Crear índices para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_kyc_user ON kyc_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_status ON kyc_documents(status);

-- Agregar campos de verificación KYC a users
ALTER TABLE users ADD COLUMN IF NOT EXISTS kyc_status VARCHAR(50) DEFAULT 'pending';
ALTER TABLE users ADD COLUMN IF NOT EXISTS kyc_verified_at TIMESTAMP WITH TIME ZONE;

-- Comentarios
COMMENT ON TABLE kyc_documents IS 'Documentos KYC para verificación de identidad';
COMMENT ON COLUMN kyc_documents.document_type IS 'Tipo: national_id_front, national_id_back, selfie, proof_address';
COMMENT ON COLUMN kyc_documents.status IS 'Estado: pending, approved, rejected';
