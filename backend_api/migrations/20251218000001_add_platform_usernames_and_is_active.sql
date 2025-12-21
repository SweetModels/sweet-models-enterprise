-- Add missing columns to users table for complete user profile support
ALTER TABLE users
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS platform_usernames JSONB DEFAULT '{}';

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_platform_usernames ON users USING GIN(platform_usernames);
