import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../database/location_database.dart' as loc_db;
import '../services/ai/ultra_fast_clustering.dart';
import '../services/ai/dbscan_clustering.dart';
import '../utils/logger.dart';
import 'location_database_provider.dart';

final _logger = AppLogger('RealtimeClusteringProvider');

/// Progressive clustering instance that updates in real-time
final progressiveClusteringProvider = StateProvider<ProgressiveClustering>((ref) {
  return ProgressiveClustering(
    mergeRadius: 50,  // 50 meters
    stayDuration: const Duration(minutes: 5),
  );
});

/// Real-time clusters that update as new points arrive
final realtimeClusterProvider = StreamProvider<List<LocationCluster>>((ref) async* {
  final progressive = ref.watch(progressiveClusteringProvider);

  // Watch for new location points
  final locationStream = ref.watch(
    recentLocationPointsProvider(const Duration(hours: 24)).stream,
  );

  await for (final locations in locationStream) {
    if (locations.isEmpty) {
      yield [];
      continue;
    }

    // Get only today's locations
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayLocations = locations
        .where((loc) => loc.timestamp.isAfter(todayStart))
        .toList();

    if (todayLocations.isEmpty) {
      yield [];
      continue;
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

    // Yield current clusters
    yield progressive.getClusters();
  }
});

/// Optimized cluster count for UI display
final clusterCountProvider = Provider<int>((ref) {
  final clustersAsync = ref.watch(realtimeClusterProvider);

  return clustersAsync.when(
    data: (clusters) => clusters.length,
    loading: () => 0,
    error: (_, __) => 0,
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
    error: (_, __) => ClusterStatistics.empty(),
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