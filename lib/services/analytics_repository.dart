import 'package:hive/hive.dart';
import 'analytics_cache_entry.dart';
import 'persistent_cache_service.dart';
import '../core/log_error_helper.dart';

class AnalyticsRepository {
  final PersistentCacheService _persistentCacheService;
  final Duration staleDuration;

  AnalyticsRepository({
    required PersistentCacheService persistentCacheService,
    this.staleDuration = const Duration(minutes: 10),
  }) : _persistentCacheService = persistentCacheService;

  Future<Map<String, dynamic>> getAnalyticsData({
    required String key,
    required Future<Map<String, dynamic>> Function() fetcher,
    String? debugSource,
  }) async {
    try {
      final cache = await _persistentCacheService.getAnalyticsCache(key);
      final now = DateTime.now();
      if (cache != null && now.difference(cache.fetchedAt) < staleDuration) {
        // Fresh cache
        return cache.data;
      } else {
        // Stale or no cache: return stale if exists, but revalidate in background
        if (cache != null) {
          fetcher().then((freshData) {
            _persistentCacheService.setAnalyticsCache(
                key,
                AnalyticsCacheEntry(
                    data: freshData, fetchedAt: DateTime.now()));
          });
          return cache.data;
        }
      }
    } catch (e, st) {
      // Log cache error, fall back to Supabase
      logError(
          error: e,
          stackTrace: st,
          source: debugSource ?? 'AnalyticsRepository.cache');
    }
    // Always fall back to Supabase if cache fails or missing
    final freshData = await fetcher();
    await _persistentCacheService.setAnalyticsCache(
        key, AnalyticsCacheEntry(data: freshData, fetchedAt: DateTime.now()));
    return freshData;
  }
}
