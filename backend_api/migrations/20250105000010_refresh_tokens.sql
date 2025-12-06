-- Migration: Refresh Tokens Table
-- Description: Stores refresh tokens for JWT authentication with automatic cleanup

-- Create refresh_tokens table
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    device_info TEXT,
    ip_address TEXT,
    user_agent TEXT,
    
    -- Ensure only one active token per device per user
    CONSTRAINT unique_user_device UNIQUE (user_id, device_info)
);

-- Indexes for performance
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX idx_refresh_tokens_revoked ON refresh_tokens(revoked_at) WHERE revoked_at IS NULL;

-- Function to clean expired tokens (runs daily)
CREATE OR REPLACE FUNCTION cleanup_expired_refresh_tokens()
RETURNS void AS $$
BEGIN
    DELETE FROM refresh_tokens
    WHERE expires_at < NOW() OR revoked_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE refresh_tokens IS 'Stores refresh tokens for JWT authentication renewal';
COMMENT ON COLUMN refresh_tokens.token IS 'Hashed refresh token (SHA256)';
COMMENT ON COLUMN refresh_tokens.expires_at IS 'Token expiration timestamp (30 days default)';
COMMENT ON COLUMN refresh_tokens.device_info IS 'Device fingerprint for security';
