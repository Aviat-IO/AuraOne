import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/ai/ultra_fast_clustering.dart';
import '../services/ai/dbscan_clustering.dart';
import 'location_database_provider.dart';

/// Progressive clustering instance that updates in real-time
/// Optimized for flutter_background_geolocation's motion-based tracking
final progressiveClusteringProvider = StateProvider<ProgressiveClustering>((ref) {
  return ProgressiveClustering(
    mergeRadius: 100,  // 100 meters (increased for motion-detected points)
    stayDuration: const Duration(minutes: 2),  // Reduced from 5 min - motion tracking ensures significance
  );
});

/// Real-time clusters that update as new points arrive
final realtimeClusterProvider = FutureProvider<List<LocationCluster>>((ref) async {
  final progressive = ref.watch(progressiveClusteringProvider);

  // Watch for new location points directly
  final locations = await ref.watch(
    recentLocationPointsProvider(const Duration(hours: 24)).future,
  );

  if (locations.isEmpty) {
    return [];
  }

  // Get only today's locations
  // With flutter_background_geolocation, filter by isSignificant to get motion-detected points
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayLocations = locations
      .where((loc) =>
          loc.timestamp.isAfter(todayStart) &&
          loc.isSignificant  // Only include significant movement points from motion detection
      )
      .toList();

  if (todayLocations.isEmpty) {
    return [];
  }

  // Sort by timestamp
  todayLocations.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Process new points incrementally
  for (final dbPoint in todayLocations) {
    final clusterPoint = LocationPoint(
      id: dbPoint.id.toString(),
      latitude: dbPoint.latitude,
      longitude: dbPoint.longitude,
      timestamp: dbPoint.timestamp,
    );
    progressive.addPoint(clusterPoint);
  }

  // Return current clusters
  return progressive.getClusters();
});

/// Optimized cluster count for UI display
final clusterCountProvider = Provider<int>((ref) {
  final clustersAsync = ref.watch(realtimeClusterProvider);

  return clustersAsync.when(
    data: (clusters) => clusters.length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

/// Pre-compute cluster statistics for UI
final clusterStatsProvider = Provider<ClusterStatistics>((ref) {
  final clustersAsync = ref.watch(realtimeClusterProvider);

  return clustersAsync.when(
    data: (clusters) {
      if (clusters.isEmpty) {
        return ClusterStatistics.empty();
      }

      // Calculate stats
      final totalDuration = clusters.fold<Duration>(
        Duration.zero,
        (sum, cluster) => sum + cluster.duration,
      );

      final longestStay = clusters.reduce(
        (a, b) => a.duration > b.duration ? a : b,
      );

      final uniquePlaces = clusters.length;

      return ClusterStatistics(
        uniquePlaces: uniquePlaces,
        totalDuration: totalDuration,
        longestStay: longestStay,
        averageDuration: Duration(
          minutes: totalDuration.inMinutes ~/ uniquePlaces,
        ),
      );
    },
    loading: () => ClusterStatistics.empty(),
    error: (_, _) => ClusterStatistics.empty(),
  );
});

class ClusterStatistics {
  final int uniquePlaces;
  final Duration totalDuration;
  final LocationCluster? longestStay;
  final Duration averageDuration;

  ClusterStatistics({
    required this.uniquePlaces,
    required this.totalDuration,
    this.longestStay,
    required this.averageDuration,
  });

  factory ClusterStatistics.empty() => ClusterStatistics(
    uniquePlaces: 0,
    totalDuration: Duration.zero,
    averageDuration: Duration.zero,
  );
}