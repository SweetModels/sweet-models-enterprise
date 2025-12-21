CREATE TABLE IF NOT EXISTS user_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_room INT NOT NULL CHECK (assigned_room BETWEEN 1 AND 3),
    assigned_shift INT NOT NULL CHECK (assigned_shift BETWEEN 1 AND 4),
    week_id VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, week_id)
);

CREATE INDEX IF NOT EXISTS idx_user_shifts_user_week ON user_shifts(user_id, week_id);

CREATE OR REPLACE FUNCTION set_timestamp_user_shifts()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_shifts_updated_at ON user_shifts;
CREATE TRIGGER trg_user_shifts_updated_at
    BEFORE UPDATE ON user_shifts
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_user_shifts();
