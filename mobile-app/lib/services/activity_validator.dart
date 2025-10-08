import 'dart:math' as math;
import 'package:drift/drift.dart';
import '../database/location_database.dart';
import '../utils/logger.dart';

/// Validates and corrects activity types using speed-based analysis
///
/// flutter_background_geolocation's activity detection can be inaccurate,
/// especially confusing similar activities like walking/running or cycling/driving.
/// This service uses speed data to validate and correct activity classifications.
class ActivityValidator {
  static final _logger = AppLogger('ActivityValidator');

  /// Speed thresholds for different activities (in meters/second)
  ///
  /// Based on typical human movement patterns:
  /// - Walking: 1.2-1.8 m/s (4.3-6.5 km/h)
  /// - Running: 2.5-5 m/s (9-18 km/h)
  /// - Cycling: 3-8 m/s (10.8-28.8 km/h)
  /// - Driving: >5 m/s (>18 km/h), typically 8-33 m/s (30-120 km/h)
  static const double _stationaryMaxSpeed = 1.0; // 3.6 km/h
  static const double _walkingMaxSpeed = 2.5; // 9 km/h
  static const double _runningMaxSpeed = 5.0; // 18 km/h
  static const double _cyclingMaxSpeed = 8.0; // 28.8 km/h
  static const double _drivingMinSpeed = 5.0; // 18 km/h

  /// Minimum number of consecutive points required to consider an activity legitimate
  /// This prevents brief GPS glitches or momentary speed fluctuations from
  /// appearing as actual activities in the narrative
  static const int _minClusterSize = 3;

  /// Validate and correct a single location's activity type based on speed
  String validateActivity({
    required String? reportedActivity,
    required double? speed,
    double? accuracy,
  }) {
    // If no speed data, trust the reported activity
    if (speed == null) {
      return reportedActivity ?? 'unknown';
    }

    // Low accuracy GPS can give wrong speed readings - be conservative
    if (accuracy != null && accuracy > 50) {
      _logger.debug('Low GPS accuracy ($accuracy m), trusting reported activity');
      return reportedActivity ?? _inferFromSpeed(speed);
    }

    final absoluteSpeed = speed.abs();
    final inferredActivity = _inferFromSpeed(absoluteSpeed);

    // If reported activity matches speed-based inference, trust it
    if (reportedActivity != null && _activitiesMatch(reportedActivity, inferredActivity)) {
      return reportedActivity;
    }

    // If there's a clear mismatch, correct it
    if (reportedActivity != null && _isClearMismatch(reportedActivity, absoluteSpeed)) {
      _logger.info(
        'Correcting activity: "$reportedActivity" → "$inferredActivity" '
        '(speed: ${(absoluteSpeed * 3.6).toStringAsFixed(1)} km/h)'
      );
      return inferredActivity;
    }

    // For ambiguous cases, prefer reported activity with speed hints
    return reportedActivity ?? inferredActivity;
  }

  /// Infer activity type from speed alone
  String _inferFromSpeed(double speed) {
    if (speed < _stationaryMaxSpeed) {
      return 'still';
    } else if (speed < _walkingMaxSpeed) {
      return 'walking';
    } else if (speed < _runningMaxSpeed) {
      return 'running';
    } else if (speed < _cyclingMaxSpeed) {
      return 'on_bicycle';
    } else {
      return 'in_vehicle';
    }
  }

  /// Check if two activity types are compatible (variations of same activity)
  bool _activitiesMatch(String activity1, String activity2) {
    // Exact match
    if (activity1 == activity2) return true;

    // Stationary variations
    if (_isStationary(activity1) && _isStationary(activity2)) return true;

    // On foot variations
    if (_isOnFoot(activity1) && _isOnFoot(activity2)) return true;

    return false;
  }

  /// Check if there's a clear mismatch between reported activity and speed
  bool _isClearMismatch(String reportedActivity, double speed) {
    // Running reported but speed is too slow
    if (reportedActivity == 'running' && speed < _walkingMaxSpeed) {
      return true;
    }

    // Cycling reported but speed is walking pace or driving speed
    if (reportedActivity == 'on_bicycle') {
      if (speed < _walkingMaxSpeed || speed > _cyclingMaxSpeed) {
        return true;
      }
    }

    // Walking reported but speed is too fast (running/cycling/driving)
    if (reportedActivity == 'walking' && speed > _runningMaxSpeed) {
      return true;
    }

    // Driving reported but speed is too slow
    if (reportedActivity == 'in_vehicle' && speed < _drivingMinSpeed) {
      return true;
    }

    // Still/stationary reported but speed indicates movement
    if (_isStationary(reportedActivity) && speed > _stationaryMaxSpeed) {
      return true;
    }

    return false;
  }

  /// Check if activity is a stationary type
  bool _isStationary(String activity) {
    return activity == 'still' ||
           activity == 'stationary' ||
           activity == 'STILL';
  }

  /// Check if activity is on-foot type
  bool _isOnFoot(String activity) {
    return activity == 'on_foot' ||
           activity == 'walking' ||
           activity == 'running' ||
           activity == 'ON_FOOT';
  }

