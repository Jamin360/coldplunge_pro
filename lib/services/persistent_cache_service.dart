import 'package:hive/hive.dart';
import 'dashboard_cache_entry.dart';
import 'analytics_cache_entry.dart';
import 'hive_init_service.dart';
import '../core/log_error_helper.dart';

class PersistentCacheService {
  static const String dashboardBoxName = HiveInitService.kDashboardCacheBox;
  static const String analyticsBoxName = HiveInitService.kAnalyticsCacheBox;

  Future<void> init() async {
    try {
      await Hive.openBox<DashboardCacheEntry>(dashboardBoxName);
    } catch (e, st) {
      logError(error: e, stackTrace: st, source: 'Hive init dashboardBox');
    }
    try {
      await Hive.openBox<AnalyticsCacheEntry>(analyticsBoxName);
    } catch (e, st) {
      logError(error: e, stackTrace: st, source: 'Hive init analyticsBox');
    }
  }

  // Dashboard cache
  Future<DashboardCacheEntry?> getDashboardCache(String key) async {
    try {
      if (!Hive.isBoxOpen(dashboardBoxName)) {
        await Hive.openBox<DashboardCacheEntry>(dashboardBoxName);
      }
      final box = Hive.box<DashboardCacheEntry>(dashboardBoxName);
      return box.get(key);
    } catch (e, st) {
      logError(error: e, stackTrace: st, source: 'Hive getDashboardCache');
      return null;
    }
  }

  Future<void> setDashboardCache(String key, DashboardCacheEntry entry) async {
    try {
      if (!Hive.isBoxOpen(dashboardBoxName)) {
        await Hive.openBox<DashboardCacheEntry>(dashboardBoxName);
      }
      final box = Hive.box<DashboardCacheEntry>(dashboardBoxName);
      await box.put(key, entry);
    } catch (e, st) {
      logError(error: e, stackTrace: st, source: 'Hive setDashboardCache');
      // Ignore cache write errors
    }
  }

  // Analytics cache
  Future<AnalyticsCacheEntry?> getAnalyticsCache(String key) async {
    try {
      if (!Hive.isBoxOpen(analyticsBoxName)) {
        await Hive.openBox<AnalyticsCacheEntry>(analyticsBoxName);
      }
      final box = Hive.box<AnalyticsCacheEntry>(analyticsBoxName);
      return box.get(key);
    } catch (e, st) {
      logError(error: e, stackTrace: st, source: 'Hive getAnalyticsCache');
      return null;
    }
  }

  Future<void> setAnalyticsCache(String key, AnalyticsCacheEntry entry) async {
    try {
      if (!Hive.isBoxOpen(analyticsBoxName)) {
        await Hive.openBox<AnalyticsCacheEntry>(analyticsBoxName);
      }
      final box = Hive.box<AnalyticsCacheEntry>(analyticsBoxName);
      await box.put(key, entry);
    } catch (e, st) {
      logError(error: e, stackTrace: st, source: 'Hive setAnalyticsCache');
      // Ignore cache write errors
    }
  }

  Future<void> clearAll() async {
    try {
      if (!Hive.isBoxOpen(dashboardBoxName)) {
        await Hive.openBox<DashboardCacheEntry>(dashboardBoxName);
      }
      if (!Hive.isBoxOpen(analyticsBoxName)) {
        await Hive.openBox<AnalyticsCacheEntry>(analyticsBoxName);
      }
      await Hive.box<DashboardCacheEntry>(dashboardBoxName).clear();
      await Hive.box<AnalyticsCacheEntry>(analyticsBoxName).clear();
    } catch (e, st) {
      logError(error: e, stackTrace: st, source: 'Hive clearAll');
    }
  }
}
