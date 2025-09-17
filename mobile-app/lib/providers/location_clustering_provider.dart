import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../database/location_database.dart' as loc_db;
import '../services/ai/dbscan_clustering.dart';
import '../services/ai/ultra_fast_clustering.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';
import 'location_database_provider.dart';

/// Simple cache for clustering results
class _ClusteringCache {
  final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheExpiry = Duration(hours: 1);

  _CacheEntry? get(String key) {
    final entry = _cache[key];
    if (entry != null && DateTime.now().difference(entry.timestamp) < _cacheExpiry) {
      return entry;
    }
    _cache.remove(key);
    return null;
  }

  void put(String key, List<LocationCluster> clusters, List<JourneySegment> journeys) {
    _cache[key] = _CacheEntry(
      clusters: clusters,
      journeys: journeys,
      timestamp: DateTime.now(),
    );
  }

  void invalidate() {
    _cache.clear();
  }
}

class _CacheEntry {
  final List<LocationCluster> clusters;
  final List<JourneySegment> journeys;
  final DateTime timestamp;

  _CacheEntry({
    required this.clusters,
    required this.journeys,
    required this.timestamp,
  });
}

final _clusteringCache = _ClusteringCache();
final _logger = AppLogger('LocationClusteringProvider');

// Provider for cache invalidation - invalidates cache when new location data arrives
// Using manual invalidation to prevent excessive cache clearing
final cacheInvalidationProvider = Provider<void>((ref) {
  // Only invalidate cache on significant changes, not every update
  // This prevents cache thrashing during continuous location updates
  ref.listen(recentLocationPointsProvider(const Duration(days: 7)), (previous, next) {
    if (previous != next && next.hasValue) {
      if (previous?.hasValue == true) {
        // Only invalidate if there's a significant change in data count
        final prevCount = previous?.value?.length ?? 0;
        final nextCount = next.value?.length ?? 0;
        final percentChange = prevCount > 0 ? ((nextCount - prevCount).abs() / prevCount) : 1.0;

        // Invalidate only if more than 10% change or more than 100 new points
        if (percentChange > 0.1 || (nextCount - prevCount).abs() > 100) {
          _logger.info('Significant location data change detected ($prevCount -> $nextCount), invalidating cache');
          _clusteringCache.invalidate();
        }
      } else {
        // Initial data load - invalidate to ensure fresh start
        _clusteringCache.invalidate();
      }
    }
  });
});

// Provider for clustered locations for a specific date
final clusteredLocationsProvider = FutureProvider.family<List<LocationCluster>, DateTime>(
  (ref, date) async {
    // Watch cache invalidation provider to ensure proper cleanup
    ref.watch(cacheInvalidationProvider);

    final timer = PerformanceTimer('clusteredLocationsProvider');

    try {
      // Get the location points for the date from the database
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final cacheKey = 'clusters_${date.year}-${date.month}-${date.day}';

      // Check cache first
      final cachedEntry = _clusteringCache.get(cacheKey);
      if (cachedEntry != null) {
        _logger.info('Using cached clustering result for $cacheKey');
        timer.stop();
        return cachedEntry.clusters;
      }

      // Watch the location points stream and get the data
      final locationStream = ref.watch(recentLocationPointsProvider(const Duration(days: 7)));

      final locationHistory = await locationStream.when(
        data: (locations) => Future.value(locations),
        loading: () => Future.value(<loc_db.LocationPoint>[]),
        error: (_, __) => Future.value(<loc_db.LocationPoint>[]),
      );

      // Filter locations for the specific date
      final dayLocations = locationHistory
          .where((loc) => loc.timestamp.isAfter(dayStart) && loc.timestamp.isBefore(dayEnd))
          .toList();

      if (dayLocations.isEmpty) {
        timer.stop();
        return [];
      }

      // Convert database location points to clustering location points
      final clusteringPoints = dayLocations.map((dbPoint) {
        return LocationPoint(
          id: dbPoint.id.toString(),
          latitude: dbPoint.latitude,
          longitude: dbPoint.longitude,
          timestamp: dbPoint.timestamp,
        );
      }).toList();

      // Use hybrid smart clustering for optimal performance
      // Automatically selects best algorithm based on data characteristics
      final result = await HybridClustering.smartCluster(
        clusteringPoints,
        eps: 50.0,  // 50 meters radius
        minPts: 8,   // Minimum 8 points to form a cluster
      );

      // Filter clusters to only include those with significant duration
      // This filters out places you just drove through slowly
      final significantClusters = result.clusters.where((cluster) {
        // Only count as a visited place if you stayed for at least 3 minutes
        return cluster.duration.inMinutes >= 3;
      }).toList();

      // Cache the result
      _clusteringCache.put(cacheKey, significantClusters, result.journeys);

      timer.stop();
      return significantClusters;
    } catch (e) {
      timer.stop();
      _logger.warning('Error in clustering: $e');
      return [];
    }
  },
);

// Provider for the count of unique locations visited on a date
final uniqueLocationsCountProvider = FutureProvider.family<int, DateTime>(
  (ref, date) async {
    final clusters = await ref.watch(clusteredLocationsProvider(date).future);
    return clusters.length;
  },
);

// Provider for journey segments (movement between locations) on a date
final journeySegmentsProvider = FutureProvider.family<List<JourneySegment>, DateTime>(
  (ref, date) async {
    // Watch cache invalidation provider to ensure proper cleanup
    ref.watch(cacheInvalidationProvider);

    final timer = PerformanceTimer('journeySegmentsProvider');

    try {
      // Get the location points for the date from the database
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final cacheKey = 'journeys_${date.year}-${date.month}-${date.day}';

      // Check cache first - use same cache as clusters since they're computed together
      final cachedEntry = _clusteringCache.get('clusters_${date.year}-${date.month}-${date.day}');
      if (cachedEntry != null) {
        _logger.info('Using cached journey result for $cacheKey');
        timer.stop();
        return cachedEntry.journeys;
      }

      // Watch the location points stream and get the data
      final locationStream = ref.watch(recentLocationPointsProvider(const Duration(days: 7)));

      final locationHistory = await locationStream.when(
        data: (locations) => Future.value(locations),
        loading: () => Future.value(<loc_db.LocationPoint>[]),
        error: (_, __) => Future.value(<loc_db.LocationPoint>[]),
      );

      // Filter locations for the specific date
      final dayLocations = locationHistory
          .where((loc) => loc.timestamp.isAfter(dayStart) && loc.timestamp.isBefore(dayEnd))
          .toList();

      if (dayLocations.isEmpty) {
        timer.stop();
        return [];
      }

      // Convert database location points to clustering location points
      final clusteringPoints = dayLocations.map((dbPoint) {
        return LocationPoint(
          id: dbPoint.id.toString(),
          latitude: dbPoint.latitude,
          longitude: dbPoint.longitude,
          timestamp: dbPoint.timestamp,
        );
      }).toList();

      // Perform DBSCAN clustering asynchronously to identify noise points (journey points)
      final dbscan = DBSCANClustering(
        eps: 50.0,  // 50 meters radius
        minPts: 8,   // Minimum 8 points to form a cluster (matches clusteredLocationsProvider)
      );

      final result = await dbscan.clusterAsync(clusteringPoints);

      // Cache the result (both clusters and journeys)
      _clusteringCache.put('clusters_${date.year}-${date.month}-${date.day}', result.clusters, result.journeys);

      timer.stop();
      return result.journeys;
    } catch (e) {
      timer.stop();
      _logger.warning('Error in journey segmentation: $e');
      return [];
    }
  },
);