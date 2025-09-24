-- Insert default admin user
-- This migration creates a default admin user with email 'admin' and password 'admin'
-- The password is hashed using bcrypt with cost 12

-- Check if admin user already exists
DO $$
BEGIN
    -- Only insert if no admin user exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@zviewer.local') THEN
        -- Insert default admin user
        INSERT INTO users (id, email, display_name, role, password_hash, created_at)
        VALUES (
            '00000000-0000-0000-0000-000000000001', -- Fixed UUID for default admin
            'admin@zviewer.local',
            'System Administrator',
            'admin',
            '$2a$12$OSl9kO2DxujKfV43G.HVQ.7bTBllGWSYdQrsa.I8CdCfB37vq0KVW', -- bcrypt hash of 'admin123' with cost 12
            NOW()
        );
        
        RAISE NOTICE 'Default admin user created successfully';
    ELSE
        RAISE NOTICE 'Admin user already exists, skipping creation';
    END IF;
END $$;
