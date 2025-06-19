-- Fix st_users table structure and RLS policies for OAuth
-- Created: 2024-06-18 04:27:46

-- First, make sure we have all required columns
ALTER TABLE st_users ADD COLUMN IF NOT EXISTS is_profile_complete BOOLEAN DEFAULT FALSE;

-- Make date_of_birth nullable for initial OAuth creation
ALTER TABLE st_users ALTER COLUMN date_of_birth DROP NOT NULL;

-- Update RLS policies to allow OAuth user creation
DROP POLICY IF EXISTS "users_own_profile" ON st_users;

-- Create more permissive policies for OAuth users
CREATE POLICY "users_can_read_own_profile" ON st_users
  FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "users_can_insert_own_profile" ON st_users
  FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "users_can_update_own_profile" ON st_users
  FOR UPDATE USING (auth.uid() = auth_user_id);

-- Allow users to read basic team info for team creation/joining
CREATE POLICY "users_can_read_teams_for_joining" ON st_teams
  FOR SELECT USING (is_public = true OR organizer_id IN (
    SELECT id FROM st_users WHERE auth_user_id = auth.uid()
  ));

-- Update team creation policy to use proper user ID lookup
DROP POLICY IF EXISTS "teams_organizer_insert" ON st_teams;
CREATE POLICY "teams_organizer_insert" ON st_teams
  FOR INSERT WITH CHECK (organizer_id IN (
    SELECT id FROM st_users WHERE auth_user_id = auth.uid()
  ));

-- Update team modification policies
DROP POLICY IF EXISTS "teams_organizer_update" ON st_teams;
CREATE POLICY "teams_organizer_update" ON st_teams
  FOR UPDATE USING (organizer_id IN (
    SELECT id FROM st_users WHERE auth_user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "teams_organizer_delete" ON st_teams;
CREATE POLICY "teams_organizer_delete" ON st_teams
  FOR DELETE USING (organizer_id IN (
    SELECT id FROM st_users WHERE auth_user_id = auth.uid()
  ));

-- Update team members policies to allow proper joining
DROP POLICY IF EXISTS "team_members_insert_self" ON st_team_members;
CREATE POLICY "team_members_insert_self" ON st_team_members
  FOR INSERT WITH CHECK (user_id IN (
    SELECT id FROM st_users WHERE auth_user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "team_members_delete_self" ON st_team_members;
CREATE POLICY "team_members_delete_self" ON st_team_members
  FOR DELETE USING (user_id IN (
    SELECT id FROM st_users WHERE auth_user_id = auth.uid()
  ));

-- Create function to help with user ID lookups
CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS UUID
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT id FROM st_users WHERE auth_user_id = auth.uid() LIMIT 1;
$$; 