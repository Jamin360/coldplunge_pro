import 'dart:async';

/// Simple cache with TTL (Time To Live) support
class CachedData<T> {
  final T data;
  final DateTime expiresAt;

  CachedData(this.data, Duration ttl) : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Data cache service to reduce redundant API calls
class DataCacheService {
  static final DataCacheService _instance = DataCacheService._();
  static DataCacheService get instance => _instance;

  DataCacheService._();

  final Map<String, CachedData> _cache = {};

  /// Get cached data if available and not expired
  T? get<T>(String key) {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      return cached.data as T;
    }
    // Remove expired cache
    if (cached != null) {
      _cache.remove(key);
    }
    return null;
  }

  /// Store data in cache with TTL
  void set<T>(String key, T data, Duration ttl) {
    _cache[key] = CachedData<T>(data, ttl);
  }

  /// Check if cache has valid (non-expired) data
  bool has(String key) {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      return true;
    }
    if (cached != null) {
      _cache.remove(key);
    }
    return false;
  }

  /// Clear specific cache key
  void clear(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clearAll() {
    _cache.clear();
  }

  /// Clear expired cache entries
  void clearExpired() {
    _cache.removeWhere((key, value) => value.isExpired);
  }
}
