/// Centralized challenge timing utilities
/// Challenges start when a user joins and run for the challenge duration
class ChallengeTimingHelper {
  /// Calculate the end time for a user's joined challenge
  static DateTime getChallengeEndTime({
    required DateTime joinedAt,
    required int durationDays,
  }) {
    return joinedAt.add(Duration(days: durationDays));
  }

  /// Check if a user's challenge is expired
  static bool isChallengeExpired({
    required DateTime joinedAt,
    required int durationDays,
  }) {
    final endTime = getChallengeEndTime(
      joinedAt: joinedAt,
      durationDays: durationDays,
    );
    return DateTime.now().isAfter(endTime);
  }

  /// Get remaining days for a user's challenge
  static int getRemainingDays({
    required DateTime joinedAt,
    required int durationDays,
  }) {
    final endTime = getChallengeEndTime(
      joinedAt: joinedAt,
      durationDays: durationDays,
    );
    final remaining = endTime.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  /// Get formatted time left string for joined challenge
  static String getTimeLeftString({
    required DateTime joinedAt,
    required int durationDays,
  }) {
    if (isChallengeExpired(joinedAt: joinedAt, durationDays: durationDays)) {
      return 'Expired';
    }

    final remaining = getRemainingDays(
      joinedAt: joinedAt,
      durationDays: durationDays,
    );

    if (remaining == 0) return 'Last day';
    if (remaining == 1) return '1 day left';
    return '$remaining days left';
  }

  /// Get formatted duration string for unjoined challenge
  static String getDurationString(int durationDays) {
    if (durationDays == 1) return '1 day challenge';
    return '$durationDays day challenge';
  }
}
