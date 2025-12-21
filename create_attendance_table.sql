-- Create attendance_logs table for tracking check-in/check-out times
CREATE TABLE IF NOT EXISTS attendance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    check_in TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    check_out TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN', -- OPEN, CLOSED
    ip_address VARCHAR(45), -- IPv4 or IPv6
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Index for fast queries on active sessions
CREATE INDEX IF NOT EXISTS idx_attendance_user_status ON attendance_logs(user_id, status)
WHERE status = 'OPEN';

-- Index for user activity history
CREATE INDEX IF NOT EXISTS idx_attendance_user_date ON attendance_logs(user_id, check_in DESC);

-- Index for quick check_out lookups
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance_logs(status);
