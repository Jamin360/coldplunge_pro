-- Location: supabase/migrations/20241108214956_coldplunge_schema_with_auth.sql
-- Schema Analysis: Fresh project - no existing schema
-- Integration Type: Complete cold plunge app schema creation
-- Dependencies: None - creating from scratch

-- 1. Types and Enums
CREATE TYPE public.user_role AS ENUM ('admin', 'member');
CREATE TYPE public.mood_type AS ENUM ('stressed', 'tired', 'anxious', 'neutral', 'energized', 'focused', 'calm', 'euphoric');
CREATE TYPE public.challenge_difficulty AS ENUM ('easy', 'medium', 'hard');
CREATE TYPE public.challenge_type AS ENUM ('streak', 'duration', 'temperature', 'consistency');
CREATE TYPE public.activity_type AS ENUM ('milestone', 'challenge', 'plunge', 'achievement');

-- 2. Core User Table (Critical intermediary for PostgREST compatibility)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    role public.user_role DEFAULT 'member'::public.user_role,
    streak_count INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,
    personal_best_duration INTEGER DEFAULT 0, -- in minutes
    is_active BOOLEAN DEFAULT true,
    bio TEXT,
    location TEXT,
    preferred_temperature INTEGER, -- in Celsius
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Cold Plunge Sessions Table
CREATE TABLE public.plunge_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    location TEXT NOT NULL,
    duration INTEGER NOT NULL, -- in minutes
    temperature INTEGER NOT NULL, -- in Celsius
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    pre_mood public.mood_type,
    post_mood public.mood_type,
    notes TEXT,
    breathing_technique TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Challenges Table
CREATE TABLE public.challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    difficulty public.challenge_difficulty NOT NULL,
    challenge_type public.challenge_type NOT NULL,
    target_value INTEGER, -- streak days, duration minutes, temperature, etc.
    duration_days INTEGER NOT NULL, -- how long the challenge lasts
    participants_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    image_url TEXT,
    reward_description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMPTZ
);

-- 5. User Challenge Participation
CREATE TABLE public.user_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
    progress DECIMAL DEFAULT 0.0, -- percentage 0-100
    is_completed BOOLEAN DEFAULT false,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    UNIQUE(user_id, challenge_id)
);

-- 6. Community Posts Table
CREATE TABLE public.community_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    activity_type public.activity_type NOT NULL,
    likes_count INTEGER DEFAULT 0,
    image_url TEXT,
    related_session_id UUID REFERENCES public.plunge_sessions(id) ON DELETE SET NULL,
    related_challenge_id UUID REFERENCES public.challenges(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. Post Likes Table
CREATE TABLE public.post_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, post_id)
);

-- 8. Weekly Goals Table
CREATE TABLE public.weekly_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    target_sessions INTEGER NOT NULL,
    target_duration INTEGER, -- total minutes for the week
    current_sessions INTEGER DEFAULT 0,
    current_duration INTEGER DEFAULT 0,
    is_achieved BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, week_start_date)
);

-- 9. Essential Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_streak ON public.user_profiles(streak_count DESC);
CREATE INDEX idx_plunge_sessions_user_id ON public.plunge_sessions(user_id);
CREATE INDEX idx_plunge_sessions_created_at ON public.plunge_sessions(created_at DESC);
CREATE INDEX idx_plunge_sessions_user_date ON public.plunge_sessions(user_id, created_at DESC);
CREATE INDEX idx_challenges_active ON public.challenges(is_active, end_date);
CREATE INDEX idx_user_challenges_user_id ON public.user_challenges(user_id);
CREATE INDEX idx_user_challenges_challenge_id ON public.user_challenges(challenge_id);
CREATE INDEX idx_community_posts_user_id ON public.community_posts(user_id);
CREATE INDEX idx_community_posts_created_at ON public.community_posts(created_at DESC);
CREATE INDEX idx_post_likes_post_id ON public.post_likes(post_id);
CREATE INDEX idx_weekly_goals_user_week ON public.weekly_goals(user_id, week_start_date);

