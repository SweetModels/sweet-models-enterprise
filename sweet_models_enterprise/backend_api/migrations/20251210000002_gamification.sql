-- Migración 001: Sistema de Gamificación
-- Crear tabla de niveles y logros del usuario

CREATE TYPE user_rank AS ENUM (
  'NOVICE',
  'RISING_STAR',
  'ELITE',
  'QUEEN',
  'GODDESS'
);

CREATE TABLE user_levels (
  user_id UUID PRIMARY KEY NOT NULL,
  xp BIGINT NOT NULL DEFAULT 0,
  current_rank user_rank NOT NULL DEFAULT 'NOVICE',
  achievements JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Tabla de histórico de XP (auditoría)
CREATE TABLE xp_history (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL,
  xp_gained BIGINT NOT NULL,
  reason TEXT NOT NULL, -- 'finance_earnings', 'photo_upload', 'manual_admin', etc.
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user_levels(user_id) ON DELETE CASCADE
);

-- Tabla de rangos (configuración)
CREATE TABLE rank_thresholds (
  rank_id user_rank PRIMARY KEY,
  min_xp BIGINT NOT NULL,
  max_xp BIGINT,
  reward_amount NUMERIC(18, 6), -- USDT reward para subir de rango
  description TEXT
);

-- Insertar umbrales de rangos
INSERT INTO rank_thresholds (rank_id, min_xp, max_xp, reward_amount, description)
VALUES
  ('NOVICE', 0, 999, 0, 'Principiante'),
  ('RISING_STAR', 1000, 4999, 50, 'Estrella Ascendente'),
  ('ELITE', 5000, 14999, 150, 'Élite'),
  ('QUEEN', 15000, 49999, 500, 'Reina'),
  ('GODDESS', 50000, NULL, 2000, 'Diosa');

-- Trigger: Auto-actualizar updated_at en user_levels
CREATE OR REPLACE FUNCTION update_user_levels_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_levels_updated_at
BEFORE UPDATE ON user_levels
FOR EACH ROW
EXECUTE FUNCTION update_user_levels_timestamp();

-- Índices
CREATE INDEX idx_user_levels_xp ON user_levels(xp DESC);
CREATE INDEX idx_user_levels_rank ON user_levels(current_rank);
CREATE INDEX idx_xp_history_user ON xp_history(user_id);
CREATE INDEX idx_xp_history_created ON xp_history(created_at DESC);
