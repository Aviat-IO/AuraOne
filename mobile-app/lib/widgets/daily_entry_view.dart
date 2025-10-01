import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:drift/drift.dart' show Value;
import '../theme/colors.dart';
import '../widgets/daily_canvas/timeline_widget.dart';
import '../widgets/daily_canvas/map_widget.dart';
import '../widgets/daily_canvas/media_gallery_widget.dart';
import '../database/journal_database.dart';
import '../providers/media_database_provider.dart';
import '../providers/photo_service_provider.dart';
import '../providers/location_clustering_provider.dart';
import '../services/journal_service.dart';
import '../services/ai/hybrid_ai_service.dart';

// Provider for sub-tab index in DailyEntryView - default to Journal (index 0)
final dailyEntrySubTabIndexProvider = StateProvider<int>((ref) => 0);

class DailyEntryView extends HookConsumerWidget {
  final DateTime date;
  final bool enableAI;
  final bool enableMediaSelection;

  const DailyEntryView({
    super.key,
    required this.date,
    this.enableAI = true,
    this.enableMediaSelection = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final tabController = useTabController(initialLength: 4);
    final currentSubTab = ref.watch(dailyEntrySubTabIndexProvider);

    // Sync tab controller with provider
    useEffect(() {
      tabController.index = currentSubTab;
      tabController.addListener(() {
        if (tabController.index != currentSubTab) {
          ref.read(dailyEntrySubTabIndexProvider.notifier).state = tabController.index;
        }
      });
      return null;
    }, [currentSubTab]);

    return Column(
      children: [
        // Tab content
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _JournalTab(date: date, enableAI: enableAI),
              _TimelineTab(date: date),
              _MapTab(date: date),
              _MediaTab(date: date, enableSelection: enableMediaSelection),
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
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
              indicatorPadding: const EdgeInsets.symmetric(vertical: 6),
              labelColor: theme.colorScheme.onPrimaryContainer,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              tabs: [
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
    );
  }
}

// Journal Tab Widget with AI Generation
class _JournalTab extends HookConsumerWidget {
  final DateTime date;
  final bool enableAI;

  const _JournalTab({required this.date, this.enableAI = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final journalService = ref.watch(journalServiceProvider);
    final mediaDb = ref.watch(mediaDatabaseProvider);

    // State for this specific date's journal entry
    final journalEntry = useState<String?>(null);
    final isEditing = useState(false);
    final controller = useTextEditingController();
    final isGenerating = useState(false);
    final aiService = useMemoized(() => HybridAIService(), []);
    final textFieldFocusNode = useFocusNode();

    // Add a flag to prevent any focus for the first 500ms after mount
    final canFocus = useState(false);

    // Prevent focus on first load - ensure edit mode is false and no keyboard
    useEffect(() {
      // Force edit mode to false on mount
      isEditing.value = false;
      canFocus.value = false;

      // Ensure keyboard doesn't pop up on first load - unfocus multiple times to be sure
      WidgetsBinding.instance.addPostFrameCallback((_) {
        textFieldFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();

        // Double-check after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            textFieldFocusNode.unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          }
        });

        // Additional check after a longer delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            textFieldFocusNode.unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          }
        });

        // Allow focus only after 500ms to prevent any auto-focus behavior
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            canFocus.value = true;
          }
        });
      });
      return null;
    }, []);

    // Function to load existing journal entry for this date
    Future<void> loadEntry() async {
      try {
        final entry = await journalService.getEntryForDate(date);
        if (entry != null && context.mounted) {
          journalEntry.value = entry.content;
          controller.text = entry.content;
        }
      } catch (e) {
        // Handle error silently
      }
    }

    // Format date helper function
    String formatDate(DateTime date) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    // Load existing journal entry for this date
    useEffect(() {
      // Reset journal entry when date changes to prevent showing old data
      journalEntry.value = null;
      controller.text = '';
      loadEntry();
      return null;
    }, [date]);

    // Calculate stats for AI generation (if enabled)
    final dayStart = DateTime(date.year, date.month, date.day);

    // Get photos count for this specific date
    final photosCountAsync = useMemoized(
      () => mediaDb.getRecentMedia(duration: const Duration(days: 7), limit: 500),
      [date],
    );
    final photosFuture = useFuture(photosCountAsync);
    final dayPhotos = photosFuture.data?.where((item) {
      return item.createdDate.year == dayStart.year &&
             item.createdDate.month == dayStart.month &&
             item.createdDate.day == dayStart.day &&
             !item.isDeleted; // Only count included photos
    }).toList() ?? [];
    final photosCount = dayPhotos.length;

    // Get unique locations count using DBSCAN clustering for this specific date
    final locationsCountAsync = ref.watch(uniqueLocationsCountProvider(date));
    final locationsCount = locationsCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    // Function to generate AI summary for this specific date
    Future<void> generateSummary() async {
      if (!enableAI) return;

      isGenerating.value = true;
      try {
        if (!aiService.isInitialized) {
          await aiService.initialize(); // Initialize without API key - will use on-device AI
        }

        // Create context with available data
        final journalContext = {
          'date': date.toIso8601String(),
          'photosCount': photosCount,
          'locationsCount': locationsCount,
        };

        final result = await aiService.generateJournalEntry(journalContext);
        final content = result['content'] as String? ?? '';

        if (context.mounted && content.isNotEmpty) {
          journalEntry.value = content;
          controller.text = content;

          // Automatically save the AI-generated content
          try {
            // Get existing entry first
            final existingEntry = await journalService.getEntryForDate(date);

            if (existingEntry != null) {
              // Update existing entry with AI-generated content
              await journalService.updateJournalEntry(
                id: existingEntry.id,
                content: content,
              );
            } else {
              // Create new entry with AI-generated content
              final db = ref.read(journalDatabaseProvider);
              await db.insertJournalEntry(
                JournalEntriesCompanion(
                  date: Value(DateTime(date.year, date.month, date.day)),
                  title: Value('AI Journal - ${formatDate(date)}'),
                  content: Value(content),
                  summary: Value(content.length > 100
                      ? '${content.substring(0, 100)}...'
                      : content),
                  isAutoGenerated: const Value(true),
                  isEdited: const Value(false),
                  createdAt: Value(DateTime.now()),
                  updatedAt: Value(DateTime.now()),
                ),
              );
            }

            // Reload the entry to ensure we have the latest data from database
            await loadEntry();
          } catch (e) {
            // Handle save error silently but keep the generated content in UI
          }
        }
      } catch (e) {
        // Handle errors silently
      } finally {
        if (context.mounted) {
          isGenerating.value = false;
        }
      }
    }

    // Save journal entry
    Future<void> saveEntry() async {
      try {
        // Get existing entry first
        final existingEntry = await journalService.getEntryForDate(date);

        if (existingEntry != null) {
          // Update existing entry
          await journalService.updateJournalEntry(
            id: existingEntry.id,
            content: controller.text,
            title: existingEntry.title, // Keep existing title
          );
        } else {
          // Create new entry
          final db = ref.read(journalDatabaseProvider);
          await db.insertJournalEntry(
            JournalEntriesCompanion(
              date: Value(DateTime(date.year, date.month, date.day)),
              title: Value('Journal Entry - ${formatDate(date)}'),
              content: Value(controller.text),
              summary: Value(controller.text.length > 100
                  ? '${controller.text.substring(0, 100)}...'
                  : controller.text),
              isAutoGenerated: const Value(false),
              isEdited: const Value(true),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
        journalEntry.value = controller.text;

        // Reload the entry to ensure we have the latest data
        await loadEntry();
      } catch (e) {
        // Handle error silently
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-Enhanced Journal Entry Card
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              enableAI ? Icons.auto_awesome : Icons.edit_note,
                              color: theme.colorScheme.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                "Journal Entry",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Generate/Refresh button (only if AI enabled)
                          if (enableAI && !isEditing.value)
                            IconButton(
                              icon: isGenerating.value
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    journalEntry.value != null ? Icons.refresh : Icons.add_circle_outline,
                                    color: theme.colorScheme.primary,
                                  ),
                              onPressed: isGenerating.value ? null : generateSummary,
                              tooltip: journalEntry.value != null ? 'Regenerate Summary' : 'Generate Summary',
                            ),
                          // Edit button
                          IconButton(
                            icon: Icon(
                              isEditing.value ? Icons.check : Icons.edit,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: !canFocus.value ? null : () async {
                              // Only allow editing after initial delay to prevent auto-focus
                              if (!canFocus.value) return;

                              if (isEditing.value) {
                                await saveEntry();
                                // Unfocus when exiting edit mode
                                textFieldFocusNode.unfocus();
                              } else {
                                // When entering edit mode, only focus if user explicitly wants to edit
                                // Don't auto-focus to prevent unwanted keyboard popup
                              }
                              isEditing.value = !isEditing.value;
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isEditing.value
                      ? TextField(
                          controller: controller,
                          focusNode: textFieldFocusNode,
                          autofocus: false,
                          readOnly: !canFocus.value, // Prevent any interaction until ready
                          enableInteractiveSelection: canFocus.value,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Write about this day...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                          ),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                        )
                      : journalEntry.value != null && journalEntry.value!.isNotEmpty
                        ? Text(
                            journalEntry.value!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                            ),
                          )
                        : _buildEmptyState(theme, enableAI && (photosCount > 0 || locationsCount > 0)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool hasDataForAI) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasDataForAI ? Icons.auto_awesome : Icons.edit_note,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasDataForAI
              ? 'Tap the ✨ button to generate an AI summary'
              : 'No journal entry for this date',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (!hasDataForAI) ...[
            const SizedBox(height: 8),
            Text(
              'Tap the edit button to start writing',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
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

// Media Tab Widget with Selection Capabilities
class _MediaTab extends HookConsumerWidget {
  final DateTime date;
  final bool enableSelection;

  const _MediaTab({required this.date, this.enableSelection = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoService = ref.watch(photoServiceProvider);
    final isLoading = useState(false);
    final hasScanned = useState(false);

    // Get day's media
    final dayStart = DateTime(date.year, date.month, date.day);

    // Scan and index photos on first mount (if it's today)
    useEffect(() {
      final isToday = dayStart.year == DateTime.now().year &&
                     dayStart.month == DateTime.now().month &&
                     dayStart.day == DateTime.now().day;

      if (isToday && !hasScanned.value) {
        Future<void> scanPhotos() async {
          hasScanned.value = true;
          isLoading.value = true;
          try {
            final permission = await Permission.photos.request();
            if (permission.isGranted || permission.isLimited) {
              await photoService.scanAndIndexTodayPhotos();
            }
          } catch (e) {
            // Handle error silently
          } finally {
            if (context.mounted) {
              isLoading.value = false;
            }
          }
        }
        scanPhotos();
      }
      return null;
    }, [date]);

    // For the unified component, we can use the existing MediaGalleryWidget
    // which already handles date-specific media display
    return Container(
      padding: const EdgeInsets.all(16),
      child: MediaGalleryWidget(
        date: date,
        enableSelection: enableSelection,
      ),
    );
  }
}