import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../utils/logger.dart';
import 'dbscan_clustering.dart';

/// Ultra-fast clustering engine with aggressive optimizations
class UltraFastClustering {
  static final _logger = AppLogger('UltraFastClustering');

  /// Time-based clustering - group by time windows instead of spatial distance
  /// This is MUCH faster and often more meaningful for daily activity
  static List<LocationCluster> timeBasedClustering(
    List<LocationPoint> points, {
    Duration stayDuration = const Duration(minutes: 5),
    double mergeRadius = 100, // meters
  }) {
    if (points.isEmpty) return [];

    // Sort by time once
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final clusters = <LocationCluster>[];
    final currentCluster = <LocationPoint>[];
    LocationPoint? lastPoint;

    for (final point in points) {
      if (lastPoint == null) {
        currentCluster.add(point);
      } else {
        final timeDiff = point.timestamp.difference(lastPoint.timestamp);
        final distance = _fastDistance(lastPoint, point);

        // Start new cluster if moved significantly or big time gap
        if (timeDiff > stayDuration || distance > mergeRadius) {
          if (currentCluster.length >= 3) { // Minimum points for a stay
            clusters.add(_buildCluster(currentCluster, clusters.length + 1));
          }
          currentCluster.clear();
        }
        currentCluster.add(point);
      }
      lastPoint = point;
    }

    // Add final cluster
    if (currentCluster.length >= 3) {
      clusters.add(_buildCluster(currentCluster, clusters.length + 1));
    }

    return clusters;
  }

  /// Grid-based approximate clustering - trade accuracy for speed
  /// Uses fixed grid cells for O(n) complexity
  static List<LocationCluster> gridClustering(
    List<LocationPoint> points, {
    double cellSize = 0.001, // ~100m at equator
    int minPoints = 5,
  }) {
    if (points.isEmpty) return [];

    // Group points into grid cells
    final grid = <String, List<LocationPoint>>{};

    for (final point in points) {
      final cellX = (point.latitude / cellSize).floor();
      final cellY = (point.longitude / cellSize).floor();
      final key = '$cellX,$cellY';

      grid.putIfAbsent(key, () => []).add(point);
    }

    // Convert cells with enough points to clusters
    final clusters = <LocationCluster>[];
    var clusterId = 1;

    grid.forEach((key, cellPoints) {
      if (cellPoints.length >= minPoints) {
        // Check temporal continuity
        cellPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Split by time gaps
        final subClusters = _splitByTimeGaps(cellPoints);

        for (final subCluster in subClusters) {
          if (subCluster.length >= minPoints) {
            clusters.add(_buildCluster(subCluster, clusterId++));
          }
        }
      }
    });

    return clusters;
  }

  /// Hierarchical decimation - progressively reduce points
  static List<LocationPoint> decimatePoints(
    List<LocationPoint> points, {
    int targetCount = 500,
    double minDistance = 10, // meters
    Duration minTime = const Duration(seconds: 30),
  }) {
    if (points.length <= targetCount) return points;

    // Calculate decimation factor
    final factor = points.length ~/ targetCount;
    if (factor <= 1) return points;

    final decimated = <LocationPoint>[];
    LocationPoint? lastKept;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Always keep first and last
      if (i == 0 || i == points.length - 1) {
        decimated.add(point);
        lastKept = point;
        continue;
      }

      // Keep every Nth point, or if significant change
      if (i % factor == 0 || lastKept == null) {
        decimated.add(point);
        lastKept = point;
      } else {
        final timeDiff = point.timestamp.difference(lastKept.timestamp);
        final distance = _fastDistance(lastKept, point);

        if (timeDiff >= minTime || distance >= minDistance) {
          decimated.add(point);
          lastKept = point;
        }
      }
    }

