-- Migration: Notifications System
-- Description: Push notifications and in-app notification center

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'info', 'warning', 'success', 'achievement', 'payment', 'contract'
    priority VARCHAR(20) DEFAULT 'normal', -- 'low', 'normal', 'high', 'urgent'
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    data JSONB, -- Additional metadata (e.g., deep link, action buttons)
    image_url TEXT,
    action_url TEXT
);

-- Create notification_preferences table
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    push_enabled BOOLEAN DEFAULT true,
    email_enabled BOOLEAN DEFAULT true,
    in_app_enabled BOOLEAN DEFAULT true,
    achievement_notifications BOOLEAN DEFAULT true,
    payment_notifications BOOLEAN DEFAULT true,
    contract_notifications BOOLEAN DEFAULT true,
    production_reminders BOOLEAN DEFAULT true,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create device_tokens table for FCM/APNS
CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL, -- 'android', 'ios', 'web', 'windows'
    device_info JSONB,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_device_token UNIQUE (user_id, token)
);

-- Indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_read_at ON notifications(read_at) WHERE read_at IS NULL;
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_platform ON device_tokens(platform);

-- Function to auto-delete old read notifications (keep only 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
    DELETE FROM notifications
    WHERE read_at IS NOT NULL 
      AND created_at < NOW() - INTERVAL '30 days';
    
    DELETE FROM notifications
    WHERE expires_at IS NOT NULL 
      AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_count(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    count INTEGER;
BEGIN
    SELECT COUNT(*)::INTEGER INTO count
    FROM notifications
    WHERE user_id = p_user_id 
      AND read_at IS NULL
      AND (expires_at IS NULL OR expires_at > NOW());
    
    RETURN count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE notifications IS 'In-app and push notifications for users';
COMMENT ON TABLE notification_preferences IS 'User notification settings and preferences';
COMMENT ON TABLE device_tokens IS 'FCM/APNS tokens for push notifications';
