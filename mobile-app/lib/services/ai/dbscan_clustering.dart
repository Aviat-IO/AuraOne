import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../utils/logger.dart';

/// Location point for clustering
class LocationPoint {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  int clusterId;
  bool visited;
  bool noise;

  LocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.clusterId = -1,
    this.visited = false,
    this.noise = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'clusterId': clusterId,
    'noise': noise,
  };
}

/// Cluster representing a significant location
class LocationCluster {
  final int id;
  final List<LocationPoint> points;
  final double centerLatitude;
  final double centerLongitude;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  LocationCluster({
    required this.id,
    required this.points,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.startTime,
    required this.endTime,
  }) : duration = endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
    'id': id,
    'centerLatitude': centerLatitude,
    'centerLongitude': centerLongitude,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'duration': duration.inMinutes,
    'pointCount': points.length,
  };
}

/// Data class for passing clustering parameters to isolate
class ClusteringParams {
  final List<LocationPoint> points;
  final double eps;
  final int minPts;

  ClusteringParams({
    required this.points,
    required this.eps,
    required this.minPts,
  });
}

/// Data class for returning clustering results from isolate
class ClusteringResult {
  final List<LocationCluster> clusters;
  final List<JourneySegment> journeys;

  ClusteringResult({
    required this.clusters,
    required this.journeys,
  });
}

/// DBSCAN (Density-Based Spatial Clustering of Applications with Noise) implementation
/// for identifying significant stay points from GPS coordinates
class DBSCANClustering {
  static final _logger = AppLogger('DBSCANClustering');

  final double eps; // Maximum distance between points in meters
  final int minPts; // Minimum points to form a cluster

  DBSCANClustering({
    this.eps = 50.0, // 50 meters default radius
    this.minPts = 3, // Minimum 3 points to form a cluster
  });

  /// Perform DBSCAN clustering on location points asynchronously
  Future<ClusteringResult> clusterAsync(List<LocationPoint> points) async {
    if (points.isEmpty) {
      return ClusteringResult(clusters: [], journeys: []);
    }

    final stopwatch = Stopwatch()..start();

    // Pre-filter points to reduce dataset size
    final filteredPoints = _preFilterPoints(points);
    final filterTime = stopwatch.elapsedMilliseconds;

    final reductionPercentage = points.isEmpty ? 0 : ((points.length - filteredPoints.length) / points.length * 100).round();

    _logger.info('Starting async DBSCAN clustering with ${filteredPoints.length} points '
        '(filtered from ${points.length}, $reductionPercentage% reduction in ${filterTime}ms)');

    final params = ClusteringParams(
      points: filteredPoints,
      eps: eps,
      minPts: minPts,
    );

    // Run clustering in a separate isolate to avoid blocking UI
    stopwatch.reset();
    final result = await compute(_clusterInIsolate, params);
    final clusteringTime = stopwatch.elapsedMilliseconds;

    stopwatch.stop();

    _logger.info('Async DBSCAN clustering completed in ${clusteringTime}ms: '
        '${result.clusters.length} clusters, ${result.journeys.length} journeys');

    // Validate performance
    if (clusteringTime > 1000) {
      _logger.warning('Clustering took longer than expected: ${clusteringTime}ms for ${filteredPoints.length} points');
    } else if (clusteringTime < 50) {
      _logger.info('Excellent clustering performance: ${clusteringTime}ms for ${filteredPoints.length} points');
    }

    return result;
  }

  /// Perform DBSCAN clustering on location points (synchronous, for backward compatibility)
  List<LocationCluster> cluster(List<LocationPoint> points) {
    if (points.isEmpty) {
      return [];
    }

    _logger.info('Starting DBSCAN clustering with ${points.length} points');

    // Build spatial index for large datasets
    final useSpatialIndex = points.length > 500;
    final spatialIndex = useSpatialIndex ? _buildSpatialIndex(points) : <String, List<LocationPoint>>{};

    int clusterId = 0;

    for (final point in points) {
      if (point.visited) {
        continue;
      }

      point.visited = true;

      final neighbors = useSpatialIndex
          ? _getNeighborsWithIndex(point, spatialIndex)
          : _getNeighbors(point, points);

      if (neighbors.length < minPts) {
        point.noise = true;
      } else {
        clusterId++;
        _expandCluster(point, neighbors, clusterId, points, spatialIndex, useSpatialIndex);
      }
    }

    // Build clusters from labeled points
    final clusters = _buildClusters(points, clusterId);

    _logger.info('Clustering complete: ${clusters.length} clusters found, '
        '${points.where((p) => p.noise).length} noise points');

    return clusters;
  }

