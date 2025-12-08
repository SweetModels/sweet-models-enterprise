-- ============================================================================
-- AUDIT LEDGER TABLE - Blockchain para Inmutabilidad Financiera
-- ============================================================================
-- Este esquema implementa una cadena de bloques criptográfica para garantizar
-- la inmutabilidad e integridad de todas las transacciones financieras.

CREATE TABLE IF NOT EXISTS audit_ledger (
    -- Identificador único del bloque
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Hash SHA3-512 del bloque anterior (encadenamiento)
    prev_hash VARCHAR(128) NOT NULL,

    -- Datos de la transacción en formato JSON
    -- Estructura: { tx_type, user_id, amount, currency, description, metadata }
    data JSONB NOT NULL,

    -- Nonce para prueba de trabajo (timestamp-based)
    nonce BIGINT NOT NULL,

    -- Hash SHA3-512 del bloque completo (id + prev_hash + data + nonce)
    hash VARCHAR(128) NOT NULL UNIQUE,

    -- Timestamp de creación del bloque
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Índices para búsqueda y auditoría
    CONSTRAINT audit_ledger_hash_valid CHECK (hash ~ '^[a-f0-9]{128}$'),
    CONSTRAINT audit_ledger_prev_hash_valid CHECK (prev_hash ~ '^[a-f0-9]{128}$|^0$')
);

-- Índice para búsqueda por usuario
CREATE INDEX idx_audit_ledger_user_id ON audit_ledger USING GIN ((data -> 'user_id'));

-- Índice para búsqueda por timestamp (orden cronológico)
CREATE INDEX idx_audit_ledger_timestamp ON audit_ledger (timestamp DESC);

-- Índice para búsqueda por tipo de transacción
CREATE INDEX idx_audit_ledger_tx_type ON audit_ledger USING GIN ((data ->> 'tx_type'));

-- Índice para búsqueda por hash (validación de integridad)
CREATE UNIQUE INDEX idx_audit_ledger_hash ON audit_ledger (hash);

-- Índice para búsqueda por prev_hash (encadenamiento)
CREATE INDEX idx_audit_ledger_prev_hash ON audit_ledger (prev_hash);

-- Vista para auditoría de transacciones por usuario
CREATE OR REPLACE VIEW user_transaction_audit AS
SELECT
    id AS block_id,
    data->>'user_id' AS user_id,
    data->>'tx_type' AS transaction_type,
    (data->>'amount')::NUMERIC AS amount,
    data->>'currency' AS currency,
    data->>'description' AS description,
    timestamp,
    hash,
    prev_hash
FROM audit_ledger
ORDER BY timestamp DESC;

-- Vista para verificar integridad de cadena
CREATE OR REPLACE VIEW ledger_chain_status AS
SELECT
    COUNT(*) AS total_blocks,
    MAX(timestamp) AS last_block_timestamp,
    COUNT(DISTINCT prev_hash) AS unique_prev_hashes,
    COUNT(DISTINCT hash) AS unique_hashes
FROM audit_ledger;

-- Función para obtener el último bloque
CREATE OR REPLACE FUNCTION get_last_block()
RETURNS TABLE (
    id UUID,
    prev_hash VARCHAR,
    data JSONB,
    nonce BIGINT,
    hash VARCHAR,
    timestamp TIMESTAMP WITH TIME ZONE
) AS $$
SELECT id, prev_hash, data, nonce, hash, timestamp
FROM audit_ledger
ORDER BY timestamp DESC
LIMIT 1;
$$ LANGUAGE SQL;

-- Función para contar transacciones por usuario
CREATE OR REPLACE FUNCTION count_user_transactions(user_uuid UUID)
RETURNS INTEGER AS $$
SELECT COUNT(*)::INTEGER
FROM audit_ledger
WHERE data->>'user_id' = user_uuid::TEXT;
$$ LANGUAGE SQL;

-- Función para calcular total de transacciones por usuario y tipo
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

-- Tabla de logs de integridad para auditoría de verificaciones
CREATE TABLE IF NOT EXISTS ledger_integrity_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_blocks INTEGER NOT NULL,
    is_valid BOOLEAN NOT NULL,
    issues_found TEXT,
    checked_by VARCHAR(255)
);

-- Índice para búsqueda de verificaciones por timestamp
CREATE INDEX idx_integrity_checks_timestamp ON ledger_integrity_checks (check_timestamp DESC);

-- ============================================================================
-- DATOS DE EJEMPLO (comentados)
-- ============================================================================
-- INSERT INTO audit_ledger (prev_hash, data, nonce, hash) VALUES
-- ('0', '{"tx_type": "payment", "user_id": "550e8400-e29b-41d4-a716-446655440000", "amount": 100.50, "currency": "COP", "description": "Pago inicial"}', 1702000000000000000, 'hash_placeholder_1');
