-- Production logs table for tracking daily token generation
CREATE TABLE IF NOT EXISTS production_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    model_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    amount_tokens NUMERIC(15, 2) NOT NULL DEFAULT 0,
    tokens_earned NUMERIC(15, 2) NOT NULL DEFAULT 0,
    tokens_usd NUMERIC(15, 2) NOT NULL DEFAULT 0,
    production_date DATE NOT NULL DEFAULT CURRENT_DATE,
    entered_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for fast queries
CREATE INDEX IF NOT EXISTS idx_production_logs_group_id ON production_logs(group_id);
CREATE INDEX IF NOT EXISTS idx_production_logs_model_id ON production_logs(model_id);
CREATE INDEX IF NOT EXISTS idx_production_logs_date ON production_logs(date DESC);
CREATE INDEX IF NOT EXISTS idx_production_logs_production_date ON production_logs(production_date DESC);
CREATE INDEX IF NOT EXISTS idx_production_logs_entered_by ON production_logs(entered_by);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_production_logs_model_date ON production_logs(model_id, production_date DESC);
CREATE INDEX IF NOT EXISTS idx_production_logs_group_date ON production_logs(group_id, date DESC);

COMMENT ON TABLE production_logs IS 'Daily production token tracking for models and groups';
COMMENT ON COLUMN production_logs.amount_tokens IS 'Legacy column for group-based tracking';
COMMENT ON COLUMN production_logs.tokens_earned IS 'Tokens earned by model (for individual tracking)';
COMMENT ON COLUMN production_logs.tokens_usd IS 'USD value of tokens earned';
COMMENT ON COLUMN production_logs.date IS 'Legacy date column';
COMMENT ON COLUMN production_logs.production_date IS 'Production date (primary date field)';
