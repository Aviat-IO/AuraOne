import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/location_database_provider.dart';

class MapDebugOverlay extends HookConsumerWidget {
  final DateTime date;

  const MapDebugOverlay({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dayLocationsAsync = ref.watch(locationPointsForDateProvider(date));

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
            _buildLocationStatus(theme, dayLocationsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatus(ThemeData theme, AsyncValue dayLocationsAsync) {
    return dayLocationsAsync.when(
      data: (locations) {
        final visibleLocations = locations
            .where((loc) => loc.accuracy == null || loc.accuracy! <= 100)
            .toList();

        final statusColor = visibleLocations.isEmpty
            ? theme.colorScheme.error
            : visibleLocations.length < 10
            ? theme.colorScheme.tertiary
            : theme.colorScheme.primary;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              visibleLocations.isEmpty ? Icons.location_off : Icons.location_on,
              size: 12,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Visible points: ${visibleLocations.length}',
              style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
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
          Text('Loading locations...', style: theme.textTheme.bodySmall),
        ],
      ),
      error: (error, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 12, color: theme.colorScheme.error),
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
}
