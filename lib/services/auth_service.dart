import 'package:supabase_flutter/supabase_flutter.dart';
import './analytics_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      return response;
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? avatarUrl,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'avatar_url': avatarUrl ?? ''},
      );
      return response;
    } catch (error) {
      throw Exception('Sign up failed: $error');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign in failed: $error');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw Exception('Sign out failed: $error');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? location,
    int? preferredTemperature,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;
    if (location != null) updates['location'] = location;
    if (preferredTemperature != null)
      updates['preferred_temperature'] = preferredTemperature;

    updates['updated_at'] = DateTime.now().toIso8601String();

    try {
      final response = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', currentUser!.id)
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Profile update failed: $error');
    }
  }

  /// Update user streak
  Future<void> updateStreak(int newStreak) async {
    if (!isAuthenticated) return;

    try {
      await _client
          .from('user_profiles')
          .update({
            'streak_count': newStreak,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser!.id);
    } catch (error) {
      throw Exception('Streak update failed: $error');
    }
  }

  /// Listen to authentication state changes
  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;

  /// Check if user has completed session today
  Future<bool> hasSessionToday() async {
    if (!isAuthenticated) return false;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('plunge_sessions')
          .select('id')
          .eq('user_id', currentUser!.id)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .limit(1);

      return response.isNotEmpty;
    } catch (error) {
      return false;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      // Get basic profile data
      final profile = await getCurrentUserProfile();

      // Calculate actual current streak from session history
      final currentStreak = await AnalyticsService().calculateCurrentStreak();

      // Get this week's sessions
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      ).toIso8601String();

      final weekSessions = await _client
          .from('plunge_sessions')
          .select('duration')
          .eq('user_id', currentUser!.id)
          .gte('created_at', weekStartStr);

      // Calculate weekly stats
      final weekCount = weekSessions.length;
      final totalWeekDuration = weekSessions.fold<int>(
        0,
        (sum, session) => sum + (session['duration'] as int? ?? 0),
      );
      final avgDuration = weekCount > 0
          ? (totalWeekDuration / weekCount).toStringAsFixed(1)
          : '0.0';

      return {
        'streak_count': currentStreak,
        'total_sessions': profile?['total_sessions'] ?? 0,
        'personal_best_duration': profile?['personal_best_duration'] ?? 0,
        'week_sessions': weekCount,
        'week_duration': totalWeekDuration,
        'avg_duration': avgDuration,
      };
    } catch (error) {
      throw Exception('Failed to get user stats: $error');
    }
  }
}
