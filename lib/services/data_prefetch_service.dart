import '../services/analytics_repository.dart';
import '../services/auth_service.dart';
import '../services/dashboard_repository.dart';
import '../services/persistent_cache_service.dart';
import '../services/session_service.dart';

/// Service to prefetch data in the background after authentication
/// This ensures instant display when users navigate to Home or Analytics tabs
class DataPrefetchService {
  static final DataPrefetchService instance = DataPrefetchService._internal();
  DataPrefetchService._internal();

  bool _isPrefetching = false;
  bool _hasPrefetched = false;

  /// Prefetch dashboard and analytics data after successful authentication
  /// This runs in the background without blocking the UI
  Future<void> prefetchAppData() async {
    // Prevent duplicate prefetch calls
    if (_isPrefetching || _hasPrefetched) return;

    // Only prefetch if user is authenticated
    if (!AuthService.instance.isAuthenticated) return;

    _isPrefetching = true;

    try {
      print('🚀 Starting data prefetch...');

      // Initialize repositories
      final persistentCache = PersistentCacheService();
      final dashboardRepo =
          DashboardRepository(persistentCacheService: persistentCache);
      final analyticsRepo =
          AnalyticsRepository(persistentCacheService: persistentCache);

      // Prefetch dashboard data (Home tab)
      // Don't await - let it run in background
      dashboardRepo
          .getDashboardData(
        key: 'main',
        forceRefresh: false, // Use cache if available
        fetcher: () async {
          final results = await Future.wait([
            SessionService.instance.getRecentSessions(),
            SessionService.instance.getWeeklyProgress(),
            AuthService.instance.getUserStats(),
            AuthService.instance.hasSessionToday(),
          ]);
          return {
            'recentSessions': results[0],
            'weeklyData': results[1],
            'userStats': results[2],
            'hasPlungedToday': results[3],
          };
        },
      )
          .then((_) {
        print('✅ Dashboard data prefetched');
      }).catchError((error) {
        print('⚠️ Dashboard prefetch failed (non-critical): $error');
      });

      // Optionally prefetch analytics data (less critical)
      // Uncomment if you want to prefetch analytics too
      // analyticsRepo
      //     .getAnalyticsData(
      //   key: 'main',
      //   forceRefresh: false,
      //   fetcher: () async {
      //     // Add analytics fetcher logic here
      //     return {};
      //   },
      // )
      //     .then((_) {
      //   print('✅ Analytics data prefetched');
      // }).catchError((error) {
      //   print('⚠️ Analytics prefetch failed (non-critical): $error');
      // });

      _hasPrefetched = true;
      print('🎉 Data prefetch completed');
    } catch (error) {
      print('⚠️ Prefetch error (non-critical): $error');
    } finally {
      _isPrefetching = false;
    }
  }

  /// Reset prefetch state (call on logout)
  void reset() {
    _hasPrefetched = false;
    _isPrefetching = false;
  }
}
