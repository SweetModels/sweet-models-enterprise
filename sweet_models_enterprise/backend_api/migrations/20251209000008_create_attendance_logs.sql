CREATE TABLE IF NOT EXISTS attendance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    check_in TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    check_out TIMESTAMPTZ,
    is_late BOOLEAN NOT NULL DEFAULT FALSE,
    photo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attendance_user ON attendance_logs(user_id, check_in DESC);
CREATE INDEX IF NOT EXISTS idx_attendance_late ON attendance_logs(is_late);

CREATE OR REPLACE FUNCTION set_timestamp_attendance_logs()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_attendance_logs_updated_at ON attendance_logs;
CREATE TRIGGER trg_attendance_logs_updated_at
    BEFORE UPDATE ON attendance_logs
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_attendance_logs();
