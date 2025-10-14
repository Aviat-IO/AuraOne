import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/ai/dbscan_clustering.dart';

/// Cache for expensive computations
class MemoizedClusteringCache {
  final Map<String, dynamic> _cache = {};

  T? get<T>(String key) => _cache[key] as T?;

  void set<T>(String key, T value) {
    _cache[key] = value;
  }

  void clear() {
    _cache.clear();
  }

  void remove(String key) {
    _cache.remove(key);
  }
}

final memoizationCacheProvider = Provider<MemoizedClusteringCache>((ref) {
  return MemoizedClusteringCache();
});

/// Memoized cluster count provider
final memoizedClusterCountProvider = Provider.family<int, List<LocationCluster>>((ref, clusters) {
  final cache = ref.watch(memoizationCacheProvider);
  final key = 'count_${clusters.hashCode}';

  final cached = cache.get<int>(key);
  if (cached != null) {
    return cached;
  }

  final count = clusters.length;
  cache.set(key, count);
  return count;
});

/// Memoized total duration provider
final memoizedTotalDurationProvider = Provider.family<Duration, List<LocationCluster>>((ref, clusters) {
  final cache = ref.watch(memoizationCacheProvider);
  final key = 'duration_${clusters.hashCode}';

  final cached = cache.get<Duration>(key);
  if (cached != null) {
    return cached;
  }

  final duration = clusters.fold(
    Duration.zero,
    (total, cluster) => total + cluster.duration,
  );

  cache.set(key, duration);
  return duration;
});

/// Memoized cluster sorting provider
final memoizedSortedClustersProvider = Provider.family<List<LocationCluster>, List<LocationCluster>>((ref, clusters) {
  final cache = ref.watch(memoizationCacheProvider);
  final key = 'sorted_${clusters.hashCode}';

  final cached = cache.get<List<LocationCluster>>(key);
  if (cached != null) {
    return cached;
  }

  final sorted = List<LocationCluster>.from(clusters)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  cache.set(key, sorted);
  return sorted;
});

/// Memoized significant clusters provider (duration > 3 minutes)
final memoizedSignificantClustersProvider = Provider.family<List<LocationCluster>, List<LocationCluster>>((ref, clusters) {
  final cache = ref.watch(memoizationCacheProvider);
  final key = 'significant_${clusters.hashCode}';

  final cached = cache.get<List<LocationCluster>>(key);
  if (cached != null) {
    return cached;
  }

  final significant = clusters
      .where((cluster) => cluster.duration.inMinutes >= 3)
      .toList();

  cache.set(key, significant);
  return significant;
});