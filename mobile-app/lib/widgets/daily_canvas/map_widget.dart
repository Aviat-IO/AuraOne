import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/colors.dart';
import '../../database/location_database.dart';
import '../../providers/location_database_provider.dart';
import '../../providers/location_clustering_provider.dart';
import '../../services/ai/dbscan_clustering.dart' as clustering;
import '../../services/simple_location_service.dart' as location_service;

// Provider for real location data from database
final mapDataProvider = FutureProvider.family<MapData?, DateTime>((ref, date) async {
  final database = ref.watch(locationDatabaseProvider);

  // Get start and end of the requested date
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  // Fetch location points from database
  final locationPoints = await database.getLocationPointsBetween(startOfDay, endOfDay);

  // Debug logging
  print('MapWidget: Querying locations for date: $date');
  print('MapWidget: Start of day: $startOfDay');
  print('MapWidget: End of day: $endOfDay');
  print('MapWidget: Found ${locationPoints.length} location points');

  if (locationPoints.isEmpty) {
    // Also try to get recent points to see if there's any data at all
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentPoints = await database.getLocationPointsBetween(sevenDaysAgo, now);
    print('MapWidget: Recent points (last 7 days): ${recentPoints.length}');
    if (recentPoints.isNotEmpty) {
      print('MapWidget: First recent point: ${recentPoints.first.timestamp}');
      print('MapWidget: Last recent point: ${recentPoints.last.timestamp}');
    }
    return null;
  }

  // Get clustered locations to show unique places
  final clusters = await ref.read(clusteredLocationsProvider(date).future);

  // Get journey segments for distance calculation
  final journeys = await ref.read(journeySegmentsProvider(date).future);

  // Calculate total distance from journeys and movements between clusters
  double totalDistance = 0;
  for (final journey in journeys) {
    totalDistance += journey.totalDistance;
  }

  // Convert clusters to MapData location points (one per unique location)
  final locations = clusters.map((cluster) => MapLocationPoint(
    latitude: cluster.centerLatitude,
    longitude: cluster.centerLongitude,
    time: cluster.startTime,
    name: _inferLocationNameFromCluster(cluster),
    type: _inferLocationTypeFromCluster(cluster),
  )).toList();

  // Calculate total active time (sum of time spent at each location)
  Duration totalTime = Duration.zero;
  for (final cluster in clusters) {
    totalTime += cluster.duration;
  }

  return MapData(
    locations: locations,
    totalDistance: totalDistance / 1000, // Convert to kilometers
    totalTime: totalTime,
    allPoints: locationPoints, // Keep all points for drawing the path
  );
});

// Provider for loading state
final mapLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for focused location
final focusedLocationProvider = StateProvider<MapLocationPoint?>((ref) => null);

enum LocationType { home, work, food, shopping, exercise, social, other }

class MapLocationPoint {
  final double latitude;
  final double longitude;
  final DateTime time;
  final String name;
  final LocationType type;

  MapLocationPoint({
    required this.latitude,
    required this.longitude,
    required this.time,
    required this.name,
    required this.type,
  });
}

class MapData {
  final List<MapLocationPoint> locations;
  final double totalDistance;
  final Duration totalTime;
  final List<LocationPoint>? allPoints; // Optional, for drawing the path

  MapData({
    required this.locations,
    required this.totalDistance,
    required this.totalTime,
    this.allPoints,
  });
}

class MapWidget extends HookConsumerWidget {
  final DateTime date;

