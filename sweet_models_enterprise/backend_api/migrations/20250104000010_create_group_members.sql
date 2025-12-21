-- Group members table for tracking which users belong to which groups
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    role VARCHAR(50) DEFAULT 'member',
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Ensure user can only be in group once
    CONSTRAINT unique_group_user UNIQUE (group_id, user_id)
);

-- Indexes for fast membership queries
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_active ON group_members(is_active) WHERE is_active = TRUE;

COMMENT ON TABLE group_members IS 'Maps users to groups for team-based production tracking';
COMMENT ON COLUMN group_members.role IS 'Member role within group (leader, member, etc)';
