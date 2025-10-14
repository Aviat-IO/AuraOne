import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/location_clustering_provider.dart';
import '../../providers/location_database_provider.dart';
import '../../database/location_database.dart' as loc_db;
import '../../services/ai/dbscan_clustering.dart';
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
    final shouldResetView = previousDate.value == null ||
        !_isSameDay(previousDate.value!, targetDate);

    // Update previous date
    useEffect(() {
      previousDate.value = targetDate;
      return null;
    }, [targetDate]);

    // Get clusters for the target date
    final clustersAsync = ref.watch(clusteredLocationsProvider(targetDate));

    // Get recent location history for path visualization (last 7 days)
    final locationHistoryAsync = ref.watch(recentLocationPointsProvider(const Duration(days: 7)));

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
            clustersAsync.when(
          loading: () => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading map data...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
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
                      color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (clusters) {
            // If no clusters, show a map with helpful message
            if (clusters.isEmpty) {
              return _buildEmptyMap(context, isDark, mapController);
            }

            // Calculate center and zoom for this date
            final center = _calculateMapCenter(clusters);
            final zoom = _calculateOptimalZoom(clusters);

            // Only reset view when date changes or first load
            if (shouldResetView) {
              // Use post-frame callback to move map without rebuilding
              WidgetsBinding.instance.addPostFrameCallback((_) {
                mapController.move(center, zoom);
              });
            }

            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                minZoom: 1.0,  // Reduced from 2.0 to allow wider view
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
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
                // Add a semi-transparent overlay in dark mode to improve contrast
                if (isDark)
                  Container(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                // Add path visualization layers (polylines and direction arrows)
                ...locationHistoryAsync.when(
                  data: (locationHistory) => PathVisualizerWidget.buildPathLayers(
                    locations: _filterLocationsByDate(locationHistory, targetDate),
                    theme: theme,
                    pathColor: theme.colorScheme.primary.withValues(alpha: 0.7),
                    pathWidth: 3.0,
                    arrowSpacing: 150.0, // Show arrows every 150 meters
                  ),
                  loading: () => [],
                  error: (_, _) => [],
                ),
                // Cluster markers removed - clustering logic still runs for AI summary generation
                // but we don't display the cluster markers on the map
                // Show helpful overlay for very few location points (not clusters)
                if (_getTotalLocationPoints(clusters) <= 2)
                  Container(
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Limited location data - check location permissions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
            ),
            // Debug overlay in debug mode only
            if (kDebugMode)
              MapDebugOverlay(date: targetDate),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMap(BuildContext context, bool isDark, MapController mapController) {
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
        // Add a semi-transparent overlay in dark mode to improve contrast
        if (isDark)
          Container(
            color: Colors.white.withValues(alpha: 0.15),
          ),
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

  int _getTotalLocationPoints(List<LocationCluster> clusters) {
    return clusters.fold(0, (sum, cluster) => sum + cluster.points.length);
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

  LatLng _calculateMapCenter(List<LocationCluster> clusters) {
    if (clusters.isEmpty) {
      return const LatLng(40.7128, -74.0060); // Default to NYC
    }

    // Calculate center from ALL location points (not cluster centers)
    // to get the true geographic center of the path
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
      return const LatLng(40.7128, -74.0060); // Fallback
    }

    // Center is the midpoint of the bounding box
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    if (kDebugMode) {
      print('Map center - Lat: $centerLat, Lng: $centerLng (from bounds: $minLat-$maxLat, $minLng-$maxLng)');
    }

    return LatLng(centerLat, centerLng);
  }

  double _calculateOptimalZoom(List<LocationCluster> clusters) {
    if (clusters.isEmpty) return 10.0;
    if (clusters.length == 1) return 13.0;  // Single location gets comfortable zoom

    // Calculate bounding box from ALL location points (not just cluster centers)
    // to ensure the entire path is visible
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

    // Fallback if no points found
    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return 13.0;
    }

    // Calculate raw span
    final rawLatSpan = maxLat - minLat;
    final rawLngSpan = maxLng - minLng;

    if (kDebugMode) {
      print('Map bounds - Lat: $minLat to $maxLat (span: $rawLatSpan), Lng: $minLng to $maxLng (span: $rawLngSpan)');
    }

    // Add VERY generous padding (100% on each side = 300% total span)
    // This ensures all points are well within the visible area
    final latSpan = rawLatSpan * 3.0;
    final lngSpan = rawLngSpan * 3.0;
    final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

    // Calculate zoom level based on padded span
    // At zoom level Z, the world spans approximately 360 / (2^Z) degrees
    // So: maxSpan = 360 / (2^Z)
    // Therefore: Z = log2(360 / maxSpan)

    if (maxSpan <= 0) return 13.0; // Fallback for edge case

    // Calculate ideal zoom using logarithm
    final idealZoom = math.log(360 / maxSpan) / math.ln2;

    // Apply additional zoom-out for extra comfort
    final zoom = (idealZoom - 1.5).clamp(1.0, 15.0);

    if (kDebugMode) {
      print('Zoom calculation - maxSpan: $maxSpan, idealZoom: $idealZoom, finalZoom: $zoom');
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



  List<loc_db.LocationPoint> _filterLocationsByDate(
    List<loc_db.LocationPoint> locations,
    DateTime targetDate,
  ) {
    final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return locations
        .where((loc) =>
            (loc.timestamp.isAtSameMomentAs(dayStart) || loc.timestamp.isAfter(dayStart)) &&
            loc.timestamp.isBefore(dayEnd))
        .toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}