import 'dart:math' as math;
import '../database/location_database.dart';
import '../utils/logger.dart';

/// Service for calculating distances traveled from location data
class DistanceCalculator {
  static final _logger = AppLogger('DistanceCalculator');
  static final DistanceCalculator _instance = DistanceCalculator._internal();

  factory DistanceCalculator() => _instance;
  DistanceCalculator._internal();

  /// Calculate total distance traveled from a list of location points
  /// Returns distance in meters
  double calculateTotalDistance(List<LocationPoint> points) {
    if (points.isEmpty || points.length < 2) {
      return 0.0;
    }

    // Sort points by timestamp to ensure correct order
    final sortedPoints = List<LocationPoint>.from(points)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalDistance = 0.0;

    for (int i = 0; i < sortedPoints.length - 1; i++) {
      final point1 = sortedPoints[i];
      final point2 = sortedPoints[i + 1];

      final distance = _haversineDistance(
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude,
      );

      // Only add if distance seems reasonable (< 100km between consecutive points)
      // This filters out GPS errors and jumps
      if (distance < 100000) {
        totalDistance += distance;
      } else {
        _logger.debug(
          'Skipping suspicious distance: ${(distance / 1000).toStringAsFixed(1)}km '
          'between ${point1.timestamp} and ${point2.timestamp}',
        );
      }
    }

    return totalDistance;
  }

  /// Calculate distance between two geographic coordinates using Haversine formula
  /// Returns distance in meters
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Format distance in human-readable format
  /// Returns formatted string like "2.3km" or "150m"
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Calculate distance traveled between specific time range
  Future<double> calculateDistanceForTimeRange({
    required LocationDatabase database,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final points = await database.getLocationPointsBetween(
      startTime,
      endTime,
    );

    return calculateTotalDistance(points);
  }

  /// Group location points into segments based on time gaps
  /// Useful for separating distinct trips/movements
  List<List<LocationPoint>> segmentLocationPoints(
    List<LocationPoint> points, {
    Duration maxTimeBetweenPoints = const Duration(minutes: 30),
  }) {
    if (points.isEmpty) {
      return [];
    }

    final sortedPoints = List<LocationPoint>.from(points)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final segments = <List<LocationPoint>>[];
    List<LocationPoint> currentSegment = [sortedPoints.first];

    for (int i = 1; i < sortedPoints.length; i++) {
      final timeDiff = sortedPoints[i].timestamp.difference(
        sortedPoints[i - 1].timestamp,
      );

      if (timeDiff <= maxTimeBetweenPoints) {
        // Continue current segment
        currentSegment.add(sortedPoints[i]);
      } else {
        // Start new segment
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment);
        }
        currentSegment = [sortedPoints[i]];
      }
    }

    // Add final segment
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }

    return segments;
  }

  /// Get distance statistics for a list of points
  DistanceStatistics getDistanceStatistics(List<LocationPoint> points) {
    if (points.isEmpty) {
      return DistanceStatistics(
        totalDistance: 0,
        averageSpeed: 0,
        maxSpeed: 0,
        segmentCount: 0,
      );
    }

    final sortedPoints = List<LocationPoint>.from(points)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalDistance = 0;
    double maxSpeed = 0;
    final speeds = <double>[];

    for (int i = 0; i < sortedPoints.length - 1; i++) {
      final point1 = sortedPoints[i];
      final point2 = sortedPoints[i + 1];

      final distance = _haversineDistance(
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude,
      );

      final timeDiff = point2.timestamp.difference(point1.timestamp).inSeconds;

      if (timeDiff > 0 && distance < 100000) {
        totalDistance += distance;

        // Calculate speed in m/s
        final speed = distance / timeDiff;
        speeds.add(speed);

        if (speed > maxSpeed) {
          maxSpeed = speed;
        }
      }
    }

    final averageSpeed = speeds.isNotEmpty
        ? speeds.reduce((a, b) => a + b) / speeds.length
        : 0.0;

    final segments = segmentLocationPoints(points);

    return DistanceStatistics(
      totalDistance: totalDistance,
      averageSpeed: averageSpeed,
      maxSpeed: maxSpeed,
      segmentCount: segments.length,
    );
  }
}

/// Distance and movement statistics
class DistanceStatistics {
  final double totalDistance; // meters
  final double averageSpeed; // meters/second
  final double maxSpeed; // meters/second
  final int segmentCount; // number of distinct movement segments

  DistanceStatistics({
    required this.totalDistance,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.segmentCount,
  });

  /// Format average speed in km/h
  String get averageSpeedKmh => '${(averageSpeed * 3.6).toStringAsFixed(1)} km/h';

  /// Format max speed in km/h
  String get maxSpeedKmh => '${(maxSpeed * 3.6).toStringAsFixed(1)} km/h';

  /// Format total distance in human-readable format
  String get formattedDistance => DistanceCalculator().formatDistance(totalDistance);
}
