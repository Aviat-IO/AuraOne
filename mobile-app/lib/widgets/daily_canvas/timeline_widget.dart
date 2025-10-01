import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import '../../database/journal_database.dart';
import '../../database/media_database.dart';
import '../../utils/date_utils.dart';
import '../../services/journal_service.dart';
import '../../services/calendar_service.dart';
import '../../services/calendar_initialization_service.dart';
import '../../providers/media_database_provider.dart';
import '../../providers/media_thumbnail_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_providers.dart';

// Helper function to get calendar events for a specific date
Future<List<CalendarEventData>> _getCalendarEventsForDate(
  CalendarService calendarService,
  DateTime date,
  Set<String> enabledCalendarIds,
) async {
  // For calendar queries, use local day boundaries (device calendar expects local times)
  final startDate = DateTime(date.year, date.month, date.day);
  final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  try {
    return await calendarService.getEventsInRange(
      startDate,
      endDate,
      enabledCalendarIds: enabledCalendarIds,
    );
  } catch (e) {
    // Return empty list if calendar access fails (no permissions, etc.)
    return [];
  }
}

// Provider for calendar events from device calendar
final calendarEventsProvider = FutureProvider.family<List<CalendarEventData>, DateTime>((ref, date) async {
  final calendarService = ref.watch(calendarServiceProvider);
  var calendarSettings = ref.watch(calendarSettingsProvider);

  // Check if calendar settings need initialization
  if (calendarSettings.enabledCalendarIds.isEmpty) {
    // Try to initialize calendars if not already done
    final calendarInitService = ref.read(calendarInitializationServiceProvider);
    await calendarInitService.initialize();

    // Refresh the settings after initialization
    await ref.read(calendarSettingsProvider.notifier).loadSettings();
    calendarSettings = ref.read(calendarSettingsProvider);
  }

  // Get events for the selected date
  // For calendar queries, use local day boundaries (device calendar expects local times)
  final startDate = DateTime(date.year, date.month, date.day);
  final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  try {
    final events = await calendarService.getEventsInRange(
      startDate,
      endDate,
      enabledCalendarIds: calendarSettings.enabledCalendarIds,
    );
    return events;
  } catch (e) {
    // Return empty list if calendar access fails (no permissions, etc.)
    return [];
  }
});

// Provider for calendar metadata (names, colors, etc.) - cached and shared across all dates
final calendarMetadataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final calendarService = ref.watch(calendarServiceProvider);

  try {
    // Cache for 5 minutes to avoid frequent calendar queries
    ref.keepAlive();
    final timer = Timer(const Duration(minutes: 5), () {
      ref.invalidateSelf();
    });
    ref.onDispose(() => timer.cancel());

    final calendars = await calendarService.getCalendars();
    return Map.fromEntries(
      calendars.map((calendar) => MapEntry(calendar.id, calendar.name))
    );
  } catch (e) {
    // Return empty map if calendar access fails
    return {};
  }
});

