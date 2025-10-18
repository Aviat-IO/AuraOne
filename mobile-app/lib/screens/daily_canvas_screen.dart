import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:drift/drift.dart' as drift;
import '../theme/colors.dart';
import '../widgets/daily_canvas/timeline_widget.dart';
import '../widgets/daily_canvas/summary_widget.dart';
import '../widgets/daily_canvas/map_widget.dart';
import '../widgets/daily_canvas/media_gallery_widget.dart';
import '../widgets/common/pill_tab_bar.dart';
import '../services/media_picker_service.dart';
import '../services/journal_service.dart';
import '../providers/location_database_provider.dart';
import '../providers/location_clustering_provider.dart';
import '../database/location_database.dart';

// Provider for selected date
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailyCanvasPrefetchProvider = FutureProvider.family<void, DateTime>((ref, date) async {
  await Future.wait([
    ref.watch(clusteredLocationsProvider(date).future),
    ref.watch(recentLocationPointsProvider(const Duration(days: 7)).future),
    ref.watch(mediaItemsProvider((date: date, includeDeleted: false)).future),
  ]);
});

// Provider for view mode (compact vs expanded)
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.expanded);

enum ViewMode { compact, expanded }

// Provider for active section
final activeSectionProvider = StateProvider<CanvasSection?>((ref) => null);

enum CanvasSection { timeline, summary, map, media }

class DailyCanvasScreen extends HookConsumerWidget {
  final DateTime? date;

  const DailyCanvasScreen({super.key, this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // Use the provided date if available, otherwise use the provider value
    useEffect(() {
      if (date != null) {
        // Set the initial date when the screen is created
        Future.microtask(() {
          ref.read(selectedDateProvider.notifier).state = date!;
        });
      }
      return null;
    }, [date]);

    final selectedDate = ref.watch(selectedDateProvider);
    final viewMode = ref.watch(viewModeProvider);
    final activeSection = ref.watch(activeSectionProvider);

    final prefetchState = ref.watch(dailyCanvasPrefetchProvider(selectedDate));
    final isPrefetching = prefetchState.isLoading;

    // Animation controllers for smooth transitions
    final scrollController = useScrollController();
    final tabController = useTabController(initialLength: 4);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? [
                    AuraColors.lightSurface,
                    AuraColors.lightSurface.withValues(alpha: 0.98),
                    AuraColors.lightSurfaceContainerLow,
                  ]
                : [
                    AuraColors.darkSurface,
                    AuraColors.darkSurface.withValues(alpha: 0.98),
                    AuraColors.darkSurfaceContainerLow,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with date navigation
              _buildHeader(context, theme, isLight, selectedDate, ref, isPrefetching),

              // Main content area with responsive layout
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive breakpoints
                    final isTablet = constraints.maxWidth > 600;
                    final isDesktop = constraints.maxWidth > 900;

                    if (isDesktop) {
                      return _buildDesktopLayout(
                        context,
                        theme,
                        isLight,
                        selectedDate,
                        activeSection,
                        ref,
                      );
                    } else if (isTablet) {
                      return _buildTabletLayout(
                        context,
                        theme,
                        isLight,
                        selectedDate,
                        activeSection,
                        viewMode,
                        ref,
                      );
                    } else {
                      return _buildMobileLayout(
                        context,
                        theme,
                        isLight,
                        selectedDate,
                        activeSection,
                        viewMode,
                        scrollController,
                        tabController,
                        ref,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Floating action button for quick actions
      floatingActionButton: _buildFloatingActionButton(context, theme, isLight, ref),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    DateTime selectedDate,
    WidgetRef ref,
    bool isPrefetching,
  ) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

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
          // Back button to return to History screen
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.pop();
            },
            tooltip: 'Back to History',
          ),

          // Date navigation
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state =
                selectedDate.subtract(const Duration(days: 1));
            },
            tooltip: 'Previous day',
          ),

