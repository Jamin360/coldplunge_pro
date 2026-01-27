import 'package:flutter/foundation.dart';

class PerformanceLogger {
  static final Map<String, Stopwatch> _stopwatches = {};

  static void start(String tag) {
    if (kDebugMode) {
      _stopwatches[tag] = Stopwatch()..start();
    }
  }

  static void end(String tag, [String? additionalInfo]) {
    if (kDebugMode && _stopwatches.containsKey(tag)) {
      final stopwatch = _stopwatches[tag]!;
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      String logMessage = '⚡ [$tag] took ${elapsed}ms';
      if (additionalInfo != null) {
        logMessage += ' - $additionalInfo';
      }

      // Color code based on performance
      if (elapsed > 1000) {
        debugPrint('🔴 $logMessage (SLOW!)');
      } else if (elapsed > 500) {
        debugPrint('🟡 $logMessage (Consider optimizing)');
      } else if (elapsed > 200) {
        debugPrint('🟢 $logMessage');
      } else {
        debugPrint('✅ $logMessage (Fast)');
      }

      _stopwatches.remove(tag);
    }
  }

  static void log(String message) {
    if (kDebugMode) {
      debugPrint('📊 $message');
    }
  }
}
