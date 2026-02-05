import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dashboard_cache_entry.dart';
import 'analytics_cache_entry.dart';

class CacheInitializer {
  static Future<void> initHive() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    Hive.registerAdapter(DashboardCacheEntryAdapter());
    Hive.registerAdapter(AnalyticsCacheEntryAdapter());
  }
}
