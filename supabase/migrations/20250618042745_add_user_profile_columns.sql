-- Add missing columns to st_users table for profile management
ALTER TABLE st_users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE st_users ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE st_users ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE st_users ADD COLUMN IF NOT EXISTS preferred_sports TEXT[] DEFAULT ARRAY[]::TEXT[];
