import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../database/location_database.dart' as loc_db;
import '../services/ai/dbscan_clustering.dart';
import '../services/ai/ultra_fast_clustering.dart';
import '../services/ai/cluster_merger.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';
import 'location_database_provider.dart';

/// Simple cache for clustering results with memory pressure monitoring
class _ClusteringCache {
  final Map<String, _CacheEntry> cache = {};
  static const Duration cacheExpiry = Duration(hours: 1);
  static const int maxCacheSize = 50; // Limit cache size to prevent memory issues

  _CacheEntry? get(String key) {
    final entry = cache[key];
    if (entry != null && DateTime.now().difference(entry.timestamp) < cacheExpiry) {
      return entry;
    }
    cache.remove(key);
    return null;
  }

  void put(String key, List<LocationCluster> clusters, List<JourneySegment> journeys) {
    // Check memory pressure and clean up if needed
    if (cache.length >= maxCacheSize) {
      _cleanupOldEntries();
    }

    cache[key] = _CacheEntry(
      clusters: clusters,
      journeys: journeys,
      timestamp: DateTime.now(),
    );
  }

  void invalidate() {
    cache.clear();
  }

  // Clean up oldest entries when cache is full
  void _cleanupOldEntries() {
    if (cache.isEmpty) return;

    // Sort by timestamp and remove oldest 25%
    final entries = cache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    final toRemove = (entries.length * 0.25).ceil();
    for (int i = 0; i < toRemove && i < entries.length; i++) {
      cache.remove(entries[i].key);
    }

    _logger.info('Cleaned up $toRemove old cache entries due to memory pressure');
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

// Provider for cache invalidation - optimized to prevent cache thrashing
final cacheInvalidationProvider = Provider<void>((ref) {
  // Debounce cache invalidation to prevent excessive clearing during rapid location updates
  // Use a timer to batch invalidations within a 30-second window
  Timer? invalidationTimer;

  ref.listen(recentLocationPointsProvider(const Duration(days: 7)), (previous, next) {
    if (previous != next && next.hasValue) {
      if (previous?.hasValue == true) {
        final prevCount = previous?.value?.length ?? 0;
        final nextCount = next.value?.length ?? 0;
        final percentChange = prevCount > 0 ? ((nextCount - prevCount).abs() / prevCount) : 1.0;

        // Only invalidate if significant change AND not already scheduled
        if ((percentChange > 0.1 || (nextCount - prevCount).abs() > 100) && invalidationTimer == null) {
          _logger.info('Scheduling cache invalidation for significant change ($prevCount -> $nextCount)');

          // Debounce invalidation by 30 seconds to allow batching of rapid updates
          invalidationTimer = Timer(const Duration(seconds: 30), () {
            _logger.info('Executing debounced cache invalidation');
            _clusteringCache.invalidate();
            invalidationTimer = null;
          });
        }
      } else {
        // Cancel any pending invalidation and invalidate immediately for initial load
        invalidationTimer?.cancel();
        invalidationTimer = null;
        _clusteringCache.invalidate();
      }
    }
  });

  // Cleanup timer on dispose
  ref.onDispose(() {
    invalidationTimer?.cancel();
  });
});

// Provider for clustered locations for a specific date with timeout protection
final clusteredLocationsProvider = FutureProvider.family<List<LocationCluster>, DateTime>(
  (ref, date) async {
    // Watch cache invalidation provider to ensure proper cleanup
    ref.watch(cacheInvalidationProvider);

    final timer = PerformanceTimer('clusteredLocationsProvider');

    try {
      final cacheKey = 'clusters_${date.year}-${date.month}-${date.day}';

      // Check cache first
      final cachedEntry = _clusteringCache.get(cacheKey);
      if (cachedEntry != null) {
        _logger.info('Using cached clustering result for $cacheKey');
        timer.stop();
        return cachedEntry.clusters;
      }

      // Load location data with timeout protection
      _logger.info('Loading location data for date $date');
      final locationHistory = await ref.read(locationPointsForDateProvider(date).future).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.warning('Location data loading timed out for $date');
          return <loc_db.LocationPoint>[];
        },
      );
      _logger.info('Loaded ${locationHistory.length} raw location points for date $date');

      // Filter out low-accuracy points (>100m accuracy) to improve map visualization quality
      // Relaxed from 30m to 100m to ensure we have data to display
      var dayLocations = locationHistory
          .where((loc) => (loc.accuracy == null || loc.accuracy! <= 100.0))
          .toList();

      // Sort by timestamp to ensure proper ordering
      dayLocations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Limit location points to 1000 most recent per day to prevent performance issues
      if (dayLocations.length > 1000) {
        dayLocations = dayLocations.take(1000).toList();
        _logger.info('Limited location points to 1000 most recent for performance');
      }

      _logger.info('Loaded ${locationHistory.length} points for clustering, filtered to ${dayLocations.length} for date ${date.year}-${date.month}-${date.day}');

      if (dayLocations.isEmpty) {
        timer.stop();
        return [];
      }

      // Early exit if too many points (performance protection)
      if (dayLocations.length > 2000) {
        _logger.warning('Too many location points (${dayLocations.length}) for date $date, using simplified clustering');
        // For very large datasets, use a simpler approach
        return await _fastClusterLargeDataset(dayLocations);
      }

      // Apply a chain of outlier filters to clean up GPS data with timeout protection
      var filteredLocations = dayLocations;

      // Run filters with individual timeouts to prevent hanging
      try {
        filteredLocations = await Future.microtask(() => _removeGeographicOutliers(filteredLocations))
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        _logger.warning('Geographic outlier filtering timed out or failed: $e');
      }

      try {
        filteredLocations = await Future.microtask(() => _removeSpeedOutliers(filteredLocations))
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        _logger.warning('Speed outlier filtering timed out or failed: $e');
      }

      try {
        filteredLocations = await Future.microtask(() => _removeConsecutiveDistanceOutliers(filteredLocations))
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        _logger.warning('Consecutive distance outlier filtering timed out or failed: $e');
      }

      if (filteredLocations.isEmpty) {
        timer.stop();
        return [];
      }

      // Convert database location points to clustering location points
      final clusteringPoints = filteredLocations.map((dbPoint) {
        return LocationPoint(
          id: dbPoint.id.toString(),
          latitude: dbPoint.latitude,
          longitude: dbPoint.longitude,
          timestamp: dbPoint.timestamp,
        );
      }).toList();

       // Use hybrid smart clustering with timeout protection and retry logic
       ClusteringResult result;
       try {
         result = await HybridClustering.smartCluster(
           clusteringPoints,
           eps: 150.0,
           minPts: 2,
         ).timeout(
           const Duration(seconds: 15),
           onTimeout: () {
             _logger.warning('Clustering algorithm timed out for $date');
             return ClusteringResult(clusters: [], journeys: []);
           },
         );
       } catch (e) {
         _logger.warning('Clustering failed, attempting fallback: $e');
         // Silent retry with simpler algorithm
         try {
           result = await Future.microtask(() => _simpleClusteringFallback(clusteringPoints))
               .timeout(const Duration(seconds: 5));
         } catch (fallbackError) {
           _logger.warning('Fallback clustering also failed: $fallbackError');
           result = ClusteringResult(clusters: [], journeys: []);
         }
       }

      // Filter significant clusters
      var significantClusters = result.clusters.where((cluster) {
        return cluster.duration.inSeconds >= 30;
      }).toList();

      // Merge clusters with timeout protection
      try {
        significantClusters = await Future.microtask(() => ClusterMerger.smartMerge(
          significantClusters,
          locationRadius: 150,
          timeGap: const Duration(hours: 6),
        )).timeout(const Duration(seconds: 3));
      } catch (e) {
        _logger.warning('Cluster merging timed out or failed: $e');
      }

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

// Simple clustering fallback for when complex algorithms fail
ClusteringResult _simpleClusteringFallback(List<LocationPoint> points) {
  if (points.isEmpty) {
    return ClusteringResult(clusters: [], journeys: []);
  }

  // Create a single cluster with all points for basic functionality
  final cluster = LocationCluster(
    id: 0, // Simple fallback cluster gets ID 0
    points: points,
    centerLatitude: points.first.latitude,
    centerLongitude: points.first.longitude,
    startTime: points.first.timestamp,
    endTime: points.last.timestamp,
  );

  return ClusteringResult(clusters: [cluster], journeys: []);
}

// Fast clustering for large datasets to prevent performance issues
Future<List<LocationCluster>> _fastClusterLargeDataset(List<loc_db.LocationPoint> locations) async {
  // For large datasets, create simple time-based clusters instead of full DBSCAN
  final clusters = <LocationCluster>[];

  if (locations.isEmpty) return clusters;

  // Sort by time
  final sortedLocations = List<loc_db.LocationPoint>.from(locations)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Group into 30-minute intervals
  const intervalMinutes = 30;
  final intervalDuration = Duration(minutes: intervalMinutes);

  List<loc_db.LocationPoint> currentGroup = [sortedLocations.first];

  for (int i = 1; i < sortedLocations.length; i++) {
    final current = sortedLocations[i];
    final lastInGroup = currentGroup.last;

    if (current.timestamp.difference(lastInGroup.timestamp) <= intervalDuration) {
      currentGroup.add(current);
    } else {
      // Create cluster from current group
      if (currentGroup.length >= 2) {
        final cluster = _createSimpleCluster(currentGroup);
        if (cluster != null) {
          clusters.add(cluster);
        }
      }
      currentGroup = [current];
    }
  }

  // Add final group
  if (currentGroup.length >= 2) {
    final cluster = _createSimpleCluster(currentGroup);
    if (cluster != null) {
      clusters.add(cluster);
    }
  }

  return clusters;
}

// Create a simple cluster from a group of location points
LocationCluster? _createSimpleCluster(List<loc_db.LocationPoint> points) {
  if (points.isEmpty) return null;

  // Calculate centroid
  double sumLat = 0, sumLng = 0;
  for (final point in points) {
    sumLat += point.latitude;
    sumLng += point.longitude;
  }

  final centerLat = sumLat / points.length;
  final centerLng = sumLng / points.length;

  // Convert to clustering points
  final clusteringPoints = points.map((dbPoint) {
    return LocationPoint(
      id: dbPoint.id.toString(),
      latitude: dbPoint.latitude,
      longitude: dbPoint.longitude,
      timestamp: dbPoint.timestamp,
    );
  }).toList();

  return LocationCluster(
    id: 0, // Simple cluster gets ID 0
    points: clusteringPoints,
    centerLatitude: centerLat,
    centerLongitude: centerLng,
    startTime: points.first.timestamp,
    endTime: points.last.timestamp,
  );
}

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
      final cacheKey = 'journeys_${date.year}-${date.month}-${date.day}';

      // Check cache first - use same cache as clusters since they're computed together
      final cachedEntry = _clusteringCache.get('clusters_${date.year}-${date.month}-${date.day}');
      if (cachedEntry != null) {
        _logger.info('Using cached journey result for $cacheKey');
        timer.stop();
        return cachedEntry.journeys;
      }

      // Load location data for this specific date only (24 hours in user's timezone)
      final locationHistory = await ref.read(locationPointsForDateProvider(date).future);

      // Filter out low-accuracy points (>100m accuracy) to improve map visualization quality
      // Relaxed from 30m to 100m to ensure we have data to display
      // Show all locations regardless of isSignificant flag to visualize complete location history
      final dayLocations = locationHistory
          .where((loc) => (loc.accuracy == null || loc.accuracy! <= 100.0))
          .toList();

      _logger.info('Loaded ${locationHistory.length} points for journeys, filtered to ${dayLocations.length} for date ${date.year}-${date.month}-${date.day}');

      if (dayLocations.isEmpty) {
        timer.stop();
        return [];
      }

      // Apply a chain of outlier filters to clean up GPS data
      // Each filter is independent and composable
      var filteredLocations = dayLocations;

      // Filter 1: Remove geographic outliers (far from median location)
      filteredLocations = _removeGeographicOutliers(filteredLocations);

      // Filter 2: Remove speed-based outliers (impossible travel speeds)
      filteredLocations = _removeSpeedOutliers(filteredLocations);

      // Filter 3: Remove consecutive distance outliers (sudden jumps in path)
      filteredLocations = _removeConsecutiveDistanceOutliers(filteredLocations);

      if (filteredLocations.isEmpty) {
        timer.stop();
        return [];
      }

      // Convert database location points to clustering location points
      final clusteringPoints = filteredLocations.map((dbPoint) {
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

/// Filter 1: Removes geographic outliers from location data using median-based distance filtering
/// This helps eliminate GPS glitches and bad data points that are far from the main activity area
List<loc_db.LocationPoint> _removeGeographicOutliers(List<loc_db.LocationPoint> locations) {
  if (locations.length < 3) {
    // Not enough data to determine outliers
    return locations;
  }

  // Calculate median latitude and longitude
  final sortedByLat = [...locations]..sort((a, b) => a.latitude.compareTo(b.latitude));
  final sortedByLng = [...locations]..sort((a, b) => a.longitude.compareTo(b.longitude));

  final medianLat = locations.length.isOdd
      ? sortedByLat[locations.length ~/ 2].latitude
      : (sortedByLat[locations.length ~/ 2 - 1].latitude + sortedByLat[locations.length ~/ 2].latitude) / 2;

  final medianLng = locations.length.isOdd
      ? sortedByLng[locations.length ~/ 2].longitude
      : (sortedByLng[locations.length ~/ 2 - 1].longitude + sortedByLng[locations.length ~/ 2].longitude) / 2;

  // Calculate distances from median point
  final distances = locations.map((loc) {
    final latDiff = (loc.latitude - medianLat) * 111320; // Convert to meters (approx)
    final lngDiff = (loc.longitude - medianLng) * 111320 * (0.9962951347331251); // Adjust for latitude
    return (latDiff * latDiff + lngDiff * lngDiff).abs().toDouble(); // Squared distance
  }).toList();

  // Calculate median absolute deviation (MAD) - robust to outliers
  final sortedDistances = [...distances]..sort();
  final medianDistance = sortedDistances[sortedDistances.length ~/ 2];

  // Calculate MAD
  final deviations = distances.map((d) => (d - medianDistance).abs()).toList()..sort();
  final mad = deviations[deviations.length ~/ 2];

  // Filter outliers: remove points that are more than 3 MAD from median
  // Typical threshold is 2-3 MAD; we use 3 to be conservative
  // This roughly corresponds to removing points more than ~50km away from median in typical cases
  final threshold = medianDistance + (3 * mad);

  final filtered = <loc_db.LocationPoint>[];
  for (int i = 0; i < locations.length; i++) {
    if (distances[i] <= threshold) {
      filtered.add(locations[i]);
    } else {
      _logger.info('Filtered outlier at ${locations[i].latitude}, ${locations[i].longitude} (distance from median: ${distances[i].toStringAsFixed(0)}m)');
    }
  }

  return filtered;
}

/// Filter 2: Removes points that require impossible speeds to reach from the previous point
/// This catches GPS glitches that create sudden "jumps" in location
/// Maximum reasonable driving speed: 140 km/h (~87 mph) to account for highway driving
/// This is more realistic than 200 km/h and filters more aggressive outliers
List<loc_db.LocationPoint> _removeSpeedOutliers(List<loc_db.LocationPoint> locations) {
  if (locations.length < 2) {
    return locations;
  }

  // Sort by timestamp to ensure chronological order
  final sorted = [...locations]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final filtered = <loc_db.LocationPoint>[sorted.first]; // Always keep first point

  // Maximum reasonable speed: 140 km/h (~87 mph) for highway driving
  // Reduced from 200 km/h to be more realistic
  const maxSpeedMetersPerSecond = 140 / 3.6; // Convert km/h to m/s (~38.9 m/s)

  for (int i = 1; i < sorted.length; i++) {
    final prev = filtered.last; // Compare against last filtered point, not previous raw point
    final curr = sorted[i];

    // Calculate distance between points (Haversine formula for accuracy)
    final latDiff = (curr.latitude - prev.latitude) * 111320; // meters
    final lngDiff = (curr.longitude - prev.longitude) * 111320 * (0.9962951347331251); // meters, adjusted for latitude
    final distance = (latDiff * latDiff + lngDiff * lngDiff).abs() / 1000; // sqrt approximation

    // Calculate time difference in seconds
    final timeDiff = curr.timestamp.difference(prev.timestamp).inSeconds;

    if (timeDiff > 0) {
      final speed = distance / timeDiff; // meters per second

      if (speed <= maxSpeedMetersPerSecond) {
        filtered.add(curr);
      } else {
        _logger.info('Filtered speed outlier: ${speed.toStringAsFixed(1)} m/s (${(speed * 3.6).toStringAsFixed(1)} km/h) between ${prev.timestamp} and ${curr.timestamp}');
      }
    } else {
      // Same timestamp - keep it
      filtered.add(curr);
    }
  }

  return filtered;
}

/// Filter 3: Removes points with abnormal consecutive distances using MAD-based detection
/// This catches GPS glitches that create sudden jumps inconsistent with the activity type
List<loc_db.LocationPoint> _removeConsecutiveDistanceOutliers(List<loc_db.LocationPoint> locations) {
  if (locations.length < 4) {
    // Need at least 4 points to calculate meaningful statistics
    return locations;
  }

  // Sort by timestamp to ensure chronological order
  final sorted = [...locations]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Calculate distances between consecutive points
  final distances = <double>[];
  final activityTypes = <String?>[];

  for (int i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final curr = sorted[i];

    // Calculate distance using Haversine approximation
    final latDiff = (curr.latitude - prev.latitude) * 111320; // meters
    final lngDiff = (curr.longitude - prev.longitude) * 111320 * (0.9962951347331251); // meters
    final distance = (latDiff * latDiff + lngDiff * lngDiff).abs() / 1000; // sqrt approximation in meters

    distances.add(distance);
    activityTypes.add(curr.activityType ?? prev.activityType);
  }

  // Calculate median distance
  final sortedDistances = [...distances]..sort();
  final medianDistance = sortedDistances[sortedDistances.length ~/ 2];

  // Calculate MAD (Median Absolute Deviation)
  final deviations = distances.map((d) => (d - medianDistance).abs()).toList()..sort();
  final mad = deviations[deviations.length ~/ 2];

  // Determine activity-based threshold multiplier
  // Use the most common activity type in the dataset
  final activityCounts = <String, int>{};
  for (final activity in activityTypes.where((a) => a != null)) {
    activityCounts[activity!] = (activityCounts[activity] ?? 0) + 1;
  }

  final dominantActivity = activityCounts.isEmpty
      ? null
      : activityCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  // Activity-specific expected maximum distances (meters between consecutive points)
  // Very aggressive thresholds to filter GPS glitches
  final activityThresholds = {
    'still': 3.0,       // Still/stationary: minimal movement
    'walking': 20.0,    // Walking: ~1.5 m/s * 13s = 20m
    'running': 60.0,    // Running: ~4 m/s * 15s = 60m
    'on_bicycle': 120.0, // Cycling: ~8 m/s * 15s = 120m
    'in_vehicle': 300.0, // Driving: ~20 m/s * 15s = 300m
  };

  final defaultThreshold = 150.0; // Default for unknown activities (very conservative)
  final maxExpectedDistance = dominantActivity != null
      ? (activityThresholds[dominantActivity] ?? defaultThreshold)
      : defaultThreshold;

  // Filter using 1.5 MAD threshold (very aggressive) OR activity-specific threshold
  // Use whichever is more restrictive (smaller)
  final madThreshold = medianDistance + (1.5 * mad);
  final finalThreshold = madThreshold < maxExpectedDistance ? madThreshold : maxExpectedDistance;

  final filtered = <loc_db.LocationPoint>[sorted.first]; // Always keep first point

  for (int i = 1; i < sorted.length; i++) {
    final distance = distances[i - 1];

    if (distance <= finalThreshold) {
      filtered.add(sorted[i]);
    } else {
      _logger.info('Filtered consecutive distance outlier: ${distance.toStringAsFixed(1)}m (threshold: ${finalThreshold.toStringAsFixed(1)}m, activity: ${activityTypes[i - 1] ?? "unknown"})');
    }
  }

  return filtered;
}