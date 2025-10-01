import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../database/location_database.dart' as loc_db;

/// Widget to visualize movement paths with directional arrows
/// Uses heading data from flutter_background_geolocation to show direction of travel
class PathVisualizerWidget {
  /// Creates polyline layers showing paths between location points
  /// with arrow markers indicating direction of movement
  static List<Widget> buildPathLayers({
    required List<loc_db.LocationPoint> locations,
    required ThemeData theme,
    Color? pathColor,
    double pathWidth = 3.0,
    double arrowSpacing = 100.0, // Distance between arrows in meters
  }) {
    if (locations.isEmpty) return [];

    final layers = <Widget>[];
    final color = pathColor ?? theme.colorScheme.primary;

    // Sort locations by timestamp to ensure correct path order
    final sortedLocations = List<loc_db.LocationPoint>.from(locations)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Build the path polyline
    final pathPoints = sortedLocations
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();

    layers.add(
      PolylineLayer(
        polylines: [
          Polyline(
            points: pathPoints,
            strokeWidth: pathWidth,
            color: color,
            borderStrokeWidth: pathWidth + 2,
            borderColor: Colors.white.withValues(alpha: 0.5),
          ),
        ],
      ),
    );

    // Add directional arrow markers along the path
    final arrowMarkers = _buildArrowMarkers(
      sortedLocations,
      color,
      theme,
      arrowSpacing,
    );

    if (arrowMarkers.isNotEmpty) {
      layers.add(
        MarkerLayer(markers: arrowMarkers),
      );
    }

    return layers;
  }

  /// Creates arrow markers along the path showing direction of movement
  static List<Marker> _buildArrowMarkers(
    List<loc_db.LocationPoint> locations,
    Color color,
    ThemeData theme,
    double spacingMeters,
  ) {
    if (locations.length < 2) return [];

    final markers = <Marker>[];
    double accumulatedDistance = 0;
    bool shouldAddMarker = true;

    for (int i = 1; i < locations.length; i++) {
      final prev = locations[i - 1];
      final current = locations[i];

      // Calculate distance between points
      final distance = _calculateDistance(
        prev.latitude,
        prev.longitude,
        current.latitude,
        current.longitude,
      );

      accumulatedDistance += distance;

      // Add arrow marker if we've traveled enough distance
      if (shouldAddMarker || accumulatedDistance >= spacingMeters) {
        // Use heading if available, otherwise calculate from movement
        final heading = current.heading ?? _calculateBearing(
          prev.latitude,
          prev.longitude,
          current.latitude,
          current.longitude,
        );

        markers.add(
          Marker(
            point: LatLng(current.latitude, current.longitude),
            width: 24,
            height: 24,
            child: Transform.rotate(
              angle: _degreesToRadians(heading),
              child: Icon(
                Icons.arrow_upward,
                color: color,
                size: 20,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        );

        accumulatedDistance = 0;
        shouldAddMarker = false;
      }
    }

    return markers;
  }

  /// Calculate distance between two coordinates in meters using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000; // meters
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

  /// Calculate bearing (heading) between two coordinates
  static double _calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final y = math.sin(dLon) * math.cos(_degreesToRadians(lat2));
    final x = math.cos(_degreesToRadians(lat1)) *
            math.sin(_degreesToRadians(lat2)) -
        math.sin(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (_radiansToDegrees(bearing) + 360) % 360;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
  static double _radiansToDegrees(double radians) => radians * 180 / math.pi;
}
