-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    media_item_id UUID NOT NULL REFERENCES media_items(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (length(content) > 0 AND length(content) <= 1000),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'deleted', 'moderated', 'pending')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    is_edited BOOLEAN DEFAULT FALSE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_media_item_id ON comments(media_item_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_comments_status ON comments(status);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at);
CREATE INDEX IF NOT EXISTS idx_comments_updated_at ON comments(updated_at);
CREATE INDEX IF NOT EXISTS idx_comments_deleted_at ON comments(deleted_at);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_comments_media_status ON comments(media_item_id, status);
CREATE INDEX IF NOT EXISTS idx_comments_user_status ON comments(user_id, status);
CREATE INDEX IF NOT EXISTS idx_comments_parent_status ON comments(parent_id, status) WHERE parent_id IS NOT NULL;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_comments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_update_comments_updated_at
    BEFORE UPDATE ON comments
    FOR EACH ROW
    EXECUTE FUNCTION update_comments_updated_at();

-- Create function to update replies count
CREATE OR REPLACE FUNCTION update_comment_replies_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.parent_id IS NOT NULL THEN
        UPDATE comments 
        SET replies_count = replies_count + 1 
        WHERE id = NEW.parent_id;
    ELSIF TG_OP = 'DELETE' AND OLD.parent_id IS NOT NULL THEN
        UPDATE comments 
        SET replies_count = GREATEST(replies_count - 1, 0) 
        WHERE id = OLD.parent_id;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle parent_id changes
        IF OLD.parent_id IS NOT NULL AND (NEW.parent_id IS NULL OR OLD.parent_id != NEW.parent_id) THEN
            UPDATE comments 
            SET replies_count = GREATEST(replies_count - 1, 0) 
            WHERE id = OLD.parent_id;
        END IF;
        IF NEW.parent_id IS NOT NULL AND (OLD.parent_id IS NULL OR OLD.parent_id != NEW.parent_id) THEN
            UPDATE comments 
            SET replies_count = replies_count + 1 
            WHERE id = NEW.parent_id;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update replies count
CREATE TRIGGER trigger_update_comment_replies_count
    AFTER INSERT OR UPDATE OR DELETE ON comments
    FOR EACH ROW
    EXECUTE FUNCTION update_comment_replies_count();

-- Add replies_count column to comments table
ALTER TABLE comments ADD COLUMN IF NOT EXISTS replies_count INTEGER DEFAULT 0;

-- Create view for active comments with user names
CREATE OR REPLACE VIEW active_comments AS
SELECT 
    c.*,
    u.username as user_name
FROM comments c
JOIN users u ON c.user_id = u.id
WHERE c.status = 'active' AND c.deleted_at IS NULL;

-- Create view for comment statistics
CREATE OR REPLACE VIEW comment_stats AS
SELECT 
    COUNT(*) as total_comments,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_comments,
    COUNT(CASE WHEN status = 'deleted' THEN 1 END) as deleted_comments,
    COUNT(CASE WHEN status = 'moderated' THEN 1 END) as moderated_comments,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_comments,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as comments_today,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as comments_this_week,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as comments_this_month
FROM comments;

-- Create view for user comment statistics
CREATE OR REPLACE VIEW user_comment_stats AS
SELECT 
    c.user_id,
    u.username as user_name,
    COUNT(*) as total_comments,
    COUNT(CASE WHEN c.status = 'active' THEN 1 END) as active_comments,
    MAX(c.created_at) as last_comment_at
FROM comments c
JOIN users u ON c.user_id = u.id
GROUP BY c.user_id, u.username;

-- Create view for media comment statistics
CREATE OR REPLACE VIEW media_comment_stats AS
SELECT 
    c.media_item_id,
    COUNT(*) as total_comments,
    COUNT(CASE WHEN c.status = 'active' THEN 1 END) as active_comments,
    MAX(c.created_at) as last_comment_at
FROM comments c
GROUP BY c.media_item_id;
