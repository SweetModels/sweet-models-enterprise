-- Migración: Crear usuario Beyorder AI y tablas necesarias

-- 1. Insertar usuario Beyorder (si no existe)
INSERT INTO users (username, email, password_hash, role, created_at)
VALUES (
    'beyorder',
    'beyorder@sweetmodels.ai',
    '$argon2id$v=19$m=19456,t=2,p=1$AAAAAAAAAAAAAAAAAAAAAA$AAAAAAAAAAAAAAAAAAAAAA', -- Password placeholder
    'admin',
    NOW()
)
ON CONFLICT (username) DO NOTHING;

-- 2. Agregar campos opcionales a users para mejorar análisis de Beyorder
ALTER TABLE users
ADD COLUMN IF NOT EXISTS daily_goal INT DEFAULT 5000,
ADD COLUMN IF NOT EXISTS primary_platform VARCHAR(50) DEFAULT 'chaturbate';

-- 3. Crear índices para mejorar queries de Beyorder
CREATE INDEX IF NOT EXISTS idx_attendance_user_date 
ON attendance(user_id, DATE(started_at));

CREATE INDEX IF NOT EXISTS idx_attendance_platform 
ON attendance(platform);

CREATE INDEX IF NOT EXISTS idx_chat_messages_receiver 
ON chat_messages(receiver_id, created_at DESC);

-- 4. Agregar columna de plataforma en attendance (si no existe)
ALTER TABLE attendance
ADD COLUMN IF NOT EXISTS platform VARCHAR(50) DEFAULT 'chaturbate';

-- 5. Crear tabla de configuración de Beyorder (opcional)
CREATE TABLE IF NOT EXISTS beyorder_config (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Configuraciones iniciales
INSERT INTO beyorder_config (key, value)
VALUES 
    ('observation_interval_mins', '30'),
    ('underperformance_threshold', '-0.20'),
    ('enabled', 'true'),
    ('ai_model', 'gpt-4o-mini')
ON CONFLICT (key) DO NOTHING;

-- 6. Crear tabla de logs de Beyorder (para auditoría)
CREATE TABLE IF NOT EXISTS beyorder_logs (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL, -- 'motivate', 'congratulate', 'chat_response'
    message TEXT NOT NULL,
    context JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_beyorder_logs_user_date
ON beyorder_logs(user_id, created_at DESC);

-- 7. Comentarios de documentación
COMMENT ON TABLE beyorder_config IS 'Configuración dinámica del AI Coach Beyorder';
COMMENT ON TABLE beyorder_logs IS 'Registro de todas las intervenciones de Beyorder';
COMMENT ON COLUMN users.daily_goal IS 'Meta diaria de tokens para la modelo';
COMMENT ON COLUMN users.primary_platform IS 'Plataforma principal donde trabaja (chaturbate, stripchat, camsoda)';
