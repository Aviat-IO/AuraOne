import 'dart:math';
import 'package:geolocator/geolocator.dart';
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

  /// Perform DBSCAN clustering on location points
  List<LocationCluster> cluster(List<LocationPoint> points) {
    if (points.isEmpty) {
      return [];
    }

    _logger.info('Starting DBSCAN clustering with ${points.length} points');

    int clusterId = 0;

    for (final point in points) {
      if (point.visited) {
        continue;
      }

      point.visited = true;

      final neighbors = _getNeighbors(point, points);

      if (neighbors.length < minPts) {
        point.noise = true;
      } else {
        clusterId++;
        _expandCluster(point, neighbors, clusterId, points);
      }
    }

    // Build clusters from labeled points
    final clusters = _buildClusters(points, clusterId);

    _logger.info('Clustering complete: ${clusters.length} clusters found, '
        '${points.where((p) => p.noise).length} noise points');

    return clusters;
  }

  /// Get all neighbors within eps distance
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
  ) {
    point.clusterId = clusterId;

    int index = 0;
    while (index < neighbors.length) {
      final neighbor = neighbors[index];

      if (!neighbor.visited) {
        neighbor.visited = true;

        final neighborNeighbors = _getNeighbors(neighbor, allPoints);

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

  /// Calculate distance between two points in meters
  double _calculateDistance(LocationPoint p1, LocationPoint p2) {
    return Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );
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

  JourneySegment({required List<LocationPoint> points})
      : points = points,
        startTime = points.first.timestamp,
        endTime = points.last.timestamp,
        totalDistance = _calculateTotalDistance(points);

  static double _calculateTotalDistance(List<LocationPoint> points) {
    if (points.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += Geolocator.distanceBetween(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
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