  const MapWidget({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final mapDataAsync = ref.watch(mapDataProvider(date));

    // Use hook to create and maintain MapController
    final mapController = useMemoized(() => MapController(), []);

    // Check if location tracking is running and try to start it if not
    useEffect(() {
      Future<void> checkAndStartTracking() async {
        final isTracking = ref.read(location_service.isTrackingProvider);
        if (!isTracking) {
          debugPrint('MapWidget: Location tracking not active, attempting to start...');
          final locationService = ref.read(location_service.simpleLocationServiceProvider);
          final started = await locationService.startTracking();
          if (started) {
            debugPrint('MapWidget: Location tracking started successfully');
          } else {
            debugPrint('MapWidget: Could not start location tracking');
          }
        }
      }
      checkAndStartTracking();
      return null;
    }, []);

    return mapDataAsync.when(
      data: (mapData) => _buildMapContent(mapData, theme, isLight, mapController, ref),
      loading: () => _buildLoadingState(theme),
      error: (error, stack) => _buildErrorState(error, theme),
    );
  }

  Widget _buildMapContent(MapData? mapData, ThemeData theme, bool isLight, MapController mapController, WidgetRef ref) {
    return Column(
      children: [
        // Real FlutterMap implementation
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: _buildFlutterMap(mapData, theme, mapController, ref),
          ),
        ),

        // Location stats
        if (mapData != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? AuraColors.lightCardGradient
                    : AuraColors.darkCardGradient,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  icon: Icons.place,
                  value: mapData.locations.length.toString(),
                  label: 'Places',
                  theme: theme,
                ),
                _buildStat(
                  icon: Icons.straighten,
                  value: '${mapData.totalDistance.toStringAsFixed(1)} km',
                  label: 'Distance',
                  theme: theme,
                ),
                _buildStat(
                  icon: Icons.timer,
                  value: '${mapData.totalTime.inHours}h ${mapData.totalTime.inMinutes % 60}m',
                  label: 'Active Time',
                  theme: theme,
                ),
              ],
            ),
          ),
        ],

        // Location list
        if (mapData != null && mapData.locations.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: mapData.locations.length,
              itemBuilder: (context, index) {
                final location = mapData.locations[index];
                return _buildLocationCard(
                  location: location,
                  theme: theme,
                  isLight: isLight,
                  mapController: mapController,
                  ref: ref,
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          // Map skeleton
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stats skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(3, (index) => Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 30,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              )),
            ),
          ),
          const SizedBox(height: 16),
          // Location list skeleton
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading map data',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFlutterMap(MapData? mapData, ThemeData theme, MapController mapController, WidgetRef? ref) {
    if (mapData == null || mapData.locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No location data',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable location services to track your journey',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Get focused location for special marker
    final focusedLocation = ref?.watch(focusedLocationProvider);

    // Calculate map center based on location points
    final locations = mapData.locations;
    final avgLat = locations.map((l) => l.latitude).reduce((a, b) => a + b) / locations.length;
    final avgLng = locations.map((l) => l.longitude).reduce((a, b) => a + b) / locations.length;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(avgLat, avgLng),
            initialZoom: 13.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.auraone.app',
            ),

            // Draw route polyline if we have multiple points
            if (locations.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: locations.map((loc) => LatLng(loc.latitude, loc.longitude)).toList(),
                    color: theme.colorScheme.primary,
                    strokeWidth: 3.0,
                  ),
                ],
              ),

            // Add markers for significant locations
            MarkerLayer(
              markers: [
                // Start marker
                if (locations.isNotEmpty)
                  Marker(
                    point: LatLng(locations.first.latitude, locations.first.longitude),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                    ),
                  ),

                // End marker
                if (locations.length > 1)
                  Marker(
                    point: LatLng(locations.last.latitude, locations.last.longitude),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.stop, color: Colors.white, size: 20),
                    ),
                  ),

                // Significant location markers (every nth point to avoid clutter)
                ...locations
                    .asMap()
                    .entries
                    .where((entry) => entry.key % (locations.length ~/ 5 + 1) == 0 &&
                           entry.key != 0 && entry.key != locations.length - 1)
                    .map((entry) {
                  final location = entry.value;
                  final color = _getLocationColor(location.type, theme);

                  return Marker(
                    point: LatLng(location.latitude, location.longitude),
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getLocationIcon(location.type),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  );
                }),

                // Focused location marker (special highlight)
                if (focusedLocation != null)
                  Marker(
                    point: LatLng(focusedLocation.latitude, focusedLocation.longitude),
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getLocationColor(focusedLocation.type, theme),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _getLocationColor(focusedLocation.type, theme).withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getLocationIcon(focusedLocation.type),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Map controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildMapControl(
                icon: Icons.add,
                onTap: () => _zoomIn(mapController),
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildMapControl(
                icon: Icons.remove,
                onTap: () => _zoomOut(mapController),
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildMapControl(
                icon: Icons.my_location,
                onTap: () => _centerOnCurrentLocation(mapController),
                theme: theme,
              ),
            ],
          ),
        ),

        // Map attribution
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '© OpenStreetMap',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Map control methods
  void _zoomIn(MapController mapController) {
    final currentZoom = mapController.camera.zoom;
    if (currentZoom < 18.0) {
      mapController.move(
        mapController.camera.center,
        (currentZoom + 1).clamp(3.0, 18.0),
      );
    }
  }

  void _zoomOut(MapController mapController) {
    final currentZoom = mapController.camera.zoom;
    if (currentZoom > 3.0) {
      mapController.move(
        mapController.camera.center,
        (currentZoom - 1).clamp(3.0, 18.0),
      );
    }
  }

  void _centerOnCurrentLocation(MapController mapController) async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return; // Permission denied, can't get location
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return; // Permissions permanently denied
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Center map on current location
      mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0, // Zoom to street level
      );
    } catch (e) {
      // Handle location errors silently
      debugPrint('Error getting current location: $e');
    }
  }

  void _focusOnLocation(MapLocationPoint location, MapController mapController, WidgetRef ref) {
    try {
      // Set focused location for visual feedback
      ref.read(focusedLocationProvider.notifier).state = location;

      // Center map on the selected location with smooth animation
      mapController.move(
        LatLng(location.latitude, location.longitude),
        16.0, // Zoom level for location detail view
      );

      // Clear focused state after 5 seconds for better UX
      Timer(const Duration(seconds: 5), () {
        if (ref.read(focusedLocationProvider) == location) {
          ref.read(focusedLocationProvider.notifier).state = null;
        }
      });
    } catch (e) {
      debugPrint('Error focusing on location: $e');
    }
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard({
    required MapLocationPoint location,
    required ThemeData theme,
    required bool isLight,
    required MapController mapController,
    required WidgetRef ref,
  }) {
    final color = _getLocationColor(location.type, theme);
    final focusedLocation = ref.watch(focusedLocationProvider);
    final isSelected = focusedLocation != null &&
        focusedLocation.latitude == location.latitude &&
        focusedLocation.longitude == location.longitude &&
        focusedLocation.time == location.time;

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.2),
                ]
              : [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.08),
                ],
        ),
        border: Border.all(
          color: isSelected
              ? color.withValues(alpha: 0.6)
              : color.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _focusOnLocation(location, mapController, ref);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getLocationIcon(location.type),
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  location.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${location.time.hour.toString().padLeft(2, '0')}:${location.time.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getLocationIcon(LocationType type) {
    switch (type) {
      case LocationType.home:
        return Icons.home;
      case LocationType.work:
        return Icons.work;
      case LocationType.food:
        return Icons.restaurant;
      case LocationType.shopping:
        return Icons.shopping_bag;
      case LocationType.exercise:
        return Icons.fitness_center;
      case LocationType.social:
        return Icons.people;
      case LocationType.other:
        return Icons.place;
    }
  }

  Color _getLocationColor(LocationType type, ThemeData theme) {
    switch (type) {
      case LocationType.home:
        return theme.colorScheme.primary;
      case LocationType.work:
        return Colors.blue;
      case LocationType.food:
        return Colors.orange;
      case LocationType.shopping:
        return Colors.purple;
      case LocationType.exercise:
        return Colors.green;
      case LocationType.social:
        return Colors.pink;
      case LocationType.other:
        return Colors.grey;
    }
  }
}

// Helper functions for location inference
String _inferLocationName(LocationPoint point) {
  // Simple heuristic based on activity type
  switch (point.activityType?.toLowerCase()) {
    case 'stationary':
      return 'Location';
    case 'walking':
      return 'Walk Route';
    case 'driving':
      return 'Drive Route';
    default:
      return 'Unknown Location';
  }
}

LocationType _inferLocationType(LocationPoint point) {
  // Simple heuristic - can be enhanced with geofencing data
  final hour = point.timestamp.hour;

  if (hour >= 22 || hour <= 6) {
    return LocationType.home;
  } else if (hour >= 9 && hour <= 17) {
    return LocationType.work;
  } else if (hour >= 12 && hour <= 14) {
    return LocationType.food;
  } else {
    return LocationType.other;
  }
}

// Helper functions for cluster-based location inference
String _inferLocationNameFromCluster(clustering.LocationCluster cluster) {
  // Generate name based on duration spent at location
  final minutes = cluster.duration.inMinutes;

  if (minutes < 5) {
    return 'Brief Stop';
  } else if (minutes < 30) {
    return 'Quick Visit';
  } else if (minutes < 120) {
    return 'Location Visit';
  } else {
    return 'Extended Stay';
  }
}

LocationType _inferLocationTypeFromCluster(clustering.LocationCluster cluster) {
  // Use the average time of the cluster to infer type
  final hour = cluster.startTime.hour;
  final duration = cluster.duration;

  // Long stays in evening/night are likely home
  if ((hour >= 20 || hour <= 7) && duration.inHours >= 4) {
    return LocationType.home;
  }
  // Long stays during work hours are likely work
  else if (hour >= 9 && hour <= 17 && duration.inHours >= 2) {
    return LocationType.work;
  }
  // Short stays around meal times might be food
  else if ((hour >= 11 && hour <= 14) || (hour >= 18 && hour <= 20)) {
    if (duration.inMinutes >= 20 && duration.inMinutes <= 90) {
      return LocationType.food;
    }
  }
  // Morning/evening short stops might be exercise
  else if ((hour >= 5 && hour <= 8) || (hour >= 17 && hour <= 19)) {
    if (duration.inMinutes >= 30 && duration.inMinutes <= 120) {
      return LocationType.exercise;
    }
  }
  // Weekend afternoon activities might be social
  else if (cluster.startTime.weekday >= 6 && hour >= 12 && hour <= 20) {
    return LocationType.social;
  }

  return LocationType.other;
}

// Distance calculation helper
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // meters
  final double dLat = _toRadians(lat2 - lat1);
  final double dLon = _toRadians(lon2 - lon1);

  final double a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
      math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) *
      math.sin(dLon / 2);

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degrees) {
  return degrees * (math.pi / 180);
}
