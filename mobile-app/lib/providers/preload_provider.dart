import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'media_database_provider.dart';
import 'location_clustering_provider.dart';
import 'location_database_provider.dart';
import 'photo_service_provider.dart';
import '../utils/logger.dart';

final _logger = AppLogger('PreloadProvider');

/// Provider that preloads media and map data in the background with queuing
/// This ensures data is already cached when user switches tabs
final preloadProvider = Provider.family<void, DateTime>((ref, date) {
  // Use a queue to prevent concurrent expensive operations
  // Only allow one preload operation per date at a time
  final preloadKey = 'preload_${date.year}_${date.month}_${date.day}';

  // Check if already preloading this date
  if (_activePreloads.contains(preloadKey)) {
    _logger.info('Preload already in progress for ${date.toIso8601String()}');
    return;
  }

  _activePreloads.add(preloadKey);

  // Start preloading with lower priority to avoid blocking UI
  Future(() async {
    try {
      _logger.info('Starting background preload for ${date.toIso8601String()}');

      // Preload media first (usually faster)
      try {
        final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final mediaDb = ref.read(mediaDatabaseProvider);
        await mediaDb.getMediaByDateRange(
          startDate: startOfDay,
          endDate: endOfDay,
          processedOnly: false,
          includeDeleted: false,
        ).timeout(const Duration(seconds: 5));
        _logger.info('Preloaded media for ${date.toIso8601String()}');
      } catch (e) {
        _logger.warning('Error preloading media for ${date.toIso8601String()}: $e');
      }

      // Small delay to prevent overwhelming the system
      await Future.delayed(const Duration(milliseconds: 100));

      // Preload location points (needed for clustering)
      try {
        await ref.read(locationPointsForDateProvider(date).future)
            .timeout(const Duration(seconds: 3));
        _logger.info('Preloaded location points for ${date.toIso8601String()}');
      } catch (e) {
        _logger.warning('Error preloading location points for ${date.toIso8601String()}: $e');
      }

      // Small delay before clustering (most expensive operation)
      await Future.delayed(const Duration(milliseconds: 200));

      // Preload clustering last (most expensive)
      try {
        await ref.read(clusteredLocationsProvider(date).future)
            .timeout(const Duration(seconds: 10));
        _logger.info('Preloaded clusters for ${date.toIso8601String()}');
      } catch (e) {
        _logger.warning('Error preloading clusters for ${date.toIso8601String()}: $e');
      }

    } finally {
      // Always remove from active preloads
      _activePreloads.remove(preloadKey);
      _logger.info('Completed preload for ${date.toIso8601String()}');
    }
  }).catchError((e) {
    _logger.warning('Preload failed for ${date.toIso8601String()}: $e');
    _activePreloads.remove(preloadKey);
  });
});

// Track active preloads to prevent duplicates
final _activePreloads = <String>{};

/// Provider that manages background data warming for the current date
/// Call this when navigating to Today tab to start warming caches
final dataWarmingProvider = Provider<void>((ref) {
  final today = DateTime.now();

  // Trigger photo scan for today to ensure latest photos are in database
  Future.microtask(() async {
    try {
      final photoService = ref.read(photoServiceProvider);
      await photoService.scanAndIndexTodayPhotos();
      _logger.info('Triggered photo scan for today');
    } catch (e) {
      _logger.warning('Failed to trigger photo scan: $e');
    }
  });

  // Priority #1: Preload today's data (most important)
  ref.watch(preloadProvider(today));

  // Only preload adjacent days if system is not under load
  // Use staggered delays to prevent overwhelming the system on app start
  Future.delayed(const Duration(seconds: 3), () {
    if (_activePreloads.length < 2) { // Only if not too many preloads active
      // Priority #2: Preload yesterday's data (user might browse back)
      ref.watch(preloadProvider(today.subtract(const Duration(days: 1))));
    }
  });

  Future.delayed(const Duration(seconds: 8), () {
    if (_activePreloads.isEmpty) { // Even more restrictive for older data
      // Priority #3: Preload day before yesterday (less common but still useful)
      ref.watch(preloadProvider(today.subtract(const Duration(days: 2))));
    }
  });
});
