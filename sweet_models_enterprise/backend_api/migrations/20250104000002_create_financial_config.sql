-- Financial configuration table (TRM and other financial parameters)
CREATE TABLE IF NOT EXISTS financial_config (
    id SERIAL PRIMARY KEY,
    config_key TEXT UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- Insert default TRM value
INSERT INTO financial_config (config_key, config_value, description)
VALUES ('trm_daily', '4000', 'Tasa Representativa del Mercado (TRM) diaria')
ON CONFLICT (config_key) DO NOTHING;

-- Create index for fast config lookups
CREATE INDEX IF NOT EXISTS idx_financial_config_key ON financial_config(config_key);
