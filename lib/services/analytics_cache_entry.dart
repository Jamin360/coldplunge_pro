import 'package:hive/hive.dart';

part 'analytics_cache_entry.g.dart';

@HiveType(typeId: 1)
class AnalyticsCacheEntry extends HiveObject {
  @HiveField(0)
  final Map<String, dynamic> data;

  @HiveField(1)
  final DateTime fetchedAt;

  AnalyticsCacheEntry({required this.data, required this.fetchedAt});
}
