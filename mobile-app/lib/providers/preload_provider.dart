import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'media_database_provider.dart';
import 'location_clustering_provider.dart';
import 'location_database_provider.dart';
import '../utils/logger.dart';

final _logger = AppLogger('PreloadProvider');

/// Provider that preloads media and map data in the background
/// This ensures data is already cached when user switches tabs
final preloadProvider = Provider.family<void, DateTime>((ref, date) {
  // Immediately start preloading media for this date (last 7 days worth to capture the day)
  Future.microtask(() {
    try {
      // Trigger media provider to load and cache data
      ref.read(recentMediaProvider((duration: const Duration(days: 7), limit: 500)).future);
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

  // Preload recent location points (used by map for path visualization)
  Future.microtask(() {
    try {
      ref.read(recentLocationPointsProvider(const Duration(days: 7)).future);
      _logger.info('Preloading recent location points');
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
