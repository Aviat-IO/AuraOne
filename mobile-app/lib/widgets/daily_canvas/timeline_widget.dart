import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

// Provider for timeline events with async loading simulation
final timelineEventsProvider = FutureProvider.family<List<TimelineEvent>, DateTime>((ref, date) async {
  // Simulate loading delay
  await Future.delayed(const Duration(milliseconds: 600));

  // TODO: Replace with actual data from storage
  return [
    TimelineEvent(
      time: DateTime(date.year, date.month, date.day, 7, 30),
      title: 'Morning Routine',
      description: 'Wake up, meditation, and breakfast',
      type: EventType.routine,
      icon: Icons.wb_sunny,
    ),
    TimelineEvent(
      time: DateTime(date.year, date.month, date.day, 9, 0),
      title: 'Work Session',
      description: 'Focus time on project tasks',
      type: EventType.work,
      icon: Icons.work,
    ),
    TimelineEvent(
      time: DateTime(date.year, date.month, date.day, 12, 30),
      title: 'Lunch Break',
      description: 'Healthy meal and short walk',
      type: EventType.meal,
      icon: Icons.restaurant,
    ),
    TimelineEvent(
      time: DateTime(date.year, date.month, date.day, 15, 0),
      title: 'Meeting',
      description: 'Team sync and planning',
      type: EventType.social,
      icon: Icons.people,
    ),
    TimelineEvent(
      time: DateTime(date.year, date.month, date.day, 18, 0),
      title: 'Exercise',
      description: 'Gym workout - upper body',
      type: EventType.exercise,
      icon: Icons.fitness_center,
    ),
    TimelineEvent(
      time: DateTime(date.year, date.month, date.day, 20, 0),
      title: 'Dinner',
      description: 'Family dinner at home',
      type: EventType.meal,
      icon: Icons.dinner_dining,
    ),
    TimelineEvent(
      time: DateTime(date.year, date.month, date.day, 22, 0),
      title: 'Evening Routine',
      description: 'Reading and relaxation',
      type: EventType.routine,
      icon: Icons.book,
    ),
  ];
});

// Provider for loading state
final timelineLoadingProvider = StateProvider<bool>((ref) => false);

enum EventType { routine, work, meal, social, exercise, leisure }

class TimelineEvent {
  final DateTime time;
  final String title;
  final String description;
  final EventType type;
  final IconData icon;

  TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
  });
}

class TimelineWidget extends ConsumerWidget {
  final DateTime date;

  const TimelineWidget({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final eventsAsync = ref.watch(timelineEventsProvider(date));

    return eventsAsync.when(
      data: (events) => events.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isFirst = index == 0;
                final isLast = index == events.length - 1;

                return _buildTimelineItem(
                  event: event,
                  isFirst: isFirst,
                  isLast: isLast,
                  context: context,
                  theme: theme,
                  isLight: isLight,
                );
              },
            ),
      loading: () => Skeletonizer(
        enabled: true,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (context, index) {
            final isFirst = index == 0;
            final isLast = index == 3;

            return _buildTimelineSkeletonItem(
              isFirst: isFirst,
              isLast: isLast,
              theme: theme,
            );
          },
        ),
      ),
      error: (error, stack) => Center(
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
              'Error loading timeline',
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
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No events for this day',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Events will appear here as they are captured',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required TimelineEvent event,
    required bool isFirst,
    required bool isLast,
    required ThemeData theme,
    required bool isLight,
    required BuildContext context,
  }) {
    final timeFormat = DateFormat('HH:mm');
    final color = _getEventColor(event.type, theme);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                timeFormat.format(event.time),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),

          // Timeline line and dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),

                // Event dot
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),

          // Event content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Navigate to event detail screen
                      context.push('/event-detail', extra: event);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              event.icon,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (event.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    event.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSkeletonItem({
    required bool isFirst,
    required bool isLast,
    required ThemeData theme,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column skeleton
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                width: 40,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // Timeline line and dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),

                // Event dot skeleton
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),

                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),

          // Event content skeleton
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 120,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(EventType type, ThemeData theme) {
    switch (type) {
      case EventType.routine:
        return theme.colorScheme.primary;
      case EventType.work:
        return Colors.blue;
      case EventType.meal:
        return Colors.orange;
      case EventType.social:
        return Colors.purple;
      case EventType.exercise:
        return Colors.green;
      case EventType.leisure:
        return Colors.teal;
    }
  }
}
