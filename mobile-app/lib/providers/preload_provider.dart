import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'media_database_provider.dart';
import 'location_clustering_provider.dart';
import 'location_database_provider.dart';
import 'photo_service_provider.dart';
import '../utils/logger.dart';

final _logger = AppLogger('PreloadProvider');

final preloadProvider = Provider.family<void, DateTime>((ref, date) {
  _startPreload(ref, date, includeClusters: false);
});

final clusteredPreloadProvider = Provider.family<void, DateTime>((ref, date) {
  _startPreload(ref, date, includeClusters: true);
});

void _startPreload(Ref ref, DateTime date, {required bool includeClusters}) {
  final preloadKey =
      'preload_${date.year}_${date.month}_${date.day}_${includeClusters ? 'clusters' : 'raw'}';

  if (_activePreloads.contains(preloadKey)) {
    _logger.info('Preload already in progress for ${date.toIso8601String()}');
    return;
  }

  _activePreloads.add(preloadKey);

  Future(() async {
    try {
      _logger.info('Starting background preload for ${date.toIso8601String()}');

      try {
        final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final mediaDb = ref.read(mediaDatabaseProvider);
        await mediaDb
            .getMediaByDateRange(
              startDate: startOfDay,
              endDate: endOfDay,
              processedOnly: false,
              includeDeleted: false,
            )
            .timeout(const Duration(seconds: 5));
        _logger.info('Preloaded media for ${date.toIso8601String()}');
      } catch (e) {
        _logger.warning(
          'Error preloading media for ${date.toIso8601String()}: $e',
        );
      }

      await Future.delayed(const Duration(milliseconds: 100));

      try {
        await ref
            .read(locationPointsForDateProvider(date).future)
            .timeout(const Duration(seconds: 3));
        _logger.info('Preloaded location points for ${date.toIso8601String()}');
      } catch (e) {
        _logger.warning(
          'Error preloading location points for ${date.toIso8601String()}: $e',
        );
      }

      if (includeClusters) {
        await Future.delayed(const Duration(milliseconds: 200));

        try {
          await ref
              .read(clusteredLocationsProvider(date).future)
              .timeout(const Duration(seconds: 10));
          _logger.info('Preloaded clusters for ${date.toIso8601String()}');
        } catch (e) {
          _logger.warning(
            'Error preloading clusters for ${date.toIso8601String()}: $e',
          );
        }
      }
    } finally {
      _activePreloads.remove(preloadKey);
      _logger.info('Completed preload for ${date.toIso8601String()}');
    }
  }).catchError((e) {
    _logger.warning('Preload failed for ${date.toIso8601String()}: $e');
    _activePreloads.remove(preloadKey);
  });
}

final _activePreloads = <String>{};

final dataWarmingProvider = Provider<void>((ref) {
  final today = DateTime.now();

  Future.microtask(() async {
    try {
      final photoService = ref.read(photoServiceProvider);
      await photoService.scanAndIndexTodayPhotos();
      _logger.info('Triggered photo scan for today');
    } catch (e) {
      _logger.warning('Failed to trigger photo scan: $e');
    }
  });

  ref.watch(preloadProvider(today));

  Future.delayed(const Duration(seconds: 3), () {
    if (_activePreloads.length < 2) {
      ref.watch(preloadProvider(today.subtract(const Duration(days: 1))));
    }
  });

  Future.delayed(const Duration(seconds: 8), () {
    if (_activePreloads.isEmpty) {
      ref.watch(preloadProvider(today.subtract(const Duration(days: 2))));
    }
  });
});
