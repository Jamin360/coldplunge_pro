# Challenge System Update

## Summary
Updated the ColdPlunge Pro app to use exactly 9 curated challenges with clear, non-overlapping logic.

## Changes Made

### 1. Database Migration
**File**: `supabase/migrations/20260127120000_update_to_9_curated_challenges.sql`

This migration:
- Deactivates and deletes all existing challenges
- Creates exactly 9 new challenges:
  - **Beginner**: Quick Start, Two-Minute Club, Ice Breaker
  - **Intermediate**: Ice Warrior (7 days), Weekend Warrior, Monthly Milestone
  - **Advanced**: Ice Master, Extreme Cold Challenge, Arctic Explorer

**To apply the migration**:
```bash
# Using Supabase CLI
supabase db reset

# Or manually run the SQL in Supabase Studio SQL Editor
```

### 2. Challenge Service Logic
**File**: `lib/services/challenge_service.dart`

Updated `updateUserChallengeProgress()` to handle:

#### Streak Challenges
- Ice Warrior – 7 Day Streak
- Monthly Milestone (14 days)
- Ice Master (14 days Advanced)

Uses `user_profiles.streak_count` to track consecutive days.

#### Duration Challenge
- Two-Minute Club: Single session ≥ 2 minutes

Checks max duration of any session since joining.

#### Consistency Challenges
- **Quick Start**: 5 sessions in 7 days (simple count)
- **Weekend Warrior**: Filters for Saturday/Sunday sessions, counts up to 8 weekend days
- **Arctic Explorer**: 30 sessions in 30 days (simple count)

#### Temperature Challenges
- **Ice Breaker**: Counts sessions at or below 12°C, needs 10 qualifying sessions
- **Extreme Cold Challenge**: Calculates consecutive days with sessions ≤ 10°C, needs 14 consecutive days

### 3. Key Improvements

✅ **No overlapping logic**: Each challenge has a unique completion criterion
✅ **Correct progress tracking**: Challenge-specific logic for Weekend Warrior and Extreme Cold
✅ **User-joined dates**: All challenges count from `joined_at`, not global dates
✅ **Clean labels**: Database titles match actual requirements
✅ **Predictable behavior**: No ambiguous or confusing challenge mechanics

## Challenge Breakdown

| Challenge | Type | Target | Duration | Logic |
|-----------|------|--------|----------|-------|
| Quick Start | consistency | 5 sessions | 7 days | Count sessions |
| Two-Minute Club | duration | 120s | 30 days | Max single session duration |
| Ice Breaker | temperature | 12°C | 30 days | Count sessions ≤ 12°C (need 10) |
| Ice Warrior | streak | 7 days | 7 days | Consecutive plunge days |
| Weekend Warrior | consistency | 8 weekend days | 28 days | Count Sat/Sun sessions |
| Monthly Milestone | streak | 14 days | 14 days | Consecutive plunge days |
| Ice Master | streak | 14 days | 14 days | Consecutive plunge days (Advanced) |
| Extreme Cold | temperature | 10°C | 14 days | Consecutive days with ≤ 10°C |
| Arctic Explorer | consistency | 30 sessions | 30 days | Count sessions |

## Testing

After applying the migration:

1. **Verify in Supabase**:
   ```sql
   SELECT title, difficulty, challenge_type, target_value, duration_days, is_active
   FROM challenges
   ORDER BY 
     CASE difficulty 
       WHEN 'beginner' THEN 1 
       WHEN 'intermediate' THEN 2 
       WHEN 'advanced' THEN 3 
     END,
     id;
   ```
   Should show exactly 9 active challenges.

2. **Test in App**:
   - Navigate to Challenges tab
   - Verify all 9 challenges appear
   - Join a challenge and verify countdown starts from joined date
   - Complete a plunge and verify progress updates correctly

3. **Test Specific Challenges**:
   - **Weekend Warrior**: Complete plunges on Sat/Sun, verify progress increments
   - **Extreme Cold**: Complete consecutive days below 50°F, verify streak counting
   - **Ice Breaker**: Complete sessions at low temp, verify count increments

## Notes

- Temperature values in database are stored in Celsius
- Streak count comes from `user_profiles.streak_count`
- All session queries filter by `joined_at` timestamp
- Challenge completion detection happens in `_detectAndEmitCompletions()`