// Provider for timeline events from journal database
final timelineEventsProvider = FutureProvider.family<List<TimelineEvent>, DateTime>((ref, date) async {
  final journalDb = ref.watch(journalDatabaseProvider);
  final calendarService = ref.watch(calendarServiceProvider);
  var calendarSettings = ref.watch(calendarSettingsProvider);

  // Check if calendar settings need initialization
  if (calendarSettings.enabledCalendarIds.isEmpty) {
    // Try to initialize calendars if not already done
    final calendarInitService = ref.read(calendarInitializationServiceProvider);
    await calendarInitService.initialize();

    // Refresh the settings after initialization
    await ref.read(calendarSettingsProvider.notifier).loadSettings();
    calendarSettings = ref.read(calendarSettingsProvider);
  }

  // Load journal activities and calendar events in parallel
  final results = await Future.wait([
    journalDb.getActivitiesForDate(date),
    _getCalendarEventsForDate(calendarService, date, calendarSettings.enabledCalendarIds),
  ]);

  final activities = results[0] as List<JournalActivity>;
  final calendarEvents = results[1] as List<CalendarEventData>;

  // Filter out the automatic "Personal reflections and thoughts" manual entry
  final filteredActivities = activities.where((activity) {
    // Skip the placeholder manual entry
    if (activity.activityType == 'manual' &&
        activity.description == 'Personal reflections and thoughts') {
      return false;
    }
    return true;
  }).toList();

  // Convert JournalActivity to TimelineEvent
  final journalEvents = filteredActivities.map((activity) {
    // Parse metadata if available
    Map<String, dynamic>? metadata;
    if (activity.metadata != null) {
      try {
        metadata = jsonDecode(activity.metadata!);
      } catch (_) {
        metadata = null;
      }
    }

    // Map activity type to EventType and icon
    EventType eventType;
    IconData icon;

    switch (activity.activityType) {
      case 'location':
        eventType = EventType.routine;
        icon = Icons.location_on;
        break;
      case 'photo':
        eventType = EventType.leisure;
        icon = Icons.photo_camera;
        break;
      case 'movement':
        eventType = EventType.exercise;
        icon = Icons.directions_walk;
        break;
      case 'calendar':
        eventType = EventType.work;
        icon = Icons.event;
        break;
      case 'manual':
        eventType = EventType.routine;
        icon = Icons.edit_note;
        break;
      default:
        eventType = EventType.routine;
        icon = Icons.circle;
    }

    // Extract title from description or use activity type
    String title = activity.description;
    if (title.length > 30) {
      // Extract first part as title if description is long
      final parts = title.split(' - ');
      if (parts.length > 1) {
        title = parts[0];
      } else {
        title = activity.activityType[0].toUpperCase() + activity.activityType.substring(1);
      }
    }

    // Create detailed description from metadata
    String description = activity.description;
    if (metadata != null) {
      final details = <String>[];
      if (metadata['duration'] != null) {
        details.add('Duration: ${metadata['duration']}');
      }
      if (metadata['distance'] != null) {
        details.add('Distance: ${metadata['distance']}');
      }
      if (metadata['steps'] != null) {
        details.add('Steps: ${metadata['steps']}');
      }
      if (metadata['count'] != null) {
        details.add('Count: ${metadata['count']}');
      }
      if (details.isNotEmpty) {
        description = details.join(', ');
      }
    }

    return TimelineEvent(
      time: activity.timestamp.toLocal(),  // Convert UTC to local time for journal activities
      title: title,
      description: description,
      type: eventType,
      icon: icon,
    );
  }).toList();

  // Convert calendar events to TimelineEvent and filter all-day events
  final calendarTimelineEvents = calendarEvents
      .where((calendarEvent) {
        // For all-day events, strictly check if they belong to the selected date
        if (calendarEvent.isAllDay) {
          final eventDate = calendarEvent.startDate;
          final selectedDate = date;

          // Compare dates directly - CalendarEventData.fromEvent already
          // extracts the correct date from UTC for all-day events
          return eventDate.year == selectedDate.year &&
                 eventDate.month == selectedDate.month &&
                 eventDate.day == selectedDate.day;
        }
        // For timed events, they're already filtered by the query
        return true;
      })
      .map((calendarEvent) {
        return TimelineEvent(
          time: calendarEvent.startDate,  // Already in local time from CalendarEventData
          title: calendarEvent.title,
          description: calendarEvent.description ?? '',
          type: EventType.work, // Default calendar events to work type
          icon: Icons.event,
          isCalendarEvent: true,
          calendarEventData: calendarEvent,
        );
      }).toList();

  // Combine journal and calendar events
  final allEvents = [...journalEvents, ...calendarTimelineEvents];

  // Sort events by time
  allEvents.sort((a, b) => a.time.compareTo(b.time));

  // If no events exist, return empty list (will show empty state)
  return allEvents;
});

// Provider for loading state
final timelineLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for photos near timeline events
final timelinePhotosProvider = FutureProvider.family<List<MediaItem>, ({DateTime date, DateTime? eventTime})>((ref, params) async {
  final mediaDb = ref.watch(mediaDatabaseProvider);

  if (params.eventTime == null) return [];

  // Get photos within 30 minutes of the event time
  final startTime = params.eventTime!.subtract(const Duration(minutes: 30));
  final endTime = params.eventTime!.add(const Duration(minutes: 30));

  return await mediaDb.getMediaByDateRange(
    startDate: startTime,
    endDate: endTime,
    processedOnly: false,
    includeDeleted: false,
  );
});

enum EventType { routine, work, movement, social, exercise, leisure }

