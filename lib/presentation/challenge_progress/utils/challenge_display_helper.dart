import '../../../services/user_settings_service.dart';

/// Display metadata for challenge progress UI
class ChallengeDisplayMetadata {
  final String currentText;
  final String goalText;
  final String unitLabel;
  final String subLabel;
  final String iconName;

  const ChallengeDisplayMetadata({
    required this.currentText,
    required this.goalText,
    required this.unitLabel,
    required this.subLabel,
    required this.iconName,
  });
}

/// Helper to determine proper display format for challenge progress
class ChallengeDisplayHelper {
  /// Get display metadata for a challenge based on its type, title, and values
  static ChallengeDisplayMetadata getProgressDisplay({
    required String challengeTitle,
    required String challengeType,
    required int targetValue,
    required int durationDays,
    required double currentProgress,
  }) {
    final currentValue = (currentProgress * targetValue / 100).round();

    // Special handling for streak-with-temperature-condition challenges
    // These are marked as 'temperature' type but are actually day-streak challenges
    if (_isStreakWithTemperatureCondition(challengeTitle, challengeType)) {
      return _buildStreakWithTempDisplay(
        challengeTitle: challengeTitle,
        currentProgress: currentProgress,
        durationDays: durationDays,
        tempThresholdC: targetValue,
      );
    }

    // Handle other challenge types
    switch (challengeType) {
      case 'streak':
        return ChallengeDisplayMetadata(
          currentText: '$currentValue',
          goalText: '$targetValue',
          unitLabel: 'Days',
          subLabel: 'Consecutive days',
          iconName: 'trending_up',
        );

      case 'duration':
        // Single session duration threshold
        final targetSeconds = targetValue;

        return ChallengeDisplayMetadata(
          currentText: '$currentValue',
          goalText: '$targetSeconds',
          unitLabel: 'Seconds',
          subLabel: formatDurationCondition(targetSeconds),
          iconName: 'trending_up',
        );

      case 'temperature':
        // Temperature-based session count (e.g., Ice Breaker)
        return _buildTemperatureSessionCountDisplay(
          currentValue: currentValue,
          targetValue: targetValue,
        );

      case 'consistency':
      default:
        // Session count challenges
        return ChallengeDisplayMetadata(
          currentText: '$currentValue',
          goalText: '$targetValue',
          unitLabel: 'Sessions',
          subLabel: 'Total sessions',
          iconName: 'trending_up',
        );
    }
  }

  /// Check if this is a streak challenge with temperature condition
  static bool _isStreakWithTemperatureCondition(
      String challengeTitle, String challengeType) {
    // Extreme Cold Challenge: 14 consecutive days at or below temperature
    if (challengeTitle.contains('Extreme Cold')) return true;

    // Future: add other streak-with-condition challenges here
    return false;
  }

  /// Build display for streak-with-temperature challenges
  static ChallengeDisplayMetadata _buildStreakWithTempDisplay({
    required String challengeTitle,
    required double currentProgress,
    required int durationDays,
    required int tempThresholdC,
  }) {
    final currentDays = (currentProgress * durationDays / 100).round();

    return ChallengeDisplayMetadata(
      currentText: '$currentDays',
      goalText: '$durationDays',
      unitLabel: 'Days',
      subLabel: formatTemperatureCondition(tempThresholdC),
      iconName: 'trending_up',
    );
  }

  /// Build display for temperature-based session count
  static ChallengeDisplayMetadata _buildTemperatureSessionCountDisplay({
    required int currentValue,
    required int targetValue,
  }) {
    // For challenges like Ice Breaker: count sessions at or below temperature
    return ChallengeDisplayMetadata(
      currentText: '$currentValue',
      goalText: '10', // Ice Breaker requires 10 sessions
      unitLabel: 'Sessions',
      subLabel: formatTemperatureCondition(targetValue),
      iconName: 'trending_up',
    );
  }

  /// Format temperature condition for display (always uses strict less-than)
  /// Returns format: "< 50°F (10°C)"
  static String formatTemperatureCondition(int tempCelsius) {
    final tempF = _celsiusToFahrenheit(tempCelsius);
    return '< ${tempF}°F (${tempCelsius}°C)';
  }

  /// Format duration condition for display (clean, human-readable)
  /// Returns format: "Single session 60 min" or "Single session 10 min"
  static String formatDurationCondition(int targetSeconds) {
    final targetMinutes = (targetSeconds / 60).floor();
    final targetSecondsRemainder = targetSeconds % 60;

    if (targetSecondsRemainder > 0) {
      return 'Single session $targetMinutes min ${targetSecondsRemainder}s';
    } else {
      return 'Single session $targetMinutes min';
    }
  }

  /// Convert Celsius to Fahrenheit
  static int _celsiusToFahrenheit(int celsius) {
    return ((celsius * 9 / 5) + 32).round();
  }
}
