-- Add full_name column to users table if it doesn't exist
ALTER TABLE users
ADD COLUMN IF NOT EXISTS full_name VARCHAR(255);

-- Create index on full_name for search performance
CREATE INDEX IF NOT EXISTS idx_users_full_name ON users(full_name);
