import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../widgets/daily_canvas/timeline_widget.dart';
import '../widgets/daily_canvas/map_widget.dart';
import '../widgets/daily_canvas/media_gallery_widget.dart';
import '../widgets/daily_canvas/journal_editor_widget.dart';

// Provider for selected date
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider for view mode (compact vs expanded)
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.expanded);

enum ViewMode { compact, expanded }

// Provider for active section
final activeSectionProvider = StateProvider<JournalSection?>((ref) => null);

enum JournalSection { timeline, map, media, journal }

class DailyCanvasScreen extends HookConsumerWidget {
  const DailyCanvasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final selectedDate = ref.watch(selectedDateProvider);
    final viewMode = ref.watch(viewModeProvider);
    final activeSection = ref.watch(activeSectionProvider);
    
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
              _buildHeader(context, theme, isLight, selectedDate, ref),
              
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
        ],
      ),
    );
  }
  
  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    DateTime selectedDate,
    JournalSection? activeSection,
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
              isActive: activeSection == JournalSection.timeline,
              onTap: () => ref.read(activeSectionProvider.notifier).state = 
                activeSection == JournalSection.timeline ? null : JournalSection.timeline,
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
              isActive: activeSection == JournalSection.map,
              onTap: () => ref.read(activeSectionProvider.notifier).state = 
                activeSection == JournalSection.map ? null : JournalSection.map,
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
              isActive: activeSection == JournalSection.media,
              onTap: () => ref.read(activeSectionProvider.notifier).state = 
                activeSection == JournalSection.media ? null : JournalSection.media,
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Journal',
              icon: Icons.edit_note,
              child: SizedBox(
                height: 300,
                child: JournalEditorWidget(date: selectedDate),
              ),
              theme: theme,
              isLight: isLight,
              isActive: activeSection == JournalSection.journal,
              onTap: () => ref.read(activeSectionProvider.notifier).state = 
                activeSection == JournalSection.journal ? null : JournalSection.journal,
            ),
          ],
        ),
      );
    } else {
      // Expanded view - tabbed interface
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: TabBar(
              controller: tabController,
              tabs: const [
                Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
                Tab(icon: Icon(Icons.map), text: 'Map'),
                Tab(icon: Icon(Icons.photo_library), text: 'Media'),
                Tab(icon: Icon(Icons.edit_note), text: 'Journal'),
              ],
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
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
                  child: MapWidget(date: selectedDate),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: MediaGalleryWidget(date: selectedDate),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: JournalEditorWidget(date: selectedDate),
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
    JournalSection? activeSection,
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
                    isActive: activeSection == JournalSection.timeline,
                    onTap: () => ref.read(activeSectionProvider.notifier).state = 
                      activeSection == JournalSection.timeline ? null : JournalSection.timeline,
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
                    isActive: activeSection == JournalSection.map,
                    onTap: () => ref.read(activeSectionProvider.notifier).state = 
                      activeSection == JournalSection.map ? null : JournalSection.map,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right column - Media and Journal
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: viewMode == ViewMode.compact ? 1 : 2,
                  child: _buildSectionCard(
                    title: 'Media',
                    icon: Icons.photo_library,
                    child: MediaGalleryWidget(date: selectedDate),
                    theme: theme,
                    isLight: isLight,
                    isActive: activeSection == JournalSection.media,
                    onTap: () => ref.read(activeSectionProvider.notifier).state = 
                      activeSection == JournalSection.media ? null : JournalSection.media,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: viewMode == ViewMode.compact ? 2 : 3,
                  child: _buildSectionCard(
                    title: 'Journal',
                    icon: Icons.edit_note,
                    child: JournalEditorWidget(date: selectedDate),
                    theme: theme,
                    isLight: isLight,
                    isActive: activeSection == JournalSection.journal,
                    onTap: () => ref.read(activeSectionProvider.notifier).state = 
                      activeSection == JournalSection.journal ? null : JournalSection.journal,
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
    JournalSection? activeSection,
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
              isActive: activeSection == JournalSection.timeline,
              onTap: () => ref.read(activeSectionProvider.notifier).state = 
                activeSection == JournalSection.timeline ? null : JournalSection.timeline,
            ),
          ),
          const SizedBox(width: 16),
          // Middle column - Map and Media
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: _buildSectionCard(
                    title: 'Map',
                    icon: Icons.map,
                    child: MapWidget(date: selectedDate),
                    theme: theme,
                    isLight: isLight,
                    isActive: activeSection == JournalSection.map,
                    onTap: () => ref.read(activeSectionProvider.notifier).state = 
                      activeSection == JournalSection.map ? null : JournalSection.map,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildSectionCard(
                    title: 'Media',
                    icon: Icons.photo_library,
                    child: MediaGalleryWidget(date: selectedDate),
                    theme: theme,
                    isLight: isLight,
                    isActive: activeSection == JournalSection.media,
                    onTap: () => ref.read(activeSectionProvider.notifier).state = 
                      activeSection == JournalSection.media ? null : JournalSection.media,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right column - Journal
          Expanded(
            flex: 5,
            child: _buildSectionCard(
              title: 'Journal',
              icon: Icons.edit_note,
              child: JournalEditorWidget(date: selectedDate),
              theme: theme,
              isLight: isLight,
              isActive: activeSection == JournalSection.journal,
              onTap: () => ref.read(activeSectionProvider.notifier).state = 
                activeSection == JournalSection.journal ? null : JournalSection.journal,
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
      child: const Icon(Icons.add, color: Colors.white),
      tooltip: 'Add content',
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
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement photo capture
                    },
                    theme: theme,
                  ),
                  _buildQuickAddButton(
                    icon: Icons.mic,
                    label: 'Voice',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement voice recording
                    },
                    theme: theme,
                  ),
                  _buildQuickAddButton(
                    icon: Icons.location_on,
                    label: 'Location',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement location tagging
                    },
                    theme: theme,
                  ),
                  _buildQuickAddButton(
                    icon: Icons.edit,
                    label: 'Note',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(activeSectionProvider.notifier).state = JournalSection.journal;
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
}