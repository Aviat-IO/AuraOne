import 'dart:math' as math;
import 'package:geocoding/geocoding.dart';
import '../database/location_database.dart';
import '../utils/logger.dart';

/// Service for naming location clusters using reverse geocoding
class LocationClusterNamer {
  static final _logger = AppLogger('LocationClusterNamer');
  static final LocationClusterNamer _instance = LocationClusterNamer._internal();

  factory LocationClusterNamer() => _instance;
  LocationClusterNamer._internal();

  bool _reverseGeocodingEnabled = false;

  /// Enable or disable reverse geocoding
  void setReverseGeocodingEnabled(bool enabled) {
    _reverseGeocodingEnabled = enabled;
    _logger.info('Reverse geocoding ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if reverse geocoding is enabled
  bool isReverseGeocodingEnabled() => _reverseGeocodingEnabled;

  /// Get place names for a list of location points
  /// Returns map of location coordinate keys to place names
  Future<Map<String, String>> getPlaceNames(
    List<LocationPoint> points,
  ) async {
    if (!_reverseGeocodingEnabled) {
      _logger.debug('Reverse geocoding disabled, returning coordinates');
      return {};
    }

    if (points.isEmpty) {
      return {};
    }

    final placeNames = <String, String>{};

    // Group points by proximity (cluster nearby points)
    final clusters = _clusterPoints(points);

    _logger.debug('Found ${clusters.length} location clusters to geocode');

    // Get place name for each cluster
    for (final cluster in clusters) {
      // Use center point of cluster for geocoding
      final centerPoint = _calculateClusterCenter(cluster);
      final key = _locationKey(centerPoint.latitude, centerPoint.longitude);

      try {
        final placeName = await _reverseGeocode(
          centerPoint.latitude,
          centerPoint.longitude,
        );

        if (placeName != null) {
          placeNames[key] = placeName;
          _logger.debug('Geocoded cluster: $placeName');
        }
      } catch (e) {
        _logger.warning('Failed to geocode cluster at $key: $e');
      }

      // Rate limit to avoid API throttling
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return placeNames;
  }

  /// Cluster nearby location points together
  /// Points within 100 meters are considered the same location
  List<List<LocationPoint>> _clusterPoints(
    List<LocationPoint> points, {
    double radiusMeters = 100,
  }) {
    if (points.isEmpty) {
      return [];
    }

    final clusters = <List<LocationPoint>>[];
    final processed = <int>{};

    for (int i = 0; i < points.length; i++) {
      if (processed.contains(i)) continue;

      final cluster = <LocationPoint>[points[i]];
      processed.add(i);

      // Find all points within radius
      for (int j = i + 1; j < points.length; j++) {
        if (processed.contains(j)) continue;

        final distance = _calculateDistance(
          points[i].latitude,
          points[i].longitude,
          points[j].latitude,
          points[j].longitude,
        );

        if (distance <= radiusMeters) {
          cluster.add(points[j]);
          processed.add(j);
        }
      }

      clusters.add(cluster);
    }

    return clusters;
  }

  /// Calculate center point of a cluster (centroid)
  LocationPoint _calculateClusterCenter(List<LocationPoint> cluster) {
    if (cluster.length == 1) {
      return cluster.first;
    }

    double sumLat = 0;
    double sumLon = 0;

    for (final point in cluster) {
      sumLat += point.latitude;
      sumLon += point.longitude;
    }

    final centerLat = sumLat / cluster.length;
    final centerLon = sumLon / cluster.length;

    // Return a synthetic LocationPoint with center coordinates
    // Use timestamp from first point in cluster
    return LocationPoint(
      id: cluster.first.id,
      timestamp: cluster.first.timestamp,
      latitude: centerLat,
      longitude: centerLon,
      accuracy: cluster.first.accuracy,
      altitude: cluster.first.altitude,
      speed: cluster.first.speed,
      heading: cluster.first.heading,
      activityType: cluster.first.activityType,
      confidence: cluster.first.confidence,
      batteryLevel: cluster.first.batteryLevel,
      isMoving: cluster.first.isMoving,
    );
  }

  /// Reverse geocode coordinates to place name
  Future<String?> _reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        _logger.debug('No placemarks found for coordinates');
        return null;
      }

      return _formatPlaceName(placemarks.first);
    } catch (e) {
      _logger.warning('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Format place name from placemark
  String _formatPlaceName(Placemark placemark) {
    // Priority order for place naming:
    // 1. Name (e.g., "Harbor Roast Coffee", "Golden Gate Park")
    // 2. Street + Locality (e.g., "Market St, San Francisco")
    // 3. Locality only (e.g., "San Francisco")
    // 4. Administrative area (e.g., "California")

    if (placemark.name != null && placemark.name!.isNotEmpty) {
      // Filter out generic names like street numbers
      final name = placemark.name!;
      if (!RegExp(r'^\d+$').hasMatch(name)) {
        return name;
      }
    }

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        return '${placemark.street}, ${placemark.locality}';
      }
      return placemark.street!;
    }

    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      return placemark.locality!;
    }

    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      return placemark.administrativeArea!;
    }

    return 'Unknown Location';
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in meters
  double _calculateDistance(
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

  /// Create a unique key for a location coordinate
  String _locationKey(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
