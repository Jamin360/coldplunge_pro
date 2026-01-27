# Debug Button & Instrumentation Guide

## What Was Added

### 1. Debug Button in Challenges Screen
**Location**: Top-right of Challenges screen AppBar (orange bug icon)
- Only visible in debug mode (`kDebugMode`)
- Triggers a fake challenge completion event
- Tests the entire popup system end-to-end

### 2. Comprehensive Debug Logging

#### Stream Setup (main.dart)
```
🔧 DEBUG: Setting up challenge completion stream listener
🔧 DEBUG: Stream listener setup complete
```

#### When Button is Tapped
```
🐛 DEBUG: Test popup button tapped
🐛 DEBUG: debugEmitCompletion() called
🐛 DEBUG: Emitting fake completion to stream
🐛 DEBUG: Fake completion emitted
```

#### Stream Receives Event
```
📡 DEBUG: completionStream received event with 1 completion(s)
📡 DEBUG: Completion IDs: debug_test_challenge
✅ DEBUG: Context available, showing dialog...
```

#### Dialog Shown
```
🎭 DEBUG: _showChallengeCompletionDialog called
🎭 DEBUG: Showing modal for: Debug Test Challenge
🎭 DEBUG: Building _CompletionBottomSheet widget
🎭 DEBUG: showModalBottomSheet called successfully
```

#### Real Session Save Flow
```
💾 DEBUG: Saving session to database...
💾 DEBUG: Session saved successfully
🎯 DEBUG: Calling updateUserChallengeProgress()...
🔄 DEBUG: updateUserChallengeProgress() called
📋 DEBUG: Fetching active challenges...
📋 DEBUG: Found X active challenge(s)
📈 DEBUG: Progress changed for [Challenge Name]: 50% → 100%
🔍 DEBUG: Calling _detectAndEmitCompletions()...
🔍 DEBUG: _detectAndEmitCompletions() called
🔍 DEBUG: Found 1 newly completed challenge(s)
🎉 DEBUG: Challenge IDs: xxx-xxx-xxx
🎉 DEBUG: Challenge names: 7-Day Streak Challenge
🎉 DEBUG: Emitting to completionStream...
🎉 DEBUG: Completion event emitted successfully
📡 DEBUG: completionStream received event with 1 completion(s)
... (dialog shown as above)
```

#### When No Completions Found
```
ℹ️  DEBUG: No new completions detected
```

## How to Use

### Testing the Popup UI
1. Open the app in debug mode
2. Navigate to Challenges tab
3. Look for orange bug icon (🐞) in top-right
4. Tap the bug button
5. **Expected**: Challenge Complete popup appears immediately
6. Check console logs for the full flow

### Debugging Real Completions
1. Complete a plunge session that should complete a challenge
2. Watch the console output to see WHERE the flow breaks:

**Problem Scenarios:**

**A) No logs after "Calling updateUserChallengeProgress"**
- Issue: `updateUserChallengeProgress()` not being called
- Fix: Check session save flow in plunge_timer.dart

**B) "Found 0 active challenge(s)"**
- Issue: User not joined to any challenges
- Fix: Join a challenge first

**C) "No progress change" for all challenges**
- Issue: Session not counting toward challenge requirements
- Fix: Check challenge type logic (streak/duration/consistency/temperature)

**D) "No new completions detected"**
- Issue: Completion not detected (most likely)
- Possible causes:
  - Cache not updated (`_lastKnownCompletionStatus`)
  - Already notified (`_notifiedChallengeIds`)
  - Progress at 99% instead of 100%
- Fix: Check detection logic in `_detectAndEmitCompletions()`

**E) Logs show completion but no popup**
- Issue: Stream listener not working or context issue
- Fix: Check stream setup in main.dart

**F) "No context available from navigatorKey"**
- Issue: Navigator not initialized
- Fix: Check navigatorKey setup in MaterialApp

## Log Emoji Legend

- 🔧 Setup/initialization
- 🐛 Debug button actions
- 📡 Stream events
- ✅ Success/positive state
- ❌ Error/missing state
- 🎭 UI/dialog operations
- 💾 Database operations
- 🎯 Challenge progress calls
- 🔄 Progress update cycle
- 📋 Data fetching
- 📈 Progress changes
- 📊 No changes
- 🔍 Detection phase
- 🎉 Completion found
- ℹ️  Information
- ⚠️  Warning

## Files Modified

1. **lib/services/challenge_service.dart**
   - Added `debugEmitCompletion()` method
   - Added debug logs throughout completion detection
   - Added logs in `updateUserChallengeProgress()`

2. **lib/main.dart**
   - Added debug logs in stream listener setup
   - Added debug logs when stream receives events
   - Added debug logs in dialog showing

3. **lib/presentation/challenges/challenges.dart**
   - Imported `foundation.dart` for `kDebugMode`
   - Added debug button in AppBar actions
   - Button calls `debugEmitCompletion()`

4. **lib/presentation/plunge_timer/plunge_timer.dart**
   - Added debug logs around session save
   - Added debug logs around challenge progress update

## Next Steps

1. **Verify Debug Button Works**
   - Tap bug button → popup should appear
   - If it works: UI/stream/listener are all functioning
   - If not: Check console for which log is missing

2. **Complete a Real Challenge**
   - Do a plunge that should complete a challenge
   - Watch console logs closely
   - Identify exactly where the flow breaks

3. **Fix Based on Findings**
   - Use the log patterns above to diagnose
   - Most likely issue: detection not finding transitions
   - Check `_lastKnownCompletionStatus` is being initialized

4. **Remove Debug Code**
   - Once fixed, remove debug button
   - Can keep logs or wrap in `kDebugMode`
   - Clean up for production

## Known Issues to Check

- `_lastKnownCompletionStatus` map starts empty → first completion won't be detected
  - **Solution**: Initialize cache on first fetch
  
- `_notifiedChallengeIds` persists in memory → cleared on app restart
  - **Solution**: May need persistent storage if duplicates occur

- Detection runs AFTER updates → race condition possible
  - **Solution**: Use `await` properly in sequence
