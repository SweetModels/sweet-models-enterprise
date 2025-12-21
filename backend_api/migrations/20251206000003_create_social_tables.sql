-- ============================================================================
-- Sweet Models Enterprise - Social Module Database Schema
-- Tablas para Chat y Feed Social
-- ============================================================================

-- Tipos ENUM
CREATE TYPE message_type AS ENUM ('text', 'image', 'video', 'audio', 'file');
CREATE TYPE media_type AS ENUM ('photo', 'video', 'gallery');

-- ============================================================================
-- TABLA: messages (Mensajes privados)
-- ============================================================================
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL, -- Contenido encriptado
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    read BOOLEAN NOT NULL DEFAULT FALSE,
    message_type message_type NOT NULL DEFAULT 'text',
    
    -- Índices para búsquedas rápidas
    CONSTRAINT chk_different_users CHECK (sender_id != receiver_id)
);

CREATE INDEX idx_messages_sender ON messages(sender_id, timestamp DESC);
CREATE INDEX idx_messages_receiver ON messages(receiver_id, timestamp DESC);
CREATE INDEX idx_messages_conversation ON messages(sender_id, receiver_id, timestamp DESC);
CREATE INDEX idx_messages_unread ON messages(receiver_id, read) WHERE read = FALSE;

-- ============================================================================
-- TABLA: posts (Posts del feed social)
-- ============================================================================
CREATE TABLE IF NOT EXISTS posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes_count INTEGER NOT NULL DEFAULT 0,
    comments_count INTEGER NOT NULL DEFAULT 0,
    media_url TEXT,
    media_type media_type,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Validaciones
    CONSTRAINT chk_likes_positive CHECK (likes_count >= 0),
    CONSTRAINT chk_comments_positive CHECK (comments_count >= 0),
    CONSTRAINT chk_content_length CHECK (char_length(content) <= 5000)
);

CREATE INDEX idx_posts_user ON posts(user_id, created_at DESC);
CREATE INDEX idx_posts_feed ON posts(created_at DESC);
CREATE INDEX idx_posts_popular ON posts(likes_count DESC, created_at DESC);

-- ============================================================================
-- TABLA: likes (Likes en posts)
-- ============================================================================
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Unicidad: Un usuario solo puede dar like una vez por post
    CONSTRAINT unique_like UNIQUE (post_id, user_id)
);

CREATE INDEX idx_likes_post ON likes(post_id);
CREATE INDEX idx_likes_user ON likes(user_id, created_at DESC);

-- ============================================================================
-- TABLA: comments (Comentarios en posts)
-- ============================================================================
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Validaciones
    CONSTRAINT chk_comment_length CHECK (char_length(content) <= 1000)
);

CREATE INDEX idx_comments_post ON comments(post_id, created_at DESC);
CREATE INDEX idx_comments_user ON comments(user_id, created_at DESC);

-- ============================================================================
-- TRIGGERS: Actualizar updated_at automáticamente
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FUNCIONES: Estadísticas y utilidades
-- ============================================================================

-- Obtener conversaciones recientes de un usuario
CREATE OR REPLACE FUNCTION get_recent_conversations(p_user_id UUID, p_limit INTEGER DEFAULT 20)
RETURNS TABLE (
    other_user_id UUID,
    last_message_time TIMESTAMPTZ,
    unread_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN m.sender_id = p_user_id THEN m.receiver_id
            ELSE m.sender_id
        END as other_user_id,
        MAX(m.timestamp) as last_message_time,
        COUNT(*) FILTER (WHERE m.receiver_id = p_user_id AND NOT m.read) as unread_count
    FROM messages m
    WHERE m.sender_id = p_user_id OR m.receiver_id = p_user_id
    GROUP BY other_user_id
    ORDER BY last_message_time DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Obtener posts de usuarios seguidos (requiere tabla follows)
CREATE OR REPLACE FUNCTION get_following_feed(p_user_id UUID, p_limit INTEGER DEFAULT 50, p_offset INTEGER DEFAULT 0)
RETURNS SETOF posts AS $$
BEGIN
    -- Si no existe la tabla follows, retornar todos los posts
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'follows') THEN
        RETURN QUERY
        SELECT * FROM posts
        ORDER BY created_at DESC
        LIMIT p_limit OFFSET p_offset;
    ELSE
        RETURN QUERY
        SELECT p.* FROM posts p
        WHERE p.user_id IN (
            SELECT followed_id FROM follows WHERE follower_id = p_user_id
        ) OR p.user_id = p_user_id
        ORDER BY p.created_at DESC
        LIMIT p_limit OFFSET p_offset;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- DATOS DE EJEMPLO (OPCIONAL - Descomentar para testing)
-- ============================================================================

/*
-- Insertar algunos posts de ejemplo
INSERT INTO posts (user_id, content, likes_count, comments_count) VALUES
    ((SELECT id FROM users LIMIT 1), 'Mi primer post en Sweet Models! 🎉', 5, 2),
    ((SELECT id FROM users LIMIT 1), 'Increíble sesión de hoy! #trabajo #webcam', 12, 5);

-- Insertar algunos mensajes de ejemplo
DO $$
DECLARE
    user1 UUID;
    user2 UUID;
BEGIN
    SELECT id INTO user1 FROM users ORDER BY created_at LIMIT 1;
    SELECT id INTO user2 FROM users ORDER BY created_at LIMIT 1 OFFSET 1;
    
    IF user1 IS NOT NULL AND user2 IS NOT NULL THEN
        INSERT INTO messages (sender_id, receiver_id, content, message_type) VALUES
            (user1, user2, 'SGVsbG8h', 'text'),  -- "Hello!" en base64
            (user2, user1, 'SGkgdGhlcmUh', 'text');  -- "Hi there!" en base64
    END IF;
END $$;
*/

-- ============================================================================
-- GRANTS (Ajustar según el usuario de la aplicación)
-- ============================================================================

-- GRANT SELECT, INSERT, UPDATE, DELETE ON messages, posts, likes, comments TO your_app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO your_app_user;

-- ============================================================================
-- COMENTARIOS FINALES
-- ============================================================================

COMMENT ON TABLE messages IS 'Mensajes privados encriptados entre usuarios';
COMMENT ON TABLE posts IS 'Posts públicos del feed social';
COMMENT ON TABLE likes IS 'Likes de usuarios en posts';
COMMENT ON TABLE comments IS 'Comentarios en posts del feed';
COMMENT ON COLUMN messages.content IS 'Contenido encriptado con AES-256-GCM';
COMMENT ON FUNCTION get_recent_conversations IS 'Obtiene las conversaciones recientes de un usuario';
COMMENT ON FUNCTION get_following_feed IS 'Feed personalizado con posts de usuarios seguidos';
