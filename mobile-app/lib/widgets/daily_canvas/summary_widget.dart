import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../database/journal_database.dart';
import '../../services/journal_service.dart';
import '../../services/summary_edit_tracker.dart';
import 'timeline_widget.dart';
import 'style_picker_sheet.dart';
import 'data_inclusion_card.dart';

// Provider for daily summary data
final dailySummaryProvider = FutureProvider.family<DailySummary, DateTime>((ref, date) async {
  final journalDb = ref.watch(journalDatabaseProvider);

  // Get activities for the date
  final activities = await journalDb.getActivitiesForDate(date);

  // Get journal entry for the date
  final journalService = ref.watch(journalServiceProvider);
  final journalEntry = await journalService.getEntryForDate(date);

  return DailySummary.fromActivities(activities, journalEntry, date);
});

class DailySummary {
  final DateTime date;
  final int totalEvents;
  final Map<EventType, int> eventCounts;
  final Map<String, int> activityTypeCounts;
  final List<String> topLocations;
  final int photoCount;
  final int calendarEventCount;
  final int movementMinutes;
  final String? journalWordCount;
  final String? aiSummary;
  final TimeOfDay? firstActivity;
  final TimeOfDay? lastActivity;

  DailySummary({
    required this.date,
    required this.totalEvents,
    required this.eventCounts,
    required this.activityTypeCounts,
    required this.topLocations,
    required this.photoCount,
    required this.calendarEventCount,
    required this.movementMinutes,
    this.journalWordCount,
    this.aiSummary,
    this.firstActivity,
    this.lastActivity,
  });

  factory DailySummary.fromActivities(
    List<JournalActivity> activities,
    JournalEntry? journalEntry,
    DateTime date,
  ) {
    final eventCounts = <EventType, int>{};
    final activityTypeCounts = <String, int>{};
    final locations = <String>[];
    var photoCount = 0;
    var calendarEventCount = 0;
    var movementMinutes = 0;

    DateTime? firstTime;
    DateTime? lastTime;

    for (final activity in activities) {
      // Track first and last activity times
      if (firstTime == null || activity.timestamp.isBefore(firstTime)) {
        firstTime = activity.timestamp;
      }
      if (lastTime == null || activity.timestamp.isAfter(lastTime)) {
        lastTime = activity.timestamp;
      }

      // Count activity types
      activityTypeCounts[activity.activityType] =
          (activityTypeCounts[activity.activityType] ?? 0) + 1;

      // Map activity types to event types and count
      EventType eventType;
      switch (activity.activityType) {
        case 'location':
          eventType = EventType.routine;
          // Extract location from metadata
          if (activity.metadata != null) {
            try {
              final metadata = jsonDecode(activity.metadata!);
              if (metadata['location'] != null) {
                locations.add(metadata['location']);
              }
            } catch (_) {}
          }
          break;
        case 'photo':
          eventType = EventType.leisure;
          photoCount++;
          break;
        case 'movement':
          eventType = EventType.exercise;
          // Extract duration from metadata
          if (activity.metadata != null) {
            try {
              final metadata = jsonDecode(activity.metadata!);
              if (metadata['duration'] != null) {
                // Parse duration and add to total
                final duration = metadata['duration'].toString();
                final minutes = _parseDurationMinutes(duration);
                movementMinutes += minutes;
              }
            } catch (_) {}
          }
          break;
        case 'calendar':
          eventType = EventType.work;
          calendarEventCount++;
          break;
        case 'manual':
          eventType = EventType.routine;
          break;
        default:
          eventType = EventType.routine;
      }

      eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;
    }

    // Get top 3 locations
    final locationCounts = <String, int>{};
    for (final location in locations) {
      locationCounts[location] = (locationCounts[location] ?? 0) + 1;
    }
    final sortedLocations = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topLocations = sortedLocations.take(3).map((e) => e.key).toList();

    return DailySummary(
      date: date,
      totalEvents: activities.length,
      eventCounts: eventCounts,
      activityTypeCounts: activityTypeCounts,
      topLocations: topLocations,
      photoCount: photoCount,
      calendarEventCount: calendarEventCount,
      movementMinutes: movementMinutes,
      journalWordCount: journalEntry?.content.split(' ').length.toString(),
      aiSummary: journalEntry?.summary,
      firstActivity: firstTime != null ? TimeOfDay.fromDateTime(firstTime) : null,
      lastActivity: lastTime != null ? TimeOfDay.fromDateTime(lastTime) : null,
    );
  }

