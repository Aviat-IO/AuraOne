import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../widgets/page_header.dart';
import '../database/journal_database.dart';
import '../services/journal_service.dart';
import 'home_screen.dart'; // Import for historySelectedDateProvider
import '../widgets/daily_canvas/timeline_widget.dart';
import '../widgets/daily_canvas/map_widget.dart';
import '../widgets/daily_canvas/media_gallery_widget.dart';
import '../widgets/daily_canvas/journal_editor_widget.dart';

// Provider for sub-tab index in History screen
final historySubTabIndexProvider = StateProvider<int>((ref) => 0);

// Provider for recent journal entries to show dots on calendar
final recentJournalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  final journalService = ref.watch(journalServiceProvider);
  return journalService.watchRecentEntries(limit: 100); // Get more entries for calendar dots
});

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final tabController = useTabController(initialLength: 4);
    final currentSubTab = ref.watch(historySubTabIndexProvider);

    // State management
    final selectedDay = useState<DateTime>(DateTime.now());
    final focusedDay = useState(DateTime.now());

    // Sync tab controller with provider
    useEffect(() {
      tabController.index = currentSubTab;
      tabController.addListener(() {
        if (tabController.index != currentSubTab) {
          ref.read(historySubTabIndexProvider.notifier).state = tabController.index;
        }
      });
      return null;
    }, [currentSubTab]);


    // Check if we have a date from media navigation
    useEffect(() {
      final dateFromMedia = ref.read(historySelectedDateProvider);
      if (dateFromMedia != null) {
        selectedDay.value = dateFromMedia;
        focusedDay.value = dateFromMedia;
        // Clear the navigation date
        Future.microtask(() {
          ref.read(historySelectedDateProvider.notifier).state = null;
        });
      }
      return null;
    }, []);

    // Listen to navigation from media tab
    ref.listen<DateTime?>(historySelectedDateProvider, (previous, next) {
      if (next != null) {
        selectedDay.value = next;
        focusedDay.value = next;
        // Clear the navigation date
        Future.microtask(() {
          ref.read(historySelectedDateProvider.notifier).state = null;
        });
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight ? [
              AuraColors.lightSurface,
              AuraColors.lightSurface.withValues(alpha: 0.95),
              AuraColors.lightSurfaceContainerLow.withValues(alpha: 0.9),
            ] : [
              AuraColors.darkSurface,
              AuraColors.darkSurface.withValues(alpha: 0.98),
              AuraColors.darkSurfaceContainerLow.withValues(alpha: 0.95),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with date selector
              _buildHeader(context, theme, isLight, selectedDay, focusedDay, ref),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    _TimelineTab(date: selectedDay.value),
                    _JournalTab(date: selectedDay.value),
                    _MapTab(date: selectedDay.value),
                    _MediaTab(date: selectedDay.value),
                  ],
                ),
              ),

              // Sub-tabs at bottom (sticky) - matching main nav bar colors
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isLight
                        ? [
                            AuraColors.lightSurface.withValues(alpha: 0.95),
                            AuraColors.lightSurface,
                          ]
                        : [
                            AuraColors.darkSurface.withValues(alpha: 0.95),
                            AuraColors.darkSurface,
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLight
                        ? Colors.black.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 0), // Removed bottom margin to connect with main nav bar
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.symmetric(vertical: 6), // Add padding around indicator
                    labelColor: theme.colorScheme.onPrimaryContainer,
                    unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // Add padding to tabs
                    tabs: [
                      Tab(
                        height: 48, // Standard height with container padding
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timeline, size: 16),
                            const SizedBox(height: 4),
                            Text('Timeline', style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                      Tab(
                        height: 48,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit_note, size: 16),
                            const SizedBox(height: 4),
                            Text('Journal', style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                      Tab(
                        height: 48,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map, size: 16),
                            const SizedBox(height: 4),
                            Text('Map', style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                      Tab(
                        height: 48,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_library, size: 16),
                            const SizedBox(height: 4),
                            Text('Media', style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    ValueNotifier<DateTime> selectedDay,
    ValueNotifier<DateTime> focusedDay,
    WidgetRef ref,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date navigation
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              selectedDay.value = selectedDay.value.subtract(const Duration(days: 1));
              focusedDay.value = selectedDay.value;
            },
            tooltip: 'Previous day',
          ),

          Expanded(
            child: GestureDetector(
              onTap: () => _showCalendarPicker(context, ref, selectedDay, focusedDay),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(selectedDay.value),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigate to next day
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              if (selectedDay.value.isBefore(DateTime.now())) {
                selectedDay.value = selectedDay.value.add(const Duration(days: 1));
                focusedDay.value = selectedDay.value;
              }
            },
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }

  void _showCalendarPicker(BuildContext context, WidgetRef ref, ValueNotifier<DateTime> selectedDay, ValueNotifier<DateTime> focusedDay) async {
    final recentEntriesAsync = ref.read(recentJournalEntriesProvider);
    final datesWithEntries = recentEntriesAsync.when(
      data: (entries) => entries.map((entry) => DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      )).toSet(),
      loading: () => <DateTime>{},
      error: (_, __) => <DateTime>{},
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  // Calendar
                  Expanded(
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.now(),
                      focusedDay: focusedDay.value,
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (day) {
                        return isSameDay(selectedDay.value, day);
                      },
                      onDaySelected: (selected, focused) {
                        selectedDay.value = selected;
                        focusedDay.value = focused;
                        Navigator.of(context).pop();
                      },
                      eventLoader: (day) {
                        final normalizedDay = DateTime(day.year, day.month, day.day);
                        return datesWithEntries.contains(normalizedDay) ? ['entry'] : [];
                      },
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 1,
                        markerSize: 6.0,
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

}

// Timeline Tab Widget
class _TimelineTab extends ConsumerWidget {
  final DateTime date;

  const _TimelineTab({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TimelineWidget(date: date),
    );
  }
}

// Journal Tab Widget
class _JournalTab extends ConsumerWidget {
  final DateTime date;

  const _JournalTab({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: JournalEditorWidget(date: date),
    );
  }
}

// Map Tab Widget
class _MapTab extends ConsumerWidget {
  final DateTime date;

  const _MapTab({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: MapWidget(date: date),
    );
  }
}

// Media Tab Widget
class _MediaTab extends ConsumerWidget {
  final DateTime date;

  const _MediaTab({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: MediaGalleryWidget(date: date),
    );
  }
}