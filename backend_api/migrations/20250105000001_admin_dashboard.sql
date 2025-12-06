-- Migration: Admin Dashboard and Export Support
-- Description: Views and tables for administrative reporting and data export

-- Create export_logs table to track data exports
CREATE TABLE IF NOT EXISTS export_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    export_type VARCHAR(50) NOT NULL, -- 'payroll', 'production', 'users', 'audit', 'contracts'
    format VARCHAR(20) NOT NULL, -- 'csv', 'excel', 'pdf', 'json'
    filters JSONB, -- Export filters/parameters
    file_size INTEGER, -- bytes
    record_count INTEGER,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    file_path TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Create system_stats table for dashboard metrics
CREATE TABLE IF NOT EXISTS system_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stat_date DATE NOT NULL UNIQUE,
    total_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    total_models INTEGER DEFAULT 0,
    active_models INTEGER DEFAULT 0,
    total_groups INTEGER DEFAULT 0,
    tokens_generated NUMERIC(15,2) DEFAULT 0,
    revenue_usd NUMERIC(15,2) DEFAULT 0,
    contracts_signed INTEGER DEFAULT 0,
    production_logs_count INTEGER DEFAULT 0,
    average_tokens_per_model NUMERIC(10,2) DEFAULT 0,
    top_performing_group_id UUID,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create materialized view for admin dashboard (fast queries)
CREATE MATERIALIZED VIEW IF NOT EXISTS admin_dashboard_stats AS
SELECT
    -- User stats
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM users WHERE role = 'model') as total_models,
    (SELECT COUNT(*) FROM users WHERE role = 'moderator') as total_moderators,
    (SELECT COUNT(DISTINCT model_id) FROM production_logs 
     WHERE production_date >= CURRENT_DATE - INTERVAL '7 days') as active_users_week,
    
    -- Group stats
    (SELECT COUNT(*) FROM groups) as total_groups,
    (SELECT AVG(member_count) FROM 
        (SELECT COUNT(*) as member_count FROM group_members GROUP BY group_id) g
    ) as avg_group_size,
    
    -- Production stats (last 30 days)
    (SELECT COALESCE(SUM(tokens_earned), 0) FROM production_logs 
     WHERE production_date >= CURRENT_DATE - INTERVAL '30 days') as tokens_last_30_days,
    (SELECT COUNT(*) FROM production_logs 
     WHERE production_date >= CURRENT_DATE - INTERVAL '30 days') as production_logs_last_30_days,
    (SELECT COALESCE(AVG(tokens_earned), 0) FROM production_logs 
     WHERE production_date >= CURRENT_DATE - INTERVAL '30 days') as avg_tokens_per_log,
    
    -- Contract stats
    (SELECT COUNT(*) FROM contracts) as total_contracts,
    (SELECT COUNT(*) FROM contracts 
     WHERE signed_at >= CURRENT_DATE - INTERVAL '7 days') as contracts_signed_week,
    
    -- Financial stats (last 30 days)
    (SELECT COALESCE(SUM(tokens_earned * 0.05), 0) FROM production_logs 
     WHERE production_date >= CURRENT_DATE - INTERVAL '30 days') as estimated_revenue_30_days,
    
    -- Audit stats
    (SELECT COUNT(*) FROM audit_trail 
     WHERE created_at >= CURRENT_DATE - INTERVAL '24 hours') as audit_logs_24h,
    
    -- Top performers
    (SELECT json_agg(row_to_json(t)) FROM (
        SELECT u.id, u.email, SUM(pl.tokens_earned) as total_tokens
        FROM users u
        JOIN production_logs pl ON u.id = pl.model_id
        WHERE pl.production_date >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY u.id, u.email
        ORDER BY total_tokens DESC
        LIMIT 10
    ) t) as top_models_30_days,
    
    NOW() as last_updated;

-- Indexes for export logs
CREATE INDEX idx_export_logs_user_id ON export_logs(user_id);
CREATE INDEX idx_export_logs_created_at ON export_logs(created_at DESC);
CREATE INDEX idx_export_logs_status ON export_logs(status);

-- Indexes for system stats
CREATE INDEX idx_system_stats_date ON system_stats(stat_date DESC);

-- Function to refresh admin dashboard stats
CREATE OR REPLACE FUNCTION refresh_admin_dashboard()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW admin_dashboard_stats;
END;
$$ LANGUAGE plpgsql;

-- Function to generate daily system stats (should run via cron/scheduler)
CREATE OR REPLACE FUNCTION generate_daily_stats()
RETURNS void AS $$
DECLARE
    today DATE := CURRENT_DATE;
BEGIN
    INSERT INTO system_stats (
        stat_date,
        total_users,
        active_users,
        total_models,
        active_models,
        total_groups,
        tokens_generated,
        contracts_signed,
        production_logs_count,
        average_tokens_per_model
    )
    SELECT
        today,
        (SELECT COUNT(*) FROM users),
        (SELECT COUNT(DISTINCT model_id) FROM production_logs WHERE production_date = today),
        (SELECT COUNT(*) FROM users WHERE role = 'model'),
        (SELECT COUNT(DISTINCT model_id) FROM production_logs WHERE production_date = today AND model_id IN (SELECT id FROM users WHERE role = 'model')),
        (SELECT COUNT(*) FROM groups),
        (SELECT COALESCE(SUM(tokens_earned), 0) FROM production_logs WHERE production_date = today),
        (SELECT COUNT(*) FROM contracts WHERE DATE(signed_at) = today),
        (SELECT COUNT(*) FROM production_logs WHERE production_date = today),
        (SELECT COALESCE(AVG(tokens_earned), 0) FROM production_logs WHERE production_date = today)
    ON CONFLICT (stat_date) DO UPDATE SET
        total_users = EXCLUDED.total_users,
        active_users = EXCLUDED.active_users,
        total_models = EXCLUDED.total_models,
        active_models = EXCLUDED.active_models,
        total_groups = EXCLUDED.total_groups,
        tokens_generated = EXCLUDED.tokens_generated,
        contracts_signed = EXCLUDED.contracts_signed,
        production_logs_count = EXCLUDED.production_logs_count,
        average_tokens_per_model = EXCLUDED.average_tokens_per_model;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE export_logs IS 'Tracks all data export requests by administrators';
COMMENT ON TABLE system_stats IS 'Daily aggregated statistics for admin dashboard';
COMMENT ON MATERIALIZED VIEW admin_dashboard_stats IS 'Real-time admin dashboard metrics (refresh periodically)';
