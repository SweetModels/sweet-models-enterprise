-- ============================================================================
-- Sweet Models Enterprise - Treasury Module Database Schema
-- Transacciones financieras y balance de usuarios
-- ============================================================================

CREATE TYPE transaction_type AS ENUM ('EARNING', 'WITHDRAWAL', 'PENALTY');

-- ============================================================================
-- TABLA: transactions (Registro de todas las transacciones)
-- ============================================================================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(20, 8) NOT NULL, -- Cantidad (positiva o negativa)
    type transaction_type NOT NULL,
    reference TEXT, -- Descripción de la transacción
    blockchain_tx_hash TEXT, -- Hash de transacción en blockchain (si aplica)
    status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING, CONFIRMED, FAILED
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Validaciones
    CONSTRAINT chk_amount_precision CHECK (amount != 0)
);

CREATE INDEX idx_transactions_user ON transactions(user_id, created_at DESC);
CREATE INDEX idx_transactions_type ON transactions(type, created_at DESC);
CREATE INDEX idx_transactions_status ON transactions(status, created_at DESC);
CREATE INDEX idx_transactions_blockchain ON transactions(blockchain_tx_hash) WHERE blockchain_tx_hash IS NOT NULL;

-- ============================================================================
-- TABLA: balance_cache (Cache del balance actual por usuario)
-- ============================================================================
CREATE TABLE IF NOT EXISTS balance_cache (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    total_balance DECIMAL(20, 8) NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- TABLA: withdrawal_requests (Solicitudes de retiro pendientes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount_usdt DECIMAL(20, 2) NOT NULL,
    wallet_address TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING, APPROVED, SENT, COMPLETED, REJECTED
    transaction_id UUID REFERENCES transactions(id),
    blockchain_tx_hash TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Validaciones
    CONSTRAINT chk_withdraw_amount CHECK (amount_usdt > 0)
);

CREATE INDEX idx_withdrawal_requests_user ON withdrawal_requests(user_id, created_at DESC);
CREATE INDEX idx_withdrawal_requests_status ON withdrawal_requests(status, created_at DESC);
CREATE INDEX idx_withdrawal_requests_blockchain ON withdrawal_requests(blockchain_tx_hash) WHERE blockchain_tx_hash IS NOT NULL;

-- ============================================================================
-- FUNCIÓN: update_balance_cache()
-- Actualizar cache de balance cuando hay nueva transacción
-- ============================================================================
CREATE OR REPLACE FUNCTION update_balance_cache()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO balance_cache (user_id, total_balance, last_updated)
    SELECT 
        NEW.user_id,
        COALESCE(SUM(amount), 0),
        NOW()
    FROM transactions
    WHERE user_id = NEW.user_id
    ON CONFLICT (user_id) DO UPDATE SET
        total_balance = EXCLUDED.total_balance,
        last_updated = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_balance_cache
    AFTER INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_balance_cache();

-- ============================================================================
-- FUNCIÓN: update_updated_at_column()
-- Actualizar timestamp automáticamente
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_withdrawal_requests_updated_at
    BEFORE UPDATE ON withdrawal_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
