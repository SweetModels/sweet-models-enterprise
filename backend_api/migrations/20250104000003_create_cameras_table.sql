-- Cameras table for streaming URLs management
CREATE TABLE IF NOT EXISTS cameras (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    stream_url TEXT NOT NULL,
    model_id UUID REFERENCES users(id),
    platform TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_active_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_cameras_model_id ON cameras(model_id);
CREATE INDEX IF NOT EXISTS idx_cameras_platform ON cameras(platform);
CREATE INDEX IF NOT EXISTS idx_cameras_is_active ON cameras(is_active);

-- Insert sample cameras
INSERT INTO cameras (name, stream_url, platform, is_active)
VALUES 
    ('Main Studio Cam 1', 'rtsp://192.168.1.100:554/stream1', 'Studio', true),
    ('Main Studio Cam 2', 'rtsp://192.168.1.101:554/stream1', 'Studio', true),
    ('VIP Room Cam', 'rtsp://192.168.1.102:554/stream1', 'VIP', true),
    ('Lobby Cam', 'rtsp://192.168.1.103:554/stream1', 'Lobby', true)
ON CONFLICT DO NOTHING;
