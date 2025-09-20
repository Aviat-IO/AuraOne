import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/location_clustering_provider.dart';
import '../../services/ai/dbscan_clustering.dart';
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

    // Get clusters for the target date
    final clustersAsync = ref.watch(clusteredLocationsProvider(targetDate));

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
              return _buildEmptyMap(context, isDark);
            }

            // For very few clusters, show them with a wider view
            final center = _calculateMapCenter(clusters);
            final zoom = _calculateOptimalZoom(clusters);

            return FlutterMap(
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
                MarkerLayer(
                  markers: _buildMarkers(clusters, theme),
                ),
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

  Widget _buildEmptyMap(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return FlutterMap(
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

  LatLng _calculateMapCenter(List<LocationCluster> clusters) {
    if (clusters.isEmpty) {
      return const LatLng(40.7128, -74.0060); // Default to NYC
    }

    double totalLat = 0;
    double totalLng = 0;
    int totalPoints = 0;

    for (final cluster in clusters) {
      totalLat += cluster.centerLatitude;
      totalLng += cluster.centerLongitude;
      totalPoints++;
    }

    return LatLng(totalLat / totalPoints, totalLng / totalPoints);
  }

  double _calculateOptimalZoom(List<LocationCluster> clusters) {
    if (clusters.isEmpty) return 10.0;
    if (clusters.length == 1) return 13.0;  // Reduced from 15.0 for better context
    if (clusters.length == 2) return 12.0;  // New case for two clusters

    // Calculate bounding box
    double minLat = clusters.first.centerLatitude;
    double maxLat = clusters.first.centerLatitude;
    double minLng = clusters.first.centerLongitude;
    double maxLng = clusters.first.centerLongitude;

    for (final cluster in clusters) {
      minLat = minLat < cluster.centerLatitude ? minLat : cluster.centerLatitude;
      maxLat = maxLat > cluster.centerLatitude ? maxLat : cluster.centerLatitude;
      minLng = minLng < cluster.centerLongitude ? minLng : cluster.centerLongitude;
      maxLng = maxLng > cluster.centerLongitude ? maxLng : cluster.centerLongitude;
    }

    // Calculate appropriate zoom based on span - more generous zoom levels
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

    // More generous zoom levels to show context better
    if (maxSpan > 10) return 3.0;   // Reduced from 4.0
    if (maxSpan > 5) return 5.0;    // Reduced from 6.0
    if (maxSpan > 1) return 7.0;    // Reduced from 8.0
    if (maxSpan > 0.1) return 9.0;  // Reduced from 11.0
    if (maxSpan > 0.01) return 11.0; // Reduced from 13.0
    return 13.0;  // Reduced from 15.0
  }

  List<Marker> _buildMarkers(List<LocationCluster> clusters, ThemeData theme) {
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
  }

  double _getMarkerSize(int pointCount) {
    if (pointCount == 1) return 20.0;
    if (pointCount < 5) return 30.0;
    if (pointCount < 10) return 40.0;
    if (pointCount < 20) return 50.0;
    return 60.0;
  }

  Color _getMarkerColor(int pointCount, ThemeData theme) {
    if (pointCount == 1) return theme.colorScheme.secondary;
    if (pointCount < 5) return theme.colorScheme.primary;
    if (pointCount < 10) return theme.colorScheme.tertiary;
    return theme.colorScheme.error;
  }
}