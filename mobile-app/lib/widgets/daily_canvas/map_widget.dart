import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../database/location_database.dart' as loc_db;
import '../../providers/location_database_provider.dart';
import '../location/path_visualizer.dart';
import 'map_debug_overlay.dart';

class MapWidget extends HookConsumerWidget {
  final DateTime? selectedDate;
  final DateTime? date;
  final Function(DateTime)? onDateSelected;

  const MapWidget({
    super.key,
    this.selectedDate,
    this.date,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use the date parameter if provided, otherwise use selectedDate
    final targetDate = date ?? selectedDate ?? DateTime.now();

    // Create MapController to preserve user's view state
    final mapController = useMemoized(() => MapController());
    final previousDate = useRef<DateTime?>(null);

    // Track if we should reset the map view (only on date change)
    final shouldResetView =
        previousDate.value == null ||
        !_isSameDay(previousDate.value!, targetDate);

    // Update previous date
    useEffect(() {
      previousDate.value = targetDate;
      return null;
    }, [targetDate]);

    final locationHistoryAsync = ref.watch(
      locationPointsForDateProvider(targetDate),
    );

    // Add loading timeout state
    final isLoadingTimedOut = useState(false);
    final loadingStartTime = useRef<DateTime?>(null);

    // Track loading timeout
    useEffect(() {
      if (locationHistoryAsync.isLoading && loadingStartTime.value == null) {
        loadingStartTime.value = DateTime.now();
      } else if (!locationHistoryAsync.isLoading) {
        loadingStartTime.value = null;
        isLoadingTimedOut.value = false;
      } else if (loadingStartTime.value != null &&
          DateTime.now().difference(loadingStartTime.value!) >
              const Duration(seconds: 20)) {
        isLoadingTimedOut.value = true;
      }
      return null;
    }, [locationHistoryAsync]);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            locationHistoryAsync.when(
              loading: () => Stack(
                children: [
                  // Show a skeleton map while loading
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(
                        40.7128,
                        -74.0060,
                      ), // Default center
                      initialZoom: 10.0,
                      minZoom: 1.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag
                            .none, // Disable interaction while loading
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isDark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        maxZoom: 19,
                        additionalOptions: const {},
                      ),
                      if (isDark)
                        Container(color: Colors.white.withValues(alpha: 0.15)),
                    ],
                  ),
                  // Loading overlay with blur effect
                  Container(
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Show different message if timed out
                          if (isLoadingTimedOut.value) ...[
                            Icon(
                              Icons.warning,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Map data is taking longer to load',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try switching tabs and back, or restart the app if this persists',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            // Animated loading indicator
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Loading location data',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Analyzing movement patterns...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              error: (error, stack) => Container(
                color: theme.colorScheme.errorContainer,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load map',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${error.toString()}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (locationHistory) {
                final mapLocations = _filterMapLocations(locationHistory);

                if (mapLocations.isEmpty) {
                  return _buildEmptyMap(context, isDark, mapController);
                }

                _calculateMapViewAsync(mapLocations)
                    .then((view) {
                      if (shouldResetView && context.mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            mapController.move(view.center, view.zoom);
                          }
                        });
                      }
                    })
                    .catchError((e) {
                      debugPrint('Error calculating map view: $e');
                      if (shouldResetView && context.mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            mapController.move(
                              const LatLng(40.7128, -74.0060),
                              10.0,
                            );
                          }
                        });
                      }
                    });

                final initialCenter = const LatLng(40.7128, -74.0060);
                final initialZoom = 10.0;

                return FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: initialZoom,
                    minZoom: 1.0, // Reduced from 2.0 to allow wider view
                    maxZoom: 18.0,
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDark
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                          : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      maxZoom: 19,
                      additionalOptions: const {},
                    ),
                    if (isDark)
                      Container(color: Colors.white.withValues(alpha: 0.15)),
                    ...PathVisualizerWidget.buildPathLayers(
                      locations: mapLocations,
                      theme: theme,
                      pathColor: theme.colorScheme.primary.withValues(
                        alpha: 0.7,
                      ),
                      pathWidth: 3.0,
                      arrowSpacing: 150.0,
                    ),
                    if (mapLocations.length <= 2)
                      Container(
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            'Limited location data - check location permissions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // Debug overlay in debug mode only
            if (kDebugMode) MapDebugOverlay(date: targetDate),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMap(
    BuildContext context,
    bool isDark,
    MapController mapController,
  ) {
    final theme = Theme.of(context);

    return FlutterMap(
      mapController: mapController,
      options: const MapOptions(
        initialCenter: LatLng(40.7128, -74.0060), // New York City as default
        initialZoom: 10.0,
        minZoom: 2.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          maxZoom: 19,
          additionalOptions: const {},
        ),
        if (isDark) Container(color: Colors.white.withValues(alpha: 0.15)),
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 32,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No location data for this date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<loc_db.LocationPoint> _filterMapLocations(
    List<loc_db.LocationPoint> locationHistory,
  ) {
    final filteredLocations =
        locationHistory
            .where((loc) => loc.accuracy == null || loc.accuracy! <= 100.0)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return filteredLocations;
  }

  /// Calculate bounds from all location points to ensure everything is visible
  // Unused: Future feature for auto-zoom
  /* LatLngBounds? _calculateBounds(List<LocationCluster> clusters) {
    if (clusters.isEmpty) return null;

    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;

    for (final cluster in clusters) {
      for (final point in cluster.points) {
        if (minLat == null || point.latitude < minLat) minLat = point.latitude;
        if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
        if (minLng == null || point.longitude < minLng) minLng = point.longitude;
        if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return null;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  } */

  LatLng _calculateMapCenter(List<loc_db.LocationPoint> locations) {
    if (locations.isEmpty) {
      return const LatLng(40.7128, -74.0060); // Default to NYC
    }

    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;

    for (final point in locations) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return const LatLng(40.7128, -74.0060); // Fallback
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    if (kDebugMode) {
      print(
        'Map center - Lat: $centerLat, Lng: $centerLng (from bounds: $minLat-$maxLat, $minLng-$maxLng)',
      );
    }

    return LatLng(centerLat, centerLng);
  }

  double _calculateOptimalZoom(List<loc_db.LocationPoint> locations) {
    if (locations.isEmpty) return 10.0;
    if (locations.length == 1) return 13.0;

    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;

    for (final point in locations) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return 13.0;
    }

    final rawLatSpan = maxLat - minLat;
    final rawLngSpan = maxLng - minLng;

    if (kDebugMode) {
      print(
        'Map bounds - Lat: $minLat to $maxLat (span: $rawLatSpan), Lng: $minLng to $maxLng (span: $rawLngSpan)',
      );
    }

    final latSpan = rawLatSpan * 3.0;
    final lngSpan = rawLngSpan * 3.0;
    final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

    if (maxSpan <= 0) return 13.0;

    final idealZoom = math.log(360 / maxSpan) / math.ln2;

    final zoom = (idealZoom - 1.5).clamp(1.0, 15.0);

    if (kDebugMode) {
      print(
        'Zoom calculation - maxSpan: $maxSpan, idealZoom: $idealZoom, finalZoom: $zoom',
      );
    }

    return zoom;
  }

  // Unused: Future feature for custom markers
  /* List<Marker> _buildMarkers(List<LocationCluster> clusters, ThemeData theme) {
    return clusters.map((cluster) {
      final size = _getMarkerSize(cluster.points.length);
      final color = _getMarkerColor(cluster.points.length, theme);

      return Marker(
        point: LatLng(cluster.centerLatitude, cluster.centerLongitude),
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.onPrimary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              cluster.points.length.toString(),
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: size * 0.3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }).toList();
  } */

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<_MapView> _calculateMapViewAsync(
    List<loc_db.LocationPoint> locations,
  ) async {
    return await Future.microtask(() {
      final center = _calculateMapCenter(locations);
      final zoom = _calculateOptimalZoom(locations);
      return _MapView(center: center, zoom: zoom);
    }).timeout(
      const Duration(seconds: 2),
      onTimeout: () =>
          const _MapView(center: LatLng(40.7128, -74.0060), zoom: 10.0),
    );
  }
}

// Helper class for map view data
class _MapView {
  final LatLng center;
  final double zoom;

  const _MapView({required this.center, required this.zoom});
}
