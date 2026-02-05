import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global error logger for debug and release
void logError({
  BuildContext? context,
  required Object error,
  StackTrace? stackTrace,
  String source = '',
}) {
  final errorMsg = '[${source.isNotEmpty ? source : 'Error'}] $error';
  if (kDebugMode) {
    debugPrint(errorMsg);
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
  // Optionally, show a SnackBar or send to analytics in release
  // if (context != null) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('An error occurred. Please try again.')),
  //   );
  // }
}
