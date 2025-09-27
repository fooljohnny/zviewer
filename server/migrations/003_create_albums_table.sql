-- Create albums table
CREATE TABLE IF NOT EXISTS albums (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    cover_image_id UUID,
    cover_image_path VARCHAR(500),
    cover_thumbnail_path VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    is_public BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    tags TEXT[] DEFAULT '{}'
);

-- Create album_images junction table
CREATE TABLE IF NOT EXISTS album_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    album_id UUID NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
    image_id UUID NOT NULL,
    image_path VARCHAR(500) NOT NULL,
    thumbnail_path VARCHAR(500),
    mime_type VARCHAR(100),
    file_size BIGINT,
    width INTEGER,
    height INTEGER,
    sort_order INTEGER DEFAULT 0,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    added_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for albums table
CREATE INDEX IF NOT EXISTS idx_albums_user_id ON albums(user_id);
CREATE INDEX IF NOT EXISTS idx_albums_status ON albums(status);
CREATE INDEX IF NOT EXISTS idx_albums_created_at ON albums(created_at);
CREATE INDEX IF NOT EXISTS idx_albums_updated_at ON albums(updated_at);
CREATE INDEX IF NOT EXISTS idx_albums_is_public ON albums(is_public);
CREATE INDEX IF NOT EXISTS idx_albums_tags ON albums USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_albums_metadata ON albums USING GIN(metadata);

-- Create indexes for album_images table
CREATE INDEX IF NOT EXISTS idx_album_images_album_id ON album_images(album_id);
CREATE INDEX IF NOT EXISTS idx_album_images_image_id ON album_images(image_id);
CREATE INDEX IF NOT EXISTS idx_album_images_sort_order ON album_images(album_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_album_images_added_at ON album_images(added_at);

-- Add constraints
DO $$ 
BEGIN
    -- Album status constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_album_status') THEN
        ALTER TABLE albums ADD CONSTRAINT chk_album_status 
        CHECK (status IN ('draft', 'published', 'archived'));
    END IF;
    
    -- Album title constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_album_title_not_empty') THEN
        ALTER TABLE albums ADD CONSTRAINT chk_album_title_not_empty 
        CHECK (LENGTH(TRIM(title)) > 0);
    END IF;
    
    -- Album description constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_album_description_length') THEN
        ALTER TABLE albums ADD CONSTRAINT chk_album_description_length 
        CHECK (LENGTH(description) <= 2000);
    END IF;
    
    -- Album view_count constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_album_view_count') THEN
        ALTER TABLE albums ADD CONSTRAINT chk_album_view_count 
        CHECK (view_count >= 0);
    END IF;
    
    -- Album like_count constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_album_like_count') THEN
        ALTER TABLE albums ADD CONSTRAINT chk_album_like_count 
        CHECK (like_count >= 0);
    END IF;
    
    -- Album_images sort_order constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_album_images_sort_order') THEN
        ALTER TABLE album_images ADD CONSTRAINT chk_album_images_sort_order 
        CHECK (sort_order >= 0);
    END IF;
    
    -- Album_images file_size constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_album_images_file_size') THEN
        ALTER TABLE album_images ADD CONSTRAINT chk_album_images_file_size 
        CHECK (file_size >= 0);
    END IF;
    
    -- Album_images dimensions constraints
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_album_images_width') THEN
        ALTER TABLE album_images ADD CONSTRAINT chk_album_images_width 
        CHECK (width > 0);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_album_images_height') THEN
        ALTER TABLE album_images ADD CONSTRAINT chk_album_images_height 
        CHECK (height > 0);
    END IF;
END $$;

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_album_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for albums table
DROP TRIGGER IF EXISTS trigger_update_albums_updated_at ON albums;
CREATE TRIGGER trigger_update_albums_updated_at
    BEFORE UPDATE ON albums
    FOR EACH ROW
    EXECUTE FUNCTION update_album_updated_at();

-- Create function to get album image count
CREATE OR REPLACE FUNCTION get_album_image_count(album_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM album_images
        WHERE album_id = album_uuid
    );
END;
$$ LANGUAGE plpgsql;

-- Create function to get album cover image
CREATE OR REPLACE FUNCTION get_album_cover_image(album_uuid UUID)
RETURNS TABLE (
    image_id UUID,
    image_path VARCHAR(500),
    thumbnail_path VARCHAR(500)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ai.image_id,
        ai.image_path,
        ai.thumbnail_path
    FROM album_images ai
    WHERE ai.album_id = album_uuid
    ORDER BY ai.sort_order ASC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;
