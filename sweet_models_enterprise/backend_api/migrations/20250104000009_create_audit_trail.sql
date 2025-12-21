-- Audit trail table for tracking all system changes
CREATE TABLE IF NOT EXISTS audit_trail (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('create', 'update', 'delete', 'login', 'logout')),
    old_value JSONB,
    new_value JSONB NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for audit queries
CREATE INDEX IF NOT EXISTS idx_audit_trail_entity ON audit_trail(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_trail_user_id ON audit_trail(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_trail_action ON audit_trail(action);
CREATE INDEX IF NOT EXISTS idx_audit_trail_created_at ON audit_trail(created_at DESC);

COMMENT ON TABLE audit_trail IS 'Complete audit log of all system operations';
COMMENT ON COLUMN audit_trail.entity_type IS 'Type of entity modified (user, group, production, etc)';
COMMENT ON COLUMN audit_trail.old_value IS 'Previous state (NULL for create operations)';
COMMENT ON COLUMN audit_trail.new_value IS 'New state (complete object as JSONB)';
