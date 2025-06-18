-- Migration: Fix games RLS policies for st_users table
-- Created: 2024-01-01 12:00:06
-- Description: Update games RLS policies to work with st_users table mapping

-- Drop existing games policies
DROP POLICY IF EXISTS "games_view_all" ON st_games;
DROP POLICY IF EXISTS "games_organizer_insert" ON st_games;
DROP POLICY IF EXISTS "games_organizer_update" ON st_games;
DROP POLICY IF EXISTS "games_organizer_delete" ON st_games;

-- Create updated games policies that work with st_users table
CREATE POLICY "games_view_all" ON st_games
  FOR SELECT USING (true);

CREATE POLICY "games_organizer_insert" ON st_games
  FOR INSERT WITH CHECK (
    organizer_id IN (
      SELECT id FROM st_users WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "games_organizer_update" ON st_games
  FOR UPDATE USING (
    organizer_id IN (
      SELECT id FROM st_users WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "games_organizer_delete" ON st_games
  FOR DELETE USING (
    organizer_id IN (
      SELECT id FROM st_users WHERE auth_user_id = auth.uid()
    )
  ); 