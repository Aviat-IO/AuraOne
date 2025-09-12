import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart';
import '../widgets/page_header.dart';
import '../database/media_database.dart';
import '../services/simple_location_service.dart';
import '../providers/media_database_provider.dart';
import '../services/ai/enhanced_ai_service.dart';
import '../services/ai/narrative_generation.dart';
import '../providers/location_database_provider.dart';
import '../database/location_database.dart' as loc_db;
import '../providers/photo_service_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main_layout_screen.dart'; // Import for selectedTabIndexProvider

// Provider to store the current day's journal entry
final todayJournalEntryProvider = StateProvider<String?>((ref) => null);

// Provider for sub-tab index
final homeSubTabIndexProvider = StateProvider<int>((ref) => 0);

// Provider for history screen selected date (used when navigating from media)
final historySelectedDateProvider = StateProvider<DateTime?>((ref) => null);

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final tabController = useTabController(initialLength: 3);
    final currentSubTab = ref.watch(homeSubTabIndexProvider);

    // Sync tab controller with provider
    useEffect(() {
      tabController.index = currentSubTab;
      tabController.addListener(() {
        if (tabController.index != currentSubTab) {
          ref.read(homeSubTabIndexProvider.notifier).state = tabController.index;
        }
      });
      return null;
    }, [currentSubTab]);

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
              // Header - consistent across all tabs
              Padding(
                padding: const EdgeInsets.all(16),
                child: PageHeader(
                  icon: Icons.home,
                  title: _getGreeting(),
                  subtitle: _getFormattedDate(),
                ),
              ),
              // Tab content without header
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    _OverviewTab(),
                    _MapTab(),
                    _MediaTab(),
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
                            const Icon(Icons.dashboard, size: 16), // Reduced from 20
                            const SizedBox(height: 4),
                            Text('Overview', style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                      Tab(
                        height: 48,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map, size: 16), // Reduced from 20
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
                            const Icon(Icons.photo_library, size: 16), // Reduced from 20
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];
    final month = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][now.month - 1];
    return '$weekday, $month ${now.day}';
  }
}

