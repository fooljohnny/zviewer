-- Migration: 005_create_admin_tables.sql
-- Description: Create admin service tables for admin actions, content moderation, and system stats

-- Create admin_actions table
CREATE TABLE IF NOT EXISTS admin_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    target_type VARCHAR(20) NOT NULL,
    target_id UUID,
    description TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_admin_actions_admin_user_id 
        FOREIGN KEY (admin_user_id) 
        REFERENCES users(id) 
        ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_admin_actions_action_type 
        CHECK (action_type IN (
            'user_created', 'user_updated', 'user_deleted', 'user_role_changed', 'user_status_changed',
            'content_approved', 'content_rejected', 'content_flagged', 'content_deleted',
            'comment_deleted', 'payment_refunded', 'system_config_changed'
        )),
    
    CONSTRAINT chk_admin_actions_target_type 
        CHECK (target_type IN ('user', 'content', 'comment', 'payment', 'system'))
);

-- Create content_moderations table
CREATE TABLE IF NOT EXISTS content_moderations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL,
    moderator_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    reason TEXT,
    flags JSONB,
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_content_moderations_content_id 
        FOREIGN KEY (content_id) 
        REFERENCES media_items(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT fk_content_moderations_moderator_id 
        FOREIGN KEY (moderator_id) 
        REFERENCES users(id) 
        ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_content_moderations_status 
        CHECK (status IN ('pending', 'approved', 'rejected', 'flagged')),
    
    -- Unique constraint to ensure one moderation record per content item
    CONSTRAINT uk_content_moderations_content_id 
        UNIQUE (content_id)
);

-- Create system_stats table
CREATE TABLE IF NOT EXISTS system_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,4) NOT NULL,
    metric_type VARCHAR(20) NOT NULL,
    labels JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Check constraints
    CONSTRAINT chk_system_stats_metric_type 
        CHECK (metric_type IN ('counter', 'gauge', 'histogram')),
    
    CONSTRAINT chk_system_stats_metric_value 
        CHECK (metric_value >= 0)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_admin_actions_admin_user_id ON admin_actions(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_action_type ON admin_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_admin_actions_target_type ON admin_actions(target_type);
CREATE INDEX IF NOT EXISTS idx_admin_actions_target_id ON admin_actions(target_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_created_at ON admin_actions(created_at);

CREATE INDEX IF NOT EXISTS idx_content_moderations_content_id ON content_moderations(content_id);
CREATE INDEX IF NOT EXISTS idx_content_moderations_moderator_id ON content_moderations(moderator_id);
CREATE INDEX IF NOT EXISTS idx_content_moderations_status ON content_moderations(status);
CREATE INDEX IF NOT EXISTS idx_content_moderations_created_at ON content_moderations(created_at);

CREATE INDEX IF NOT EXISTS idx_system_stats_metric_name ON system_stats(metric_name);
CREATE INDEX IF NOT EXISTS idx_system_stats_metric_type ON system_stats(metric_type);
CREATE INDEX IF NOT EXISTS idx_system_stats_timestamp ON system_stats(timestamp);
CREATE INDEX IF NOT EXISTS idx_system_stats_labels ON system_stats USING GIN (labels);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for content_moderations updated_at
CREATE TRIGGER update_content_moderations_updated_at 
    BEFORE UPDATE ON content_moderations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert initial system stats
INSERT INTO system_stats (metric_name, metric_value, metric_type, labels) VALUES
('total_users', 0, 'gauge', '{"service": "admin"}'),
('active_users', 0, 'gauge', '{"service": "admin"}'),
('total_content', 0, 'gauge', '{"service": "admin"}'),
('pending_content', 0, 'gauge', '{"service": "admin"}'),
('approved_content', 0, 'gauge', '{"service": "admin"}'),
('rejected_content', 0, 'gauge', '{"service": "admin"}'),
('total_comments', 0, 'gauge', '{"service": "admin"}'),
('total_payments', 0, 'gauge', '{"service": "admin"}'),
('total_revenue', 0, 'gauge', '{"service": "admin"}'),
('system_uptime', 0, 'counter', '{"service": "admin"}'),
('error_rate', 0, 'gauge', '{"service": "admin"}'),
('response_time', 0, 'histogram', '{"service": "admin"}'),
('database_connections', 0, 'gauge', '{"service": "admin"}'),
('memory_usage', 0, 'gauge', '{"service": "admin"}'),
('cpu_usage', 0, 'gauge', '{"service": "admin"}'),
('disk_usage', 0, 'gauge', '{"service": "admin"}')
ON CONFLICT DO NOTHING;
