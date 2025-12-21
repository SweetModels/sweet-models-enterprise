-- Seed modelo user for testing - DISABLED (crear manualmente después)
-- Email: modelo@sweet.com
-- Password: Modelo123!
-- Hash generated with Argon2 (equivalent to "Modelo123!")

-- INSERT INTO users (email, password_hash, role, created_at, updated_at)
-- VALUES (
--   'modelo@sweet.com',
--   '$argon2id$v=19$m=19456,t=2,p=1$mOPVP8r9rjBIbV5uLlnLdA$lCTKmQ8h5Y+7dHzl8JQ8P7KxR/J7+8e9K8z9L5m8eW8',
--   'model',
--   CURRENT_TIMESTAMP,
--   CURRENT_TIMESTAMP
-- )
-- ON CONFLICT (email) DO NOTHING;

-- Placeholder para mantener la migración válida
SELECT 1;
