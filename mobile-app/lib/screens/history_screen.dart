import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/colors.dart';
import '../widgets/page_header.dart';
import '../services/calendar_service.dart';
import '../providers/service_providers.dart';
import 'home_screen.dart'; // Import for historySelectedDateProvider

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month; // Fixed to month view
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEventData>> _journalEntries = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Check if we have a date from media navigation
    final dateFromMedia = ref.read(historySelectedDateProvider);
    if (dateFromMedia != null) {
      _selectedDay = dateFromMedia;
      _focusedDay = dateFromMedia;
      // Clear the provider after consuming it
      Future.microtask(() {
        ref.read(historySelectedDateProvider.notifier).state = null;
      });
    } else {
      _selectedDay = _focusedDay;
    }
    
    _loadCalendarEntries();
  }

  Future<void> _loadCalendarEntries() async {
    try {
      final calendarService = ref.read(calendarServiceProvider);
      
      // Load entries for the current month and surrounding months
      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
      
      final entries = await calendarService.getJournalSummaryEntries(
        startDate: startDate,
        endDate: endDate,
      );
      
      // Group entries by date
      final Map<DateTime, List<CalendarEventData>> groupedEntries = {};
      for (final entry in entries) {
        final dateKey = DateTime(
          entry.startDate.year,
          entry.startDate.month,
          entry.startDate.day,
        );
        if (!groupedEntries.containsKey(dateKey)) {
          groupedEntries[dateKey] = [];
        }
        groupedEntries[dateKey]!.add(entry);
      }
      
      setState(() {
        _journalEntries = groupedEntries;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<CalendarEventData> _getEntriesForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _journalEntries[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    // Listen to navigation from media tab
    ref.listen<DateTime?>(historySelectedDateProvider, (previous, next) {
      if (next != null && mounted) {
        setState(() {
          _selectedDay = next;
          _focusedDay = next;
        });
        // Clear the provider after consuming it
        Future.microtask(() {
          ref.read(historySelectedDateProvider.notifier).state = null;
        });
        // Reload entries if needed for the new month
        _loadCalendarEntries();
      }
    });

    if (_isLoading) {
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
          child: const SafeArea(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // History header
                PageHeader(
                  icon: Icons.book,
                  title: 'Journal History',
                  subtitle:
                  'Find your past entries',
                ),
                const SizedBox(height: 24),

                // Calendar widget
                Container(
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
                  child: TableCalendar<String>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) {
                      // Convert CalendarEventData to List<String> for the calendar widget
                      final events = _getEntriesForDay(day);
                      return events.map((e) => e.title).toList();
                    },
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ) ?? TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      holidayTextStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ) ?? TextStyle(
                        color: theme.colorScheme.primary,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      markerSize: 6,
                      markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                    ),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false, // Hide format toggle button
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: theme.colorScheme.primary,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) {
                      setState(() {
                        _focusedDay = focused;
                      });
                      // Load more entries if needed
                      _loadCalendarEntries();
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Selected day entries
                Expanded(
                  child: _selectedDay != null
                      ? _buildSelectedDayEntries(theme, isLight, _selectedDay!, _getEntriesForDay(_selectedDay!))
                      : _buildNoSelectionPlaceholder(theme, isLight),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayEntries(ThemeData theme, bool isLight, DateTime selectedDate, List<CalendarEventData> entries) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entries for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (entries.isEmpty)
          Expanded(
            child: Container(
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No entries for this day',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your wellness journey by\\ncreating your first entry',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
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
                          ? AuraColors.lightPrimary.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      entry.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Created: ${entry.startDate.day}/${entry.startDate.month}/${entry.startDate.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    children: [
                      if (entry.description != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            entry.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
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
    );
  }

  Widget _buildNoSelectionPlaceholder(ThemeData theme, bool isLight) {
    return Container(
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a Date',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap on a date to view\\nyour journal entries',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
