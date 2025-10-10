import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../database/location_database.dart' as loc_db;
import '../services/ai/dbscan_clustering.dart';
import '../services/ai/ultra_fast_clustering.dart';
import '../services/ai/cluster_merger.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';
import '../utils/date_utils.dart';
import 'location_database_provider.dart';

/// Simple cache for clustering results
class _ClusteringCache {
  final Map<String, _CacheEntry> cache = {};
  static const Duration cacheExpiry = Duration(hours: 1);

  _CacheEntry? get(String key) {
    final entry = cache[key];
    if (entry != null && DateTime.now().difference(entry.timestamp) < cacheExpiry) {
      return entry;
    }
    cache.remove(key);
    return null;
  }

  void put(String key, List<LocationCluster> clusters, List<JourneySegment> journeys) {
    cache[key] = _CacheEntry(
      clusters: clusters,
      journeys: journeys,
      timestamp: DateTime.now(),
    );
  }

  void invalidate() {
    cache.clear();
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
      // Get UTC boundaries for the local day
      final (dayStart, dayEnd) = DateTimeUtils.getUtcDayBoundaries(date);
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
        error: (_, _) => Future.value(<loc_db.LocationPoint>[]),
      );

      // Filter locations for the specific date
      // Show all locations regardless of isSignificant flag to visualize complete location history
      // Filter out low-accuracy points (>50m accuracy) to improve map visualization quality
      final dayLocations = locationHistory
          .where((loc) =>
              loc.timestamp.isAfter(dayStart) &&
              loc.timestamp.isBefore(dayEnd) &&
              (loc.accuracy == null || loc.accuracy! <= 50.0)  // Only include points with good accuracy
          )
          .toList();

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

      // Use hybrid smart clustering for optimal performance
      // Automatically selects best algorithm based on data characteristics
      final result = await HybridClustering.smartCluster(
        clusteringPoints,
        eps: 150.0,  // Increased to 150 meters radius to capture more locations (was 100)
        minPts: 2,   // Reduced to 2 points to form a cluster (even more aggressive grouping)
      );

      // Since flutter_background_geolocation only returns locations when moving (50m+ filter),
      // we don't need aggressive time-based filtering. Most clusters represent actual movement/stops.
      // Keep duration threshold minimal to capture brief stops while filtering noise
      var significantClusters = result.clusters.where((cluster) {
        // Very minimal threshold - just filter out data anomalies
        // Motion-based tracking already ensures these are significant movements
        return cluster.duration.inSeconds >= 30; // 30 seconds minimum (reduced from 1 minute)
      }).toList();

      // Merge clusters that are at the same location
      // This prevents multiple entries for the same place
      significantClusters = ClusterMerger.smartMerge(
        significantClusters,
        locationRadius: 150, // 150 meters radius for same location (increased from 100)
        timeGap: const Duration(hours: 6), // Merge visits within 6 hours (increased from 4)
      );

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
      // Get UTC boundaries for the local day
      final (dayStart, dayEnd) = DateTimeUtils.getUtcDayBoundaries(date);
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
        error: (_, _) => Future.value(<loc_db.LocationPoint>[]),
      );

      // Filter locations for the specific date
      // Show all locations regardless of isSignificant flag to visualize complete location history
      // Filter out low-accuracy points (>50m accuracy) to improve map visualization quality
      final dayLocations = locationHistory
          .where((loc) =>
              loc.timestamp.isAfter(dayStart) &&
              loc.timestamp.isBefore(dayEnd) &&
              (loc.accuracy == null || loc.accuracy! <= 50.0)  // Only include points with good accuracy
          )
          .toList();

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
List<loc_db.LocationPoint> _removeSpeedOutliers(List<loc_db.LocationPoint> locations) {
  if (locations.length < 2) {
    return locations;
  }

  // Sort by timestamp to ensure chronological order
  final sorted = [...locations]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final filtered = <loc_db.LocationPoint>[sorted.first]; // Always keep first point

  // Maximum reasonable speed: 200 km/h (~125 mph) to account for highway driving
  const maxSpeedMetersPerSecond = 200 / 3.6; // Convert km/h to m/s (~55.5 m/s)

  for (int i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
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