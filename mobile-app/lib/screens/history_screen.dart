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

// Provider for calendar expansion state
final calendarExpandedProvider = StateProvider<bool>((ref) => true);

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

    // State management
    final selectedDay = useState<DateTime?>(null);
    final focusedDay = useState(DateTime.now());
    final isCalendarExpanded = ref.watch(calendarExpandedProvider);

    // Reset state when navigating to this screen
    useEffect(() {
      // Reset to initial state when widget is first built
      selectedDay.value = null;
      Future.microtask(() {
        ref.read(calendarExpandedProvider.notifier).state = true;
      });
      return null;
    }, const []);

    // Animation controller for smooth transitions
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
      initialValue: isCalendarExpanded ? 1.0 : 0.0,
    );

    // Sync animation with expansion state
    useEffect(() {
      if (isCalendarExpanded) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [isCalendarExpanded]);

    // Check if we have a date from media navigation
    useEffect(() {
      final dateFromMedia = ref.read(historySelectedDateProvider);
      if (dateFromMedia != null) {
        selectedDay.value = dateFromMedia;
        focusedDay.value = dateFromMedia;
        // Delay provider modifications to avoid build phase conflicts
        Future.microtask(() {
          ref.read(calendarExpandedProvider.notifier).state = false;
          ref.read(historySelectedDateProvider.notifier).state = null;
        });
      }
      return null;
    }, []);

    // Auto-collapse when a date is selected
    useEffect(() {
      if (selectedDay.value != null && isCalendarExpanded) {
        // Delay the state change to avoid modifying provider during build
        Future.microtask(() {
          ref.read(calendarExpandedProvider.notifier).state = false;
        });
      }
      return null;
    }, [selectedDay.value]);

    // Listen to navigation from media tab
    ref.listen<DateTime?>(historySelectedDateProvider, (previous, next) {
      if (next != null) {
        selectedDay.value = next;
        focusedDay.value = next;
        // Delay provider modifications to avoid build phase conflicts
        Future.microtask(() {
          ref.read(calendarExpandedProvider.notifier).state = false;
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
              // Page header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: PageHeader(
                  icon: Icons.book,
                  title: 'Journal History',
                  subtitle: 'Browse your daily reflections',
                ),
              ),

              // Calendar section (collapsible)
              AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  final heightAnimation = Tween<double>(
                    begin: 60,
                    end: 360,
                  ).animate(CurvedAnimation(
                    parent: animationController,
                    curve: Curves.easeInOut,
                  ));

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: heightAnimation.value,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isLight
                          ? AuraColors.lightCardGradient
                          : AuraColors.darkCardGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isLight
                            ? AuraColors.lightPrimary.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: isCalendarExpanded
                          ? _buildExpandedCalendar(context, theme, ref, selectedDay, focusedDay)
                          : _buildCollapsedCalendar(context, theme, ref, selectedDay.value),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Show empty state when calendar is collapsed
              if (!isCalendarExpanded && selectedDay.value == null)
                // Show placeholder when calendar is collapsed but no date selected
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a date to view journal entry',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedCalendar(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    ValueNotifier<DateTime?> selectedDay,
    ValueNotifier<DateTime> focusedDay,
  ) {
    final recentEntriesAsync = ref.watch(recentJournalEntriesProvider);

    // Get list of dates that have journal entries
    final datesWithEntries = recentEntriesAsync.when(
      data: (entries) => entries.map((entry) => DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      )).toSet(),
      loading: () => <DateTime>{},
      error: (_, __) => <DateTime>{},
    );

    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.now(),
      focusedDay: focusedDay.value,
      calendarFormat: CalendarFormat.month,
      selectedDayPredicate: (day) {
        return selectedDay.value != null && isSameDay(selectedDay.value, day);
      },
      onDaySelected: (selected, focused) {
        selectedDay.value = selected;
        focusedDay.value = focused;
        // Navigate to Daily Canvas when a date is selected
        context.push('/daily-canvas', extra: selected);
      },
      eventLoader: (day) {
        // Return a list with one item if this day has an entry
        final normalizedDay = DateTime(day.year, day.month, day.day);
        return datesWithEntries.contains(normalizedDay) ? ['entry'] : [];
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        defaultTextStyle: theme.textTheme.bodyMedium!,
        weekendTextStyle: theme.textTheme.bodyMedium!,
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        // Style for marker dots
        markerDecoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
        markerSize: 6.0,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: theme.colorScheme.onSurface,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: theme.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        weekendStyle: theme.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildCollapsedCalendar(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    DateTime? selectedDate,
  ) {
    return GestureDetector(
      onTap: () {
        if (selectedDate != null) {
          // If a date is selected, navigate to Daily Canvas
          context.push('/daily-canvas', extra: selectedDate);
        } else {
          // Otherwise, expand the calendar to select a date
          ref.read(calendarExpandedProvider.notifier).state = true;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              selectedDate != null
                  ? DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)
                  : 'Select a date',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: selectedDate != null
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.expand_more),
              onPressed: () {
                ref.read(calendarExpandedProvider.notifier).state = true;
              },
              tooltip: 'Expand calendar',
            ),
          ],
        ),
      ),
    );
  }

}