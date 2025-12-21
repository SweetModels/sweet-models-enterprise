-- Create zk_identities table for Schnorr-based login
CREATE TABLE IF NOT EXISTS zk_identities (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    public_commitment BYTEA NOT NULL
);

-- Remove legacy password storage
ALTER TABLE users DROP COLUMN IF EXISTS password_hash;
