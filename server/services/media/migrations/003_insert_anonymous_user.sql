-- Insert anonymous user for media uploads
-- This migration creates an anonymous user with a fixed UUID for unauthenticated uploads

-- Check if anonymous user already exists
DO $$
BEGIN
    -- Only insert if no anonymous user exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = '00000000-0000-0000-0000-000000000000') THEN
        -- Insert anonymous user
        INSERT INTO users (id, email, display_name, role, password_hash, created_at)
        VALUES (
            '00000000-0000-0000-0000-000000000000', -- Fixed UUID for anonymous user
            'anonymous@zviewer.local',
            'Anonymous User',
            'user',
            '$2a$12$dummy.hash.for.anonymous.user.no.login.required', -- Dummy hash since anonymous users can't login
            NOW()
        );
        
        RAISE NOTICE 'Anonymous user created successfully';
    ELSE
        RAISE NOTICE 'Anonymous user already exists, skipping creation';
    END IF;
END $$;