  /// Pre-filter points to reduce dataset size for better performance
  List<LocationPoint> _preFilterPoints(List<LocationPoint> points) {
    if (points.length <= 500) {
      return points; // No need to filter small datasets
    }

    // For very large datasets, use aggressive sampling
    if (points.length > 2000) {
      return _aggressiveSampling(points);
    }

    // Sort points by timestamp
    final sortedPoints = List<LocationPoint>.from(points);
    sortedPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final filtered = <LocationPoint>[];
    LocationPoint? lastPoint;

    for (final point in sortedPoints) {
      if (lastPoint == null) {
        filtered.add(point);
        lastPoint = point;
        continue;
      }

      // Only keep points that are either:
      // 1. More than 30 seconds apart (temporal filtering)
      // 2. More than 10 meters apart (spatial filtering)
      final timeDiff = point.timestamp.difference(lastPoint.timestamp);
      final distance = _calculateDistance(lastPoint, point);

      if (timeDiff.inSeconds >= 30 || distance >= 10.0) {
        filtered.add(point);
        lastPoint = point;
      }
    }

    return filtered;
  }

  /// Aggressive sampling for very large datasets
  List<LocationPoint> _aggressiveSampling(List<LocationPoint> points) {
    // Sort by timestamp
    final sortedPoints = List<LocationPoint>.from(points);
    sortedPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final sampled = <LocationPoint>[];
    LocationPoint? lastPoint;

    for (final point in sortedPoints) {
      if (lastPoint == null) {
        sampled.add(point);
        lastPoint = point;
        continue;
      }

      // For large datasets, be more aggressive:
      // 1. At least 60 seconds apart (temporal)
      // 2. At least 25 meters apart (spatial)
      final timeDiff = point.timestamp.difference(lastPoint.timestamp);
      final distance = _calculateDistance(lastPoint, point);

      if (timeDiff.inSeconds >= 60 || distance >= 25.0) {
        sampled.add(point);
        lastPoint = point;
      }
    }

    _logger.info('Aggressive sampling reduced ${points.length} points to ${sampled.length} points');
    return sampled;
  }

  /// Build spatial index for efficient neighbor queries
  Map<String, List<LocationPoint>> _buildSpatialIndex(List<LocationPoint> points) {
    final index = <String, List<LocationPoint>>{};

    // Grid size in degrees (roughly 100m at equator)
    const gridSize = 0.001;

    for (final point in points) {
      final gridX = (point.latitude / gridSize).floor();
      final gridY = (point.longitude / gridSize).floor();
      final key = '$gridX,$gridY';

      index.putIfAbsent(key, () => []).add(point);
    }

    return index;
  }

  /// Get all neighbors within eps distance using spatial index
  List<LocationPoint> _getNeighborsWithIndex(
    LocationPoint point,
    Map<String, List<LocationPoint>> spatialIndex,
  ) {
    final neighbors = <LocationPoint>[];

    // Grid size in degrees
    const gridSize = 0.001;

    // Calculate grid cells to search (based on eps radius)
    // Convert eps (meters) to approximate degrees
    final searchRadius = eps / 111000.0; // Rough conversion
    final cellsToSearch = (searchRadius / gridSize).ceil();

    final centerGridX = (point.latitude / gridSize).floor();
    final centerGridY = (point.longitude / gridSize).floor();

    // Search neighboring cells
    for (int dx = -cellsToSearch; dx <= cellsToSearch; dx++) {
      for (int dy = -cellsToSearch; dy <= cellsToSearch; dy++) {
        final gridX = centerGridX + dx;
        final gridY = centerGridY + dy;
        final key = '$gridX,$gridY';

        final cellPoints = spatialIndex[key];
        if (cellPoints != null) {
          for (final other in cellPoints) {
            final distance = _calculateDistance(point, other);
            if (distance <= eps) {
              neighbors.add(other);
            }
          }
        }
      }
    }

    return neighbors;
  }

  /// Get all neighbors within eps distance (fallback for small datasets)
  List<LocationPoint> _getNeighbors(LocationPoint point, List<LocationPoint> allPoints) {
    final neighbors = <LocationPoint>[];

    for (final other in allPoints) {
      final distance = _calculateDistance(point, other);
      if (distance <= eps) {
        neighbors.add(other);
      }
    }

    return neighbors;
  }

  /// Expand cluster by adding density-reachable points
  void _expandCluster(
    LocationPoint point,
    List<LocationPoint> neighbors,
    int clusterId,
    List<LocationPoint> allPoints,
    Map<String, List<LocationPoint>> spatialIndex,
    bool useSpatialIndex,
  ) {
    point.clusterId = clusterId;

    int index = 0;
    while (index < neighbors.length) {
      final neighbor = neighbors[index];

      if (!neighbor.visited) {
        neighbor.visited = true;

        final neighborNeighbors = useSpatialIndex
            ? _getNeighborsWithIndex(neighbor, spatialIndex)
            : _getNeighbors(neighbor, allPoints);

        if (neighborNeighbors.length >= minPts) {
          // Add new neighbors to the list for processing
          for (final nn in neighborNeighbors) {
            if (!neighbors.contains(nn)) {
              neighbors.add(nn);
            }
          }
        }
      }

      if (neighbor.clusterId == -1) {
        neighbor.clusterId = clusterId;
        neighbor.noise = false;
      }

      index++;
    }
  }

