-- Finance schema v2: Colombian payment rails + admin FX settings

-- Enum for Colombian payment methods
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
        CREATE TYPE payment_method AS ENUM ('NEQUI', 'BANCOLOMBIA', 'DAVIPLATA', 'EFECTIVO', 'USDT');
    END IF;
END$$;

-- System settings holding admin-controlled FX rates
CREATE TABLE IF NOT EXISTS system_settings (
    id INTEGER PRIMARY KEY DEFAULT 1,
    admin_base_rate NUMERIC(12,4) NOT NULL DEFAULT 4000, -- COP per USD defined by admin
    current_dollar_rate NUMERIC(12,4) NOT NULL DEFAULT 4000, -- Binance/market price for reference
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT system_settings_singleton CHECK (id = 1)
);

-- Ensure singleton row exists
INSERT INTO system_settings (id, admin_base_rate, current_dollar_rate)
VALUES (1, 4000, 4000)
ON CONFLICT (id) DO NOTHING;

-- User payment preferences for mixed rails
CREATE TABLE IF NOT EXISTS user_payment_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    method payment_method NOT NULL,
    account_number TEXT NOT NULL,
    account_type TEXT, -- Ahorros/Corriente or empty for wallets
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_payment_details_user ON user_payment_details(user_id);
CREATE INDEX IF NOT EXISTS idx_user_payment_details_method ON user_payment_details(method);

-- Only one default method per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_payment_default
    ON user_payment_details(user_id)
    WHERE is_default = TRUE;

-- Maintain updated_at
CREATE OR REPLACE FUNCTION set_timestamp_user_payment_details()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_payment_details_updated_at ON user_payment_details;
CREATE TRIGGER trg_user_payment_details_updated_at
    BEFORE UPDATE ON user_payment_details
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_user_payment_details();
