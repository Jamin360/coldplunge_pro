-- Update challenges system to use exactly 9 curated challenges
-- This migration replaces all existing challenges with a clean, well-defined set

-- First, deactivate all existing challenges
UPDATE public.challenges SET is_active = false;

-- Delete all existing challenges to start fresh
DELETE FROM public.challenges;

-- Insert the 9 curated challenges
-- Valid challenge_type values: 'streak', 'duration', 'temperature', 'consistency'

-- ==========================================================
-- BEGINNER CHALLENGES
-- ==========================================================

-- 1) Quick Start
INSERT INTO public.challenges (
    title,
    description,
    challenge_type,
    target_value,
    duration_days,
    difficulty,
    reward_description,
    image_url,
    is_active
) VALUES (
    'Quick Start',
    'Complete 5 cold plunge sessions within 7 days. Build momentum and kickstart your cold plunge journey.',
    'consistency', -- session_count + time_window
    5, -- 5 sessions
    7, -- within 7 days
    'beginner',
    'Earn the Quick Start badge and begin your transformation',
    'https://images.unsplash.com/photo-1551632811-56155776d0cd?w=800&auto=format&fit=crop',
    true
);

-- 2) Two-Minute Club
INSERT INTO public.challenges (
    title,
    description,
    challenge_type,
    target_value,
    duration_days,
    difficulty,
    reward_description,
    image_url,
    is_active
) VALUES (
    'Two-Minute Club',
    'Complete ONE cold plunge session lasting at least 2 minutes. Join the elite club of endurance.',
    'duration', -- single_session_duration
    120, -- 2 minutes in seconds
    30, -- 30 days to complete
    'beginner',
    'Earn the Two-Minute Club badge and special recognition',
    'https://images.pixabay.com/photo/2017/08/06/07/22/cold-2589944_1280.jpg?w=800',
    true
);

-- 3) Ice Breaker
INSERT INTO public.challenges (
    title,
    description,
    challenge_type,
    target_value,
    duration_days,
    difficulty,
    reward_description,
    image_url,
    is_active
) VALUES (
    'Ice Breaker',
    'Complete 10 cold plunge sessions at or below 12°C (54°F). Experience the power of extreme cold.',
    'temperature', -- session_count + temperature_threshold
    12, -- 12°C threshold
    30, -- 30 days to complete
    'beginner',
    'Earn the Ice Breaker badge for mastering cold tolerance',
    'https://images.unsplash.com/photo-1483921020237-2ff51e8e4b22?w=800&auto=format&fit=crop',
    true
);

-- ==========================================================
-- INTERMEDIATE CHALLENGES
-- ==========================================================

-- 4) Ice Warrior – 7 Day Streak
INSERT INTO public.challenges (
    title,
    description,
    challenge_type,
    target_value,
    duration_days,
    difficulty,
    reward_description,
    image_url,
    is_active
) VALUES (
    'Ice Warrior – 7 Day Streak',
    'Complete at least one plunge per day for 7 consecutive days. Build the warrior mindset through consistency.',
    'streak', -- consecutive days
    7, -- 7 day streak
    7, -- duration matches target for streak challenges
    'intermediate',
    'Earn the Ice Warrior badge and 100 bonus points',
    'https://images.pexels.com/photos/4498481/pexels-photo-4498481.jpeg?w=800&auto=compress',
    true
);

-- 5) Weekend Warrior
INSERT INTO public.challenges (
    title,
    description,
    challenge_type,
    target_value,
    duration_days,
    difficulty,
    reward_description,
    image_url,
    is_active
) VALUES (
    'Weekend Warrior',
    'Complete at least one plunge on BOTH Saturday and Sunday for 4 consecutive weeks. Master the weekend routine.',
    'consistency', -- custom: day_of_week + streak (handled as consistency with special logic)
    8, -- 8 weekend days (4 weeks × 2 days)
    28, -- 4 weeks = 28 days
    'intermediate',
    'Earn the Weekend Warrior badge for weekend dedication',
    'https://images.unsplash.com/photo-1483728642387-6c3bdd6c93e5?w=800&auto=format&fit=crop',
    true
);

-- 6) Monthly Milestone
INSERT INTO public.challenges (
    title,
    description,
    challenge_type,
    target_value,
    duration_days,
    difficulty,
    reward_description,
    image_url,
    is_active
) VALUES (
    'Monthly Milestone',
    'Complete a 14-day consecutive plunge streak. Achieve a major milestone in your cold exposure journey.',
    'streak', -- consecutive days
    14, -- 14 day streak
    14, -- duration matches target for streak challenges
    'intermediate',
    'Earn the Monthly Milestone badge and 150 bonus points',
    'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=800&auto=format&fit=crop',
    true
);

-- ==========================================================
-- ADVANCED CHALLENGES
-- ==========================================================

-- 7) Ice Master
INSERT INTO public.challenges (
    title,
    description,
    challenge_type,
    target_value,
    duration_days,
    difficulty,
    reward_description,
    image_url,
    is_active
) VALUES (
    'Ice Master',
    'Complete a 14-day consecutive plunge streak at an advanced level. Master the art of cold exposure.',
    'streak', -- consecutive days
    14, -- 14 day streak
    14, -- duration matches target for streak challenges
    'advanced',
    'Earn the legendary Ice Master badge and exclusive profile badge',
    'https://images.pexels.com/photos/3935702/pexels-photo-3935702.jpeg?w=800&auto=compress',
    true
);

-- 8) Extreme Cold Challenge
INSERT INTO public.challenges (
    title,
    description,
    challenge_type,
    target_value,
    duration_days,
    difficulty,
    reward_description,
    image_url,
    is_active
) VALUES (
    'Extreme Cold Challenge',
    'Complete at least one plunge per day at or below 50°F (10°C) for 14 consecutive days. Push your limits.',
    'temperature', -- temperature + streak (special handling needed)
    10, -- 10°C (50°F) threshold
    14, -- 14 days
    'advanced',
    'Earn the Extreme Cold badge for ultimate cold tolerance',
    'https://images.unsplash.com/photo-1519904981063-b0cf448d479e?w=800&auto=format&fit=crop',
    true
);

-- 9) Arctic Explorer – 30 Day Journey
INSERT INTO public.challenges (
    title,
    description,
    challenge_type,
    target_value,
    duration_days,
    difficulty,
    reward_description,
    image_url,
    is_active
) VALUES (
    'Arctic Explorer – 30 Day Journey',
    'Complete 30 plunge sessions within 30 days. Embark on the ultimate cold exposure journey.',
    'consistency', -- session_count + time_window
    30, -- 30 sessions
    30, -- within 30 days
    'advanced',
    'Earn the Arctic Explorer badge and legendary status',
    'https://images.unsplash.com/photo-1476611338391-6f395a0ebc7b?w=800&auto=format&fit=crop',
    true
);

-- Verification: Ensure we have exactly 9 active challenges
DO $$
DECLARE
    challenge_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO challenge_count FROM public.challenges WHERE is_active = true;
    IF challenge_count != 9 THEN
        RAISE EXCEPTION 'Expected 9 active challenges, found %', challenge_count;
    END IF;
    RAISE NOTICE '✓ Successfully created 9 curated challenges';
END $$;