// Overview Tab
class _OverviewTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final journalEntry = ref.watch(todayJournalEntryProvider);
    final isEditing = useState(false);
    final controller = useTextEditingController(text: journalEntry ?? '');
    final isLoading = useState(false);
    final isGenerating = useState(false);
    final aiService = ref.watch(enhancedAIServiceProvider);

    // Get today's stats
    final mediaDb = ref.watch(mediaDatabaseProvider);

    // Calculate stats
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Get photos count - using getRecentMedia for today's photos
    final photosCountAsync = useMemoized(
      () => mediaDb.getRecentMedia(duration: const Duration(days: 2), limit: 500),
      [todayStart],
    );
    final photosFuture = useFuture(photosCountAsync);
    final todayPhotos = photosFuture.data?.where((item) {
      return item.createdDate.year == todayStart.year &&
             item.createdDate.month == todayStart.month &&
             item.createdDate.day == todayStart.day;
    }).toList() ?? [];
    final photosCount = todayPhotos.length;

    // Get locations count from database
    final locationStream = ref.watch(recentLocationPointsProvider(const Duration(hours: 24)));
    final locationHistory = locationStream.maybeWhen(
      data: (locations) => locations,
      orElse: () => <loc_db.LocationPoint>[],
    );
    final locationsCount = locationHistory
        .where((loc) => loc.timestamp.isAfter(todayStart) && loc.timestamp.isBefore(todayEnd))
        .length;

    // Calculate distance traveled
    double distanceTraveled = 0;
    final todayLocations = locationHistory
        .where((loc) => loc.timestamp.isAfter(todayStart) && loc.timestamp.isBefore(todayEnd))
        .toList();
    for (int i = 1; i < todayLocations.length; i++) {
      distanceTraveled += _calculateDistance(
        todayLocations[i-1].latitude,
        todayLocations[i-1].longitude,
        todayLocations[i].latitude,
        todayLocations[i].longitude,
      );
    }

    // Calculate active time (simplified - time between first and last location)
    String activeTime = '0h';
    if (todayLocations.length >= 2) {
      final duration = todayLocations.last.timestamp.difference(todayLocations.first.timestamp);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      activeTime = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    }

    // Generate AI summary if we don't have one and there's data
    useEffect(() {
      if (journalEntry == null && !isGenerating.value) {
        // Check if we have any data for today
        if (photosCount > 0 || locationsCount > 0) {
          // Automatically generate summary after a short delay
          Future.delayed(const Duration(seconds: 2), () async {
            if (!context.mounted) return;
            if (ref.read(todayJournalEntryProvider) != null) return; // Already generated

            isGenerating.value = true;
            try {
              final result = await aiService.generateDailySummary(
                date: DateTime.now(),
                style: NarrativeStyle.casual,
              );
              if (context.mounted) {
                ref.read(todayJournalEntryProvider.notifier).state = result.narrative;
                controller.text = result.narrative;
              }
            } catch (e) {
              // Silently handle errors
            } finally {
              if (context.mounted) {
                isGenerating.value = false;
              }
            }
          });
        }
      }
      return null;
    }, [photosCount, locationsCount]);

    // Function to manually generate/regenerate summary
    Future<void> generateSummary() async {
      isGenerating.value = true;
      try {
        final result = await aiService.generateDailySummary(
          date: DateTime.now(),
          style: NarrativeStyle.casual,
        );
        if (context.mounted) {
          ref.read(todayJournalEntryProvider.notifier).state = result.narrative;
          controller.text = result.narrative;
        }
      } catch (e) {
        // Silently handle errors
      } finally {
        if (context.mounted) {
          isGenerating.value = false;
        }
      }
    }

    return Skeletonizer(
      enabled: isLoading.value || isGenerating.value,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Summary Card
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
                                Icons.auto_awesome,
                                color: theme.colorScheme.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  "Today's Summary",
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
                            // Generate/Refresh button
                            if (!isEditing.value)
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
                                      journalEntry != null ? Icons.refresh : Icons.auto_awesome,
                                      color: theme.colorScheme.primary,
                                    ),
                                onPressed: isGenerating.value ? null : generateSummary,
                                tooltip: journalEntry != null ? 'Regenerate Summary' : 'Generate Summary',
                              ),
                            // Edit button
                            IconButton(
                              icon: Icon(
                                isEditing.value ? Icons.check : Icons.edit,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () async {
                                if (isEditing.value) {
                                  // Save the edited text to memory
                                  ref.read(todayJournalEntryProvider.notifier).state =
                                    controller.text;

                                  // Save to calendar
                                  await _saveJournalEntryToCalendar(
                                    ref,
                                    controller.text,
                                    DateTime.now(),
                                  );
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
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Write about your day...',
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
                        : journalEntry != null && journalEntry.isNotEmpty
                          ? Text(
                              journalEntry,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                              ),
                            )
                          : _buildSummaryEmptyState(theme, photosCount > 0 || locationsCount > 0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Text(
              'Daily Stats',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  icon: Icons.photo_library,
                  value: photosCount.toString(),
                  label: 'Photos',
                  theme: theme,
                  isLight: isLight,
                  onTap: () {
                    // Switch to Media tab
                    ref.read(homeSubTabIndexProvider.notifier).state = 2;
                  },
                ),
                _buildStatCard(
                  icon: Icons.route,
                  value: '${(distanceTraveled / 1000).toStringAsFixed(1)} km',
                  label: 'Distance',
                  theme: theme,
                  isLight: isLight,
                  onTap: () {
                    // Switch to Map tab
                    ref.read(homeSubTabIndexProvider.notifier).state = 1;
                  },
                ),
                _buildStatCard(
                  icon: Icons.timer,
                  value: activeTime,
                  label: 'Active Time',
                  theme: theme,
                  isLight: isLight,
                ),
                _buildStatCard(
                  icon: Icons.place,
                  value: locationsCount.toString(),
                  label: 'Places',
                  theme: theme,
                  isLight: isLight,
                  onTap: () {
                    // Switch to Map tab
                    ref.read(homeSubTabIndexProvider.notifier).state = 1;
                  },
                ),
              ],
            ),
            const SizedBox(height: 80), // Extra space for bottom navigation
          ],
        ),
      ),
    );
  }

  // Build empty state for Today's Summary
  Widget _buildSummaryEmptyState(ThemeData theme, bool hasData) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasData ? Icons.auto_awesome_outlined : Icons.analytics_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasData ? 'Ready to generate summary' : 'No data yet today',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasData
                ? 'Tap the sparkle icon above to generate\nyour AI-powered daily summary'
                : 'Your daily summary will automatically appear\nas you use the app throughout the day',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
    required bool isLight,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Save journal entry to calendar
  Future<void> _saveJournalEntryToCalendar(
    WidgetRef ref,
    String content,
    DateTime date,
  ) async {
    try {
      // TODO: Implement calendar service provider
      // final calendarService = ref.read(calendarServiceProvider);

      final title = "Today's Summary - ${date.day}/${date.month}/${date.year}";

      // TODO: Implement calendar integration
      // Try to create the calendar entry
      // final eventId = await calendarService.createJournalSummaryEntry(
      //   date: date,
      //   title: title,
      //   content: content,
      // );
      
      // For now, just keep content in memory
      print('Journal entry saved: $title');
    } catch (e) {
      // Error saving to calendar - content is still in memory
      print('Error saving journal entry: $e');
    }
  }
}

