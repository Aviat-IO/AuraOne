import 'package:flutter/material.dart';

/// Shows what data is available and will be included in summary generation
class DataInclusionCard extends StatelessWidget {
  final int timelineEventCount;
  final int locationCount;
  final double distanceKm;
  final int photoCount;
  final int calendarEventCount;

  const DataInclusionCard({
    super.key,
    required this.timelineEventCount,
    required this.locationCount,
    required this.distanceKm,
    required this.photoCount,
    required this.calendarEventCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.data_usage,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Data Available',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data items
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDataChip(
                  theme,
                  '$timelineEventCount events',
                  Icons.timeline,
                  timelineEventCount > 0,
                ),
                if (locationCount > 0)
                  _buildDataChip(
                    theme,
                    '$locationCount locations',
                    Icons.place,
                    true,
                  ),
                if (distanceKm > 0)
                  _buildDataChip(
                    theme,
                    '${distanceKm.toStringAsFixed(1)}km traveled',
                    Icons.directions_walk,
                    true,
                  ),
                if (photoCount > 0)
                  _buildDataChip(
                    theme,
                    '$photoCount photos',
                    Icons.photo_camera,
                    true,
                  ),
                if (calendarEventCount > 0)
                  _buildDataChip(
                    theme,
                    '$calendarEventCount calendar events',
                    Icons.event,
                    true,
                  ),
              ],
            ),

            // Empty state
            if (timelineEventCount == 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No timeline data available for this day',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataChip(
    ThemeData theme,
    String label,
    IconData icon,
    bool hasData,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasData
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasData
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: hasData
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: hasData
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: hasData ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
