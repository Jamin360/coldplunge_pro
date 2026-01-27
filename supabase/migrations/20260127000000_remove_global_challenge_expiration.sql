-- Migration: Remove Global Challenge Expiration Fields
-- Purpose: Remove expires_at from user_challenges and end_date from challenges
--          Challenges now use dynamic expiration based on joined_at + duration_days
-- Date: 2026-01-27

-- =========================================================================
-- STEP 1: Drop expires_at from user_challenges
-- =========================================================================

-- Drop indexes on expires_at first
DROP INDEX IF EXISTS public.idx_user_challenges_expires_at;
DROP INDEX IF EXISTS public.idx_user_challenges_user_expires;

-- Drop the expires_at column (no longer needed - computed dynamically)
ALTER TABLE public.user_challenges 
DROP COLUMN IF EXISTS expires_at;

-- =========================================================================
-- STEP 2: Drop end_date from challenges
-- =========================================================================

-- Drop index on end_date if it exists
DROP INDEX IF EXISTS public.idx_challenges_end_date;

-- Drop the end_date column (challenges are now evergreen, no global expiration)
ALTER TABLE public.challenges 
DROP COLUMN IF EXISTS end_date;

-- =========================================================================
-- STEP 3: Drop old expiration functions
-- =========================================================================

-- Drop the function that checked user challenge expiration (no longer needed)
DROP FUNCTION IF EXISTS is_user_challenge_expired(UUID);

-- =========================================================================
-- STEP 4: Add comments for clarity
-- =========================================================================

COMMENT ON COLUMN public.user_challenges.joined_at IS 
  'Timestamp when user joined challenge. Expiration calculated as joined_at + duration_days from challenges table.';

COMMENT ON COLUMN public.challenges.duration_days IS 
  'Duration of challenge in days. Each user''s challenge expires duration_days after their joined_at timestamp.';

-- =========================================================================
-- NOTES
-- =========================================================================

-- Challenges now work as follows:
-- 1. Challenges have duration_days but NO global end_date
-- 2. Users join a challenge, which sets joined_at
-- 3. Challenge expiration is computed dynamically: joined_at + duration_days
-- 4. Each user has their own personalized timeline starting from their join date
-- 5. Challenges never expire globally - they're "evergreen"
