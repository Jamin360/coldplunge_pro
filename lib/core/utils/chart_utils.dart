import 'dart:math';

/// Utility class for chart calculations and formatting
class ChartUtils {
  /// Calculate optimal Y-axis interval based on data range
  /// Returns interval that produces 5-6 labels maximum
  static double calculateOptimalInterval(double minValue, double maxValue,
      {int maxLabels = 6}) {
    if (maxValue <= minValue) return 1.0;

    final range = maxValue - minValue;
    final rawInterval = range / (maxLabels - 1);

    // Round to nice values
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
  /// Adds 20% padding and rounds to nice interval
  static double calculateMaxY(List<double> values, {double minRange = 180.0}) {
    if (values.isEmpty) return minRange;

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final paddedMax = maxValue * 1.2;

    // Calculate interval for nice rounding
    final interval = calculateOptimalInterval(0, paddedMax);
    final roundedMax = (paddedMax / interval).ceil() * interval;

    return max(roundedMax, minRange);
  }

  /// Format duration in seconds to clean string (0s, 1m, 2m, etc.)
  static String formatDurationLabel(double seconds) {
    if (seconds == 0) return '0s';

    final totalSeconds = seconds.round();
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }

    final minutes = totalSeconds ~/ 60;
    return '${minutes}m';
  }

  /// Format temperature to clean string (e.g., 30°F, 40°F)
  static String formatTemperatureLabel(double fahrenheit) {
    return '${fahrenheit.round()}°F';
  }

  /// Format session count to clean string
  static String formatCountLabel(double count) {
    return count.round().toString();
  }

  /// Calculate optimal minY for temperature charts
  static double calculateMinTemperature(List<double> temperatures) {
    if (temperatures.isEmpty) return 30;

    final minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    final interval = calculateOptimalInterval(minTemp - 10, minTemp + 10);
    return ((minTemp - 10) / interval).floor() * interval;
  }

  /// Calculate optimal maxY for temperature charts
  static double calculateMaxTemperature(List<double> temperatures) {
    if (temperatures.isEmpty) return 70;

    final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    final interval = calculateOptimalInterval(maxTemp - 10, maxTemp + 10);
    return ((maxTemp + 10) / interval).ceil() * interval;
  }
}
