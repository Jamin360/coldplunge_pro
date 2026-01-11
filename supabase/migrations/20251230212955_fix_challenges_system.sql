-- Migration: Fix Challenges System
-- Purpose: Add missing database functions and sample challenge data

-- =========================================================================
-- STEP 1: Create RPC Functions for Challenge Participant Management
-- =========================================================================

-- Function to increment challenge participants count
CREATE OR REPLACE FUNCTION increment_challenge_participants(challenge_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE challenges
  SET participants_count = COALESCE(participants_count, 0) + 1
  WHERE id = challenge_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement challenge participants count
CREATE OR REPLACE FUNCTION decrement_challenge_participants(challenge_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE challenges
  SET participants_count = GREATEST(COALESCE(participants_count, 0) - 1, 0)
  WHERE id = challenge_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =========================================================================
-- STEP 2: Create Trigger to Update Progress on Session Creation
-- =========================================================================

-- Function to update challenge progress when a new session is created
CREATE OR REPLACE FUNCTION update_challenge_progress_on_session()
RETURNS TRIGGER AS $$
DECLARE
  v_user_challenge RECORD;
  v_challenge RECORD;
  v_progress NUMERIC;
  v_target_value INTEGER;
  v_current_value INTEGER;
  v_total_duration INTEGER;
  v_has_met_target BOOLEAN;
  v_days_since_start INTEGER;
BEGIN
  -- Loop through user's active challenges
  FOR v_user_challenge IN
    SELECT uc.*, c.challenge_type, c.target_value, c.duration_days, uc.joined_at
    FROM user_challenges uc
    JOIN challenges c ON uc.challenge_id = c.id
    WHERE uc.user_id = NEW.user_id 
      AND uc.is_completed = false
      AND uc.joined_at <= NEW.created_at
  LOOP
    v_progress := 0.0;
    v_target_value := v_user_challenge.target_value;

    CASE v_user_challenge.challenge_type
      WHEN 'streak' THEN
        -- Get current streak from user profile
        SELECT streak_count INTO v_current_value
        FROM user_profiles
        WHERE id = NEW.user_id;

        IF v_target_value > 0 THEN
          v_progress := LEAST((v_current_value::NUMERIC / v_target_value) * 100, 100);
        END IF;

      WHEN 'consistency' THEN
        -- Count total sessions since joining challenge
        SELECT COUNT(*) INTO v_current_value
        FROM plunge_sessions
        WHERE user_id = NEW.user_id
          AND created_at >= v_user_challenge.joined_at;

        IF v_target_value > 0 THEN
          v_progress := LEAST((v_current_value::NUMERIC / v_target_value) * 100, 100);
        END IF;

      WHEN 'duration' THEN
        -- Sum total duration since joining challenge
        SELECT COALESCE(SUM(duration), 0) INTO v_total_duration
        FROM plunge_sessions
        WHERE user_id = NEW.user_id
          AND created_at >= v_user_challenge.joined_at;

        IF v_target_value > 0 THEN
          v_progress := LEAST((v_total_duration::NUMERIC / v_target_value) * 100, 100);
        END IF;

      WHEN 'temperature' THEN
        -- Check if any session meets temperature requirement
        SELECT EXISTS(
          SELECT 1
          FROM plunge_sessions
          WHERE user_id = NEW.user_id
            AND created_at >= v_user_challenge.joined_at
            AND temperature <= v_target_value
        ) INTO v_has_met_target;

        IF v_has_met_target THEN
          -- Calculate based on days completed vs challenge duration
          v_days_since_start := EXTRACT(DAYS FROM (NOW() - v_user_challenge.joined_at))::INTEGER + 1;
          v_progress := LEAST((v_days_since_start::NUMERIC / v_user_challenge.duration_days) * 100, 100);
        END IF;
    END CASE;

    -- Update progress if changed
    IF v_progress != COALESCE(v_user_challenge.progress, 0.0) THEN
      UPDATE user_challenges
      SET 
        progress = v_progress,
        is_completed = (v_progress >= 100.0),
        completed_at = CASE WHEN v_progress >= 100.0 THEN NOW() ELSE NULL END
      WHERE id = v_user_challenge.id;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for automatic progress updates
DROP TRIGGER IF EXISTS trigger_update_challenge_progress ON plunge_sessions;
CREATE TRIGGER trigger_update_challenge_progress
  AFTER INSERT ON plunge_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_challenge_progress_on_session();

-- =========================================================================
-- STEP 3: Insert Sample Challenge Data
-- =========================================================================

-- Insert diverse challenge types for testing
INSERT INTO challenges (
  title,
  description,
  challenge_type,
  difficulty,
  target_value,
  duration_days,
  reward_description,
  image_url,
  is_active,
  end_date
) VALUES
  (
    'Ice Warrior - 7 Day Streak',
    'Complete a cold plunge session every day for 7 consecutive days. Build your mental toughness and establish a consistent routine.',
    'streak',
    'easy',
    7,
    7,
    'Ice Warrior Badge + 100 XP',
    'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800',
    true,
    NOW() + INTERVAL '30 days'
  ),
  (
    'Arctic Explorer - 30 Day Journey',
    'Take the ultimate challenge! Complete 30 cold plunge sessions in 30 days. Transform your body and mind through consistent cold exposure.',
    'streak',
    'hard',
    30,
    30,
    'Arctic Explorer Badge + 500 XP + Exclusive Community Access',
    'https://images.unsplash.com/photo-1483921020237-2ff51e8e4b22?w=800',
    true,
    NOW() + INTERVAL '45 days'
  ),
  (
    'Consistency Champion',
    'Complete 20 cold plunge sessions within 30 days. Consistency is key to building resilience and reaping the benefits of cold exposure.',
    'consistency',
    'medium',
    20,
    30,
    'Consistency Champion Badge + 250 XP',
    'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800',
    true,
    NOW() + INTERVAL '35 days'
  ),
  (
    'Duration Master - 60 Minutes Total',
    'Accumulate 60 minutes of total cold plunge time. Push your limits and build endurance through extended cold exposure.',
    'duration',
    'medium',
    3600,
    21,
    'Duration Master Badge + 200 XP',
    'https://images.unsplash.com/photo-1483921020237-2ff51e8e4b22?w=800',
    true,
    NOW() + INTERVAL '25 days'
  ),
  (
    'Extreme Cold Challenge',
    'Complete sessions at or below 50°F (10°C) for 14 consecutive days. This is for experienced cold plungers ready to push boundaries.',
    'temperature',
    'hard',
    50,
    14,
    'Extreme Cold Warrior Badge + 400 XP + Special Recognition',
    'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800',
    true,
    NOW() + INTERVAL '20 days'
  ),
  (
    'Weekend Warrior',
    'Complete cold plunge sessions every Saturday and Sunday for 4 weeks. Perfect for busy schedules.',
    'consistency',
    'easy',
    8,
    28,
    'Weekend Warrior Badge + 150 XP',
    'https://images.unsplash.com/photo-1483921020237-2ff51e8e4b22?w=800',
    true,
    NOW() + INTERVAL '30 days'
  );

-- Update participants count to 0 for all challenges (will be incremented when users join)
UPDATE challenges SET participants_count = 0;

-- =========================================================================
-- STEP 4: Grant Execute Permissions
-- =========================================================================

-- Grant execute permission to authenticated users for RPC functions
GRANT EXECUTE ON FUNCTION increment_challenge_participants TO authenticated;
GRANT EXECUTE ON FUNCTION decrement_challenge_participants TO authenticated;

-- =========================================================================
-- VERIFICATION QUERIES (for testing)
-- =========================================================================

-- Verify challenges were created
-- SELECT id, title, challenge_type, difficulty, target_value, duration_days FROM challenges;

-- Verify functions exist
-- SELECT routine_name FROM information_schema.routines 
-- WHERE routine_schema = 'public' 
-- AND routine_name LIKE '%challenge%';

-- Verify trigger exists
-- SELECT trigger_name, event_manipulation, event_object_table 
-- FROM information_schema.triggers 
-- WHERE trigger_name = 'trigger_update_challenge_progress';