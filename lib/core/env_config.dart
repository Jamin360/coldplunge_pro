import 'dart:convert';
import 'package:flutter/services.dart';

class EnvConfig {
  static EnvConfig? _instance;
  static EnvConfig get instance => _instance ??= EnvConfig._();

  EnvConfig._();

  Map<String, dynamic> _config = {};
  bool _isInitialized = false;

  /// Initialize environment configuration from env.json
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final String jsonString = await rootBundle.loadString('env.json');
      _config = json.decode(jsonString);
      _isInitialized = true;
      print('Environment configuration loaded successfully');
    } catch (e) {
      print('Error loading env.json: $e');
      _config = {};
      _isInitialized = false;
    }
  }

  /// Get a configuration value by key
  String get(String key, {String defaultValue = ''}) {
    // Return runtime configuration if available
    if (!_isInitialized) {
      print('Warning: EnvConfig not initialized. Call initialize() first.');
      return defaultValue;
    }

    return _config[key]?.toString() ?? defaultValue;
  }

  /// Check if configuration is initialized
  bool get isInitialized => _isInitialized;
}
