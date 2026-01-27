# Challenge Timing Model Update

## Overview
Updated the challenge timing system to eliminate global end dates and provide personalized challenge timelines for each user.

## Previous Model
- Challenges had a global `end_date` field
- Users had a computed `expires_at` field set when joining
- Challenges would expire for everyone at the same time
- Made it difficult to have "evergreen" challenges

## New Model
- **NO global end dates** - Challenges run indefinitely
- **Personalized timelines** - Each user's challenge starts when they join
- **Dynamic expiration** - Computed as `joined_at + duration_days`
- **Evergreen challenges** - Challenges never expire globally

## Changes Made

### 1. Created ChallengeTimingHelper Utility (`lib/core/challenge_timing_helper.dart`)
Centralized all challenge timing calculations:
- `getChallengeEndTime(joinedAt, durationDays)` - Returns when challenge expires
- `isChallengeExpired(joinedAt, durationDays)` - Checks if challenge has expired
- `getRemainingDays(joinedAt, durationDays)` - Returns days remaining
- `getTimeLeftString(joinedAt, durationDays)` - Returns formatted string ("X days left", "Expired")
- `getDurationString(durationDays)` - Returns formatted duration ("X day challenge")

### 2. Updated Challenge Service (`lib/services/challenge_service.dart`)
- Removed `end_date` from all challenge queries
- Removed `expires_at` from user challenge queries
- Simplified `joinChallenge()` to only set `joined_at` (no expires_at computation)

### 3. Updated Challenges Screen (`lib/presentation/challenges/challenges.dart`)
- Replaced `_calculateUserChallengeTimeLeft()` to use ChallengeTimingHelper
- Updated `_calculateUnjoinedChallengeTimeLeft()` to use helper
- Removed unused `_calculateDaysLeft()` function
- Joined challenges show personalized countdown
- Unjoined challenges show duration label

### 4. Updated Challenge Progress Screen (`lib/presentation/challenge_progress/challenge_progress.dart`)
- Replaced `_calculateDaysRemaining()` to use ChallengeTimingHelper
- Updated `_getChallengeStatus()` to use helper for expiration check
- All timing now computed from `joined_at + duration_days`

### 5. Database Migration (`supabase/migrations/20260127000000_remove_global_challenge_expiration.sql`)
Created migration to:
- Drop `expires_at` column from `user_challenges` table
- Drop `end_date` column from `challenges` table
- Drop old `is_user_challenge_expired()` function
- Add column comments documenting new behavior

## How It Works Now

### When User Joins Challenge
```dart
// Only stores joined_at timestamp
await _client.from('user_challenges').insert({
  'user_id': userId,
  'challenge_id': challengeId,
  'progress': 0.0,
  'joined_at': DateTime.now().toIso8601String(),
});
```

### Computing Expiration
```dart
// Dynamically computed, never stored
final endTime = ChallengeTimingHelper.getChallengeEndTime(
  joinedAt: userJoinedAt,
  durationDays: challenge.durationDays,
);

final isExpired = ChallengeTimingHelper.isChallengeExpired(
  joinedAt: userJoinedAt,
  durationDays: challenge.durationDays,
);
```

### UI Display
**Joined Challenge:**
```
"7 days left"
"2 days left"
"Last day"
"Expired"
```

**Unjoined Challenge:**
```
"7 day challenge"
"30 day challenge"
```

## Benefits
1. **Evergreen Challenges** - Challenges never expire globally
2. **User-Specific Timelines** - Each user starts from their join date
3. **Simplified Data Model** - No redundant computed fields
4. **Accurate Expiration** - Always computed fresh, never stale
5. **Flexible Duration** - Easy to adjust challenge duration without affecting users

## Testing Checklist
- [ ] Join a new challenge sets only `joined_at`
- [ ] Countdown shows correctly for joined challenges
- [ ] Unjoined challenges show duration label
- [ ] Challenge expires at `joined_at + duration_days`
- [ ] Challenge completion works correctly
- [ ] Expired challenges marked as "Failed"
- [ ] Challenge progress screen shows correct time remaining

## Migration Notes
- Run migration to drop old columns: `20260127000000_remove_global_challenge_expiration.sql`
- Existing `expires_at` data will be ignored (computation uses `joined_at` now)
- Old `end_date` values on challenges are no longer relevant
