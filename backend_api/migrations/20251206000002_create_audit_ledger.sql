-- ============================================================================
-- AUDIT LEDGER TABLE - Blockchain para Inmutabilidad Financiera
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prev_hash VARCHAR(128) NOT NULL,
    data JSONB NOT NULL,
    nonce BIGINT NOT NULL,
    hash VARCHAR(128) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT audit_ledger_hash_valid CHECK (hash ~ '^[a-f0-9]{128}$'),
    CONSTRAINT audit_ledger_prev_hash_valid CHECK (prev_hash ~ '^[a-f0-9]{128}$|^0$')
);

CREATE INDEX idx_audit_ledger_user_id ON audit_ledger ((data ->> 'user_id'));
CREATE INDEX idx_audit_ledger_created_at ON audit_ledger (created_at DESC);
CREATE INDEX idx_audit_ledger_tx_type ON audit_ledger ((data ->> 'tx_type'));
CREATE UNIQUE INDEX idx_audit_ledger_hash ON audit_ledger (hash);
CREATE INDEX idx_audit_ledger_prev_hash ON audit_ledger (prev_hash);

CREATE OR REPLACE VIEW user_transaction_audit AS
SELECT
    id AS block_id,
    data->>'user_id' AS user_id,
    data->>'tx_type' AS transaction_type,
    (data->>'amount')::NUMERIC AS amount,
    data->>'currency' AS currency,
    data->>'description' AS description,
    created_at,
    hash,
    prev_hash
FROM audit_ledger
ORDER BY created_at DESC;

CREATE OR REPLACE VIEW ledger_chain_status AS
SELECT
    COUNT(*) AS total_blocks,
    MAX(created_at) AS last_block_timestamp,
    COUNT(DISTINCT prev_hash) AS unique_prev_hashes,
    COUNT(DISTINCT hash) AS unique_hashes
FROM audit_ledger;

CREATE OR REPLACE FUNCTION get_last_block()
RETURNS TABLE (
    id UUID,
    prev_hash VARCHAR,
    data JSONB,
    nonce BIGINT,
    hash VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
SELECT id, prev_hash, data, nonce, hash, created_at
FROM audit_ledger
ORDER BY created_at DESC
LIMIT 1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION count_user_transactions(user_uuid UUID)
RETURNS INTEGER AS $$
SELECT COUNT(*)::INTEGER
FROM audit_ledger
WHERE data->>'user_id' = user_uuid::TEXT;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_user_transaction_summary(user_uuid UUID)
RETURNS TABLE (
    tx_type TEXT,
    count INTEGER,
    total_amount NUMERIC,
    currency TEXT
) AS $$
SELECT
    data->>'tx_type' AS tx_type,
    COUNT(*)::INTEGER AS count,
    SUM((data->>'amount')::NUMERIC) AS total_amount,
    data->>'currency' AS currency
FROM audit_ledger
WHERE data->>'user_id' = user_uuid::TEXT
GROUP BY data->>'tx_type', data->>'currency';
$$ LANGUAGE SQL;

CREATE TABLE IF NOT EXISTS ledger_integrity_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_blocks INTEGER NOT NULL,
    is_valid BOOLEAN NOT NULL,
    issues_found TEXT,
    checked_by VARCHAR(255)
);

CREATE INDEX idx_integrity_checks_created_at ON ledger_integrity_checks (check_created_at DESC);
