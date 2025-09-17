import 'dart:math' as math;
import 'dbscan_clustering.dart';
import '../../utils/logger.dart';

/// Post-processor that merges clusters at the same location
class ClusterMerger {
  static final _logger = AppLogger('ClusterMerger');

  /// Merge clusters that are at the same location (within merge radius)
  static List<LocationCluster> mergeSameLocationClusters(
    List<LocationCluster> clusters, {
    double mergeRadius = 100, // meters
  }) {
    if (clusters.length <= 1) return clusters;

    // Sort clusters by start time
    clusters.sort((a, b) => a.startTime.compareTo(b.startTime));

    final merged = <LocationCluster>[];
    final processed = <bool>[];

    for (int i = 0; i < clusters.length; i++) {
      processed.add(false);
    }

    for (int i = 0; i < clusters.length; i++) {
      if (processed[i]) continue;

      final baseCluster = clusters[i];
      final pointsToMerge = <LocationPoint>[...baseCluster.points];
      DateTime earliestStart = baseCluster.startTime;
      DateTime latestEnd = baseCluster.endTime;

      processed[i] = true;

      // Find all clusters at the same location
      for (int j = i + 1; j < clusters.length; j++) {
        if (processed[j]) continue;

        final otherCluster = clusters[j];
        final distance = _calculateDistance(
          baseCluster.centerLatitude,
          baseCluster.centerLongitude,
          otherCluster.centerLatitude,
          otherCluster.centerLongitude,
        );

        // If clusters are at the same location, merge them
        if (distance <= mergeRadius) {
          pointsToMerge.addAll(otherCluster.points);
          processed[j] = true;

          if (otherCluster.startTime.isBefore(earliestStart)) {
            earliestStart = otherCluster.startTime;
          }
          if (otherCluster.endTime.isAfter(latestEnd)) {
            latestEnd = otherCluster.endTime;
          }
        }
      }

      // Create merged cluster
      if (pointsToMerge.isNotEmpty) {
        // Calculate new center
        double sumLat = 0, sumLon = 0;
        for (final point in pointsToMerge) {
          sumLat += point.latitude;
          sumLon += point.longitude;
        }

        merged.add(LocationCluster(
          id: merged.length + 1,
          points: pointsToMerge,
          centerLatitude: sumLat / pointsToMerge.length,
          centerLongitude: sumLon / pointsToMerge.length,
          startTime: earliestStart,
          endTime: latestEnd,
        ));
      }
    }

    _logger.info('Merged ${clusters.length} clusters into ${merged.length} unique locations');
    return merged;
  }

  /// Merge clusters by location and time proximity
  static List<LocationCluster> smartMerge(
    List<LocationCluster> clusters, {
    double locationRadius = 100, // meters
    Duration timeGap = const Duration(hours: 2), // max gap between visits
  }) {
    if (clusters.length <= 1) return clusters;

    // Group clusters by location
    final locationGroups = <String, List<LocationCluster>>{};

    for (final cluster in clusters) {
      // Create location key based on rounded coordinates
      final latKey = (cluster.centerLatitude * 1000).round() / 1000;
      final lonKey = (cluster.centerLongitude * 1000).round() / 1000;
      final key = '$latKey,$lonKey';

      locationGroups.putIfAbsent(key, () => []).add(cluster);
    }

    final merged = <LocationCluster>[];

    // Process each location group
    locationGroups.forEach((key, group) {
      if (group.length == 1) {
        merged.add(group.first);
        return;
      }

      // Sort by start time
      group.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Merge consecutive visits to same location
      final locationMerged = <LocationCluster>[];
      LocationCluster? current;

      for (final cluster in group) {
        if (current == null) {
          current = cluster;
        } else {
          // Check if this is a continuation of the same visit
          final gap = cluster.startTime.difference(current.endTime);

          if (gap <= timeGap) {
            // Merge with current cluster
            final allPoints = [...current.points, ...cluster.points];

            current = LocationCluster(
              id: current.id,
              points: allPoints,
              centerLatitude: (current.centerLatitude + cluster.centerLatitude) / 2,
              centerLongitude: (current.centerLongitude + cluster.centerLongitude) / 2,
              startTime: current.startTime,
              endTime: cluster.endTime,
            );
          } else {
            // Start new cluster
            locationMerged.add(current);
            current = cluster;
          }
        }
      }

      if (current != null) {
        locationMerged.add(current);
      }

      merged.addAll(locationMerged);
    });

    // Re-assign IDs
    for (int i = 0; i < merged.length; i++) {
      merged[i] = LocationCluster(
        id: i + 1,
        points: merged[i].points,
        centerLatitude: merged[i].centerLatitude,
        centerLongitude: merged[i].centerLongitude,
        startTime: merged[i].startTime,
        endTime: merged[i].endTime,
      );
    }

    _logger.info('Smart merged ${clusters.length} clusters into ${merged.length} unique visits');
    return merged;
  }

  static double _calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const metersPerDegree = 111000;
    final x = (lon2 - lon1) * metersPerDegree * math.cos(lat1 * math.pi / 180);
    final y = (lat2 - lat1) * metersPerDegree;
    return math.sqrt(x * x + y * y);
  }
}