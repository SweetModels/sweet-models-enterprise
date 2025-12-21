-- Penalties table to record sanctions applied to users
CREATE TABLE IF NOT EXISTS penalties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason VARCHAR(255) NOT NULL,
    xp_deduction INTEGER NOT NULL,
    financial_fine NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT
);

-- Helpful index for recent queries per user
CREATE INDEX IF NOT EXISTS idx_penalties_user_date ON penalties(user_id, created_at DESC);
