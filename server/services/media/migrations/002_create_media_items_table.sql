-- Create media_items table
CREATE TABLE IF NOT EXISTS media_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_path VARCHAR(500) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('image', 'video')),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_name VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    categories TEXT[] DEFAULT '{}',
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    rejection_reason TEXT,
    metadata JSONB DEFAULT '{}',
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    thumbnail_path VARCHAR(500)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_media_items_user_id ON media_items(user_id);
CREATE INDEX IF NOT EXISTS idx_media_items_type ON media_items(type);
CREATE INDEX IF NOT EXISTS idx_media_items_status ON media_items(status);
CREATE INDEX IF NOT EXISTS idx_media_items_uploaded_at ON media_items(uploaded_at);
CREATE INDEX IF NOT EXISTS idx_media_items_categories ON media_items USING GIN(categories);
CREATE INDEX IF NOT EXISTS idx_media_items_metadata ON media_items USING GIN(metadata);

-- Create full-text search index for title and description
CREATE INDEX IF NOT EXISTS idx_media_items_search ON media_items USING GIN(
    to_tsvector('english', title || ' ' || COALESCE(description, ''))
);
