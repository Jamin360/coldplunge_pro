import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeService {
  static ChallengeService? _instance;
  static ChallengeService get instance => _instance ??= ChallengeService._();

  ChallengeService._();

  final SupabaseClient _client = Supabase.instance.client;

  // Stream controller for challenge completion events
  final _completionController =
      StreamController<List<ChallengeCompletion>>.broadcast();
  Stream<List<ChallengeCompletion>> get completionStream =>
      _completionController.stream;

  // Cache of last known challenge statuses to detect transitions
  final Map<String, bool> _lastKnownCompletionStatus = {};

  // Set of notified challenge IDs to prevent duplicates
  final Set<String> _notifiedChallengeIds = {};

  /// DEBUG ONLY: Emit a fake completion event to test the popup system
  void debugEmitCompletion() {
    // print('🐛 DEBUG: debugEmitCompletion() called');
    final fakeCompletion = ChallengeCompletion(
      id: 'debug_test_challenge',
      challengeId: 'debug_test_challenge',
      name: 'Debug Test Challenge',
      difficulty: 'BEGINNER',
      completedAt: DateTime.now(),
    );
    // print('🐛 DEBUG: Emitting fake completion to stream');
    _completionController.add([fakeCompletion]);
    // print('🐛 DEBUG: Fake completion emitted');
  }

  /// Get all active challenges
  Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    try {
      final response = await _client
          .from('challenges')
          .select()
          .eq('is_active', true)
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get active challenges: $error');
    }
  }

  /// Get challenges with optional filtering
  Future<List<Map<String, dynamic>>> getChallenges({
    String? difficulty,
    String? challengeType,
    bool? isActive = true,
    int? limit,
  }) async {
    try {
      var query = _client.from('challenges').select();

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (difficulty != null) {
        query = query.eq('difficulty', difficulty);
      }
      if (challengeType != null) {
        query = query.eq('challenge_type', challengeType);
      }

      final response =
          await query.order('id', ascending: false).limit(limit ?? 100);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get challenges: $error');
    }
  }

  /// Get user's active challenges
  Future<List<Map<String, dynamic>>> getUserActiveChallenges() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _client
          .from('user_challenges')
          .select('''
            *,
            challenges:challenge_id (
              id,
              title,
              description,
              difficulty,
              challenge_type,
              target_value,
              duration_days,
              reward_description,
              image_url
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('is_completed', false)
          .order('joined_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get user active challenges: $error');
    }
  }

  /// Get user's completed challenges
  Future<List<Map<String, dynamic>>> getUserCompletedChallenges() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _client
          .from('user_challenges')
          .select('''
            *,
            challenges:challenge_id (
              id,
              title,
              description,
              difficulty,
              challenge_type,
              reward_description,
              image_url
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('is_completed', true)
          .order('completed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get user completed challenges: $error');
    }
  }

  /// Join a challenge
  Future<Map<String, dynamic>> joinChallenge(String challengeId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if user is already participating
      final existing = await _client
          .from('user_challenges')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('challenge_id', challengeId)
          .limit(1);

      if (existing.isNotEmpty) {
        throw Exception('Already participating in this challenge');
      }

      final joinedAt = DateTime.now();

      // Create new participation record (expiration calculated from joined_at + duration_days)
      final response = await _client.from('user_challenges').insert({
        'user_id': currentUser.id,
        'challenge_id': challengeId,
        'progress': 0.0,
        'joined_at': joinedAt.toIso8601String(),
      }).select('''
            *,
            challenges:challenge_id (*)
          ''').single();

      // Update participant count
      await _client.rpc('increment_challenge_participants', params: {
        'challenge_id': challengeId,
      });

      return response;
    } catch (error) {
      throw Exception('Failed to join challenge: $error');
    }
  }

  /// Leave a challenge
  Future<void> leaveChallenge(String challengeId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('user_challenges')
          .delete()
          .eq('user_id', currentUser.id)
          .eq('challenge_id', challengeId);

      // Decrement participant count
      await _client.rpc('decrement_challenge_participants', params: {
        'challenge_id': challengeId,
      });
    } catch (error) {
      throw Exception('Failed to leave challenge: $error');
    }
  }

  /// Update challenge progress
  Future<Map<String, dynamic>> updateChallengeProgress({
    required String challengeId,
    required double progress,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get current state before update to detect completion transition
      final beforeUpdate = await _client
          .from('user_challenges')
          .select('''
            is_completed,
            challenges:challenge_id (
              id,
              title,
              difficulty
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('challenge_id', challengeId)
          .maybeSingle();

      final wasCompletedBefore =
          beforeUpdate?['is_completed'] as bool? ?? false;

      final isCompleted = progress >= 100.0;
      final updates = {
        'progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isCompleted) {
        updates['is_completed'] = true;
        updates['completed_at'] = DateTime.now().toIso8601String();
      }

      final response = await _client
          .from('user_challenges')
          .update(updates)
          .eq('user_id', currentUser.id)
          .eq('challenge_id', challengeId)
          .select('''
            *,
            challenges:challenge_id (*)
          ''').single();

      // Detect completion transition and notify
      // (This handles direct progress updates, but the main detection
      // happens in _detectAndEmitCompletions after batch updates)
      if (!wasCompletedBefore && isCompleted && beforeUpdate != null) {
        // Update cache immediately
        _lastKnownCompletionStatus[challengeId] = true;

        // Emit if not already notified
        if (!_notifiedChallengeIds.contains(challengeId)) {
          final challengeData =
              beforeUpdate['challenges'] as Map<String, dynamic>?;
          if (challengeData != null) {
            final completion = ChallengeCompletion(
              id: challengeId,
              challengeId: challengeId,
              name: challengeData['title'] as String? ?? 'Challenge',
              difficulty: challengeData['difficulty'] as String?,
              completedAt: DateTime.now(),
            );
            _notifiedChallengeIds.add(challengeId);
            // print(
            //     '🎉 Emitting single challenge completion: ${completion.name}');
            _completionController.add([completion]);
          }
        }
      }

      return response;
    } catch (error) {
      throw Exception('Failed to update challenge progress: $error');
    }
  }

  /// Get challenge leaderboard
  Future<List<Map<String, dynamic>>> getChallengeLeaderboard({
    String? challengeId,
    int limit = 10,
  }) async {
    try {
      var query = _client.from('user_challenges').select('''
            progress,
            is_completed,
            completed_at,
            user_profiles:user_id (
              id,
              full_name,
              avatar_url,
              streak_count
            ),
            challenges:challenge_id (
              title
            )
          ''');

      if (challengeId != null) {
        query = query.eq('challenge_id', challengeId);
      }

      final response = await query
          .order('progress', ascending: false)
          .order('completed_at', ascending: true)
          .limit(limit);

      // Transform the response to match expected leaderboard format
      final leaderboardData = <Map<String, dynamic>>[];

      for (int i = 0; i < response.length; i++) {
        final item = response[i];
        final userProfile = item['user_profiles'] as Map<String, dynamic>?;

        if (userProfile != null) {
          leaderboardData.add({
            'name': userProfile['full_name'] ?? 'Unknown User',
            'score': (item['progress'] as num?)?.round() ?? 0,
            'avatar': userProfile['avatar_url'] ?? '',
            'avatarSemanticLabel':
                'Profile picture of ${userProfile['full_name'] ?? 'user'}',
            'isCurrentUser': userProfile['id'] == _client.auth.currentUser?.id,
            'isFriend': false,
            'isCompleted': item['is_completed'] == true,
            'completedAt': item['completed_at'],
          });
        }
      }

      return leaderboardData;
    } catch (error) {
      throw Exception('Failed to get challenge leaderboard: $error');
    }
  }

  /// Get global leaderboard (based on streak count)
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard(
      {int limit = 10}) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('id, full_name, avatar_url, streak_count, total_sessions')
          .order('streak_count', ascending: false)
          .order('total_sessions', ascending: false)
          .limit(limit);

      final leaderboardData = <Map<String, dynamic>>[];

      for (final item in response) {
        leaderboardData.add({
          'name': item['full_name'] ?? 'Unknown User',
          'score': item['streak_count'] ?? 0,
          'avatar': item['avatar_url'] ?? '',
          'avatarSemanticLabel':
              'Profile picture of ${item['full_name'] ?? 'user'}',
          'isCurrentUser': item['id'] == _client.auth.currentUser?.id,
          'isFriend': false,
          'totalSessions': item['total_sessions'] ?? 0,
        });
      }

      return leaderboardData;
    } catch (error) {
      throw Exception('Failed to get global leaderboard: $error');
    }
  }

  /// Helper: Get sessions within challenge window
  Future<List<Map<String, dynamic>>> _getSessionsInWindow({
    required String userId,
    required DateTime joinedAt,
    required int durationDays,
  }) async {
    final windowEnd = joinedAt.add(Duration(days: durationDays));
    final now = DateTime.now();
    final effectiveEnd = windowEnd.isBefore(now) ? windowEnd : now;

    final sessions = await _client
        .from('plunge_sessions')
        .select('created_at, duration, temperature')
        .eq('user_id', userId)
        .gte('created_at', joinedAt.toIso8601String())
        .lte('created_at', effectiveEnd.toIso8601String())
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(sessions);
  }

  /// Helper: Extract distinct session days from sessions (using local timezone)
  Set<DateTime> _distinctSessionDays(List<Map<String, dynamic>> sessions) {
    final Set<DateTime> days = {};
    for (final session in sessions) {
      // Parse timestamp and convert to LOCAL time
      final sessionDate =
          DateTime.parse(session['created_at'] as String).toLocal();
      // Extract just the date part (year, month, day) in local timezone
      final day =
          DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
      days.add(day);
    }
    return days;
  }

  /// Helper: Compute longest consecutive day streak
  int _computeConsecutiveStreak(
      Set<DateTime> sessionDays, String challengeName) {
    if (sessionDays.isEmpty) {
      // print('   📅 No session days found for streak calculation');
      return 0;
    }

    final sortedDays = sessionDays.toList()..sort();
    // print(
    //     '   📅 Session days (local time): ${sortedDays.map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}').join(', ')}');

    int currentStreak = 1;
    int maxStreak = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    // print('   📊 Longest consecutive streak: $maxStreak day(s)');
    return maxStreak;
  }

  /// Helper: Compute Weekend Warrior progress (Sat+Sun for N weeks)
  double _computeWeekendWarriorProgress({
    required List<Map<String, dynamic>> sessions,
    required int targetWeeks,
  }) {
    // Group sessions by week number
    final Map<String, Set<int>> weekendDaysByWeek = {};

    for (final session in sessions) {
      // Convert to LOCAL time for proper weekday detection
      final sessionDate =
          DateTime.parse(session['created_at'] as String).toLocal();
      final weekday = sessionDate.weekday;

      // Only count Saturday (6) and Sunday (7)
      if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
        // Calculate week key (ISO week year-week)
        final weekNumber = _getIsoWeekNumber(sessionDate);
        final weekKey = '${sessionDate.year}-W$weekNumber';

        weekendDaysByWeek.putIfAbsent(weekKey, () => {});
        weekendDaysByWeek[weekKey]!.add(weekday);
      }
    }

    // Count how many weeks have BOTH Saturday AND Sunday
    int completeWeeks = 0;
    for (final weekdays in weekendDaysByWeek.values) {
      if (weekdays.contains(DateTime.saturday) &&
          weekdays.contains(DateTime.sunday)) {
        completeWeeks++;
      }
    }

    return targetWeeks > 0
        ? (completeWeeks / targetWeeks * 100).clamp(0, 100)
        : 0.0;
  }

  /// Helper: Get ISO week number
  int _getIsoWeekNumber(DateTime date) {
    final dayOfYear =
        int.parse(date.difference(DateTime(date.year, 1, 1)).inDays.toString());
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Helper: Single session duration threshold progress
  double _computeSingleSessionThresholdProgress({
    required List<Map<String, dynamic>> sessions,
    required int targetSeconds,
  }) {
    if (sessions.isEmpty) return 0.0;

    // Find the longest single session
    int maxDuration = 0;
    for (final session in sessions) {
      final duration = session['duration'] as int? ?? 0;
      if (duration > maxDuration) {
        maxDuration = duration;
      }
    }

    if (maxDuration >= targetSeconds) {
      return 100.0;
    }

    // Show progress toward the threshold
    return targetSeconds > 0
        ? (maxDuration / targetSeconds * 100).clamp(0, 100)
        : 0.0;
  }

  /// Helper: Temperature threshold streak (consecutive days at temp)
  double _computeTemperatureStreakProgress({
    required List<Map<String, dynamic>> sessions,
    required int targetDays,
    required double tempThresholdF,
  }) {
    final Set<DateTime> qualifyingDays = {};

    for (final session in sessions) {
      final temperature = (session['temperature'] as num?)?.toDouble() ?? 999.0;
      if (temperature <= tempThresholdF) {
        // Convert to LOCAL time for proper day grouping
        final sessionDate =
            DateTime.parse(session['created_at'] as String).toLocal();
        final day =
            DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
        qualifyingDays.add(day);
      }
    }

    final streak = _computeConsecutiveStreak(qualifyingDays, 'Temp Streak');
    return targetDays > 0 ? (streak / targetDays * 100).clamp(0, 100) : 0.0;
  }

  /// Helper: Temperature threshold session count
  double _computeTemperatureSessionCountProgress({
    required List<Map<String, dynamic>> sessions,
    required int targetCount,
    required double tempThresholdF,
  }) {
    int qualifyingSessions = 0;

    for (final session in sessions) {
      final temperature = (session['temperature'] as num?)?.toDouble() ?? 999.0;
      if (temperature <= tempThresholdF) {
        qualifyingSessions++;
      }
    }

    return targetCount > 0
        ? (qualifyingSessions / targetCount * 100).clamp(0, 100)
        : 0.0;
  }

  /// Calculate challenge progress for a user based on sessions
  /// This method detects completion transitions and emits events
  Future<void> updateUserChallengeProgress() async {
    // print('🔄 DEBUG: updateUserChallengeProgress() called');
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      // print('⚠️  DEBUG: No current user in updateUserChallengeProgress');
      return;
    }

    try {
      // Get user's active challenges
      // print('📋 DEBUG: Fetching active challenges...');
      final activeChallenges = await getUserActiveChallenges();
      // print('📋 DEBUG: Found ${activeChallenges.length} active challenge(s)');

      for (final userChallenge in activeChallenges) {
        final challenge = userChallenge['challenges'] as Map<String, dynamic>;
        final challengeTitle = challenge['title'] as String? ?? '';
        final challengeType = challenge['challenge_type'] as String;
        final targetValue = challenge['target_value'] as int?;
        final durationDays = challenge['duration_days'] as int;
        final joinedAt = DateTime.parse(userChallenge['joined_at']).toLocal();

        // print('\n📝 DEBUG: Processing "$challengeTitle"');
        // print(
        //     '   Type: $challengeType, Target: $targetValue, Duration: $durationDays days');
        // print('   Joined: ${joinedAt.toIso8601String()}');

        // Get sessions within challenge window
        final sessions = await _getSessionsInWindow(
          userId: currentUser.id,
          joinedAt: joinedAt,
          durationDays: durationDays,
        );

        // print('   Sessions in window: ${sessions.length}');

        double progress = 0.0;
        String debugMetric = '';

        // Route to correct calculation based on challenge title/type
        switch (challengeTitle) {
          // BEGINNER CHALLENGES
          case 'Quick Start':
            // 5 sessions in 7 days
            final count = sessions.length;
            progress = targetValue != null && targetValue > 0
                ? (count / targetValue * 100).clamp(0, 100)
                : 0.0;
            debugMetric = 'Sessions: $count/${targetValue ?? 0}';
            break;

          case 'Two-Minute Club':
            // Single session ≥ 2 minutes (120 seconds)
            progress = _computeSingleSessionThresholdProgress(
              sessions: sessions,
              targetSeconds: targetValue ?? 120,
            );
            final maxDuration = sessions.isEmpty
                ? 0
                : sessions
                    .map((s) => s['duration'] as int? ?? 0)
                    .reduce((a, b) => a > b ? a : b);
            debugMetric =
                'Max duration: ${maxDuration}s / ${targetValue ?? 120}s';
            break;

          case 'Ice Breaker':
            // 10 sessions ≤ 12°C (53.6°F)
            progress = _computeTemperatureSessionCountProgress(
              sessions: sessions,
              targetCount: 10,
              tempThresholdF: 53.6,
            );
            final qualCount = sessions
                .where((s) =>
                    ((s['temperature'] as num?)?.toDouble() ?? 999.0) <= 53.6)
                .length;
            debugMetric = 'Sessions ≤ 53.6°F: $qualCount/10';
            break;

          // INTERMEDIATE CHALLENGES
          case 'Ice Warrior – 7 Day Streak':
            // 7 consecutive days
            final sessionDays = _distinctSessionDays(sessions);
            final streak =
                _computeConsecutiveStreak(sessionDays, challengeTitle);
            progress = targetValue != null && targetValue > 0
                ? (streak / targetValue * 100).clamp(0, 100)
                : 0.0;
            debugMetric = 'Current streak: $streak/${targetValue ?? 0} days';
            break;

          case 'Weekend Warrior':
            // Both Sat+Sun for 4 weeks
            progress = _computeWeekendWarriorProgress(
              sessions: sessions,
              targetWeeks: 4,
            );
            debugMetric = 'Weekend Warrior progress';
            break;

          case 'Monthly Milestone':
            // 14-day consecutive streak
            final sessionDays = _distinctSessionDays(sessions);
            final streak =
                _computeConsecutiveStreak(sessionDays, challengeTitle);
            progress = (streak / 14 * 100).clamp(0, 100);
            debugMetric = 'Current streak: $streak/14 days';
            break;

          // ADVANCED CHALLENGES
          case 'Ice Master':
            // 14-day consecutive streak (Advanced)
            final sessionDays = _distinctSessionDays(sessions);
            final streak =
                _computeConsecutiveStreak(sessionDays, challengeTitle);
            progress = (streak / 14 * 100).clamp(0, 100);
            debugMetric = 'Current streak: $streak/14 days';
            break;

          case 'Extreme Cold Challenge':
            // ≤ 50°F (10°C) for 14 consecutive days
            progress = _computeTemperatureStreakProgress(
              sessions: sessions,
              targetDays: 14,
              tempThresholdF: 50.0,
            );
            debugMetric = 'Temp streak progress';
            break;

          case 'Arctic Explorer – 30 Day Journey':
            // 30 sessions in 30 days
            final count = sessions.length;
            progress = (count / 30 * 100).clamp(0, 100);
            debugMetric = 'Sessions: $count/30';
            break;

          default:
            // Fallback for unknown challenges
            // print('   ⚠️  Unknown challenge: $challengeTitle');
            continue;
        }

        // print('   $debugMetric');
        // print('   Progress: ${progress.toStringAsFixed(1)}%');

        // Update progress if changed
        final oldProgress = (userChallenge['progress'] as num? ?? 0.0);
        if ((progress - oldProgress).abs() > 0.1) {
          // print(
          //     '   📈 Updating: ${oldProgress.toStringAsFixed(1)}% → ${progress.toStringAsFixed(1)}%');
          await updateChallengeProgress(
            challengeId: challenge['id'],
            progress: progress,
          );
        } else {
          // print('   📊 No change needed');
        }
      }

      // After all updates, detect completion transitions
      // print('\n🔍 DEBUG: Calling _detectAndEmitCompletions()...');
      await _detectAndEmitCompletions();
      // print('🔍 DEBUG: _detectAndEmitCompletions() completed');
    } catch (error) {
      // Silent fail - don't throw for background progress updates
      // print('Challenge progress update failed: $error');
    }
  }

  /// Detect newly completed challenges and emit events
  /// Called after any operation that might complete a challenge
  Future<void> _detectAndEmitCompletions() async {
    // print('🔍 DEBUG: _detectAndEmitCompletions() called');
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      // print('⚠️  DEBUG: No current user, skipping detection');
      return;
    }

    try {
      // Fetch ALL user challenges (including completed ones) from network
      // This is critical: we need to see completed challenges to detect transitions
      // print('📥 DEBUG: Fetching all user_challenges from database...');
      final userChallenges = await _client.from('user_challenges').select('''
            challenge_id,
            is_completed,
            completed_at,
            progress,
            challenges:challenge_id (
              id,
              title,
              difficulty
            )
          ''').eq('user_id', currentUser.id);

      // print(
      //     '📊 DEBUG: Fetched ${userChallenges.length} total user_challenge(s)');

      final List<ChallengeCompletion> newlyCompleted = [];

      for (final uc in userChallenges) {
        final challengeId = uc['challenge_id'] as String;
        final isCompletedFlag = uc['is_completed'] as bool? ?? false;
        final completedAt = uc['completed_at'] as String?;
        final progress = (uc['progress'] as num? ?? 0.0).toDouble();

        // Determine if challenge is completed using multiple signals
        final isCompleted =
            isCompletedFlag || completedAt != null || progress >= 100.0;

        // print(
        //     '🔎 DEBUG: Challenge $challengeId - is_completed=$isCompletedFlag, completed_at=$completedAt, progress=$progress, final isCompleted=$isCompleted');

        final wasCompleted = _lastKnownCompletionStatus[challengeId] ?? false;

        // Detect transition: was not completed -> now completed
        if (!wasCompleted && isCompleted) {
          // print(
          //     '🎯 DEBUG: Transition detected for $challengeId: wasCompleted=$wasCompleted -> isCompleted=$isCompleted');

          // Check if we've already notified about this completion
          if (!_notifiedChallengeIds.contains(challengeId)) {
            final challengeData = uc['challenges'] as Map<String, dynamic>?;
            if (challengeData != null) {
              final completion = ChallengeCompletion(
                id: challengeId,
                challengeId: challengeId,
                name: challengeData['title'] as String? ?? 'Challenge',
                difficulty: challengeData['difficulty'] as String?,
                completedAt: DateTime.now(),
              );
              newlyCompleted.add(completion);
              _notifiedChallengeIds.add(challengeId);
              // print('✅ DEBUG: Added to newlyCompleted: ${completion.name}');
            }
          } else {
            // print('⏭️  DEBUG: Already notified for $challengeId, skipping');
          }
        }

        // Update cache with current status
        _lastKnownCompletionStatus[challengeId] = isCompleted;
      }

      // Emit event if there are new completions
      if (newlyCompleted.isNotEmpty) {
        // print(
        //     '🎉 DEBUG: Found ${newlyCompleted.length} newly completed challenge(s)');
        // print(
        //     '🎉 DEBUG: Challenge IDs: ${newlyCompleted.map((c) => c.challengeId).join(", ")}');
        // print(
        //     '🎉 DEBUG: Challenge names: ${newlyCompleted.map((c) => c.name).join(", ")}');
        // print('🎉 DEBUG: Emitting to completionStream...');
        _completionController.add(newlyCompleted);
        // print('🎉 DEBUG: Completion event emitted successfully');
      } else {
        // print('ℹ️  DEBUG: No new completions detected');
        // print(
        //     'ℹ️  DEBUG: Cache state: ${_lastKnownCompletionStatus.length} challenge(s) tracked');
        // print(
        //     'ℹ️  DEBUG: Already notified: ${_notifiedChallengeIds.length} challenge(s)');
      }
    } catch (error) {
      // print('❌ DEBUG: Failed to detect challenge completions: $error');
    }
  }

  /// Get challenge by ID
  Future<Map<String, dynamic>> getChallengeById(String challengeId) async {
    try {
      final response = await _client
          .from('challenges')
          .select()
          .eq('id', challengeId)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get challenge: $error');
    }
  }

  /// Get user challenge with full details by challenge ID
  Future<Map<String, dynamic>?> getUserChallengeByIdWithDetails(
      String challengeId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _client
          .from('user_challenges')
          .select('''
            *,
            challenges:challenge_id (
              id,
              title,
              description,
              difficulty,
              challenge_type,
              target_value,
              duration_days,
              reward_description,
              image_url
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('challenge_id', challengeId)
          .maybeSingle();

      return response;
    } catch (error) {
      throw Exception('Failed to get user challenge: $error');
    }
  }

  /// Get sessions for a specific challenge
  Future<List<Map<String, dynamic>>> getChallengeSessionHistory(
      String challengeId, String joinedAt) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _client
          .from('plunge_sessions')
          .select('id, duration, temperature, created_at, location')
          .eq('user_id', currentUser.id)
          .gte('created_at', joinedAt)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get challenge sessions: $error');
    }
  }

  /// Dispose resources
  void dispose() {
    _completionController.close();
  }
}

/// Data class for challenge completion events
class ChallengeCompletion {
  final String id;
  final String challengeId;
  final String name;
  final String? difficulty;
  final DateTime completedAt;

  ChallengeCompletion({
    required this.id,
    required this.challengeId,
    required this.name,
    this.difficulty,
    required this.completedAt,
  });
}
