-- Add diverse sample challenges covering all challenge types and difficulty levels
-- This migration inserts realistic cold plunge challenges with proper data types

DO $$
BEGIN
    -- Challenge 1: Weekend Warrior (Easy Streak)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Weekend Warrior',
        'Complete a cold plunge every day for 7 consecutive days. Perfect for beginners looking to build a solid foundation.',
        'streak'::public.challenge_type,
        'easy'::public.challenge_difficulty,
        7,
        7,
        CURRENT_DATE + INTERVAL '7 days',
        'https://images.pexels.com/photos/4498481/pexels-photo-4498481.jpeg',
        'Earn the Weekend Warrior badge and 100 XP points',
        true
    );

    -- Challenge 2: Consistency Champion (Medium Consistency)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Consistency Champion',
        'Complete 15 cold plunge sessions within 30 days. Build lasting habits through consistent practice.',
        'consistency'::public.challenge_type,
        'medium'::public.challenge_difficulty,
        15,
        30,
        CURRENT_DATE + INTERVAL '30 days',
        'https://images.unsplash.com/photo-1551632811-56173faa6f34',
        'Consistency Champion badge + 250 XP + Special avatar frame',
        true
    );

    -- Challenge 3: Arctic Explorer (Hard Streak)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Arctic Explorer',
        'Complete 30 consecutive days of cold plunging. This challenge requires dedication and mental fortitude.',
        'streak'::public.challenge_type,
        'hard'::public.challenge_difficulty,
        30,
        30,
        CURRENT_DATE + INTERVAL '30 days',
        'https://images.unsplash.com/photo-1483921020237-2ff51e8e4b22',
        'Arctic Explorer badge + 500 XP + Exclusive community title',
        true
    );

    -- Challenge 4: Duration Master (Medium Duration)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Duration Master',
        'Accumulate 60 minutes of total cold plunge time within 14 days. Push your limits!',
        'duration'::public.challenge_type,
        'medium'::public.challenge_difficulty,
        60,
        14,
        CURRENT_DATE + INTERVAL '14 days',
        'https://images.pexels.com/photos/6551415/pexels-photo-6551415.jpeg',
        'Duration Master badge + 300 XP + Achievement certificate',
        true
    );

    -- Challenge 5: Polar Plunge (Hard Temperature)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Polar Plunge',
        'Complete 10 sessions at or below 10°C. Only the bravest dare to take this challenge!',
        'temperature'::public.challenge_type,
        'hard'::public.challenge_difficulty,
        10,
        21,
        CURRENT_DATE + INTERVAL '21 days',
        'https://images.unsplash.com/photo-1548191265-cc70d3d45ba1',
        'Polar Plunge badge + 450 XP + Cold warrior title',
        true
    );

    -- Challenge 6: Quick Start (Easy Consistency)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Quick Start',
        'Complete 5 sessions in your first 7 days. Perfect for newcomers to build momentum!',
        'consistency'::public.challenge_type,
        'easy'::public.challenge_difficulty,
        5,
        7,
        CURRENT_DATE + INTERVAL '7 days',
        'https://images.pexels.com/photos/3094215/pexels-photo-3094215.jpeg',
        'Quick Start badge + 75 XP',
        true
    );

    -- Challenge 7: Marathon Mindset (Hard Duration)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Marathon Mindset',
        'Achieve 120 minutes total cold plunge time within 30 days. Ultimate endurance test!',
        'duration'::public.challenge_type,
        'hard'::public.challenge_difficulty,
        120,
        30,
        CURRENT_DATE + INTERVAL '30 days',
        'https://images.unsplash.com/photo-1551632811-56173faa6f34',
        'Marathon Mindset badge + 600 XP + Elite status',
        true
    );

    -- Challenge 8: Temperature Tester (Easy Temperature)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Temperature Tester',
        'Complete 5 sessions at 15°C or below. Great starting point for temperature challenges.',
        'temperature'::public.challenge_type,
        'easy'::public.challenge_difficulty,
        15,
        14,
        CURRENT_DATE + INTERVAL '14 days',
        'https://images.pexels.com/photos/8327675/pexels-photo-8327675.jpeg',
        'Temperature Tester badge + 125 XP',
        true
    );

    -- Challenge 9: Monthly Milestone (Medium Streak)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Monthly Milestone',
        'Maintain a 14-day streak without missing a single day. Consistency is key!',
        'streak'::public.challenge_type,
        'medium'::public.challenge_difficulty,
        14,
        14,
        CURRENT_DATE + INTERVAL '14 days',
        'https://images.unsplash.com/photo-1483921020237-2ff51e8e4b22',
        'Monthly Milestone badge + 200 XP + Progress tracker unlock',
        true
    );

    -- Challenge 10: Sprint Session (Easy Duration)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Sprint Session',
        'Accumulate 20 minutes total cold plunge time within 7 days. Quick wins!',
        'duration'::public.challenge_type,
        'easy'::public.challenge_difficulty,
        20,
        7,
        CURRENT_DATE + INTERVAL '7 days',
        'https://images.pexels.com/photos/4498481/pexels-photo-4498481.jpeg',
        'Sprint Session badge + 50 XP',
        true
    );

    -- Challenge 11: Ice Breaker (Medium Temperature)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Ice Breaker',
        'Complete 10 sessions at 12°C or below. Break through your comfort zone!',
        'temperature'::public.challenge_type,
        'medium'::public.challenge_difficulty,
        12,
        21,
        CURRENT_DATE + INTERVAL '21 days',
        'https://images.unsplash.com/photo-1548191265-cc70d3d45ba1',
        'Ice Breaker badge + 275 XP + Cold tolerance certification',
        true
    );

    -- Challenge 12: Commitment Crusader (Hard Consistency)
    INSERT INTO public.challenges (
        title,
        description,
        challenge_type,
        difficulty,
        target_value,
        duration_days,
        end_date,
        image_url,
        reward_description,
        is_active
    ) VALUES (
        'Commitment Crusader',
        'Complete 25 sessions within 30 days. The ultimate test of commitment and discipline.',
        'consistency'::public.challenge_type,
        'hard'::public.challenge_difficulty,
        25,
        30,
        CURRENT_DATE + INTERVAL '30 days',
        'https://images.pexels.com/photos/3094215/pexels-photo-3094215.jpeg',
        'Commitment Crusader badge + 550 XP + VIP community access',
        true
    );

END $$;