  /// Calculate distance between two points in meters using fast Haversine formula
  static double _calculateDistance(LocationPoint p1, LocationPoint p2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final lat1Rad = p1.latitude * pi / 180;
    final lat2Rad = p2.latitude * pi / 180;
    final deltaLatRad = (p2.latitude - p1.latitude) * pi / 180;
    final deltaLngRad = (p2.longitude - p1.longitude) * pi / 180;

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Build cluster objects from labeled points
  List<LocationCluster> _buildClusters(List<LocationPoint> points, int maxClusterId) {
    final clusters = <LocationCluster>[];

    for (int id = 1; id <= maxClusterId; id++) {
      final clusterPoints = points.where((p) => p.clusterId == id).toList();

      if (clusterPoints.isEmpty) {
        continue;
      }

      // Calculate center of cluster
      double sumLat = 0.0;
      double sumLon = 0.0;
      DateTime earliestTime = clusterPoints.first.timestamp;
      DateTime latestTime = clusterPoints.first.timestamp;

      for (final point in clusterPoints) {
        sumLat += point.latitude;
        sumLon += point.longitude;

        if (point.timestamp.isBefore(earliestTime)) {
          earliestTime = point.timestamp;
        }
        if (point.timestamp.isAfter(latestTime)) {
          latestTime = point.timestamp;
        }
      }

      clusters.add(LocationCluster(
        id: id,
        points: clusterPoints,
        centerLatitude: sumLat / clusterPoints.length,
        centerLongitude: sumLon / clusterPoints.length,
        startTime: earliestTime,
        endTime: latestTime,
      ));
    }

    // Sort clusters by start time
    clusters.sort((a, b) => a.startTime.compareTo(b.startTime));

    return clusters;
  }

  /// Identify journey segments (noise points between clusters)
  List<JourneySegment> identifyJourneys(List<LocationPoint> points) {
    final journeys = <JourneySegment>[];
    final noisePoints = points.where((p) => p.noise).toList();

    if (noisePoints.isEmpty) {
      return journeys;
    }

    // Sort noise points by time
    noisePoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Group consecutive noise points into journey segments
    List<LocationPoint> currentJourney = [];
    DateTime? lastTime;

    for (final point in noisePoints) {
      if (lastTime == null ||
          point.timestamp.difference(lastTime).inMinutes <= 5) {
        currentJourney.add(point);
      } else {
        if (currentJourney.isNotEmpty) {
          journeys.add(JourneySegment(points: currentJourney));
        }
        currentJourney = [point];
      }
      lastTime = point.timestamp;
    }

    if (currentJourney.isNotEmpty) {
      journeys.add(JourneySegment(points: currentJourney));
    }

    return journeys;
  }
}

/// Represents a journey segment (movement between stay points)
class JourneySegment {
  final List<LocationPoint> points;
  final DateTime startTime;
  final DateTime endTime;
  final double totalDistance;

  JourneySegment({required this.points})
      : startTime = points.first.timestamp,
        endTime = points.last.timestamp,
        totalDistance = _calculateTotalDistance(points);

  static double _calculateTotalDistance(List<LocationPoint> points) {
    if (points.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += DBSCANClustering._calculateDistance(points[i - 1], points[i]);
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'duration': endTime.difference(startTime).inMinutes,
    'distance': totalDistance.round(),
    'pointCount': points.length,
  };
}

/// Static function for running clustering in an isolate
ClusteringResult _clusterInIsolate(ClusteringParams params) {
  final stopwatch = Stopwatch()..start();

  final clustering = DBSCANClustering(
    eps: params.eps,
    minPts: params.minPts,
  );

  // Perform the clustering
  final clusters = clustering.cluster(params.points);
  final journeyStopwatch = Stopwatch()..start();
  final journeys = clustering.identifyJourneys(params.points);
  final journeyTime = journeyStopwatch.elapsedMilliseconds;

  final totalTime = stopwatch.elapsedMilliseconds;

  // Log performance metrics from isolate (note: AppLogger may not work in isolate)
  if (kDebugMode) {
    print('Isolate clustering completed: ${totalTime}ms total (journeys: ${journeyTime}ms) for ${params.points.length} points');
  }

  return ClusteringResult(
    clusters: clusters,
    journeys: journeys,
  );
}
