-- Migration: Add missing columns to st_users table
-- Created: 2024-01-01 12:00:01
-- Description: Add missing columns that the code expects but were not in original schema

-- Add missing columns to st_users table
ALTER TABLE st_users ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE st_users ADD COLUMN IF NOT EXISTS is_profile_complete BOOLEAN DEFAULT FALSE;
ALTER TABLE st_users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE st_users ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE st_users ADD COLUMN IF NOT EXISTS preferred_sports TEXT[] DEFAULT '{}';

-- Update existing records to have default values
UPDATE st_users SET 
  is_profile_complete = (date_of_birth IS NOT NULL),
  preferred_sports = '{}'
WHERE is_profile_complete IS NULL OR preferred_sports IS NULL;

-- Add comment to document the changes
COMMENT ON COLUMN st_users.bio IS 'User biography/description text';
COMMENT ON COLUMN st_users.is_profile_complete IS 'Flag indicating if user has completed profile setup';
COMMENT ON COLUMN st_users.avatar_url IS 'URL to user profile picture';
COMMENT ON COLUMN st_users.location IS 'User location/city';
COMMENT ON COLUMN st_users.preferred_sports IS 'Array of sports the user prefers to play'; 