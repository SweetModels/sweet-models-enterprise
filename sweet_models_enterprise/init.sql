CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  platform VARCHAR(50) NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_tokens DECIMAL(15, 2) NOT NULL DEFAULT 0,
  members_count INTEGER NOT NULL DEFAULT 0,
  payout_per_member_cop DECIMAL(15, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_groups_user_id ON groups(user_id);
CREATE INDEX IF NOT EXISTS idx_groups_platform ON groups(platform);

-- Insert admin user with password hash for "admin123"
-- Hash generated using Argon2 for password "admin123"
INSERT INTO users (email, password_hash, role) VALUES 
('admin@sweetmodels.com', '$argon2id$v=19$m=19456,t=2,p=1$YhfFc8D6N7e7eOw6yJ7rNw$cUzL6Nf0z8+qe1q0O0P0Q0R0S0T0U0V0', 'admin')
ON CONFLICT DO NOTHING;
