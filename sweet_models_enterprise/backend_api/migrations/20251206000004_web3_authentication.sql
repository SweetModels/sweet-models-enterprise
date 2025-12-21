-- ============================================================================
-- Sweet Models Enterprise - Web3 Authentication Support
-- Migration: Add blockchain authentication columns
-- ============================================================================

-- Add columns for Web3 authentication
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS wallet_address VARCHAR(255),
ADD COLUMN IF NOT EXISTS blockchain_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

-- Create unique index for wallet addresses (case-insensitive)
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_wallet_address_lower 
ON users (LOWER(wallet_address)) 
WHERE wallet_address IS NOT NULL;

-- Create index for blockchain type queries
CREATE INDEX IF NOT EXISTS idx_users_blockchain_type 
ON users (blockchain_type) 
WHERE blockchain_type IS NOT NULL;

-- Add comment to table
COMMENT ON COLUMN users.wallet_address IS 'Web3 wallet address (Ethereum, Solana, etc.)';
COMMENT ON COLUMN users.blockchain_type IS 'Blockchain type: ethereum, polygon, solana, binance';
COMMENT ON COLUMN users.last_login_at IS 'Last successful authentication timestamp';

-- Create table for Web3 authentication logs
CREATE TABLE IF NOT EXISTS web3_auth_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    wallet_address VARCHAR(255) NOT NULL,
    blockchain_type VARCHAR(50) NOT NULL,
    signature VARCHAR(512) NOT NULL,
    nonce VARCHAR(64) NOT NULL,
    ip_address INET,
    user_agent TEXT,
    authenticated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMPTZ
);

-- Create indexes for auth logs
CREATE INDEX IF NOT EXISTS idx_web3_auth_logs_user_id 
ON web3_auth_logs (user_id);

CREATE INDEX IF NOT EXISTS idx_web3_auth_logs_wallet_address 
ON web3_auth_logs (LOWER(wallet_address));

CREATE INDEX IF NOT EXISTS idx_web3_auth_logs_authenticated_at 
ON web3_auth_logs (authenticated_at DESC);

CREATE INDEX IF NOT EXISTS idx_web3_auth_logs_expires_at 
ON web3_auth_logs (expires_at) 
WHERE NOT revoked;

-- Add comments
COMMENT ON TABLE web3_auth_logs IS 'Audit log for Web3 authentication sessions';
COMMENT ON COLUMN web3_auth_logs.signature IS 'The cryptographic signature used for authentication';
COMMENT ON COLUMN web3_auth_logs.nonce IS 'One-time nonce used to prevent replay attacks';
COMMENT ON COLUMN web3_auth_logs.revoked IS 'TRUE if session was manually revoked (logout)';

-- Create function to automatically update last_login_at
CREATE OR REPLACE FUNCTION update_user_last_login()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users 
    SET last_login_at = NEW.authenticated_at
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic last_login update
DROP TRIGGER IF EXISTS trigger_update_last_login ON web3_auth_logs;
CREATE TRIGGER trigger_update_last_login
    AFTER INSERT ON web3_auth_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_user_last_login();

-- Create view for active Web3 sessions
CREATE OR REPLACE VIEW active_web3_sessions AS
SELECT 
    wal.id AS session_id,
    wal.user_id,
    u.email,
    wal.wallet_address,
    wal.blockchain_type,
    wal.authenticated_at,
    wal.expires_at,
    wal.ip_address,
    (wal.expires_at > NOW()) AS is_active,
    EXTRACT(EPOCH FROM (wal.expires_at - NOW())) AS seconds_until_expiry
FROM web3_auth_logs wal
JOIN users u ON u.id = wal.user_id
WHERE NOT wal.revoked
  AND wal.expires_at > NOW()
ORDER BY wal.authenticated_at DESC;

COMMENT ON VIEW active_web3_sessions IS 'Currently active Web3 authentication sessions';

-- Grant permissions (adjust as needed for your setup)
-- GRANT SELECT ON active_web3_sessions TO readonly_user;
-- GRANT ALL ON web3_auth_logs TO backend_app;
