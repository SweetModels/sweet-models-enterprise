-- Enable required extension for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Daily production ledger per model and platform
CREATE TABLE IF NOT EXISTS daily_production (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "date" DATE NOT NULL,
    platform VARCHAR(50) NOT NULL,
    token_amount INTEGER NOT NULL CHECK (token_amount >= 0),
    token_value_cop NUMERIC(14,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Avoid duplicate entries for the same (model, date, platform)
CREATE UNIQUE INDEX IF NOT EXISTS ux_daily_production_model_date_platform
ON daily_production (model_id, "date", platform);

-- Helpful index for queries by date
CREATE INDEX IF NOT EXISTS idx_daily_production_date
ON daily_production ("date");
