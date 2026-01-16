-- Location: supabase/migrations/20260114232840_seed_default_challenges.sql
-- Schema Analysis: Existing challenges table with proper structure
-- Integration Type: Enhancement - Seeding default challenges
-- Dependencies: challenges table (already exists)

-- Seed default challenges with correct challenge_type enum values
-- Valid challenge_type values: 'streak', 'duration', 'temperature', 'consistency'

DO $$
BEGIN
    -- Insert 5 default challenges if they don't exist
    -- Challenge 1: First Steps (3 sessions → consistency type)
    IF NOT EXISTS (SELECT 1 FROM public.challenges WHERE title = 'First Steps') THEN
        INSERT INTO public.challenges (
            title,
            description,
            challenge_type,
            target_value,
            duration_days,
            difficulty,
            reward_description,
            image_url,
            is_active,
            end_date
        ) VALUES
        (
            'First Steps',
            'Complete 3 cold plunge sessions to start your journey. Build the habit and experience the benefits of cold exposure.',
            'consistency'::public.challenge_type,
            3,
            7,
            'easy'::public.challenge_difficulty,
            'Earn the First Steps badge and kickstart your cold plunge journey',
            'https://images.unsplash.com/photo-1551632811-56155776d0cd?w=800&auto=format&fit=crop',
            true,
            (CURRENT_TIMESTAMP + INTERVAL '7 days')
        );
    END IF;

    -- Challenge 2: Week Warrior (7 day streak → streak type)
    IF NOT EXISTS (SELECT 1 FROM public.challenges WHERE title = 'Week Warrior') THEN
        INSERT INTO public.challenges (
            title,
            description,
            challenge_type,
            target_value,
            duration_days,
            difficulty,
            reward_description,
            image_url,
            is_active,
            end_date
        ) VALUES
        (
            'Week Warrior',
            'Plunge every day for 7 consecutive days. Consistency is key to building mental toughness and resilience.',
            'streak'::public.challenge_type,
            7,
            7,
            'medium'::public.challenge_difficulty,
            'Earn the Week Warrior badge and 100 bonus points',
            'https://images.pexels.com/photos/4498481/pexels-photo-4498481.jpeg?w=800&auto=compress',
            true,
            (CURRENT_TIMESTAMP + INTERVAL '7 days')
        );
    END IF;

    -- Challenge 3: Two-Minute Club (single session 2+ minutes → duration type)
    IF NOT EXISTS (SELECT 1 FROM public.challenges WHERE title = 'Two-Minute Club') THEN
        INSERT INTO public.challenges (
            title,
            description,
            challenge_type,
            target_value,
            duration_days,
            difficulty,
            reward_description,
            image_url,
            is_active,
            end_date
        ) VALUES
        (
            'Two-Minute Club',
            'Complete a single cold plunge session lasting 2 minutes or more. Push your limits and join the elite club.',
            'duration'::public.challenge_type,
            120,
            30,
            'easy'::public.challenge_difficulty,
            'Earn the Two-Minute Club badge and special recognition',
            'https://images.pixabay.com/photo/2017/08/06/07/22/cold-2589944_1280.jpg?w=800',
            true,
            (CURRENT_TIMESTAMP + INTERVAL '30 days')
        );
    END IF;

    -- Challenge 4: Consistency King (20 sessions → consistency type)
    IF NOT EXISTS (SELECT 1 FROM public.challenges WHERE title = 'Consistency King') THEN
        INSERT INTO public.challenges (
            title,
            description,
            challenge_type,
            target_value,
            duration_days,
            difficulty,
            reward_description,
            image_url,
            is_active,
            end_date
        ) VALUES
        (
            'Consistency King',
            'Complete 20 cold plunge sessions within 30 days. Master the art of consistency and reap maximum health benefits.',
            'consistency'::public.challenge_type,
            20,
            30,
            'medium'::public.challenge_difficulty,
            'Earn the Consistency King crown badge and 200 bonus points',
            'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=800&auto=format&fit=crop',
            true,
            (CURRENT_TIMESTAMP + INTERVAL '30 days')
        );
    END IF;

    -- Challenge 5: Ice Master (14 day streak → streak type)
    IF NOT EXISTS (SELECT 1 FROM public.challenges WHERE title = 'Ice Master') THEN
        INSERT INTO public.challenges (
            title,
            description,
            challenge_type,
            target_value,
            duration_days,
            difficulty,
            reward_description,
            image_url,
            is_active,
            end_date
        ) VALUES
        (
            'Ice Master',
            'Achieve a 14-day consecutive streak. Become a true master of cold exposure and mental fortitude.',
            'streak'::public.challenge_type,
            14,
            30,
            'hard'::public.challenge_difficulty,
            'Earn the legendary Ice Master badge and exclusive profile badge',
            'https://images.pexels.com/photos/3935702/pexels-photo-3935702.jpeg?w=800&auto=compress',
            true,
            (CURRENT_TIMESTAMP + INTERVAL '30 days')
        );
    END IF;

END $$;