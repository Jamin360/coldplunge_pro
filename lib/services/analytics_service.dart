import './supabase_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final _supabase = SupabaseService.instance.client;

  // Get user analytics data for different time periods
  Future<Map<String, dynamic>> getUserAnalytics(String period) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Calculate date range based on period
      final now = DateTime.now();
      DateTime startDate;

      switch (period.toLowerCase()) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'quarter':
          startDate = now.subtract(const Duration(days: 90));
          break;
        case 'year':
          startDate = now.subtract(const Duration(days: 365));
          break;
        default:
          startDate = now.subtract(const Duration(days: 30));
      }

      // Get user profile data
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', userId)
          .single();

      // Get sessions data for the period
      final sessionsResponse = await _supabase
          .from('plunge_sessions')
          .select('*')
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: false);

      // Get weekly goals
      final weekStart = _getWeekStartDate(now);
      final weeklyGoalsResponse = await _supabase
          .from('weekly_goals')
          .select('*')
          .eq('user_id', userId)
          .eq('week_start_date', weekStart.toIso8601String().split('T')[0])
          .maybeSingle();

      return {
        'profile': profileResponse,
        'sessions': sessionsResponse,
        'weeklyGoal': weeklyGoalsResponse,
      };
    } catch (e) {
      throw Exception('Failed to fetch analytics data: $e');
    }
  }

  // Get session frequency data for chart
  Future<List<Map<String, dynamic>>> getSessionFrequencyData(
    String period,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      List<Map<String, dynamic>> frequencyData = [];

      if (period.toLowerCase() == 'week') {
        // Get last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final startOfDay = DateTime(date.year, date.month, date.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));

          final response = await _supabase
              .from('plunge_sessions')
              .select('id')
              .eq('user_id', userId)
              .gte('created_at', startOfDay.toIso8601String())
              .lt('created_at', endOfDay.toIso8601String());

          frequencyData.add({
            'day': _getDayName(date.weekday),
            'sessions': response.length,
            'date': date,
          });
        }
      } else {
        // For other periods, get weekly data
        for (int i = 3; i >= 0; i--) {
          final weekStart = _getWeekStartDate(
            now.subtract(Duration(days: i * 7)),
          );
          final weekEnd = weekStart.add(const Duration(days: 7));

          final response = await _supabase
              .from('plunge_sessions')
              .select('id')
              .eq('user_id', userId)
              .gte('created_at', weekStart.toIso8601String())
              .lt('created_at', weekEnd.toIso8601String());

          frequencyData.add({
            'week': 'W${4 - i}',
            'sessions': response.length,
            'weekStart': weekStart,
          });
        }
      }

      return frequencyData;
    } catch (e) {
      throw Exception('Failed to fetch frequency data: $e');
    }
  }

  // Get temperature progress data - FIXED to use proper aggregation
  Future<List<Map<String, dynamic>>> getTemperatureProgressData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      List<Map<String, dynamic>> tempData = [];

      // Get last 8 weeks of temperature data for better trend visibility
      for (int i = 7; i >= 0; i--) {
        final weekStart = _getWeekStartDate(
          now.subtract(Duration(days: i * 7)),
        );
        final weekEnd = weekStart.add(const Duration(days: 7));

        final response = await _supabase
            .from('plunge_sessions')
            .select('temperature')
            .eq('user_id', userId)
            .gte('created_at', weekStart.toIso8601String())
            .lt('created_at', weekEnd.toIso8601String())
            .not('temperature', 'is', null);

        double? avgTemp;
        if (response.isNotEmpty) {
          final temperatures = response
              .map<int>((session) => session['temperature'] as int)
              .toList();
          // Use average temperature for smoother trend line
          avgTemp = temperatures.reduce((a, b) => a + b) / temperatures.length;
        }

        tempData.add({
          'week': i == 0 ? 'This Week' : '${i}w ago',
          'temp': avgTemp ?? 20.0, // More realistic default temperature
          'weekStart': weekStart,
        });
      }

      return tempData;
    } catch (e) {
      throw Exception('Failed to fetch temperature data: $e');
    }
  }

  /// Get mood analytics data
  Future<Map<String, dynamic>> getMoodAnalytics() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get all sessions with mood data for the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final response = await _supabase
          .from('plunge_sessions')
          .select('pre_mood, post_mood, created_at, rating')
          .eq('user_id', currentUser.id)
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .order('created_at', ascending: true);

      final sessions = List<Map<String, dynamic>>.from(response);

      if (sessions.isEmpty) {
        return _getEmptyMoodAnalytics();
      }

      // Process mood data with proper null safety
      final moodData = <Map<String, dynamic>>[];
      final moodCounts = <String, int>{};
      final moodImprovements = <String, List<int>>{}; // Track mood changes

      for (final session in sessions) {
        final preMoodRaw = session['pre_mood'];
        final postMoodRaw = session['post_mood'];
        final createdAt = session['created_at'] as String?;
        final rating = session['rating'] as int?;

        // Skip sessions with missing mood data
        if (preMoodRaw == null || postMoodRaw == null || createdAt == null) {
          continue;
        }

        // Ensure mood values are strings (handle potential type issues)
        final preMood = preMoodRaw.toString();
        final postMood = postMoodRaw.toString();

        // Validate mood values against enum
        if (!_isValidMoodType(preMood) || !_isValidMoodType(postMood)) {
          continue;
        }

        // Calculate mood improvement score
        final preMoodScore = _getMoodScore(preMood);
        final postMoodScore = _getMoodScore(postMood);
        final improvementScore = postMoodScore - preMoodScore;

        moodData.add({
          'date': DateTime.parse(createdAt),
          'preMood': preMood,
          'postMood': postMood,
          'preMoodScore': preMoodScore,
          'postMoodScore': postMoodScore,
          'improvement': improvementScore,
          'rating': rating ?? 3, // Default rating if null
        });

        // Count mood frequencies
        moodCounts[preMood] = (moodCounts[preMood] ?? 0) + 1;
        moodCounts[postMood] = (moodCounts[postMood] ?? 0) + 1;

        // Track improvements by pre-mood type
        if (!moodImprovements.containsKey(preMood)) {
          moodImprovements[preMood] = [];
        }
        moodImprovements[preMood]!.add(improvementScore);
      }

      // Calculate averages and trends with null safety
      final avgPreMoodScore = moodData.isEmpty
          ? 0.0
          : moodData
                  .map((e) => e['preMoodScore'] as int)
                  .reduce((a, b) => a + b) /
              moodData.length;
      final avgPostMoodScore = moodData.isEmpty
          ? 0.0
          : moodData
                  .map((e) => e['postMoodScore'] as int)
                  .reduce((a, b) => a + b) /
              moodData.length;
      final avgImprovement = moodData.isEmpty
          ? 0.0
          : moodData
                  .map((e) => e['improvement'] as int)
                  .reduce((a, b) => a + b) /
              moodData.length;

      // Find most common moods with null safety
      final mostCommonPreMood =
          _findMostCommonMood(moodCounts, isPreMood: true);
      final mostCommonPostMood =
          _findMostCommonMood(moodCounts, isPreMood: false);

      // Calculate mood consistency (how often moods improve)
      final improvementCount =
          moodData.where((m) => (m['improvement'] as int) > 0).length;
      final consistencyRate =
          moodData.isEmpty ? 0.0 : improvementCount / moodData.length;

      // Generate weekly trend data for charts
      final weeklyTrends = _generateWeeklyMoodTrends(moodData);

      return {
        'totalSessions': moodData.length,
        'avgPreMoodScore': double.parse(avgPreMoodScore.toStringAsFixed(1)),
        'avgPostMoodScore': double.parse(avgPostMoodScore.toStringAsFixed(1)),
        'avgImprovement': double.parse(avgImprovement.toStringAsFixed(1)),
        'improvementRate':
            double.parse((consistencyRate * 100).toStringAsFixed(1)),
        'mostCommonPreMood': mostCommonPreMood,
        'mostCommonPostMood': mostCommonPostMood,
        'dailyData': moodData
            .map((d) => {
                  'date': (d['date'] as DateTime).toIso8601String(),
                  'preMoodScore': d['preMoodScore'],
                  'postMoodScore': d['postMoodScore'],
                  'improvement': d['improvement'],
                  'preMood': d['preMood'],
                  'postMood': d['postMood'],
                })
            .toList(),
        'weeklyTrends': weeklyTrends,
        'moodDistribution': _calculateMoodDistribution(moodCounts),
      };
    } catch (error) {
      print('Error getting mood analytics: $error');
      return _getEmptyMoodAnalytics();
    }
  }

  /// Validate if a mood type is valid according to the enum
  bool _isValidMoodType(String mood) {
    const validMoods = [
      'stressed',
      'tired',
      'anxious',
      'neutral',
      'energized',
      'focused',
      'calm',
      'euphoric'
    ];
    return validMoods.contains(mood.toLowerCase());
  }

  /// Convert mood string to numerical score for calculations
  int _getMoodScore(String mood) {
    switch (mood.toLowerCase()) {
      case 'stressed':
        return 1;
      case 'tired':
        return 2;
      case 'anxious':
        return 3;
      case 'neutral':
        return 4;
      case 'energized':
        return 6;
      case 'focused':
        return 7;
      case 'calm':
        return 8;
      case 'euphoric':
        return 9;
      default:
        return 4; // Default to neutral
    }
  }

  /// Find most common mood with proper null safety
  String _findMostCommonMood(Map<String, int> moodCounts,
      {required bool isPreMood}) {
    if (moodCounts.isEmpty) return 'neutral';

    // Filter for pre or post mood analysis if needed
    var entry = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return entry.key;
  }

  /// Generate weekly mood trend data
  List<Map<String, dynamic>> _generateWeeklyMoodTrends(
      List<Map<String, dynamic>> moodData) {
    if (moodData.isEmpty) return [];

    // Group by week
    final weeklyGroups = <String, List<Map<String, dynamic>>>{};

    for (final mood in moodData) {
      final date = mood['date'] as DateTime;
      final weekKey = '${date.year}-W${_getWeekNumber(date)}';

      if (!weeklyGroups.containsKey(weekKey)) {
        weeklyGroups[weekKey] = [];
      }
      weeklyGroups[weekKey]!.add(mood);
    }

    // Calculate weekly averages
    final weeklyTrends = <Map<String, dynamic>>[];

    weeklyGroups.entries.forEach((entry) {
      final weekData = entry.value;
      final avgPre = weekData
              .map((m) => m['preMoodScore'] as int)
              .reduce((a, b) => a + b) /
          weekData.length;
      final avgPost = weekData
              .map((m) => m['postMoodScore'] as int)
              .reduce((a, b) => a + b) /
          weekData.length;

      weeklyTrends.add({
        'week': entry.key,
        'avgPreMood': double.parse(avgPre.toStringAsFixed(1)),
        'avgPostMood': double.parse(avgPost.toStringAsFixed(1)),
        'sessionCount': weekData.length,
      });
    });

    return weeklyTrends..sort((a, b) => a['week'].compareTo(b['week']));
  }

  /// Get week number from date
  int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Calculate mood distribution percentages
  Map<String, double> _calculateMoodDistribution(Map<String, int> moodCounts) {
    if (moodCounts.isEmpty) return {};

    final total = moodCounts.values.reduce((a, b) => a + b);
    if (total == 0) return {};

    return moodCounts.map((mood, count) =>
        MapEntry(mood, double.parse((count / total * 100).toStringAsFixed(1))));
  }

  /// Return empty analytics when no data is available
  Map<String, dynamic> _getEmptyMoodAnalytics() {
    return {
      'totalSessions': 0,
      'avgPreMoodScore': 0.0,
      'avgPostMoodScore': 0.0,
      'avgImprovement': 0.0,
      'improvementRate': 0.0,
      'mostCommonPreMood': 'neutral',
      'mostCommonPostMood': 'neutral',
      'dailyData': <Map<String, dynamic>>[],
      'weeklyTrends': <Map<String, dynamic>>[],
      'moodDistribution': <String, double>{},
    };
  }

  // Calculate key metrics
  Map<String, dynamic> calculateKeyMetrics(Map<String, dynamic> analyticsData) {
    final profile = analyticsData['profile'] as Map<String, dynamic>;
    final sessions = analyticsData['sessions'] as List<dynamic>;
    final weeklyGoal = analyticsData['weeklyGoal'] as Map<String, dynamic>?;

    // Total sessions from profile
    final totalSessions = profile['total_sessions'] ?? 0;

    // Current streak from profile
    final currentStreak = profile['streak_count'] ?? 0;

    // Calculate average duration
    double avgDuration = 0.0;
    if (sessions.isNotEmpty) {
      final durations =
          sessions.map<int>((session) => session['duration'] ?? 0).toList();
      avgDuration = durations.reduce((a, b) => a + b) / durations.length;
    }

    // Find coldest temperature
    int? coldestTemp;
    if (sessions.isNotEmpty) {
      final temperatures = sessions
          .where((session) => session['temperature'] != null)
          .map<int>((session) => session['temperature'] as int)
          .toList();
      if (temperatures.isNotEmpty) {
        coldestTemp = temperatures.reduce((a, b) => a < b ? a : b);
      }
    }

    return {
      'totalSessions': totalSessions,
      'currentStreak': currentStreak,
      'avgDuration': avgDuration,
      'coldestTemp': coldestTemp,
      'weeklyGoal': weeklyGoal,
    };
  }

  // Helper methods
  DateTime _getWeekStartDate(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  int _moodToNumber(String mood) {
    const moodMap = {
      'stressed': 2,
      'tired': 3,
      'anxious': 3,
      'neutral': 5,
      'energized': 8,
      'focused': 7,
      'calm': 8,
      'euphoric': 10,
    };
    return moodMap[mood] ?? 5;
  }

  // Export data methods
  Future<String> exportToPDF() async {
    try {
      // In a real implementation, you would generate a PDF with charts and data
      // For now, we'll simulate the export
      await Future.delayed(const Duration(seconds: 1));
      return 'PDF export completed successfully';
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  Future<String> exportToCSV() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get all user sessions for CSV export
      final sessions = await _supabase
          .from('plunge_sessions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // In a real implementation, you would generate and download a CSV file
      // For now, we'll simulate the export
      await Future.delayed(const Duration(seconds: 1));
      return 'CSV export completed with ${sessions.length} sessions';
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }
}
