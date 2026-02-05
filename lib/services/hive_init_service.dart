import 'package:hive_flutter/hive_flutter.dart';
import 'dashboard_cache_entry.dart';
import 'analytics_cache_entry.dart';

class HiveInitService {
  static const kDashboardCacheBox = 'dashboard_cache';
  static const kAnalyticsCacheBox = 'analytics_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DashboardCacheEntryAdapter());
    Hive.registerAdapter(AnalyticsCacheEntryAdapter());
    await Future.wait([
      Hive.openBox(kDashboardCacheBox),
      Hive.openBox(kAnalyticsCacheBox),
    ]);
  }
}
