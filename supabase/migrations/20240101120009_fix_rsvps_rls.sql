-- Migration: Fix RSVP RLS policies for st_users table
-- Created: 2024-01-01 12:00:09
-- Description: Update RSVP RLS policies to work with st_users table mapping

-- Drop existing RSVP policies
DROP POLICY IF EXISTS "rsvps_view_all" ON st_rsvps;
DROP POLICY IF EXISTS "rsvps_insert_self" ON st_rsvps;
DROP POLICY IF EXISTS "rsvps_update_self" ON st_rsvps;
DROP POLICY IF EXISTS "rsvps_delete_self" ON st_rsvps;

-- Create updated RSVP policies that work with st_users table
CREATE POLICY "rsvps_view_all" ON st_rsvps
  FOR SELECT USING (true);

CREATE POLICY "rsvps_insert_self" ON st_rsvps
  FOR INSERT WITH CHECK (
    user_id IN (
      SELECT id FROM st_users WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "rsvps_update_self" ON st_rsvps
  FOR UPDATE USING (
    user_id IN (
      SELECT id FROM st_users WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "rsvps_delete_self" ON st_rsvps
  FOR DELETE USING (
    user_id IN (
      SELECT id FROM st_users WHERE auth_user_id = auth.uid()
    )
  ); 