    return decimated;
  }

  /// SIMD-optimized distance calculation using Float32List
  static double _fastDistance(LocationPoint p1, LocationPoint p2) {
    // Use approximation for small distances (good enough for clustering)
    final latDiff = p1.latitude - p2.latitude;
    final lngDiff = p1.longitude - p2.longitude;

    // Equirectangular approximation (faster than Haversine)
    const metersPerDegree = 111000;
    final x = lngDiff * metersPerDegree * math.cos(p1.latitude * math.pi / 180);
    final y = latDiff * metersPerDegree;

    return math.sqrt(x * x + y * y);
  }

  static LocationCluster _buildCluster(List<LocationPoint> points, int id) {
    // Use centroid for speed
    double sumLat = 0, sumLon = 0;
    DateTime? earliest, latest;

    for (final p in points) {
      sumLat += p.latitude;
      sumLon += p.longitude;

      earliest = earliest == null || p.timestamp.isBefore(earliest)
          ? p.timestamp : earliest;
      latest = latest == null || p.timestamp.isAfter(latest)
          ? p.timestamp : latest;
    }

    // Mark points as clustered
    for (final p in points) {
      p.clusterId = id;
      p.noise = false;
    }

    return LocationCluster(
      id: id,
      points: points,
      centerLatitude: sumLat / points.length,
      centerLongitude: sumLon / points.length,
      startTime: earliest!,
      endTime: latest!,
    );
  }

  static List<List<LocationPoint>> _splitByTimeGaps(
    List<LocationPoint> points, {
    Duration maxGap = const Duration(minutes: 10),
  }) {
    final clusters = <List<LocationPoint>>[];
    var current = <LocationPoint>[];
    LocationPoint? last;

    for (final point in points) {
      if (last != null &&
          point.timestamp.difference(last.timestamp) > maxGap) {
        if (current.isNotEmpty) {
          clusters.add(current);
          current = [];
        }
      }
      current.add(point);
      last = point;
    }

    if (current.isNotEmpty) {
      clusters.add(current);
    }

    return clusters;
  }
}

/// Hybrid clustering that combines multiple strategies
class HybridClustering {
  static final _logger = AppLogger('HybridClustering');

  /// Smart clustering that picks the best algorithm based on data characteristics
  static Future<ClusteringResult> smartCluster(
    List<LocationPoint> points, {
    double eps = 50,
    int minPts = 5,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Analyze data characteristics
    final density = _calculateDensity(points);
    final timeSpan = _calculateTimeSpan(points);
    final pointCount = points.length;

    _logger.info('Data analysis: ${pointCount} points, density: ${density.toStringAsFixed(2)}, timespan: ${timeSpan.inHours}h');

    List<LocationCluster> clusters;
    List<JourneySegment> journeys = [];

    // Choose strategy based on characteristics
    if (pointCount > 5000) {
      // Extreme decimation for huge datasets
      _logger.info('Using extreme decimation strategy');
      final decimated = UltraFastClustering.decimatePoints(
        points,
        targetCount: 1000,
      );
      clusters = await _runDBSCAN(decimated, eps, minPts);

    } else if (density > 100) {
      // High density - use grid clustering
      _logger.info('Using grid clustering for high density');
      clusters = UltraFastClustering.gridClustering(
        points,
        cellSize: eps / 111000, // Convert meters to degrees
        minPoints: minPts,
      );

    } else if (timeSpan.inHours > 6) {
      // Long time span - use time-based clustering
      _logger.info('Using time-based clustering');
      clusters = UltraFastClustering.timeBasedClustering(
        points,
        stayDuration: Duration(minutes: minPts),
        mergeRadius: eps,
      );

    } else {
      // Default to optimized DBSCAN for moderate datasets
      _logger.info('Using optimized DBSCAN');
      final decimated = points.length > 2000
          ? UltraFastClustering.decimatePoints(points, targetCount: 1500)
          : points;
      clusters = await _runDBSCAN(decimated, eps, minPts);
    }

    // Identify journeys from unclustered points
    final clusteredIds = clusters
        .expand((c) => c.points.map((p) => p.id))
        .toSet();

    final noisePoints = points
        .where((p) => !clusteredIds.contains(p.id))
        .toList();

    if (noisePoints.isNotEmpty) {
      journeys = _identifyJourneys(noisePoints);
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    _logger.info('Smart clustering completed in ${elapsed}ms: ${clusters.length} clusters, ${journeys.length} journeys');

    return ClusteringResult(
      clusters: clusters,
      journeys: journeys,
    );
  }

  static Future<List<LocationCluster>> _runDBSCAN(
    List<LocationPoint> points,
    double eps,
    int minPts,
  ) async {
    final clustering = DBSCANClustering(eps: eps, minPts: minPts);
    final result = await clustering.clusterAsync(points);
    return result.clusters;
  }

  static double _calculateDensity(List<LocationPoint> points) {
    if (points.isEmpty) return 0;

    // Calculate bounding box
    double minLat = double.infinity, maxLat = -double.infinity;
    double minLon = double.infinity, maxLon = -double.infinity;

    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLon = math.min(minLon, p.longitude);
      maxLon = math.max(maxLon, p.longitude);
    }

    // Area in square meters (approximate)
    final latDiff = (maxLat - minLat) * 111000;
    final lonDiff = (maxLon - minLon) * 111000 *
        math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final area = latDiff * lonDiff;

    return area > 0 ? points.length / area : 0;
  }

  static Duration _calculateTimeSpan(List<LocationPoint> points) {
    if (points.isEmpty) return Duration.zero;

    DateTime? earliest, latest;
    for (final p in points) {
      earliest = earliest == null || p.timestamp.isBefore(earliest)
          ? p.timestamp : earliest;
      latest = latest == null || p.timestamp.isAfter(latest)
          ? p.timestamp : latest;
    }

    return latest!.difference(earliest!);
  }

  static List<JourneySegment> _identifyJourneys(List<LocationPoint> points) {
    if (points.isEmpty) return [];

    // Sort by time
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final journeys = <JourneySegment>[];
    final current = <LocationPoint>[];
    LocationPoint? last;

    for (final point in points) {
      if (last != null &&
          point.timestamp.difference(last.timestamp).inMinutes > 5) {
        if (current.isNotEmpty) {
          journeys.add(JourneySegment(points: current.toList()));
        }
        current.clear();
      }
      current.add(point);
      last = point;
    }

    if (current.isNotEmpty) {
      journeys.add(JourneySegment(points: current));
    }

    return journeys;
  }
}

/// Progressive clustering - cluster as data arrives
class ProgressiveClustering {
  final Map<String, LocationCluster> _activeClusters = {};
  final List<LocationCluster> _completedClusters = [];
  final double _mergeRadius;
  final Duration _stayDuration;
  int _nextClusterId = 1;

