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

  /// Format duration in seconds to clean string (0s, 30s, 1m, 1m30s, 2m, etc.)
  static String formatDurationLabel(double seconds) {
    if (seconds == 0) return '0s';

    final totalSeconds = seconds.toInt();
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }

    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;

    if (remainingSeconds == 0) {
      return '${minutes}m';
    } else {
      return '${minutes}m${remainingSeconds}s';
    }
  }

  /// Calculate optimal interval for duration charts (Weekly Progress)
  /// Returns clean intervals like 30s, 1m, 1m30s, 2m, 2m30s, 3m
  static double calculateDurationInterval(double maxDuration) {
    if (maxDuration <= 0) return 30.0;

    // Calculate base interval for 4-5 labels
    final rawInterval = maxDuration / 4;

    // Round to nice duration intervals
    if (rawInterval <= 30) {
      return 30.0; // 30 seconds
    } else if (rawInterval <= 60) {
      return 60.0; // 1 minute
    } else if (rawInterval <= 90) {
      return 90.0; // 1m30s
    } else if (rawInterval <= 120) {
      return 120.0; // 2 minutes
    } else if (rawInterval <= 150) {
      return 150.0; // 2m30s
    } else if (rawInterval <= 180) {
      return 180.0; // 3 minutes
    } else {
      // For longer durations, round to nearest minute
      return (rawInterval / 60).ceil() * 60.0;
    }
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
