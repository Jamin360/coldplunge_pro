/// Shared streak calculator used by Home and Analytics
class StreakCalculator {
  /// Calculate current streak from a list of sessions
  ///
  /// A streak is the number of consecutive local days with at least one session,
  /// walking backward from:
  /// - today if today has a session
  /// - yesterday if today doesn't have a session but yesterday does
  ///
  /// [sessions] - List of sessions with 'created_at' field (UTC timestamp string)
  static int calculateCurrentStreak(
    List<Map<String, dynamic>> sessions, {
    DateTime? now,
  }) {
    if (sessions.isEmpty) return 0;

    try {
      // Use device's local time
      final localNow = now?.toLocal() ?? DateTime.now();
      final todayLocal = DateTime(
        localNow.year,
        localNow.month,
        localNow.day,
      );

      // Extract unique local dates from sessions
      final sessionDates = <DateTime>{};
      for (final session in sessions) {
        final createdAtUtc = DateTime.parse(session['created_at'] as String);
        final createdAtLocal = createdAtUtc.toLocal();
        final dateOnly = DateTime(
          createdAtLocal.year,
          createdAtLocal.month,
          createdAtLocal.day,
        );
        sessionDates.add(dateOnly);
      }

      // Sort dates in descending order
      final sortedDates = sessionDates.toList()..sort((a, b) => b.compareTo(a));

      // Determine starting point for streak counting
      final yesterday = todayLocal.subtract(const Duration(days: 1));
      DateTime currentDate;
      int streak;

      if (sortedDates.first.isAtSameMomentAs(todayLocal)) {
        // Session exists today, start from today
        currentDate = todayLocal;
        streak = 1;
      } else if (sortedDates.first.isAtSameMomentAs(yesterday)) {
        // No session today but one yesterday, start from yesterday
        currentDate = yesterday;
        streak = 1;
      } else {
        // No recent sessions, streak is 0
        return 0;
      }

      // Count backwards checking for consecutive days
      int dateIndex = 1;
      while (dateIndex < sortedDates.length) {
        final previousDate = currentDate.subtract(const Duration(days: 1));

        if (sortedDates[dateIndex].isAtSameMomentAs(previousDate)) {
          // Found session on consecutive day
          streak++;
          currentDate = previousDate;
          dateIndex++;
        } else {
          // Gap found, streak ends
          break;
        }
      }

      return streak;
    } catch (e) {
      print('❌ Error calculating streak: $e');
      return 0;
    }
  }
}
