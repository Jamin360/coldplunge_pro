import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'env_config.dart';

/// AppBootstrap handles all app initialization tasks
class AppBootstrap {
  static Future<void> init() async {
    try {
      // Initialize timezone database
      tz.initializeTimeZones();

      // Initialize environment configuration
      await EnvConfig.instance.initialize();

      // Initialize Supabase
      await Supabase.initialize(
        url: EnvConfig.instance.get('SUPABASE_URL'),
        anonKey: EnvConfig.instance.get('SUPABASE_ANON_KEY'),
      );

      // Initialize Hive (cache layer)
      await _initHive();

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e, st) {
      debugPrint('❌ AppBootstrap initialization error: $e');
      debugPrint('Stack trace: $st');
      // Continue app startup even if initialization fails
    }
  }

  static Future<void> _initHive() async {
    try {
      await Hive.initFlutter();
      // Open boxes with error handling
      try {
        await Hive.openBox('dashboardBox');
      } catch (e) {
        debugPrint('⚠️ Failed to open dashboardBox: $e');
      }
      try {
        await Hive.openBox('analyticsBox');
      } catch (e) {
        debugPrint('⚠️ Failed to open analyticsBox: $e');
      }
      debugPrint('✅ Hive initialized successfully');
    } catch (e, st) {
      debugPrint('❌ Hive initialization failed: $e');
      debugPrint('Stack trace: $st');
      // Continue without Hive - app will use in-memory cache
    }
  }
}