  /// Validate activity types across a sequence of location points
  ///
  /// This provides better accuracy by considering context:
  /// - Sustained speeds over multiple points
  /// - Acceleration patterns
  /// - Duration of activity segments
  List<LocationPoint> validateSequence(List<LocationPoint> points) {
    if (points.length < 3) {
      // Not enough points for sequence analysis, just validate individually
      return points.map((p) => _validateSinglePoint(p)).toList();
    }

    final correctedPoints = <LocationPoint>[];

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Get surrounding points for context
      final prevPoint = i > 0 ? points[i - 1] : null;
      final nextPoint = i < points.length - 1 ? points[i + 1] : null;

      // Calculate average speed over the sequence
      double? avgSpeed;
      if (prevPoint != null && nextPoint != null) {
        final speeds = [
          prevPoint.speed,
          point.speed,
          nextPoint.speed,
        ].whereType<double>().toList();

        if (speeds.isNotEmpty) {
          avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
        }
      }

      // Validate using both instantaneous and average speed
      final validatedActivity = validateActivity(
        reportedActivity: point.activityType,
        speed: avgSpeed ?? point.speed,
        accuracy: point.accuracy,
      );

      // Create corrected point if activity changed
      if (validatedActivity != point.activityType) {
        correctedPoints.add(point.copyWith(activityType: Value(validatedActivity)));
      } else {
        correctedPoints.add(point);
      }
    }

    final smoothedPoints = _smoothActivitySequence(correctedPoints);
    return _filterByClusterSize(smoothedPoints);
  }

  /// Smooth activity sequence to remove brief anomalies
  ///
  /// If a single point has a different activity than its neighbors,
  /// and the neighbors agree, it's likely a misclassification.
  List<LocationPoint> _smoothActivitySequence(List<LocationPoint> points) {
    if (points.length < 3) return points;

    final smoothed = <LocationPoint>[];

    for (int i = 0; i < points.length; i++) {
      if (i == 0 || i == points.length - 1) {
        // Keep first and last points as-is
        smoothed.add(points[i]);
        continue;
      }

      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];

      // If current differs from both neighbors, and neighbors agree
      if (prev.activityType == next.activityType &&
          current.activityType != prev.activityType) {
        // This is likely an anomaly - smooth it out
        _logger.debug(
          'Smoothing activity anomaly at ${current.timestamp}: '
          '${current.activityType} → ${prev.activityType}'
        );
        smoothed.add(current.copyWith(activityType: Value(prev.activityType)));
      } else {
        smoothed.add(current);
      }
    }

    return smoothed;
  }

  /// Filter activities by minimum cluster size
  ///
  /// Requires at least _minClusterSize consecutive points of the same activity
  /// type before considering it legitimate. This prevents brief GPS glitches
  /// or momentary speed fluctuations from appearing in the narrative.
  List<LocationPoint> _filterByClusterSize(List<LocationPoint> points) {
    if (points.length < _minClusterSize) return points;

    // Identify activity clusters and their sizes
    final clusters = <_ActivityCluster>[];
    String? currentActivity;
    int clusterStart = 0;

    for (int i = 0; i < points.length; i++) {
      final activity = points[i].activityType;

      if (activity != currentActivity) {
        // Save previous cluster if it exists
        if (currentActivity != null) {
          clusters.add(_ActivityCluster(
            activity: currentActivity,
            startIndex: clusterStart,
            endIndex: i - 1,
            size: i - clusterStart,
          ));
        }

        // Start new cluster
        currentActivity = activity;
        clusterStart = i;
      }
    }

    // Save final cluster
    if (currentActivity != null) {
      clusters.add(_ActivityCluster(
        activity: currentActivity,
        startIndex: clusterStart,
        endIndex: points.length - 1,
        size: points.length - clusterStart,
      ));
    }

    // Build list of valid indices (clusters >= minimum size)
    final validIndices = <int>{};
    for (final cluster in clusters) {
      if (cluster.size >= _minClusterSize) {
        for (int i = cluster.startIndex; i <= cluster.endIndex; i++) {
          validIndices.add(i);
        }
      }
    }

    // For invalid points, find the dominant surrounding activity
    final filtered = <LocationPoint>[];
    for (int i = 0; i < points.length; i++) {
      if (validIndices.contains(i)) {
        filtered.add(points[i]);
      } else {
        // Find dominant activity from surrounding valid clusters
        String? replacementActivity = _findDominantSurroundingActivity(
          clusters,
          i,
          _minClusterSize,
        );

        _logger.debug(
          'Filtering out small activity cluster at ${points[i].timestamp}: '
          '${points[i].activityType} → ${replacementActivity ?? "unknown"}'
        );

        filtered.add(points[i].copyWith(
          activityType: Value(replacementActivity),
        ));
      }
    }

    return filtered;
  }

  /// Find the dominant activity from surrounding valid clusters
  String? _findDominantSurroundingActivity(
    List<_ActivityCluster> clusters,
    int index,
    int minSize,
  ) {
    // Find clusters before and after this index
    _ActivityCluster? beforeCluster;
    _ActivityCluster? afterCluster;

    for (final cluster in clusters) {
      if (cluster.endIndex < index && cluster.size >= minSize) {
        beforeCluster = cluster;
      } else if (cluster.startIndex > index && cluster.size >= minSize) {
        afterCluster = cluster;
        break;
      }
    }

    // If both neighbors exist and agree, use that activity
    if (beforeCluster != null &&
        afterCluster != null &&
        beforeCluster.activity == afterCluster.activity) {
      return beforeCluster.activity;
    }

    // Otherwise, use the larger neighboring cluster
    if (beforeCluster != null && afterCluster != null) {
      return beforeCluster.size >= afterCluster.size
          ? beforeCluster.activity
          : afterCluster.activity;
    }

    // Use whichever neighbor exists
    if (beforeCluster != null) return beforeCluster.activity;
    if (afterCluster != null) return afterCluster.activity;

    // No valid neighbors
    return null;
  }

  /// Validate a single point
  LocationPoint _validateSinglePoint(LocationPoint point) {
    final validated = validateActivity(
      reportedActivity: point.activityType,
      speed: point.speed,
      accuracy: point.accuracy,
    );

    if (validated != point.activityType) {
      return point.copyWith(activityType: Value(validated));
    }

    return point;
  }

  /// Calculate movement statistics for a sequence
  MovementStats calculateStats(List<LocationPoint> points) {
    if (points.isEmpty) {
      return MovementStats.empty();
    }

    final activityCounts = <String, int>{};
    final speeds = <double>[];
    var totalDistance = 0.0;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Count activities
      final activity = point.activityType ?? 'unknown';
      activityCounts[activity] = (activityCounts[activity] ?? 0) + 1;

      // Collect speeds
      if (point.speed != null) {
        speeds.add(point.speed!.abs());
      }

      // Calculate distance
      if (i > 0) {
        final prev = points[i - 1];
        final dist = _calculateDistance(
          prev.latitude, prev.longitude,
          point.latitude, point.longitude,
        );
        totalDistance += dist;
      }
    }

    // Calculate average speed
    final avgSpeed = speeds.isEmpty
        ? 0.0
        : speeds.reduce((a, b) => a + b) / speeds.length;

    // Find dominant activity
    String? dominantActivity;
    int maxCount = 0;
    activityCounts.forEach((activity, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantActivity = activity;
      }
    });

    return MovementStats(
      dominantActivity: dominantActivity ?? 'unknown',
      activityCounts: activityCounts,
      averageSpeed: avgSpeed,
      totalDistance: totalDistance,
      pointCount: points.length,
    );
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.cos(_degreesToRadians(lat1)) *
              math.cos(_degreesToRadians(lat2)) *
              math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}

