-- Migration: Create test game function
-- Created: 2024-01-01 12:00:07
-- Description: Create a function to test game creation bypassing RLS

-- Create a function that runs with elevated privileges to bypass RLS
CREATE OR REPLACE FUNCTION create_game_test(
  p_game_id UUID,
  p_team_id UUID,
  p_organizer_id UUID,
  p_title TEXT,
  p_sport TEXT,
  p_venue TEXT,
  p_scheduled_at TIMESTAMPTZ,
  p_duration_minutes INTEGER,
  p_max_players INTEGER,
  p_is_public BOOLEAN,
  p_requires_rsvp BOOLEAN,
  p_auto_confirm_rsvp BOOLEAN,
  p_weather_dependent BOOLEAN,
  p_created_at TIMESTAMPTZ,
  p_updated_at TIMESTAMPTZ
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER -- This allows the function to bypass RLS
AS $$
BEGIN
  INSERT INTO st_games (
    id,
    team_id,
    organizer_id,
    title,
    sport,
    venue,
    scheduled_at,
    duration_minutes,
    max_players,
    is_public,
    requires_rsvp,
    auto_confirm_rsvp,
    weather_dependent,
    created_at,
    updated_at
  ) VALUES (
    p_game_id,
    p_team_id,
    p_organizer_id,
    p_title,
    p_sport,
    p_venue,
    p_scheduled_at,
    p_duration_minutes,
    p_max_players,
    p_is_public,
    p_requires_rsvp,
    p_auto_confirm_rsvp,
    p_weather_dependent,
    p_created_at,
    p_updated_at
  );
END;
$$; 