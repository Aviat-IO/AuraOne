import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/location_clustering_provider.dart';
import '../../providers/location_database_provider.dart';

/// Debug overlay widget to help diagnose map loading issues
class MapDebugOverlay extends HookConsumerWidget {
  final DateTime date;

  const MapDebugOverlay({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clustersAsync = ref.watch(clusteredLocationsProvider(date));
    final recentLocationsAsync = ref.watch(recentLocationPointsProvider(const Duration(days: 1)));

    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Map Debug Info',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _buildLocationStatus(theme, recentLocationsAsync),
            const SizedBox(height: 2),
            _buildClusterStatus(theme, clustersAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatus(ThemeData theme, AsyncValue recentLocationsAsync) {
    return recentLocationsAsync.when(
      data: (locations) {
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final dayLocations = locations
            .where((loc) => loc.timestamp.isAfter(dayStart) && loc.timestamp.isBefore(dayEnd))
            .toList();

        final statusColor = dayLocations.isEmpty
            ? theme.colorScheme.error
            : dayLocations.length < 10
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              dayLocations.isEmpty ? Icons.location_off : Icons.location_on,
              size: 12,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Locations: ${dayLocations.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Loading locations...',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      error: (error, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 12,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            'Location error',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterStatus(ThemeData theme, AsyncValue clustersAsync) {
    return clustersAsync.when(
      data: (clusters) {
        final statusColor = clusters.isEmpty
            ? theme.colorScheme.error
            : clusters.length < 3
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              clusters.isEmpty ? Icons.place_outlined : Icons.place,
              size: 12,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Clusters: ${clusters.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Clustering...',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      error: (error, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 12,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            'Cluster error',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}