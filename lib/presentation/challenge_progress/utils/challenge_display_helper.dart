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
        final targetMinutes = (targetSeconds / 60).floor();
        final targetSecondsRemainder = targetSeconds % 60;
        final targetDisplay = targetSecondsRemainder > 0
            ? '${targetMinutes}m ${targetSecondsRemainder}s'
            : '${targetMinutes}m';

        return ChallengeDisplayMetadata(
          currentText: '$currentValue',
          goalText: '$targetSeconds',
          unitLabel: 'Seconds',
          subLabel: 'Single session ≥ $targetDisplay',
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

    // Convert temperature to both units for display
    final tempF = _celsiusToFahrenheit(tempThresholdC);
    final tempCondition = '≤ ${tempF}°F (${tempThresholdC}°C)';

    return ChallengeDisplayMetadata(
      currentText: '$currentDays',
      goalText: '$durationDays',
      unitLabel: 'Days',
      subLabel: tempCondition,
      iconName: 'trending_up',
    );
  }

  /// Build display for temperature-based session count
  static ChallengeDisplayMetadata _buildTemperatureSessionCountDisplay({
    required int currentValue,
    required int targetValue,
  }) {
    // For challenges like Ice Breaker: count sessions at or below temperature
    final tempF = _celsiusToFahrenheit(targetValue);
    final tempCondition = '≤ ${tempF}°F (${targetValue}°C)';

    return ChallengeDisplayMetadata(
      currentText: '$currentValue',
      goalText: '10', // Ice Breaker requires 10 sessions
      unitLabel: 'Sessions',
      subLabel: tempCondition,
      iconName: 'trending_up',
    );
  }

  /// Convert Celsius to Fahrenheit
  static int _celsiusToFahrenheit(int celsius) {
    return ((celsius * 9 / 5) + 32).round();
  }
}