  ProgressiveClustering({
    double mergeRadius = 50,
    Duration stayDuration = const Duration(minutes: 5),
  }) : _mergeRadius = mergeRadius,
       _stayDuration = stayDuration;

  /// Add a new point and update clusters incrementally
  void addPoint(LocationPoint point) {
    // Find nearest active cluster
    String? nearestClusterKey;
    double minDistance = double.infinity;

    _activeClusters.forEach((key, cluster) {
      final distance = UltraFastClustering._fastDistance(
        LocationPoint(
          id: '',
          latitude: cluster.centerLatitude,
          longitude: cluster.centerLongitude,
          timestamp: DateTime.now(),
        ),
        point,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestClusterKey = key;
      }
    });

    // Add to nearest cluster or create new one
    if (nearestClusterKey != null && minDistance <= _mergeRadius) {
      final cluster = _activeClusters[nearestClusterKey]!;

      // Check time continuity
      final timeDiff = point.timestamp.difference(cluster.endTime);
      if (timeDiff <= _stayDuration) {
        // Add to existing cluster
        _updateCluster(cluster, point);
        return;
      }
    }

    // Create new cluster
    final newCluster = LocationCluster(
      id: _nextClusterId++,
      points: [point],
      centerLatitude: point.latitude,
      centerLongitude: point.longitude,
      startTime: point.timestamp,
      endTime: point.timestamp,
    );

    _activeClusters[point.id] = newCluster;

    // Clean up old clusters
    _cleanupOldClusters(point.timestamp);
  }

  void _updateCluster(LocationCluster cluster, LocationPoint point) {
    cluster.points.add(point);

    // Update centroid incrementally
    final n = cluster.points.length;
    cluster = LocationCluster(
      id: cluster.id,
      points: cluster.points,
      centerLatitude: (cluster.centerLatitude * (n - 1) + point.latitude) / n,
      centerLongitude: (cluster.centerLongitude * (n - 1) + point.longitude) / n,
      startTime: cluster.startTime,
      endTime: point.timestamp,
    );
  }

  void _cleanupOldClusters(DateTime currentTime) {
    final keysToRemove = <String>[];

    _activeClusters.forEach((key, cluster) {
      if (currentTime.difference(cluster.endTime) > _stayDuration) {
        if (cluster.points.length >= 3) {
          _completedClusters.add(cluster);
        }
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _activeClusters.remove(key);
    }
  }

  List<LocationCluster> getClusters() {
    return [
      ..._completedClusters,
      ..._activeClusters.values.where((c) => c.points.length >= 3),
    ];
  }
}