  static int _parseDurationMinutes(String duration) {
    // Simple duration parser - extend as needed
    if (duration.contains('hour')) {
      final hours = double.tryParse(duration.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      return (hours * 60).round();
    } else if (duration.contains('min')) {
      return int.tryParse(duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return 0;
  }
}

class SummaryWidget extends ConsumerWidget {
  final DateTime date;

  const SummaryWidget({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(dailySummaryProvider(date));

    return summaryAsync.when(
      data: (summary) => _buildSummaryContent(context, theme, summary),
      loading: () => _buildLoadingSkeleton(theme),
      error: (error, stack) => _buildErrorState(theme, error),
    );
  }

  Widget _buildSummaryContent(BuildContext context, ThemeData theme, DailySummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Card
          _buildOverviewCard(theme, summary),
          const SizedBox(height: 16),

          // Activity Breakdown
          _buildActivityBreakdownCard(theme, summary),
          const SizedBox(height: 16),

          // Timeline Stats
          _buildTimelineStatsCard(context, theme, summary),
          const SizedBox(height: 16),

          // AI Summary (if available)
          if (summary.aiSummary != null && summary.aiSummary!.isNotEmpty)
            _buildAISummaryCard(context, theme, summary),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(ThemeData theme, DailySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Daily Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick stats grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Events',
                    summary.totalEvents.toString(),
                    Icons.timeline,
                    theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Photos',
                    summary.photoCount.toString(),
                    Icons.photo_camera,
                    Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Calendar',
                    summary.calendarEventCount.toString(),
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Movement',
                    '${summary.movementMinutes}m',
                    Icons.directions_walk,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBreakdownCard(ThemeData theme, DailySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Activity Breakdown',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Event type breakdown
            ...summary.eventCounts.entries.map((entry) {
              final percentage = summary.totalEvents > 0
                  ? entry.value / summary.totalEvents
                  : 0.0;
              final color = _getEventTypeColor(entry.key);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getEventTypeDisplayName(entry.key),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${entry.value} (${(percentage * 100).round()}%)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearPercentIndicator(
                      lineHeight: 6,
                      percent: percentage,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      progressColor: color,
                      barRadius: const Radius.circular(3),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStatsCard(BuildContext context, ThemeData theme, DailySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Timeline Stats',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Time range
            if (summary.firstActivity != null && summary.lastActivity != null) ...[
              _buildTimeRangeItem(
                theme,
                'Active Period',
                '${summary.firstActivity!.format(context)} - ${summary.lastActivity!.format(context)}',
                Icons.access_time,
              ),
              const SizedBox(height: 16),
            ],

            // Top locations
            if (summary.topLocations.isNotEmpty) ...[
              _buildListItem(
                theme,
                'Top Locations',
                summary.topLocations.take(3).join(', '),
                Icons.location_on,
              ),
              const SizedBox(height: 16),
            ],

            // Journal word count
            if (summary.journalWordCount != null) ...[
              _buildListItem(
                theme,
                'Journal Words',
                summary.journalWordCount!,
                Icons.edit_note,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeItem(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAISummaryCard(BuildContext context, ThemeData theme, DailySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with regeneration button
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Regeneration button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Regenerate with different style',
                  onPressed: () => _handleRegenerationRequest(context, theme, summary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary text
            Text(
              summary.aiSummary!,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle summary regeneration request with edit protection
  Future<void> _handleRegenerationRequest(
    BuildContext context,
    ThemeData theme,
    DailySummary summary,
  ) async {
    final tracker = SummaryEditTracker();

    // TODO: Get original hash from journal entry metadata
    // For now, assume no edit protection (first implementation)
    final String? originalHash = null;

    // Check if regeneration is allowed
    final canRegenerate = tracker.canRegenerate(
      currentSummary: summary.aiSummary ?? '',
      originalHash: originalHash,
    );

    if (!canRegenerate) {
      // Show edit warning dialog
      await _showEditWarningDialog(context, theme);
      return;
    }

    // Show style picker and data inclusion
    await _showRegenerationSheet(context, theme, summary);
  }

  /// Show warning when user has edited the summary
  Future<void> _showEditWarningDialog(BuildContext context, ThemeData theme) async {
    // Implementation will be added when we integrate with journal database
    // For now, this is a placeholder
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Summary Has Been Edited'),
        content: const Text(
          'This summary has been manually edited. Regenerating will overwrite your changes. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Force regeneration
            },
            child: const Text('Regenerate Anyway'),
          ),
        ],
      ),
    );
  }

  /// Show regeneration sheet with style picker and data preview
  Future<void> _showRegenerationSheet(
    BuildContext context,
    ThemeData theme,
    DailySummary summary,
  ) async {
    // TODO: Implement full regeneration flow
    // This will integrate with DailyContextSynthesizer and DataRichNarrativeBuilder

    // For now, just show the style picker
    final selectedStyle = await StylePickerSheet.show(
      context: context,
      currentStyle: NarrativeStyle.reflective,
    );

    if (selectedStyle != null) {
      // TODO: Trigger regeneration with selected style
      // This will call DailyContextSynthesizer -> DataRichNarrativeBuilder
      // with the selected narrative style
    }
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Container(
                height: 200,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Container(
                height: 150,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Container(
                height: 100,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
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
            'Error loading summary',
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

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.routine:
        return Colors.blue;
      case EventType.work:
        return Colors.orange;
      case EventType.movement:
        return Colors.green;
      case EventType.social:
        return Colors.purple;
      case EventType.exercise:
        return Colors.red;
      case EventType.leisure:
        return Colors.teal;
    }
  }

  String _getEventTypeDisplayName(EventType type) {
    switch (type) {
      case EventType.routine:
        return 'Routine';
      case EventType.work:
        return 'Work';
      case EventType.movement:
        return 'Movement';
      case EventType.social:
        return 'Social';
      case EventType.exercise:
        return 'Exercise';
      case EventType.leisure:
        return 'Leisure';
    }
  }
}