/// Helper class for tracking activity clusters
class _ActivityCluster {
  final String? activity;
  final int startIndex;
  final int endIndex;
  final int size;

  _ActivityCluster({
    required this.activity,
    required this.startIndex,
    required this.endIndex,
    required this.size,
  });
}

/// Movement statistics for a sequence of location points
class MovementStats {
  final String dominantActivity;
  final Map<String, int> activityCounts;
  final double averageSpeed; // m/s
  final double totalDistance; // meters
  final int pointCount;

  MovementStats({
    required this.dominantActivity,
    required this.activityCounts,
    required this.averageSpeed,
    required this.totalDistance,
    required this.pointCount,
  });

  factory MovementStats.empty() => MovementStats(
    dominantActivity: 'unknown',
    activityCounts: {},
    averageSpeed: 0.0,
    totalDistance: 0.0,
    pointCount: 0,
  );

  double get averageSpeedKmh => averageSpeed * 3.6;
  double get totalDistanceKm => totalDistance / 1000;

  @override
  String toString() {
    return 'MovementStats('
        'activity: $dominantActivity, '
        'avgSpeed: ${averageSpeedKmh.toStringAsFixed(1)} km/h, '
        'distance: ${totalDistanceKm.toStringAsFixed(2)} km, '
        'points: $pointCount)';
  }
}

/// Extension to copy LocationPoint with modified fields
extension LocationPointCopyWith on LocationPoint {
  LocationPoint copyWith({
    int? id,
    double? latitude,
    double? longitude,
    Value<double?>? accuracy,
    Value<double?>? altitude,
    Value<double?>? speed,
    Value<double?>? heading,
    DateTime? timestamp,
    Value<String?>? activityType,
    bool? isSignificant,
    DateTime? createdAt,
  }) {
    return LocationPoint(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy != null ? accuracy.value : this.accuracy,
      altitude: altitude != null ? altitude.value : this.altitude,
      speed: speed != null ? speed.value : this.speed,
      heading: heading != null ? heading.value : this.heading,
      timestamp: timestamp ?? this.timestamp,
      activityType: activityType != null ? activityType.value : this.activityType,
      isSignificant: isSignificant ?? this.isSignificant,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
