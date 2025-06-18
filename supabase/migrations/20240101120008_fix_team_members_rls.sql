-- Migration: Fix team members RLS policies for st_users table
-- Created: 2024-01-01 12:00:08
-- Description: Update team members RLS policies to work with st_users table mapping

-- Drop existing team members policies
DROP POLICY IF EXISTS "team_members_view_all" ON st_team_members;
DROP POLICY IF EXISTS "team_members_insert_self" ON st_team_members;
DROP POLICY IF EXISTS "team_members_update_self" ON st_team_members;
DROP POLICY IF EXISTS "team_members_delete_self" ON st_team_members;

-- Create updated team members policies that work with st_users table
CREATE POLICY "team_members_view_all" ON st_team_members
  FOR SELECT USING (true);

CREATE POLICY "team_members_insert_self" ON st_team_members
  FOR INSERT WITH CHECK (
    user_id IN (
      SELECT id FROM st_users WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "team_members_update_self" ON st_team_members
  FOR UPDATE USING (
    user_id IN (
      SELECT id FROM st_users WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "team_members_delete_self" ON st_team_members
  FOR DELETE USING (
    user_id IN (
      SELECT id FROM st_users WHERE auth_user_id = auth.uid()
    )
  ); 