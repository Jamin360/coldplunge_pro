-- Migration: Add User-Specific Challenge Expiration
-- Purpose: Fix expired challenges issue by tracking expiration per user
-- Date: 2026-01-26

-- =========================================================================
-- STEP 1: Add expires_at column to user_challenges
-- =========================================================================

-- Add the expires_at column to track when each user's challenge expires
ALTER TABLE public.user_challenges 
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

-- =========================================================================
-- STEP 2: Backfill existing data
-- =========================================================================

-- For existing joined challenges, calculate expires_at based on:
-- joined_at + duration_days from the challenge
UPDATE public.user_challenges uc
SET expires_at = uc.joined_at + (c.duration_days || ' days')::INTERVAL
FROM public.challenges c
WHERE uc.challenge_id = c.id
  AND uc.expires_at IS NULL;

-- =========================================================================
-- STEP 3: Add index for performance
-- =========================================================================

-- Add index on expires_at for efficient querying
CREATE INDEX IF NOT EXISTS idx_user_challenges_expires_at 
ON public.user_challenges(expires_at);

-- Add composite index for user_id + expires_at
CREATE INDEX IF NOT EXISTS idx_user_challenges_user_expires 
ON public.user_challenges(user_id, expires_at);

-- =========================================================================
-- STEP 4: Create function to check if challenge is expired for user
-- =========================================================================

CREATE OR REPLACE FUNCTION is_user_challenge_expired(user_challenge_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_expires_at TIMESTAMPTZ;
  v_is_completed BOOLEAN;
BEGIN
  SELECT expires_at, is_completed
  INTO v_expires_at, v_is_completed
  FROM user_challenges
  WHERE id = user_challenge_id;

  -- If completed, not expired
  IF v_is_completed THEN
    RETURN FALSE;
  END IF;

  -- If no expiration date set, not expired
  IF v_expires_at IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Check if current time is past expiration
  RETURN NOW() > v_expires_at;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION is_user_challenge_expired TO authenticated;

-- =========================================================================
-- STEP 5: Create view for active/expired challenges per user
-- =========================================================================

-- Create a view that shows challenge status for each user
CREATE OR REPLACE VIEW user_challenge_status AS
SELECT 
  uc.id,
  uc.user_id,
  uc.challenge_id,
  uc.progress,
  uc.is_completed,
  uc.joined_at,
  uc.expires_at,
  uc.completed_at,
  c.title,
  c.difficulty,
  c.challenge_type,
  c.target_value,
  c.duration_days,
  c.reward_description,
  c.image_url,
  CASE 
    WHEN uc.is_completed THEN 'completed'
    WHEN uc.expires_at IS NULL THEN 'active'
    WHEN NOW() > uc.expires_at THEN 'expired'
    ELSE 'active'
  END AS status,
  CASE
    WHEN uc.expires_at IS NULL THEN NULL
    WHEN NOW() > uc.expires_at THEN 0
    ELSE EXTRACT(EPOCH FROM (uc.expires_at - NOW()))::INTEGER
  END AS seconds_remaining
FROM user_challenges uc
JOIN challenges c ON uc.challenge_id = c.id;

-- Grant access to the view
GRANT SELECT ON user_challenge_status TO authenticated;

-- =========================================================================
-- VERIFICATION NOTES
-- =========================================================================

-- After migration, verify:
-- 1. All existing user_challenges have expires_at set
-- SELECT COUNT(*) FROM user_challenges WHERE expires_at IS NULL;

-- 2. View returns correct status
-- SELECT * FROM user_challenge_status WHERE user_id = '<your-user-id>';

-- 3. Function works correctly
-- SELECT is_user_challenge_expired(id) FROM user_challenges LIMIT 5;
