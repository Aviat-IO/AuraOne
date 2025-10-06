import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../database/journal_database.dart';
import '../services/journal_service.dart';
import '../widgets/daily_entry_view.dart';
import '../providers/preload_provider.dart';
import 'home_screen.dart'; // Import for historySelectedDateProvider
import 'main_layout_screen.dart'; // Import for selectedTabIndexProvider

// Provider for recent journal entries to show dots on calendar
final recentJournalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  final journalService = ref.watch(journalServiceProvider);
  return journalService.watchRecentEntries(limit: 100); // Get more entries for calendar dots
});

// Provider for persistent selected date in history
final historySelectedDatePersistentProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider to track if user has ever selected a date in history
final hasUserSelectedHistoryDateProvider = StateProvider<bool>((ref) => false);

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // State management - use persistent provider for selected date
    final persistentSelectedDate = ref.watch(historySelectedDatePersistentProvider);
    final selectedDay = useState<DateTime>(persistentSelectedDate);
    final focusedDay = useState<DateTime>(persistentSelectedDate);
    final hasShownCalendar = useState<bool>(false);

    // Preload data for the selected date in the background
    ref.watch(preloadProvider(selectedDay.value));

    // Update local state when persistent state changes
    useEffect(() {
      selectedDay.value = persistentSelectedDate;
      focusedDay.value = persistentSelectedDate;
      // Ensure keyboard is hidden when date changes
      FocusManager.instance.primaryFocus?.unfocus();
      return null;
    }, [persistentSelectedDate]);

    // Listen for tab changes to auto-show calendar when navigating to History tab
    ref.listen<int>(selectedTabIndexProvider, (previous, current) {
      if (current == 1 && previous != 1) { // History tab is at index 1
        // Reset to Journal subtab when navigating to History
        ref.read(dailyEntrySubTabIndexProvider.notifier).state = 0;

        // Only show calendar automatically if user hasn't selected a date before
        final hasSelectedDate = ref.read(hasUserSelectedHistoryDateProvider);
        if (!hasSelectedDate) {
          // Reset the flag when navigating to history tab
          hasShownCalendar.value = false;
          // Show calendar after a brief delay to allow the screen to render
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted && !hasShownCalendar.value) {
              hasShownCalendar.value = true;
              _showCalendarPicker(context, ref, selectedDay, focusedDay);
            }
          });
        }
      }
    });

    // Check if we have a date from media navigation
    useEffect(() {
      final dateFromMedia = ref.read(historySelectedDateProvider);
      if (dateFromMedia != null) {
        selectedDay.value = dateFromMedia;
        focusedDay.value = dateFromMedia;
        // Update persistent provider
        ref.read(historySelectedDatePersistentProvider.notifier).state = dateFromMedia;
        // Mark that user has selected a date (via media navigation)
        ref.read(hasUserSelectedHistoryDateProvider.notifier).state = true;
        // Reset to Journal subtab
        ref.read(dailyEntrySubTabIndexProvider.notifier).state = 0;
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
        // Update persistent provider
        ref.read(historySelectedDatePersistentProvider.notifier).state = next;
        // Mark that user has selected a date (via media navigation)
        ref.read(hasUserSelectedHistoryDateProvider.notifier).state = true;
        // Reset to Journal subtab
        ref.read(dailyEntrySubTabIndexProvider.notifier).state = 0;
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

              // Daily Entry View for selected date
              Expanded(
                child: GestureDetector(
                  // Unfocus text fields when tapping outside
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: DailyEntryView(
                    date: selectedDay.value,
                    enableAI: true, // Enable AI for history entries too
                    enableMediaSelection: false, // Disable media selection for history (read-only)
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
              final newDate = selectedDay.value.subtract(const Duration(days: 1));
              selectedDay.value = newDate;
              focusedDay.value = newDate;
              // Update persistent provider
              ref.read(historySelectedDatePersistentProvider.notifier).state = newDate;
              // Mark that user has selected a date
              ref.read(hasUserSelectedHistoryDateProvider.notifier).state = true;
              // Don't reset sub-tab - stay on current tab (Timeline, Map, etc.)
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
                final newDate = selectedDay.value.add(const Duration(days: 1));
                selectedDay.value = newDate;
                focusedDay.value = newDate;
                // Update persistent provider
                ref.read(historySelectedDatePersistentProvider.notifier).state = newDate;
                // Mark that user has selected a date
                ref.read(hasUserSelectedHistoryDateProvider.notifier).state = true;
                // Don't reset sub-tab - stay on current tab (Timeline, Map, etc.)
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
                        // Update persistent provider
                        ref.read(historySelectedDatePersistentProvider.notifier).state = selected;
                        // Mark that user has selected a date
                        ref.read(hasUserSelectedHistoryDateProvider.notifier).state = true;
                        // Don't reset sub-tab - stay on current tab (Timeline, Map, etc.)
                        // Close the modal first
                        Navigator.of(context).pop();
                        // Then ensure focus is cleared after modal animation completes
                        Future.delayed(const Duration(milliseconds: 350), () {
                          FocusManager.instance.primaryFocus?.unfocus();
                        });
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
                        // Make weekends look the same as weekdays
                        weekendTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        defaultTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
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