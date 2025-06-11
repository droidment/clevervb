-- Migration: Create Sports Team Management Tables
-- Created: 2024-01-01
-- Description: Initial schema for sports team management app

-- Enable PostGIS extension for location-based queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- Table 1: st_users
-- Stores user profile information and authentication data
CREATE TABLE st_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  date_of_birth DATE NOT NULL,
  skill_level TEXT CHECK (skill_level IN ('beginner', 'intermediate', 'advanced')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table 2: st_teams
-- Stores team information and metadata
CREATE TABLE st_teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  sport TEXT NOT NULL CHECK (sport IN ('volleyball', 'pickleball')),
  organizer_id UUID REFERENCES st_users(id) ON DELETE CASCADE,
  description TEXT,
  max_players INTEGER NOT NULL DEFAULT 8,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table 3: st_team_members
-- Junction table for team membership with status tracking
CREATE TABLE st_team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID REFERENCES st_teams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES st_users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'player' CHECK (role IN ('organizer', 'player')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_activity_date DATE,
  consecutive_absences INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE(team_id, user_id)
);

-- Table 4: st_invitations
-- Stores team invitation tokens and tracking
CREATE TABLE st_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID REFERENCES st_teams(id) ON DELETE CASCADE,
  invited_by UUID REFERENCES st_users(id) ON DELETE CASCADE,
  invited_email TEXT,
  invited_phone TEXT,
  token TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
  used_at TIMESTAMP WITH TIME ZONE,
  used_by UUID REFERENCES st_users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CHECK (invited_email IS NOT NULL OR invited_phone IS NOT NULL)
);

-- Table 5: st_games
-- Stores game/match information and scheduling
CREATE TABLE st_games (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID REFERENCES st_teams(id) ON DELETE CASCADE,
  organizer_id UUID REFERENCES st_users(id) ON DELETE CASCADE,
  title TEXT,
  venue_name TEXT NOT NULL,
  venue_address TEXT NOT NULL,
  court_number TEXT,
  game_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME,
  fee_per_player DECIMAL(10,2) DEFAULT 0,
  max_players INTEGER NOT NULL,
  guests_allowed BOOLEAN DEFAULT FALSE,
  max_guests_per_player INTEGER DEFAULT 0,
  location GEOGRAPHY(POINT, 4326), -- PostGIS for location searches
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table 6: st_rsvps
-- Tracks player RSVPs and guest information
CREATE TABLE st_rsvps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id UUID REFERENCES st_games(id) ON DELETE CASCADE,
  user_id UUID REFERENCES st_users(id) ON DELETE CASCADE,
  response TEXT NOT NULL CHECK (response IN ('yes', 'no', 'maybe')),
  guest_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(game_id, user_id)
);

-- Table 7: st_attendances
-- Records actual attendance for games
CREATE TABLE st_attendances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id UUID REFERENCES st_games(id) ON DELETE CASCADE,
  user_id UUID REFERENCES st_users(id) ON DELETE CASCADE,
  checked_in_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  guest_count INTEGER DEFAULT 0,
  notes TEXT,
  UNIQUE(game_id, user_id)
);

-- Table 8: st_fees
-- Tracks fee calculations and payment status
CREATE TABLE st_fees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id UUID REFERENCES st_games(id) ON DELETE CASCADE,
  user_id UUID REFERENCES st_users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  guest_fee DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) GENERATED ALWAYS AS (amount + guest_fee) STORED,
  paid_at TIMESTAMP WITH TIME ZONE,
  payment_method TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
-- User lookups
CREATE INDEX idx_st_users_auth_user_id ON st_users(auth_user_id);
CREATE INDEX idx_st_users_email ON st_users(email);

-- Team member queries
CREATE INDEX idx_st_team_members_team_id ON st_team_members(team_id);
CREATE INDEX idx_st_team_members_user_id ON st_team_members(user_id);
CREATE INDEX idx_st_team_members_active ON st_team_members(team_id, is_active);

-- Game queries
CREATE INDEX idx_st_games_team_id ON st_games(team_id);
CREATE INDEX idx_st_games_date ON st_games(game_date);
CREATE INDEX idx_st_games_location ON st_games USING GIST(location);

-- RSVP and attendance lookups
CREATE INDEX idx_st_rsvps_game_id ON st_rsvps(game_id);
CREATE INDEX idx_st_attendances_game_id ON st_attendances(game_id);
CREATE INDEX idx_st_attendances_user_id ON st_attendances(user_id);

-- Fee tracking
CREATE INDEX idx_st_fees_game_id ON st_fees(game_id);
CREATE INDEX idx_st_fees_user_id ON st_fees(user_id);
CREATE INDEX idx_st_fees_unpaid ON st_fees(user_id) WHERE paid_at IS NULL;

-- Invitation lookups
CREATE INDEX idx_st_invitations_token ON st_invitations(token);
CREATE INDEX idx_st_invitations_team_id ON st_invitations(team_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_st_users_updated_at BEFORE UPDATE ON st_users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_st_teams_updated_at BEFORE UPDATE ON st_teams FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_st_games_updated_at BEFORE UPDATE ON st_games FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_st_rsvps_updated_at BEFORE UPDATE ON st_rsvps FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 