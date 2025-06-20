-- Allow all authenticated users to read basic profile information from st_users
-- Created: 2025-06-21 01:00:00

-- This migration relaxes the RLS policy on st_users so that
-- other authenticated users (e.g., teammates) can read each other's
-- public profile fields like full_name, email, and avatar_url.

-- Revoke overly-strict read policy limited to own profile only
-- but keep it for INSERT/UPDATE operations.

-- Enable row-level security if not already
ALTER TABLE st_users ENABLE ROW LEVEL SECURITY;

-- Drop any previous universal read policy to avoid duplicates
DROP POLICY IF EXISTS "authenticated_can_read_basic_profile" ON st_users;

-- Allow all authenticated users to read (SELECT) any row
CREATE POLICY "authenticated_can_read_basic_profile" ON st_users
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- We leave INSERT/UPDATE/DELETE policies unchanged to ensure
-- users can only manage their own profile data. 