// Map Tab
class _MapTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLoading = useState(false);

    // Get locations from database for the last 24 hours
    final locationStream = ref.watch(recentLocationPointsProvider(const Duration(hours: 24)));

    // Get today's locations
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return locationStream.when(
      data: (locationHistory) {
        final todayLocations = locationHistory
            .where((loc) => loc.timestamp.isAfter(todayStart) && loc.timestamp.isBefore(todayEnd))
            .toList();

        if (todayLocations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No locations visited today',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start tracking to see your daily journey',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        // Calculate center point
        double avgLat = todayLocations.map((l) => l.latitude).reduce((a, b) => a + b) / todayLocations.length;
        double avgLng = todayLocations.map((l) => l.longitude).reduce((a, b) => a + b) / todayLocations.length;

        return Skeletonizer(
          enabled: isLoading.value,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(avgLat, avgLng),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.auraone.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: todayLocations.map((loc) => LatLng(loc.latitude, loc.longitude)).toList(),
                    color: theme.colorScheme.primary,
                    strokeWidth: 3.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Start marker
                  if (todayLocations.isNotEmpty)
                    Marker(
                      point: LatLng(todayLocations.first.latitude, todayLocations.first.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                      ),
                    ),
                  // End marker
                  if (todayLocations.length > 1)
                    Marker(
                      point: LatLng(todayLocations.last.latitude, todayLocations.last.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.stop, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading locations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Media Tab
class _MediaTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaDb = ref.watch(mediaDatabaseProvider);
    final photoService = ref.watch(photoServiceProvider);
    final isLoading = useState(false);
    final hasScanned = useState(false);

    // Get today's media
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Scan and index photos on first mount
    useEffect(() {
      if (!hasScanned.value) {
        Future<void> scanPhotos() async {
          hasScanned.value = true;
          isLoading.value = true;
          try {
            // Request permission if needed
            final permission = await Permission.photos.request();
            if (permission.isGranted || permission.isLimited) {
              // Scan and index today's photos
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
    }, []);

    // Get media from the last 2 days to ensure we catch all of today's media
    final mediaFuture = useMemoized(
      () => mediaDb.getRecentMedia(duration: const Duration(days: 2), limit: 500),
      [todayStart, hasScanned.value], // Re-fetch when scanning completes
    );
    final mediaSnapshot = useFuture(mediaFuture);

    if (mediaSnapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    final allMedia = mediaSnapshot.data ?? [];
    // Filter to only today's media
    final mediaItems = allMedia.where((item) {
      // Check if the media was created today
      return item.createdDate.year == todayStart.year &&
             item.createdDate.month == todayStart.month &&
             item.createdDate.day == todayStart.day;
    }).toList();

    if (mediaItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No photos taken today',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your daily photos will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Skeletonizer(
      enabled: isLoading.value,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: mediaItems.length,
        itemBuilder: (context, index) {
          final media = mediaItems[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Navigate to History screen and select the photo's date
                // First, switch to the History tab (index 1)
                ref.read(selectedTabIndexProvider.notifier).state = 1;
                
                // Then update the selected date in the history screen
                // This will be picked up by the HistoryScreen when it rebuilds
                final photoDate = media.createdDate;
                
                // Store the selected date for the history screen to use
                // We'll create a provider for this purpose
                ref.read(historySelectedDateProvider.notifier).state = photoDate;
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: media.filePath != null
                        ? Image.file(
                            File(media.filePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                              _buildMediaPlaceholder(media, theme),
                          )
                        : _buildMediaPlaceholder(media, theme),
                    ),
                    // Add a subtle overlay to indicate it's tappable
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Add a small link icon in the corner
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaPlaceholder(MediaItem media, ThemeData theme) {
    IconData icon;
    if (media.mimeType.startsWith('image/')) {
      icon = Icons.image;
    } else if (media.mimeType.startsWith('video/')) {
      icon = Icons.videocam;
    } else if (media.mimeType.startsWith('audio/')) {
      icon = Icons.audiotrack;
    } else {
      icon = Icons.file_present;
    }

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        icon,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: 32,
      ),
    );
  }
}
