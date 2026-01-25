import 'dart:math';

/// Utility class for chart calculations and formatting
class ChartUtils {
  /// Calculate optimal Y-axis interval based on data range
  /// Returns interval that produces 4-5 labels maximum for clean display
  static double calculateOptimalInterval(double minValue, double maxValue,
      {int maxLabels = 5}) {
    if (maxValue <= minValue) return 1.0;

    final range = maxValue - minValue;

    final rawInterval = range / (maxLabels - 1);

    // Round to nice values (1, 2, 5, 10, 20, 50, 100, etc.)
    final magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();
    final normalizedInterval = rawInterval / magnitude;

    double niceInterval;
    if (normalizedInterval <= 1) {
      niceInterval = 1;
    } else if (normalizedInterval <= 2) {
      niceInterval = 2;
    } else if (normalizedInterval <= 5) {
      niceInterval = 5;
    } else {
      niceInterval = 10;
    }

    return niceInterval * magnitude;
  }

  /// Calculate optimal maxY value based on data
  /// Adds 15% padding and rounds to nice interval
  static double calculateMaxY(List<double> values, {double minRange = 180.0}) {
    if (values.isEmpty) return minRange;

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final paddedMax = maxValue * 1.15;

    // Calculate interval for nice rounding
    final interval = calculateOptimalInterval(0, paddedMax);
    final roundedMax = (paddedMax / interval).ceil() * interval;

    return max(roundedMax, minRange);
  }

  /// Format duration in seconds to clean string for Y-axis (0m, 1m, 2m, etc.)
  /// Always shows whole minutes only, no seconds
  static String formatDurationLabel(double seconds) {
    final minutes = (seconds / 60).round();
    return '${minutes}m';
  }

  /// Calculate optimal interval for duration charts (Weekly Progress)
  /// Returns clean intervals in whole minutes only (60s, 120s, 180s, etc.)
  static double calculateDurationInterval(double maxDuration) {
    if (maxDuration <= 0) return 60.0; // Default to 1 minute

    // Convert to minutes and round up
    final maxMinutes = (maxDuration / 60).ceil();

    // Calculate interval to get 4-6 labels
    final rawInterval = maxMinutes / 5;

    // Round to whole minutes only
    int minuteInterval;
    if (rawInterval <= 1) {
      minuteInterval = 1; // 1 minute intervals
    } else if (rawInterval <= 2) {
      minuteInterval = 2; // 2 minute intervals
    } else if (rawInterval <= 3) {
      minuteInterval = 3; // 3 minute intervals
    } else if (rawInterval <= 5) {
      minuteInterval = 5; // 5 minute intervals
    } else {
      // Round up to nearest 5 minutes for larger values
      minuteInterval = ((rawInterval / 5).ceil() * 5).toInt();
    }

    // Convert back to seconds
    return (minuteInterval * 60).toDouble();
  }

  /// Format temperature to clean string (whole number only - no duplicate °F)
  static String formatTemperatureLabel(double fahrenheit) {
    return '${fahrenheit.round()}';
  }

  /// Format session count to clean string
  static String formatCountLabel(double count) {
    return count.toInt().toString();
  }

  /// Calculate optimal interval for session frequency chart
  /// Uses interval of 1 when max ≤ 5, otherwise calculates optimal
  static double calculateSessionFrequencyInterval(double maxCount) {
    if (maxCount <= 5) {
      return 1.0;
    }
    return calculateOptimalInterval(0, maxCount);
  }

  /// Calculate optimal interval for temperature charts
  /// Always rounds to whole numbers with minimum of 5 degrees
  static double calculateTemperatureInterval(double minTemp, double maxTemp) {
    final range = maxTemp - minTemp;
    if (range <= 0) return 10.0;

    // Calculate interval for 4 labels: (max - min) / 4
    var interval = (range / 4).ceilToDouble();

    // Ensure minimum interval of 5 degrees
    if (interval < 5) {
      interval = 5.0;
    } else if (interval <= 10) {
      interval = 10.0;
    } else if (interval <= 15) {
      interval = 15.0;
    } else if (interval <= 20) {
      interval = 20.0;
    } else {
      // Round up to nearest 5 for larger ranges
      interval = ((interval / 5).ceil() * 5).toDouble();
    }

    return interval;
  }

  /// Calculate optimal minY for temperature charts
  static double calculateMinTemperature(List<double> temperatures) {
    if (temperatures.isEmpty) return 30;

    final minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    final interval = calculateOptimalInterval(minTemp - 5, minTemp + 5);
    return ((minTemp - 5) / interval).floor() * interval;
  }

  /// Calculate optimal maxY for temperature charts
  static double calculateMaxTemperature(List<double> temperatures) {
    if (temperatures.isEmpty) return 70;

    final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    final interval = calculateOptimalInterval(maxTemp - 5, maxTemp + 5);
    return ((maxTemp + 5) / interval).ceil() * interval;
  }
}
