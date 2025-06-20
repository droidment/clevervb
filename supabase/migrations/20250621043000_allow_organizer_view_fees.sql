-- Migration: Allow game organizers to view fee records for their games
-- Description: Adds RLS policy to permit SELECT access on st_fees for users who are the organizer of the related game.
-- Generated on 2025-06-21

-- Ensure RLS is enabled
ALTER TABLE public.st_fees ENABLE ROW LEVEL SECURITY;

-- Clean up any existing conflicting policy
DROP POLICY IF EXISTS "Organizer can manage fees for their games" ON public.st_fees;

-- Policy: Organizer can manage fees for their games
CREATE POLICY "Organizer can manage fees for their games"
ON public.st_fees
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM public.st_games g
    JOIN public.st_users u ON g.organizer_id = u.id
    WHERE g.id = st_fees.game_id
      AND u.auth_user_id = auth.uid()
  )
);

-- Also keep existing policy allowing players to view their own fee records
DROP POLICY IF EXISTS "User can view own fees" ON public.st_fees;
CREATE POLICY "User can view own fees"
ON public.st_fees
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.st_users u
    WHERE u.id = st_fees.user_id
      AND u.auth_user_id = auth.uid()
  )
);

-- Allow anyone (player) to create their own fee rows when checking in
DROP POLICY IF EXISTS "Player can create own fees" ON public.st_fees;
CREATE POLICY "Player can create own fees" 
ON public.st_fees
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.st_users u
    WHERE u.id = st_fees.user_id
      AND u.auth_user_id = auth.uid()
  )
); 