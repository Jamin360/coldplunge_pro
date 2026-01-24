-- Drop the existing view
DROP VIEW IF EXISTS public.weekly_session_summary;

-- Recreate the view with week starting on Sunday
-- PostgreSQL's date_trunc('week', ...) starts on Monday by default
-- We subtract 1 day, truncate to week (Monday), then add 1 day to get Sunday
CREATE VIEW public.weekly_session_summary AS
SELECT 
    ps.user_id,
    -- Adjust week start to Sunday by subtracting 1 day before truncating
    (date_trunc('week', ps.created_at - interval '1 day') + interval '1 day')::date as week_start,
    COUNT(*) as sessions_count,
    SUM(ps.duration) as total_duration,
    AVG(ps.temperature)::DECIMAL(5,2) as avg_temperature
FROM public.plunge_sessions ps
GROUP BY ps.user_id, (date_trunc('week', ps.created_at - interval '1 day') + interval '1 day')::date
ORDER BY week_start DESC;

-- Update the weekly_goals table to use Sunday as week start
-- Note: This will update existing records to align with Sunday-based weeks
DO $$
DECLARE
    goal_record RECORD;
    new_week_start DATE;
BEGIN
    FOR goal_record IN 
        SELECT id, week_start_date 
        FROM public.weekly_goals
    LOOP
        -- Calculate the Sunday-based week start for each existing goal
        -- If week_start_date is Monday, subtract 1 day to get Sunday
        new_week_start := (date_trunc('week', goal_record.week_start_date::timestamp - interval '1 day') + interval '1 day')::date;
        
        -- Update only if different
        IF new_week_start != goal_record.week_start_date THEN
            UPDATE public.weekly_goals
            SET week_start_date = new_week_start
            WHERE id = goal_record.id;
        END IF;
    END LOOP;
END $$;
