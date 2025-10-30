import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'media_database_provider.dart';
import 'location_clustering_provider.dart';
import 'location_database_provider.dart';
import '../utils/logger.dart';

final _logger = AppLogger('PreloadProvider');

/// Provider that preloads media and map data in the background
/// This ensures data is already cached when user switches tabs
final preloadProvider = Provider.family<void, DateTime>((ref, date) {
  // Immediately start preloading media for this specific date
  Future.microtask(() {
    try {
      // Calculate date range for the selected day
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Trigger media database to load and cache data for this specific date
      final mediaDb = ref.read(mediaDatabaseProvider);
      mediaDb.getMediaByDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
        processedOnly: false,
        includeDeleted: false,
      );
      _logger.info('Preloading media for ${date.toIso8601String()}');
    } catch (e) {
      _logger.warning('Error preloading media: $e');
    }
  });

  // Immediately start preloading location clusters for this date
  Future.microtask(() {
    try {
      // Trigger clustering provider to load and cache data
      ref.read(clusteredLocationsProvider(date).future);
      _logger.info('Preloading clusters for ${date.toIso8601String()}');
    } catch (e) {
      _logger.warning('Error preloading clusters: $e');
    }
  });

  // Preload location points for this specific date (used by map for path visualization)
  Future.microtask(() {
    try {
      ref.read(locationPointsForDateProvider(date).future);
      _logger.info('Preloading location points for ${date.toIso8601String()}');
    } catch (e) {
      _logger.warning('Error preloading location points: $e');
    }
  });
});

/// Provider that manages background data warming for the current date
/// Call this when navigating to Today tab to start warming caches
final dataWarmingProvider = Provider<void>((ref) {
  final today = DateTime.now();

  // Priority #1: Preload today's data (most important)
  ref.watch(preloadProvider(today));

  // Priority #2: Preload yesterday's data (user might browse back)
  ref.watch(preloadProvider(today.subtract(const Duration(days: 1))));

  // Priority #3: Preload day before yesterday (less common but still useful)
  ref.watch(preloadProvider(today.subtract(const Duration(days: 2))));
});
