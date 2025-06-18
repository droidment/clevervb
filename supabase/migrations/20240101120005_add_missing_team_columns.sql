-- Migration: Add missing columns to st_teams table
-- Created: 2024-01-01 12:00:05
-- Description: Add missing columns that the team service code expects

-- Add missing columns to st_teams table
ALTER TABLE st_teams ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT TRUE;
ALTER TABLE st_teams ADD COLUMN IF NOT EXISTS sport_type TEXT;
ALTER TABLE st_teams ADD COLUMN IF NOT EXISTS max_members INTEGER;

-- Update sport_type to match existing sport values
UPDATE st_teams SET sport_type = sport WHERE sport_type IS NULL;

-- Update max_members to match existing max_players values  
UPDATE st_teams SET max_members = max_players WHERE max_members IS NULL;

-- Add constraints for new columns
ALTER TABLE st_teams ADD CONSTRAINT check_sport_type 
  CHECK (sport_type IN ('volleyball', 'pickleball'));

-- Add comments to document the changes
COMMENT ON COLUMN st_teams.is_public IS 'Whether the team accepts public join requests';
COMMENT ON COLUMN st_teams.sport_type IS 'Type of sport (duplicate of sport column for compatibility)';
COMMENT ON COLUMN st_teams.max_members IS 'Maximum number of team members (duplicate of max_players for compatibility)'; 