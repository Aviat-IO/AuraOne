import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart';
import '../database/media_database.dart';
import '../services/simple_location_service.dart';
import '../providers/media_database_provider.dart';

// Provider to store the current day's journal entry
final todayJournalEntryProvider = StateProvider<String>((ref) => 
  "Today was a peaceful day. You started with your morning routine at 7:30 AM, had a productive work session, and took a refreshing walk in the afternoon. You connected with a friend over coffee and spent the evening reading."
);

// Provider for sub-tab index
final homeSubTabIndexProvider = StateProvider<int>((ref) => 0);

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
              // Header with date and greeting
              Padding(
                padding: const EdgeInsets.all(16),
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getFormattedDate(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Sub-tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isLight 
                        ? Colors.black.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primaryContainer,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: theme.colorScheme.onPrimaryContainer,
                  unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  tabs: const [
                    Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
                    Tab(text: 'Map', icon: Icon(Icons.map, size: 20)),
                    Tab(text: 'Media', icon: Icon(Icons.photo_library, size: 20)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Tab content
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
    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                   'July', 'August', 'September', 'October', 'November', 'December'];
    
    return '${weekdays[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
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
    final controller = useTextEditingController(text: journalEntry);
    final isLoading = useState(false);
    
    // Get today's stats
    final mediaDb = ref.watch(mediaDatabaseProvider);
    
    // Calculate stats
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    // Get photos count - using getRecentMedia for today's photos
    final photosCountAsync = useMemoized(
      () => mediaDb.getRecentMedia(duration: const Duration(days: 1), limit: 100),
      [todayStart],
    );
    final photosFuture = useFuture(photosCountAsync);
    final todayPhotos = photosFuture.data?.where((item) => 
      item.createdDate.isAfter(todayStart) && item.createdDate.isBefore(todayEnd)
    ).toList() ?? [];
    final photosCount = todayPhotos.length;
    
    // Get locations count  
    final locationHistory = ref.watch(locationHistoryProvider);
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
    
    return Skeletonizer(
      enabled: isLoading.value,
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
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: theme.colorScheme.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Today's Summary",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            isEditing.value ? Icons.check : Icons.edit,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            if (isEditing.value) {
                              // Save the edited text
                              ref.read(todayJournalEntryProvider.notifier).state = 
                                controller.text;
                            }
                            isEditing.value = !isEditing.value;
                          },
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
                        : Text(
                            journalEntry,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                            ),
                          ),
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
}

// Map Tab
class _MapTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLoading = useState(false);
    final locationHistory = ref.watch(locationHistoryProvider);
    
    // Get today's locations
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));
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
  }
}

// Media Tab
class _MediaTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaDb = ref.watch(mediaDatabaseProvider);
    final isLoading = useState(false);
    
    // Get today's media
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final mediaFuture = useMemoized(
      () => mediaDb.getRecentMedia(duration: const Duration(days: 1), limit: 100),
      [todayStart],
    );
    final mediaSnapshot = useFuture(mediaFuture);
    
    if (mediaSnapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final allMedia = mediaSnapshot.data ?? [];
    final mediaItems = allMedia.where((item) => 
      item.createdDate.isAfter(todayStart) && item.createdDate.isBefore(todayEnd)
    ).toList();
    
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
          return GestureDetector(
            onTap: () {
              // TODO: Open media viewer
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: ClipRRect(
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