-- Drop attendance_logs table if rolling back
DROP TABLE IF EXISTS attendance_logs CASCADE;
DROP INDEX IF EXISTS idx_attendance_user_status;
DROP INDEX IF EXISTS idx_attendance_user_date;
DROP INDEX IF EXISTS idx_attendance_status;