class TimelineEvent {
  final DateTime time;
  final String title;
  final String description;
  final EventType type;
  final IconData icon;
  final bool isCalendarEvent;
  final CalendarEventData? calendarEventData;

  TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
    this.isCalendarEvent = false,
    this.calendarEventData,
  });
}

class TimelineWidget extends HookConsumerWidget {
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
    final calendarNamesAsync = ref.watch(calendarMetadataProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: eventsAsync.when(
        data: (events) => calendarNamesAsync.when(
          data: (calendarNames) => events.isEmpty
              ? _buildEmptyState(theme, context, ref)
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
                      ref: ref,
                      calendarNames: calendarNames,
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ListView.builder(
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
                ref: ref,
                calendarNames: const {}, // Empty map if calendar names fail
              );
            },
          ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context, ref),
        child: const Icon(Icons.add),
        tooltip: 'Add Timeline Event',
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context, WidgetRef ref) {
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEventDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Event'),
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
    required WidgetRef ref,
    required Map<String, String> calendarNames,
  }) {
    final timeFormat = DateFormat('h:mm a');  // 12-hour format with AM/PM
    final color = _getEventColor(event.type, theme);

    // Special handling for calendar events
    final isCalendarEvent = event.isCalendarEvent;
    final eventSubtitle = _getEventSubtitle(event, calendarNames);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hide time for all-day calendar events
                  if (!(isCalendarEvent && event.calendarEventData?.isAllDay == true))
                    Text(
                      timeFormat.format(event.time),  // Already converted to local in TimelineEvent constructor
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                ],
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

                // Event dot - centered between lines
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.title,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (isCalendarEvent) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.event_note,
                                        size: 14,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ],
                                  ],
                                ),
                                // For calendar events, show duration and calendar name as subtitle
                                if (isCalendarEvent && eventSubtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    eventSubtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else if (!isCalendarEvent && event.description.isNotEmpty) ...[
                                  // For non-calendar events, show description
                                  const SizedBox(height: 4),
                                  Text(
                                    event.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],

                                // Photo thumbnails
                                _buildPhotoThumbnails(ref, event, theme),
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

                // Event dot skeleton - centered between lines
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

  Widget _buildPhotoThumbnails(WidgetRef ref, TimelineEvent event, ThemeData theme) {
    final photosAsync = ref.watch(timelinePhotosProvider((date: date, eventTime: event.time)));

    return photosAsync.when(
      data: (photos) {
        if (photos.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photos.length > 3) ...[
                Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${photos.length} photos',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.take(5).length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    final isLast = index == 4 && photos.length > 5;

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < photos.take(5).length - 1 ? 6 : 0,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedThumbnailWidget(
                              filePath: photo.filePath ?? '',
                              width: 40,
                              height: 40,
                            ),
                          ),
                          if (isLast && photos.length > 5)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${photos.length - 4}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _showAddEventDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(date: date),
    );
  }

  String? _getEventDuration(TimelineEvent event) {
    if (!event.isCalendarEvent || event.calendarEventData == null) {
      return null;
    }

    final calendarEvent = event.calendarEventData!;
    if (calendarEvent.isAllDay) {
      return 'All day';
    }

    if (calendarEvent.endDate == null) {
      return null;
    }

    final duration = calendarEvent.endDate!.difference(calendarEvent.startDate);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    } else {
      final days = duration.inDays;
      return '${days}d';
    }
  }

  String? _getEventSubtitle(TimelineEvent event, Map<String, String> calendarNames) {
    if (!event.isCalendarEvent || event.calendarEventData == null) {
      return null;
    }

    final calendarEvent = event.calendarEventData!;
    final duration = _getEventDuration(event);
    final calendarName = calendarEvent.calendarId != null
        ? calendarNames[calendarEvent.calendarId!]
        : null;

    if (duration != null && calendarName != null) {
      return '$duration • $calendarName';
    } else if (duration != null) {
      return duration;
    } else if (calendarName != null) {
      return calendarName;
    }

    return null;
  }

  String _getEventDescription(TimelineEvent event) {
    if (event.isCalendarEvent && event.calendarEventData != null) {
      final calendarEvent = event.calendarEventData!;
      final parts = <String>[];

      if (event.description.isNotEmpty) {
        parts.add(event.description);
      }

      if (calendarEvent.location != null && calendarEvent.location!.isNotEmpty) {
        parts.add('📍 ${calendarEvent.location}');
      }

      return parts.join(' • ');
    }

    return event.description;
  }

  Color _getEventColor(EventType type, ThemeData theme) {
    switch (type) {
      case EventType.routine:
        return theme.colorScheme.primary;
      case EventType.work:
        return Colors.blue;
      case EventType.movement:
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

class AddEventDialog extends HookConsumerWidget {
  final DateTime date;

  const AddEventDialog({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Choose Event Type'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: EventType.values.map((eventType) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    _getEventTypeIcon(eventType),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(_getEventTypeDisplayName(eventType)),
                subtitle: Text(_getEventTypeDescription(eventType)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddEventScreen(
                        date: date,
                        eventType: eventType,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.routine:
        return Icons.circle;
      case EventType.work:
        return Icons.work;
      case EventType.movement:
        return Icons.directions_walk;
      case EventType.social:
        return Icons.people;
      case EventType.exercise:
        return Icons.fitness_center;
      case EventType.leisure:
        return Icons.movie_outlined;
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

  String _getEventTypeDescription(EventType type) {
    switch (type) {
      case EventType.routine:
        return 'Daily habits and personal activities';
      case EventType.work:
        return 'Professional tasks and meetings';
      case EventType.movement:
        return 'Travel and location changes';
      case EventType.social:
        return 'Time spent with friends and family';
      case EventType.exercise:
        return 'Physical activities and workouts';
      case EventType.leisure:
        return 'Entertainment and relaxation';
    }
  }

  String _getActivityType(EventType type) {
    switch (type) {
      case EventType.routine:
        return 'manual';
      case EventType.work:
        return 'calendar';
      case EventType.movement:
        return 'movement';
      case EventType.social:
        return 'manual';
      case EventType.exercise:
        return 'movement';
      case EventType.leisure:
        return 'manual';
    }
  }

}

// New event creation screen
class AddEventScreen extends HookConsumerWidget {
  final DateTime date;
  final EventType eventType;

  const AddEventScreen({
    super.key,
    required this.date,
    required this.eventType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final selectedTime = useState(TimeOfDay.now());
    final isLoading = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getEventTypeDisplayName(eventType)),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event type display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        _getEventTypeIcon(eventType),
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getEventTypeDisplayName(eventType),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getEventTypeDescription(eventType),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Time picker
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Time'),
                subtitle: Text(selectedTime.value.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime.value,
                  );
                  if (time != null) {
                    selectedTime.value = time;
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            // Title field
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Enter event title',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add more details about this event',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            const Spacer(),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading.value ? null : () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a title')),
                    );
                    return;
                  }

                  isLoading.value = true;

                  try {
                    final journalService = ref.read(journalServiceProvider);
                    final eventDateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      selectedTime.value.hour,
                      selectedTime.value.minute,
                    );

                    // Create manual activity in journal database
                    await journalService.addManualActivity(
                      date: date,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      timestamp: eventDateTime,
                      activityType: _getActivityType(eventType),
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Event added successfully')),
                      );
                    }

                    // Refresh timeline events
                    ref.invalidate(timelineEventsProvider);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding event: $error')),
                      );
                    }
                  } finally {
                    isLoading.value = false;
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Add Event',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.routine:
        return Icons.circle;
      case EventType.work:
        return Icons.work;
      case EventType.movement:
        return Icons.directions_walk;
      case EventType.social:
        return Icons.people;
      case EventType.exercise:
        return Icons.fitness_center;
      case EventType.leisure:
        return Icons.movie_outlined;
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

  String _getEventTypeDescription(EventType type) {
    switch (type) {
      case EventType.routine:
        return 'Daily habits and personal activities';
      case EventType.work:
        return 'Professional tasks and meetings';
      case EventType.movement:
        return 'Travel and location changes';
      case EventType.social:
        return 'Time spent with friends and family';
      case EventType.exercise:
        return 'Physical activities and workouts';
      case EventType.leisure:
        return 'Entertainment and relaxation';
    }
  }

  String _getActivityType(EventType type) {
    switch (type) {
      case EventType.routine:
        return 'manual';
      case EventType.work:
        return 'calendar';
      case EventType.movement:
        return 'movement';
      case EventType.social:
        return 'manual';
      case EventType.exercise:
        return 'movement';
      case EventType.leisure:
        return 'manual';
    }
  }
}
