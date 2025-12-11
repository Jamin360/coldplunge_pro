import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static SessionService? _instance;
  static SessionService get instance => _instance ??= SessionService._();

  SessionService._();

  final SupabaseClient _client = Supabase.instance.client;

  // Connection pooling and request debouncing
  Timer? _saveDebounceTimer;
  final Map<String, Completer<Map<String, dynamic>>> _pendingSaves = {};

  /// Create a new plunge session
  Future<Map<String, dynamic>> createSession({
    required String location,
    required int duration,
    required int temperature,
    String? preMood,
    String? postMood,
    String? notes,
    String? breathingTechnique,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final sessionData = {
        'user_id': currentUser.id,
        'location': location,
        'duration': duration,
        'temperature': temperature,
        'pre_mood': preMood,
        'post_mood': postMood,
        'notes': notes,
        'breathing_technique': breathingTechnique,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _client
              .from('plunge_sessions')
              .insert(sessionData)
              .select()
              .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create session: $error');
    }
  }

  /// Ultra-optimized session creation with advanced performance techniques
  Future<Map<String, dynamic>> createSessionUltraOptimized(
    Map<String, dynamic> sessionData,
  ) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Create unique key for deduplication
    final sessionKey =
        '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}';

    // Check if same save is already pending
    if (_pendingSaves.containsKey(sessionKey)) {
      return await _pendingSaves[sessionKey]!.future;
    }

    final completer = Completer<Map<String, dynamic>>();
    _pendingSaves[sessionKey] = completer;

    try {
      final optimizedData = <String, dynamic>{
        'user_id': currentUser.id,
        'location': sessionData['location'],
        'duration': sessionData['duration'],
        'temperature': sessionData['temperature'],
        'pre_mood': sessionData['pre_mood'],
        'post_mood': sessionData['post_mood'],
        'notes':
            sessionData['notes']?.isEmpty == true ? null : sessionData['notes'],
        'breathing_technique': sessionData['breathing_technique'],
        'created_at': DateTime.now().toIso8601String(),
      };

      // Ultra-fast save with minimal response data and retry logic
      final response = await _performSaveWithRetry(optimizedData);

      completer.complete(response);
      return response;
    } catch (error) {
      completer.completeError(error);
      rethrow;
    } finally {
      _pendingSaves.remove(sessionKey);
    }
  }

  /// Retry mechanism with exponential backoff
  Future<Map<String, dynamic>> _performSaveWithRetry(
    Map<String, dynamic> data,
  ) async {
    const maxRetries = 3;
    const baseDelay = Duration(milliseconds: 500);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Minimal database operation - only return ID
        final response = await _client
            .from('plunge_sessions')
            .insert(data)
            .select('id')
            .single()
            .timeout(const Duration(seconds: 5));

        return response;
      } catch (error) {
        if (attempt == maxRetries - 1) {
          throw Exception(
            'Failed to save session after $maxRetries attempts: $error',
          );
        }

        // Exponential backoff delay
        final delay = Duration(
          milliseconds: baseDelay.inMilliseconds * (1 << attempt),
        );
        await Future.delayed(delay);
      }
    }

    throw Exception('Maximum retry attempts reached');
  }

  /// Optimized session creation with better performance
  Future<Map<String, dynamic>> createSessionOptimized(
    Map<String, dynamic> sessionData,
  ) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Add user_id and timestamp efficiently
      final optimizedData = Map<String, dynamic>.from(sessionData)..addAll({
        'user_id': currentUser.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Single database call with minimal response data
      final response =
          await _client
              .from('plunge_sessions')
              .insert(optimizedData)
              .select('id, created_at') // Only get essential fields back
              .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create session: $error');
    }
  }

  /// Lightning-fast background save with fire-and-forget pattern
  Future<void> saveSessionInBackground(Map<String, dynamic> sessionData) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return;

    // Fire-and-forget save without waiting for response
    unawaited(_performBackgroundSave(sessionData, currentUser.id));
  }

  Future<void> _performBackgroundSave(
    Map<String, dynamic> sessionData,
    String userId,
  ) async {
    try {
      final optimizedData = <String, dynamic>{
        'user_id': userId,
        'location': sessionData['location'],
        'duration': sessionData['duration'],
        'temperature': sessionData['temperature'],
        'pre_mood': sessionData['pre_mood'],
        'post_mood': sessionData['post_mood'],
        'notes':
            sessionData['notes']?.isEmpty == true ? null : sessionData['notes'],
        'breathing_technique': sessionData['breathing_technique'],
        'created_at': DateTime.now().toIso8601String(),
      };

      // Background save without blocking UI
      await _client
          .from('plunge_sessions')
          .insert(optimizedData)
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      // Silent fail - could implement offline queue here
      print('Background save failed: $error');
    }
  }

  /// Get user's sessions with optional filtering
  Future<List<Map<String, dynamic>>> getUserSessions({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
    String? orderBy = 'created_at',
    bool ascending = false,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      var query = _client
          .from('plunge_sessions')
          .select()
          .eq('user_id', currentUser.id);

      // Apply date filters
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      // Apply ordering and limit
      final response = await query
          .order(orderBy!, ascending: ascending)
          .limit(limit ?? 100);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get sessions: $error');
    }
  }

  /// Get session by ID
  Future<Map<String, dynamic>> getSessionById(String sessionId) async {
    try {
      final response =
          await _client
              .from('plunge_sessions')
              .select()
              .eq('id', sessionId)
              .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get session: $error');
    }
  }

  /// Update an existing session
  Future<Map<String, dynamic>> updateSession({
    required String sessionId,
    String? location,
    int? duration,
    int? temperature,
    String? preMood,
    String? postMood,
    String? notes,
    String? breathingTechnique,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (location != null) updates['location'] = location;
      if (duration != null) updates['duration'] = duration;
      if (temperature != null) updates['temperature'] = temperature;
      if (preMood != null) updates['pre_mood'] = preMood;
      if (postMood != null) updates['post_mood'] = postMood;
      if (notes != null) updates['notes'] = notes;
      if (breathingTechnique != null)
        updates['breathing_technique'] = breathingTechnique;

      final response =
          await _client
              .from('plunge_sessions')
              .update(updates)
              .eq('id', sessionId)
              .eq('user_id', currentUser.id)
              .select()
              .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update session: $error');
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('plunge_sessions')
          .delete()
          .eq('id', sessionId)
          .eq('user_id', currentUser.id);
    } catch (error) {
      throw Exception('Failed to delete session: $error');
    }
  }

  /// Get recent sessions (last 5)
  Future<List<Map<String, dynamic>>> getRecentSessions() async {
    return await getUserSessions(
      limit: 10,
      orderBy: 'created_at',
      ascending: false,
    );
  }

  /// Get weekly progress data
  Future<List<Map<String, dynamic>>> getWeeklyProgress() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get sessions from the last 7 days
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 6));

      final sessions = await getUserSessions(
        startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
        endDate: now,
        orderBy: 'created_at',
        ascending: true,
      );

      // Group sessions by day
      final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final weeklyData = <Map<String, dynamic>>[];

      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final daySessions =
            sessions.where((session) {
              final sessionDate = DateTime.parse(session['created_at']);
              return sessionDate.isAfter(dayStart) &&
                  sessionDate.isBefore(dayEnd);
            }).toList();

        final totalDuration = daySessions.fold<int>(
          0,
          (sum, session) => sum + (session['duration'] as int? ?? 0),
        );

        weeklyData.add({
          'day': dayLabels[day.weekday - 1],
          'duration': totalDuration,
          'hasPlunge': daySessions.isNotEmpty,
          'sessionCount': daySessions.length,
        });
      }

      return weeklyData;
    } catch (error) {
      throw Exception('Failed to get weekly progress: $error');
    }
  }

  /// Get session statistics
  Future<Map<String, dynamic>> getSessionStats() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get all sessions for stats
      final sessions = await getUserSessions(limit: 1000);

      if (sessions.isEmpty) {
        return {
          'total_sessions': 0,
          'total_duration': 0,
          'avg_duration': 0.0,
          'avg_temperature': 0.0,
          'personal_best': 0,
          'coldest_plunge': 0,
          'favorite_location': 'N/A',
          'most_common_mood': 'N/A',
        };
      }

      final totalSessions = sessions.length;
      final totalDuration = sessions.fold<int>(
        0,
        (sum, s) => sum + (s['duration'] as int? ?? 0),
      );
      final avgDuration = totalDuration / totalSessions;
      final avgTemperature =
          sessions.fold<int>(
            0,
            (sum, s) => sum + (s['temperature'] as int? ?? 0),
          ) /
          totalSessions;
      final personalBest = sessions.fold<int>(
        0,
        (max, s) =>
            (s['duration'] as int? ?? 0) > max
                ? (s['duration'] as int? ?? 0)
                : max,
      );
      final coldestPlunge = sessions.fold<int>(
        100,
        (min, s) =>
            (s['temperature'] as int? ?? 100) < min
                ? (s['temperature'] as int? ?? 100)
                : min,
      );

      // Find favorite location
      final locationCounts = <String, int>{};
      for (final session in sessions) {
        final location = session['location'] as String? ?? 'Unknown';
        locationCounts[location] = (locationCounts[location] ?? 0) + 1;
      }
      final favoriteLocation =
          locationCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

      // Find most common post mood
      final moodCounts = <String, int>{};
      for (final session in sessions) {
        final mood = session['post_mood'] as String?;
        if (mood != null) {
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
        }
      }
      final mostCommonMood =
          moodCounts.isNotEmpty
              ? moodCounts.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key
              : 'N/A';

      return {
        'total_sessions': totalSessions,
        'total_duration': totalDuration,
        'avg_duration': double.parse(avgDuration.toStringAsFixed(1)),
        'avg_temperature': double.parse(avgTemperature.toStringAsFixed(1)),
        'personal_best': personalBest,
        'coldest_plunge': coldestPlunge,
        'favorite_location': favoriteLocation,
        'most_common_mood': mostCommonMood,
      };
    } catch (error) {
      throw Exception('Failed to get session stats: $error');
    }
  }

  /// Check if user can start a new session (rate limiting)
  Future<bool> canStartNewSession() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return false;

    try {
      // Check if there's a session in the last 30 minutes
      final thirtyMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 30),
      );

      final recentSessions = await _client
          .from('plunge_sessions')
          .select('id')
          .eq('user_id', currentUser.id)
          .gte('created_at', thirtyMinutesAgo.toIso8601String())
          .limit(1);

      return recentSessions.isEmpty;
    } catch (error) {
      return true; // Allow session creation if check fails
    }
  }

  /// Clean up resources
  void dispose() {
    _saveDebounceTimer?.cancel();
    _pendingSaves.clear();
  }
}
