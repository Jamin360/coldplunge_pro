import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeService {
  static ChallengeService? _instance;
  static ChallengeService get instance => _instance ??= ChallengeService._();

  ChallengeService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Get all active challenges
  Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    try {
      final response = await _client
          .from('challenges')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

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
          await query.order('created_at', ascending: false).limit(limit ?? 100);

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
              image_url,
              end_date
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

      // Create new participation record
      final response = await _client.from('user_challenges').insert({
        'user_id': currentUser.id,
        'challenge_id': challengeId,
        'progress': 0.0,
        'joined_at': DateTime.now().toIso8601String(),
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
            'isFriend': false, // TODO: Implement friends system
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
          'isFriend': false, // TODO: Implement friends system
          'totalSessions': item['total_sessions'] ?? 0,
        });
      }

      return leaderboardData;
    } catch (error) {
      throw Exception('Failed to get global leaderboard: $error');
    }
  }

  /// Calculate challenge progress for a user based on sessions
  Future<void> updateUserChallengeProgress() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get user's active challenges
      final activeChallenges = await getUserActiveChallenges();

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

          case 'consistency':
            // Count sessions since joining the challenge
            final sessions = await _client
                .from('plunge_sessions')
                .select('id')
                .eq('user_id', currentUser.id)
                .gte('created_at', joinedAt.toIso8601String());

            progress = targetValue != null && targetValue > 0
                ? (sessions.length / targetValue * 100).clamp(0, 100)
                : 0.0;
            break;

          case 'duration':
            // Sum total duration since joining
            final sessions = await _client
                .from('plunge_sessions')
                .select('duration')
                .eq('user_id', currentUser.id)
                .gte('created_at', joinedAt.toIso8601String());

            final totalDuration = sessions.fold<int>(
                0, (sum, s) => sum + (s['duration'] as int? ?? 0));
            progress = targetValue != null && targetValue > 0
                ? (totalDuration / targetValue * 100).clamp(0, 100)
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
        if (progress != (userChallenge['progress'] as num? ?? 0.0)) {
          await updateChallengeProgress(
            challengeId: challenge['id'],
            progress: progress,
          );
        }
      }
    } catch (error) {
      // Silent fail - don't throw for background progress updates
      print('Challenge progress update failed: $error');
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
}
