-- Migration: Reset all RLS policies
-- Created: 2024-01-01 12:00:04
-- Description: Completely reset all RLS policies to fix infinite recursion

-- First, disable RLS on all tables
ALTER TABLE st_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_teams DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_team_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_games DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_rsvps DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_attendances DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_fees DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_invitations DISABLE ROW LEVEL SECURITY;

-- Drop ALL possible policies (even if they don't exist)
DO $$ 
DECLARE 
    policy_record RECORD;
BEGIN
    -- Drop all policies on st_users
    FOR policy_record IN SELECT policyname FROM pg_policies WHERE tablename = 'st_users' LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON st_users';
    END LOOP;
    
    -- Drop all policies on st_teams
    FOR policy_record IN SELECT policyname FROM pg_policies WHERE tablename = 'st_teams' LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON st_teams';
    END LOOP;
    
    -- Drop all policies on st_team_members
    FOR policy_record IN SELECT policyname FROM pg_policies WHERE tablename = 'st_team_members' LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON st_team_members';
    END LOOP;
    
    -- Drop all policies on st_games
    FOR policy_record IN SELECT policyname FROM pg_policies WHERE tablename = 'st_games' LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON st_games';
    END LOOP;
    
    -- Drop all policies on st_rsvps
    FOR policy_record IN SELECT policyname FROM pg_policies WHERE tablename = 'st_rsvps' LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON st_rsvps';
    END LOOP;
    
    -- Drop all policies on st_attendances
    FOR policy_record IN SELECT policyname FROM pg_policies WHERE tablename = 'st_attendances' LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON st_attendances';
    END LOOP;
    
    -- Drop all policies on st_fees
    FOR policy_record IN SELECT policyname FROM pg_policies WHERE tablename = 'st_fees' LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON st_fees';
    END LOOP;
    
    -- Drop all policies on st_invitations
    FOR policy_record IN SELECT policyname FROM pg_policies WHERE tablename = 'st_invitations' LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON st_invitations';
    END LOOP;
END $$;

-- Re-enable RLS
ALTER TABLE st_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE st_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE st_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE st_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE st_rsvps ENABLE ROW LEVEL SECURITY;
ALTER TABLE st_attendances ENABLE ROW LEVEL SECURITY;
ALTER TABLE st_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE st_invitations ENABLE ROW LEVEL SECURITY;

-- Create simple, non-recursive RLS policies

-- st_users: Users can read/write their own profile
CREATE POLICY "users_own_profile" ON st_users
  FOR ALL USING (auth.uid() = auth_user_id);

-- st_teams: Everyone can view teams, organizers can modify their own
CREATE POLICY "teams_view_all" ON st_teams
  FOR SELECT USING (true);

CREATE POLICY "teams_organizer_insert" ON st_teams
  FOR INSERT WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "teams_organizer_update" ON st_teams
  FOR UPDATE USING (organizer_id = auth.uid());

CREATE POLICY "teams_organizer_delete" ON st_teams
  FOR DELETE USING (organizer_id = auth.uid());

-- st_team_members: Simplified to avoid recursion
CREATE POLICY "team_members_view_all" ON st_team_members
  FOR SELECT USING (true);

CREATE POLICY "team_members_insert_self" ON st_team_members
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "team_members_delete_self" ON st_team_members
  FOR DELETE USING (user_id = auth.uid());

-- st_games: Simplified access
CREATE POLICY "games_view_all" ON st_games
  FOR SELECT USING (true);

CREATE POLICY "games_organizer_insert" ON st_games
  FOR INSERT WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "games_organizer_update" ON st_games
  FOR UPDATE USING (organizer_id = auth.uid());

CREATE POLICY "games_organizer_delete" ON st_games
  FOR DELETE USING (organizer_id = auth.uid());

-- st_rsvps: Users can manage their own RSVPs
CREATE POLICY "rsvps_user_own" ON st_rsvps
  FOR ALL USING (user_id = auth.uid());

-- st_attendances: Users can view their own attendance
CREATE POLICY "attendance_view_own" ON st_attendances
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "attendance_insert_self" ON st_attendances
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- st_fees: Users can view their own fees
CREATE POLICY "fees_view_own" ON st_fees
  FOR SELECT USING (user_id = auth.uid());

-- st_invitations: Simple invitation access
CREATE POLICY "invitations_view_email" ON st_invitations
  FOR SELECT USING (invited_email = auth.email());

CREATE POLICY "invitations_manage_own" ON st_invitations
  FOR ALL USING (invited_by = auth.uid()); 