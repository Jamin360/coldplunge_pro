import 'analytics_cache_entry.dart';
import 'persistent_cache_service.dart';
import '../core/log_error_helper.dart';

class AnalyticsRepository {
  final PersistentCacheService _persistentCacheService;
  final Duration staleDuration;

  // In-memory cache
  Map<String, dynamic>? _memoryCache;
  DateTime? _memoryCacheFetchedAt;

  // Request deduplication
  Future<Map<String, dynamic>>? _inflightRequest;

  AnalyticsRepository({
    required PersistentCacheService persistentCacheService,
    this.staleDuration = const Duration(minutes: 5), // 5 minutes for Analytics
  }) : _persistentCacheService = persistentCacheService;

  Future<Map<String, dynamic>> getAnalyticsData({
    required String key,
    required Future<Map<String, dynamic>> Function() fetcher,
    bool forceRefresh = false,
    String? debugSource,
  }) async {
    final now = DateTime.now();

    // 1. Check in-memory cache first (fastest)
    if (!forceRefresh &&
        _memoryCache != null &&
        _memoryCacheFetchedAt != null &&
        now.difference(_memoryCacheFetchedAt!) < staleDuration) {
      // Fresh in-memory cache - return immediately
      // Start background refresh if getting close to expiry (last 1 minute)
      if (now.difference(_memoryCacheFetchedAt!) >
          staleDuration - const Duration(minutes: 1)) {
        _refreshInBackground(key, fetcher);
      }
      return _memoryCache!;
    }

    // 2. Check persistent cache (local storage)
    if (!forceRefresh) {
      try {
        final cache = await _persistentCacheService.getAnalyticsCache(key);
        if (cache != null && now.difference(cache.fetchedAt) < staleDuration) {
          // Fresh persistent cache - update memory cache and return
          _memoryCache = cache.data;
          _memoryCacheFetchedAt = cache.fetchedAt;
          // Start background refresh if getting close to expiry
          if (now.difference(cache.fetchedAt) >
              staleDuration - const Duration(minutes: 1)) {
            _refreshInBackground(key, fetcher);
          }
          return cache.data;
        }
      } catch (e, st) {
        logError(
            error: e,
            stackTrace: st,
            source: debugSource ?? 'AnalyticsRepository.persistentCache');
      }
    }

    // 3. Need to fetch fresh data
    // Deduplicate requests - if already fetching, return same Future
    if (_inflightRequest != null && !forceRefresh) {
      return _inflightRequest!;
    }

    // Start new request
    _inflightRequest = _fetchAndCache(key, fetcher, debugSource);
    try {
      final result = await _inflightRequest!;
      return result;
    } finally {
      _inflightRequest = null;
    }
  }

  Future<Map<String, dynamic>> _fetchAndCache(
    String key,
    Future<Map<String, dynamic>> Function() fetcher,
    String? debugSource,
  ) async {
    try {
      final freshData = await fetcher();
      final now = DateTime.now();

      // Update in-memory cache
      _memoryCache = freshData;
      _memoryCacheFetchedAt = now;

      // Update persistent cache
      await _persistentCacheService.setAnalyticsCache(
        key,
        AnalyticsCacheEntry(data: freshData, fetchedAt: now),
      );

      return freshData;
    } catch (e, st) {
      logError(
          error: e,
          stackTrace: st,
          source: debugSource ?? 'AnalyticsRepository.fetch');
      rethrow;
    }
  }

  void _refreshInBackground(
    String key,
    Future<Map<String, dynamic>> Function() fetcher,
  ) {
    // Don't await - fire and forget
    _fetchAndCache(key, fetcher, 'AnalyticsRepository.backgroundRefresh')
        .catchError((error) {
      // Silent failure for background refresh
      print('Background refresh failed: $error');
    });
  }

  /// Clear all caches (useful for logout)
  void clearCache() {
    _memoryCache = null;
    _memoryCacheFetchedAt = null;
    _inflightRequest = null;
  }
}
