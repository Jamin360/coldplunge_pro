import 'package:hive/hive.dart';

part 'dashboard_cache_entry.g.dart';

@HiveType(typeId: 0)
class DashboardCacheEntry extends HiveObject {
  @HiveField(0)
  final Map<String, dynamic> data;

  @HiveField(1)
  final DateTime fetchedAt;

  DashboardCacheEntry({required this.data, required this.fetchedAt});
}
