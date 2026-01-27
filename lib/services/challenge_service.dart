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
    print('🐛 DEBUG: debugEmitCompletion() called');
    final fakeCompletion = ChallengeCompletion(
      id: 'debug_test_challenge',
      challengeId: 'debug_test_challenge',
      name: 'Debug Test Challenge',
      difficulty: 'BEGINNER',
      completedAt: DateTime.now(),
    );
    print('🐛 DEBUG: Emitting fake completion to stream');
    _completionController.add([fakeCompletion]);
    print('🐛 DEBUG: Fake completion emitted');
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
            print(
                '🎉 Emitting single challenge completion: ${completion.name}');
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

  /// Calculate challenge progress for a user based on sessions
  /// This method detects completion transitions and emits events
  Future<void> updateUserChallengeProgress() async {
    print('🔄 DEBUG: updateUserChallengeProgress() called');
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      print('⚠️  DEBUG: No current user in updateUserChallengeProgress');
      return;
    }

    try {
      // Get user's active challenges
      print('📋 DEBUG: Fetching active challenges...');
      final activeChallenges = await getUserActiveChallenges();
      print('📋 DEBUG: Found ${activeChallenges.length} active challenge(s)');

      for (final userChallenge in activeChallenges) {
        final challenge = userChallenge['challenges'] as Map<String, dynamic>;
        final challengeType = challenge['challenge_type'] as String;
        final targetValue = challenge['target_value'] as int?;
        final durationDays = challenge['duration_days'] as int;
        final joinedAt = DateTime.parse(userChallenge['joined_at']);

        double progress = 0.0;

        switch (challengeType) {
          case 'streak':
            // Get current streak from user profile
            final profile = await _client
                .from('user_profiles')
                .select('streak_count')
                .eq('id', currentUser.id)
                .single();

            final currentStreak = profile['streak_count'] as int? ?? 0;
            progress = targetValue != null && targetValue > 0
                ? (currentStreak / targetValue * 100).clamp(0, 100)
                : 0.0;
            break;

          case 'duration':
            // Check if any single session meets the target duration
            final sessions = await _client
                .from('plunge_sessions')
                .select('duration')
                .eq('user_id', currentUser.id)
                .gte('created_at', joinedAt.toIso8601String())
                .order('duration', ascending: false)
                .limit(1);

            if (sessions.isNotEmpty) {
              final maxDuration = sessions.first['duration'] as int? ?? 0;
              if (targetValue != null && maxDuration >= targetValue) {
                progress = 100.0;
              } else if (targetValue != null && targetValue > 0) {
                progress = (maxDuration / targetValue * 100).clamp(0, 100);
              }
            }
            break;

          case 'consistency':
            // Count total sessions since joining the challenge
            final sessions = await _client
                .from('plunge_sessions')
                .select('id')
                .eq('user_id', currentUser.id)
                .gte('created_at', joinedAt.toIso8601String());

            progress = targetValue != null && targetValue > 0
                ? (sessions.length / targetValue * 100).clamp(0, 100)
                : 0.0;
            break;

          case 'temperature':
            // Check if any session meets temperature requirement
            final sessions = await _client
                .from('plunge_sessions')
                .select('temperature')
                .eq('user_id', currentUser.id)
                .gte('created_at', joinedAt.toIso8601String());

            final hasMetTarget = sessions.any((s) =>
                (s['temperature'] as int? ?? 100) <= (targetValue ?? -100));

            if (hasMetTarget) {
              // Calculate based on days completed vs challenge duration
              final daysSinceStart =
                  DateTime.now().difference(joinedAt).inDays + 1;
              progress = (daysSinceStart / durationDays * 100).clamp(0, 100);
            }
            break;
        }

        // Update progress if changed
        final oldProgress = (userChallenge['progress'] as num? ?? 0.0);
        if (progress != oldProgress) {
          print(
              '📈 DEBUG: Progress changed for ${challenge['title']}: $oldProgress% → $progress%');
          await updateChallengeProgress(
            challengeId: challenge['id'],
            progress: progress,
          );
        } else {
          print(
              '📊 DEBUG: No progress change for ${challenge['title']}: $progress%');
        }
      }

      // After all updates, detect completion transitions
      print('🔍 DEBUG: Calling _detectAndEmitCompletions()...');
      await _detectAndEmitCompletions();
      print('🔍 DEBUG: _detectAndEmitCompletions() completed');
    } catch (error) {
      // Silent fail - don't throw for background progress updates
      print('Challenge progress update failed: $error');
    }
  }

  /// Detect newly completed challenges and emit events
  /// Called after any operation that might complete a challenge
  Future<void> _detectAndEmitCompletions() async {
    print('🔍 DEBUG: _detectAndEmitCompletions() called');
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      print('⚠️  DEBUG: No current user, skipping detection');
      return;
    }

    try {
      // Fetch fresh user challenges from network (not cached)
      final userChallenges = await _client.from('user_challenges').select('''
            challenge_id,
            is_completed,
            challenges:challenge_id (
              id,
              title,
              difficulty
            )
          ''').eq('user_id', currentUser.id).is_('completed_at', null);

      final List<ChallengeCompletion> newlyCompleted = [];

      for (final uc in userChallenges) {
        final challengeId = uc['challenge_id'] as String;
        final isCompleted = uc['is_completed'] as bool? ?? false;
        final wasCompleted = _lastKnownCompletionStatus[challengeId] ?? false;

        // Detect transition: was not completed -> now completed
        if (!wasCompleted && isCompleted) {
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
            }
          }
        }

        // Update cache with current status
        _lastKnownCompletionStatus[challengeId] = isCompleted;
      }

      // Emit event if there are new completions
      if (newlyCompleted.isNotEmpty) {
        print(
            '🎉 DEBUG: Found ${newlyCompleted.length} newly completed challenge(s)');
        print(
            '🎉 DEBUG: Challenge IDs: ${newlyCompleted.map((c) => c.challengeId).join(", ")}');
        print(
            '🎉 DEBUG: Challenge names: ${newlyCompleted.map((c) => c.name).join(", ")}');
        print('🎉 DEBUG: Emitting to completionStream...');
        _completionController.add(newlyCompleted);
        print('🎉 DEBUG: Completion event emitted successfully');
      } else {
        print('ℹ️  DEBUG: No new completions detected');
      }
    } catch (error) {
      print('Failed to detect challenge completions: $error');
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