          Expanded(
            child: GestureDetector(
              onTap: () => _showCalendarPicker(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPrefetching)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    else
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(selectedDate),
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

          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: selectedDate.isBefore(
              DateTime.now().subtract(const Duration(hours: 23)),
            )
                ? () {
                    ref.read(selectedDateProvider.notifier).state =
                      selectedDate.add(const Duration(days: 1));
                  }
                : null,
            tooltip: 'Next day',
          ),

          // View mode toggle
          IconButton(
            icon: Icon(
              ref.watch(viewModeProvider) == ViewMode.compact
                  ? Icons.expand
                  : Icons.compress,
            ),
            onPressed: () {
              final current = ref.read(viewModeProvider);
              ref.read(viewModeProvider.notifier).state =
                current == ViewMode.compact ? ViewMode.expanded : ViewMode.compact;
            },
            tooltip: 'Toggle view mode',
          ),

          // More options menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'regenerate') {
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Regenerate Journal Entry'),
                    content: const Text(
                      'This will regenerate the journal entry for the selected date with the latest clustering logic. Continue?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Regenerate'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  try {
                    final journalService = ref.read(journalServiceProvider);
                    await journalService.regenerateEntryForDate(selectedDate);
                    if (context.mounted) {
                      Fluttertoast.showToast(
                        msg: 'Journal entry regenerated successfully',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Fluttertoast.showToast(
                        msg: 'Failed to regenerate entry: $e',
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'regenerate',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 12),
                    Text('Regenerate Entry'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    DateTime selectedDate,
    CanvasSection? activeSection,
    ViewMode viewMode,
    ScrollController scrollController,
    TabController tabController,
    WidgetRef ref,
  ) {
    if (viewMode == ViewMode.compact) {
      // Compact view - all sections in a scrollable column
      return SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Timeline',
              icon: Icons.timeline,
              child: SizedBox(
                height: 200,
                child: TimelineWidget(date: selectedDate),
              ),
              theme: theme,
              isLight: isLight,
              isActive: activeSection == CanvasSection.timeline,
              onTap: () => ref.read(activeSectionProvider.notifier).state =
                activeSection == CanvasSection.timeline ? null : CanvasSection.timeline,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Summary',
              icon: Icons.insights,
              child: SizedBox(
                height: 200,
                child: SummaryWidget(date: selectedDate),
              ),
              theme: theme,
              isLight: isLight,
              isActive: activeSection == CanvasSection.summary,
              onTap: () => ref.read(activeSectionProvider.notifier).state =
                activeSection == CanvasSection.summary ? null : CanvasSection.summary,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Map',
              icon: Icons.map,
              child: SizedBox(
                height: 200,
                child: MapWidget(date: selectedDate),
              ),
              theme: theme,
              isLight: isLight,
              isActive: activeSection == CanvasSection.map,
              onTap: () => ref.read(activeSectionProvider.notifier).state =
                activeSection == CanvasSection.map ? null : CanvasSection.map,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Media',
              icon: Icons.photo_library,
              child: SizedBox(
                height: 200,
                child: MediaGalleryWidget(date: selectedDate),
              ),
              theme: theme,
              isLight: isLight,
              isActive: activeSection == CanvasSection.media,
              onTap: () => ref.read(activeSectionProvider.notifier).state =
                activeSection == CanvasSection.media ? null : CanvasSection.media,
            ),
          ],
        ),
      );
    } else {
      // Expanded view - tabbed interface
      return Column(
        children: [
          PillTabBar(
            controller: tabController,
            items: const [
              PillTabItem(icon: Icons.timeline, label: 'Timeline'),
              PillTabItem(icon: Icons.insights, label: 'Summary'),
              PillTabItem(icon: Icons.map, label: 'Map'),
              PillTabItem(icon: Icons.photo_library, label: 'Media'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TimelineWidget(date: selectedDate),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SummaryWidget(date: selectedDate),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: MapWidget(date: selectedDate),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: MediaGalleryWidget(date: selectedDate),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildTabletLayout(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    DateTime selectedDate,
    CanvasSection? activeSection,
    ViewMode viewMode,
    WidgetRef ref,
  ) {
    // 2-column layout for tablets
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - Timeline and Map
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildSectionCard(
                    title: 'Timeline',
                    icon: Icons.timeline,
                    child: TimelineWidget(date: selectedDate),
                    theme: theme,
                    isLight: isLight,
                    isActive: activeSection == CanvasSection.timeline,
                    onTap: () => ref.read(activeSectionProvider.notifier).state =
                      activeSection == CanvasSection.timeline ? null : CanvasSection.timeline,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildSectionCard(
                    title: 'Map',
                    icon: Icons.map,
                    child: MapWidget(date: selectedDate),
                    theme: theme,
                    isLight: isLight,
                    isActive: activeSection == CanvasSection.map,
                    onTap: () => ref.read(activeSectionProvider.notifier).state =
                      activeSection == CanvasSection.map ? null : CanvasSection.map,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right column - Summary and Media
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: viewMode == ViewMode.compact ? 1 : 2,
                  child: _buildSectionCard(
                    title: 'Summary',
                    icon: Icons.insights,
                    child: SummaryWidget(date: selectedDate),
                    theme: theme,
                    isLight: isLight,
                    isActive: activeSection == CanvasSection.summary,
                    onTap: () => ref.read(activeSectionProvider.notifier).state =
                      activeSection == CanvasSection.summary ? null : CanvasSection.summary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: viewMode == ViewMode.compact ? 2 : 3,
                  child: _buildSectionCard(
                    title: 'Media',
                    icon: Icons.photo_library,
                    child: MediaGalleryWidget(date: selectedDate),
                    theme: theme,
                    isLight: isLight,
                    isActive: activeSection == CanvasSection.media,
                    onTap: () => ref.read(activeSectionProvider.notifier).state =
                      activeSection == CanvasSection.media ? null : CanvasSection.media,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    DateTime selectedDate,
    CanvasSection? activeSection,
    WidgetRef ref,
  ) {
    // 3-column layout for desktop
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - Timeline
          Expanded(
            flex: 3,
            child: _buildSectionCard(
              title: 'Timeline',
              icon: Icons.timeline,
              child: TimelineWidget(date: selectedDate),
              theme: theme,
              isLight: isLight,
              isActive: activeSection == CanvasSection.timeline,
              onTap: () => ref.read(activeSectionProvider.notifier).state =
                activeSection == CanvasSection.timeline ? null : CanvasSection.timeline,
            ),
          ),
          const SizedBox(width: 16),
          // Middle column - Summary and Map
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: _buildSectionCard(
                    title: 'Summary',
                    icon: Icons.insights,
                    child: SummaryWidget(date: selectedDate),
                    theme: theme,
                    isLight: isLight,
                    isActive: activeSection == CanvasSection.summary,
                    onTap: () => ref.read(activeSectionProvider.notifier).state =
                      activeSection == CanvasSection.summary ? null : CanvasSection.summary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildSectionCard(
                    title: 'Map',
                    icon: Icons.map,
                    child: MapWidget(date: selectedDate),
                    theme: theme,
                    isLight: isLight,
                    isActive: activeSection == CanvasSection.map,
                    onTap: () => ref.read(activeSectionProvider.notifier).state =
                      activeSection == CanvasSection.map ? null : CanvasSection.map,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right column - Media
          Expanded(
            flex: 5,
            child: _buildSectionCard(
              title: 'Media',
              icon: Icons.photo_library,
              child: MediaGalleryWidget(date: selectedDate),
              theme: theme,
              isLight: isLight,
              isActive: activeSection == CanvasSection.media,
              onTap: () => ref.read(activeSectionProvider.notifier).state =
                activeSection == CanvasSection.media ? null : CanvasSection.media,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    required ThemeData theme,
    required bool isLight,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? (isActive
                  ? [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                    ]
                  : AuraColors.lightCardGradient)
              : (isActive
                  ? [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                    ]
                  : AuraColors.darkCardGradient),
        ),
        border: isActive
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isLight
                ? (isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05))
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: isActive ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isActive ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          // Section content
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    WidgetRef ref,
  ) {
    return FloatingActionButton(
      onPressed: () => _showQuickAddMenu(context, theme, ref),
      backgroundColor: theme.colorScheme.primary,
      tooltip: 'Add content',
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showCalendarPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final selectedDate = ref.watch(selectedDateProvider);

        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.now(),
                  focusedDay: selectedDate,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                  onDaySelected: (selected, focused) {
                    ref.read(selectedDateProvider.notifier).state = selected;
                    Navigator.pop(context);
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: theme.textTheme.titleLarge!,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickAddMenu(BuildContext context, ThemeData theme, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Add',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAddButton(
                    icon: Icons.camera_alt,
                    label: 'Photo',
                    onTap: () async {
                      Navigator.pop(context);
                      await _handlePhotoCapture(context, ref);
                    },
                    theme: theme,
                  ),
                  _buildQuickAddButton(
                    icon: Icons.mic,
                    label: 'Voice',
                    onTap: () async {
                      Navigator.pop(context);
                      await _handleVoiceRecording(context, ref);
                    },
                    theme: theme,
                  ),
                  _buildQuickAddButton(
                    icon: Icons.location_on,
                    label: 'Location',
                    onTap: () async {
                      Navigator.pop(context);
                      await _handleLocationTagging(context, ref);
                    },
                    theme: theme,
                  ),
                  _buildQuickAddButton(
                    icon: Icons.edit,
                    label: 'Note',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(activeSectionProvider.notifier).state = CanvasSection.timeline;
                    },
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAddButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // Implementation for Photo Capture
  Future<void> _handlePhotoCapture(BuildContext context, WidgetRef ref) async {
    try {
      final mediaPickerService = ref.read(mediaPickerServiceProvider);

      // Show media picker options (camera or gallery)
      final photoPath = await mediaPickerService.showMediaPickerOptions(context);

      if (photoPath != null) {
        // Get the selected date for the journal entry
        final selectedDate = ref.read(selectedDateProvider);
        final journalService = ref.read(journalServiceProvider);

        // Add media to the journal entry for the selected date
        await journalService.addMediaToJournalEntry(
          selectedDate,
          photoPath,
          'photo',
        );

        Fluttertoast.showToast(
          msg: 'Photo added to journal',
          toastLength: Toast.LENGTH_SHORT,
        );

        // Refresh the media gallery if it's active
        if (ref.read(activeSectionProvider) == CanvasSection.media) {
          // Media gallery will auto-refresh via its provider
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to capture photo: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
      );
    }
  }

  // Implementation for Voice Recording (disabled - audio recording package removed)
  Future<void> _handleVoiceRecording(BuildContext context, WidgetRef ref) async {
    Fluttertoast.showToast(
      msg: 'Voice recording feature is currently unavailable',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  // Implementation for Location Tagging
  Future<void> _handleLocationTagging(BuildContext context, WidgetRef ref) async {
    try {
      // Check location permission
      final locationPermission = await Permission.location.request();

      if (!locationPermission.isGranted) {
        Fluttertoast.showToast(
          msg: 'Location permission required',
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Save location to database
      final locationDb = ref.read(locationDatabaseProvider);
      final selectedDate = ref.read(selectedDateProvider);

      // Create location point
      final locationPoint = LocationPointsCompanion(
        timestamp: drift.Value(DateTime.now()),
        latitude: drift.Value(position.latitude),
        longitude: drift.Value(position.longitude),
        altitude: drift.Value(position.altitude),
        accuracy: drift.Value(position.accuracy),
        speed: drift.Value(position.speed),
        heading: drift.Value(position.heading),
        isSignificant: const drift.Value(true),
        activityType: const drift.Value('stationary'),
      );

      await locationDb.insertLocationPoint(locationPoint);

      // Also add as a journal activity
      final journalService = ref.read(journalServiceProvider);
      await journalService.addLocationToJournalEntry(
        selectedDate,
        position.latitude,
        position.longitude,
        'Manual location tag',
      );

      Fluttertoast.showToast(
        msg: 'Location tagged successfully',
        toastLength: Toast.LENGTH_SHORT,
      );

      // Switch to map view to show the tagged location
      ref.read(activeSectionProvider.notifier).state = CanvasSection.map;
    } catch (e) {
      String errorMsg = 'Failed to tag location';
      if (e.toString().contains('timeout')) {
        errorMsg = 'Location timeout - try again with better signal';
      } else if (e.toString().contains('denied')) {
        errorMsg = 'Location permission denied';
      }

      Fluttertoast.showToast(
        msg: errorMsg,
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
      );
    }
  }
}

// Voice Recording Dialog Widget