-- 10. Functions (MUST BE BEFORE RLS POLICIES)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (
        id, 
        email, 
        full_name, 
        avatar_url,
        role
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'member'::public.user_role)
    );
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_user_stats()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update total sessions and personal best
    UPDATE public.user_profiles 
    SET 
        total_sessions = (
            SELECT COUNT(*) 
            FROM public.plunge_sessions 
            WHERE user_id = NEW.user_id
        ),
        personal_best_duration = GREATEST(
            personal_best_duration,
            NEW.duration
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_post_likes_count()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.community_posts 
        SET likes_count = likes_count + 1 
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.community_posts 
        SET likes_count = GREATEST(0, likes_count - 1) 
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

-- 11. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plunge_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_goals ENABLE ROW LEVEL SECURITY;

-- 12. RLS Policies (Using 7-Pattern System)

-- Pattern 1: Core user table (user_profiles) - Simple only, no functions
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for sessions
CREATE POLICY "users_manage_own_plunge_sessions"
ON public.plunge_sessions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public read, private write for challenges
CREATE POLICY "public_can_read_challenges"
ON public.challenges
FOR SELECT
TO public
USING (true);

CREATE POLICY "authenticated_users_can_view_challenges"
ON public.challenges
FOR SELECT
TO authenticated
USING (true);

-- Pattern 2: Simple user ownership for user challenges
CREATE POLICY "users_manage_own_user_challenges"
ON public.user_challenges
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public read, private write for community posts
CREATE POLICY "public_can_read_community_posts"
ON public.community_posts
FOR SELECT
TO public
USING (true);

CREATE POLICY "users_manage_own_community_posts"
ON public.community_posts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Simple user ownership for post likes
CREATE POLICY "users_manage_own_post_likes"
ON public.post_likes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Simple user ownership for weekly goals
CREATE POLICY "users_manage_own_weekly_goals"
ON public.weekly_goals
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 13. Triggers
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_session_created
    AFTER INSERT ON public.plunge_sessions
    FOR EACH ROW EXECUTE FUNCTION public.update_user_stats();

CREATE TRIGGER on_post_like_changed
    AFTER INSERT OR DELETE ON public.post_likes
    FOR EACH ROW EXECUTE FUNCTION public.update_post_likes_count();

-- 14. Mock Data for Testing
DO $$
DECLARE
    user1_auth_id UUID := gen_random_uuid();
    user2_auth_id UUID := gen_random_uuid();
    user3_auth_id UUID := gen_random_uuid();
    challenge1_id UUID := gen_random_uuid();
    challenge2_id UUID := gen_random_uuid();
    session1_id UUID := gen_random_uuid();
    session2_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with complete field structure
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (user1_auth_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@coldplunge.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "avatar_url": "https://img.rocket.new/generatedImages/rocket_gen_img_1ae7d9bdc-1762274136565.png"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user2_auth_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sarah@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sarah Johnson", "avatar_url": "https://img.rocket.new/generatedImages/rocket_gen_img_19dc77a7e-1762274545448.png"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user3_auth_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'mike@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Mike Rodriguez", "avatar_url": "https://img.rocket.new/generatedImages/rocket_gen_img_1b9a68aeb-1762248921203.png"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create sample challenges
    INSERT INTO public.challenges (id, title, description, difficulty, challenge_type, target_value, duration_days, participants_count, image_url, reward_description, end_date)
    VALUES
        (challenge1_id, '7-Day Cold Plunge Streak', 'Complete 7 consecutive days of cold plunges', 'easy'::public.challenge_difficulty, 'streak'::public.challenge_type, 7, 7, 1247, 'https://images.unsplash.com/photo-1635214831754-b0e2b1292a82', 'Beginner Badge + 100 XP', now() + interval '5 days'),
        (challenge2_id, 'Arctic Warrior Challenge', 'Complete 30 cold plunges in 30 days with temperatures below 4°C', 'hard'::public.challenge_difficulty, 'temperature'::public.challenge_type, 4, 30, 892, 'https://images.unsplash.com/photo-1677774362179-22ee6d120308', 'Arctic Badge + 500 XP', now() + interval '25 days');

    -- Create sample sessions
    INSERT INTO public.plunge_sessions (id, user_id, location, duration, temperature, rating, pre_mood, post_mood, notes, created_at)
    VALUES
        (session1_id, user2_auth_id, 'Home Ice Bath', 3, 4, 5, 'stressed'::public.mood_type, 'energized'::public.mood_type, 'Amazing session! Felt incredible afterwards. The breathing technique really helped me stay calm during the plunge.', now() - interval '1 day'),
        (session2_id, user2_auth_id, 'Lake Michigan', 5, 2, 4, 'tired'::public.mood_type, 'focused'::public.mood_type, 'Natural lake plunge was challenging but rewarding.', now() - interval '3 days');

    -- Create user challenge participation
    INSERT INTO public.user_challenges (user_id, challenge_id, progress, joined_at)
    VALUES
        (user2_auth_id, challenge1_id, 71.0, now() - interval '5 days'),
        (user3_auth_id, challenge2_id, 45.0, now() - interval '10 days');

    -- Create community posts
    INSERT INTO public.community_posts (user_id, content, activity_type, likes_count, related_session_id, created_at)
    VALUES
        (user2_auth_id, 'Just completed my 100th cold plunge! The journey has been incredible and I feel stronger than ever.', 'milestone'::public.activity_type, 24, session1_id, now() - interval '2 hours'),
        (user3_auth_id, 'Completed the 7-day consistency challenge! Cold exposure is becoming a daily habit.', 'challenge'::public.activity_type, 18, null, now() - interval '5 hours');

    -- Create weekly goals
    INSERT INTO public.weekly_goals (user_id, week_start_date, target_sessions, target_duration, current_sessions, current_duration)
    VALUES
        (user2_auth_id, date_trunc('week', CURRENT_DATE)::date, 5, 20, 3, 12),
        (user3_auth_id, date_trunc('week', CURRENT_DATE)::date, 7, 28, 5, 20);

END $$;

-- 15. Utility Views for Analytics
CREATE VIEW public.user_session_stats AS
SELECT 
    up.id as user_id,
    up.full_name,
    COUNT(ps.id) as total_sessions,
    AVG(ps.duration)::DECIMAL(5,2) as avg_duration,
    AVG(ps.temperature)::DECIMAL(5,2) as avg_temperature,
    MAX(ps.duration) as max_duration,
    MIN(ps.temperature) as min_temperature
FROM public.user_profiles up
LEFT JOIN public.plunge_sessions ps ON up.id = ps.user_id
GROUP BY up.id, up.full_name;

CREATE VIEW public.weekly_session_summary AS
SELECT 
    ps.user_id,
    date_trunc('week', ps.created_at) as week_start,
    COUNT(*) as sessions_count,
    SUM(ps.duration) as total_duration,
    AVG(ps.temperature)::DECIMAL(5,2) as avg_temperature
FROM public.plunge_sessions ps
GROUP BY ps.user_id, date_trunc('week', ps.created_at)
ORDER BY week_start DESC;