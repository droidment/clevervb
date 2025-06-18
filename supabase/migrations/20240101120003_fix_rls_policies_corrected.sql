-- Migration: Fix RLS policies (corrected)
-- Created: 2024-01-01 12:00:03
-- Description: Fix infinite recursion in RLS policies with correct column names

-- First, disable RLS temporarily to clear any problematic policies
ALTER TABLE st_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_teams DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_team_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_games DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_rsvps DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_attendances DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_fees DISABLE ROW LEVEL SECURITY;
ALTER TABLE st_invitations DISABLE ROW LEVEL SECURITY;

-- Drop any existing policies that might cause conflicts
DROP POLICY IF EXISTS "st_users_policy" ON st_users;
DROP POLICY IF EXISTS "st_teams_policy" ON st_teams;
DROP POLICY IF EXISTS "st_team_members_policy" ON st_team_members;
DROP POLICY IF EXISTS "st_games_policy" ON st_games;
DROP POLICY IF EXISTS "st_rsvps_policy" ON st_rsvps;
DROP POLICY IF EXISTS "st_attendances_policy" ON st_attendances;
DROP POLICY IF EXISTS "st_fees_policy" ON st_fees;
DROP POLICY IF EXISTS "st_invitations_policy" ON st_invitations;

-- Drop any other potential policy names
DROP POLICY IF EXISTS "Anyone can view public teams" ON st_teams;
DROP POLICY IF EXISTS "Organizers can modify their teams" ON st_teams;
DROP POLICY IF EXISTS "Users can view team memberships" ON st_team_members;
DROP POLICY IF EXISTS "Users can manage own memberships" ON st_team_members;
DROP POLICY IF EXISTS "Organizers can manage team members" ON st_team_members;

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
CREATE POLICY "Users can manage own profile" ON st_users
  FOR ALL USING (auth.uid() = auth_user_id);

-- st_teams: Everyone can view teams, organizers can modify their own
CREATE POLICY "Anyone can view teams" ON st_teams
  FOR SELECT USING (true);

CREATE POLICY "Organizers can modify their teams" ON st_teams
  FOR INSERT WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "Organizers can update their teams" ON st_teams
  FOR UPDATE USING (organizer_id = auth.uid());

CREATE POLICY "Organizers can delete their teams" ON st_teams
  FOR DELETE USING (organizer_id = auth.uid());

-- st_team_members: Simplified approach to avoid recursion
CREATE POLICY "Anyone can view team members" ON st_team_members
  FOR SELECT USING (true);

CREATE POLICY "Users can join teams" ON st_team_members
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can leave teams" ON st_team_members
  FOR DELETE USING (user_id = auth.uid());

-- st_games: Simplified access
CREATE POLICY "Anyone can view games" ON st_games
  FOR SELECT USING (true);

CREATE POLICY "Organizers can manage games" ON st_games
  FOR INSERT WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "Organizers can update games" ON st_games
  FOR UPDATE USING (organizer_id = auth.uid());

CREATE POLICY "Organizers can delete games" ON st_games
  FOR DELETE USING (organizer_id = auth.uid());

-- st_rsvps: Users can manage their own RSVPs
CREATE POLICY "Users can manage own RSVPs" ON st_rsvps
  FOR ALL USING (user_id = auth.uid());

-- st_attendances: Users can view their own attendance
CREATE POLICY "Users can view own attendance" ON st_attendances
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can check in themselves" ON st_attendances
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- st_fees: Users can view their own fees
CREATE POLICY "Users can view own fees" ON st_fees
  FOR SELECT USING (user_id = auth.uid());

-- st_invitations: Simple invitation access
CREATE POLICY "Users can view invitations sent to them" ON st_invitations
  FOR SELECT USING (invited_email = auth.email());

CREATE POLICY "Users can manage their invitations" ON st_invitations
  FOR INSERT WITH CHECK (invited_by = auth.uid());

CREATE POLICY "Users can update their invitations" ON st_invitations
  FOR UPDATE USING (invited_by = auth.uid());

CREATE POLICY "Users can delete their invitations" ON st_invitations
  FOR DELETE USING (invited_by = auth.uid()); 