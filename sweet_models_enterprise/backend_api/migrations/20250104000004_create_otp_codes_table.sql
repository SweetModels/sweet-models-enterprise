-- Sistema de verificación SMS con códigos OTP
CREATE TABLE IF NOT EXISTS otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_otp_phone ON otp_codes(phone_number);
CREATE INDEX IF NOT EXISTS idx_otp_expires ON otp_codes(expires_at);

-- Agregar campo phone_verified a la tabla users
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE;

-- Comentarios para documentación
COMMENT ON TABLE otp_codes IS 'Códigos OTP para verificación de teléfono (SMS 2FA)';
COMMENT ON COLUMN otp_codes.code IS 'Código de 6 dígitos enviado por SMS';
COMMENT ON COLUMN otp_codes.expires_at IS 'Expira después de 10 minutos';
COMMENT ON COLUMN otp_codes.used IS 'Marca si el código ya fue usado';
