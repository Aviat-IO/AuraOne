import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../database/location_database.dart';
import '../utils/date_utils.dart';

const allLocationDaysInvalidationKey = '__all__';

String locationCacheDayKey(DateTime date) {
  final localDay = DateTimeUtils.getLocalDateOnly(date);
  final year = localDay.year.toString().padLeft(4, '0');
  final month = localDay.month.toString().padLeft(2, '0');
  final day = localDay.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class LocationDayInvalidationNotifier extends StateNotifier<Map<String, int>> {
  LocationDayInvalidationNotifier() : super(const {});

  void invalidateDay(DateTime timestamp) {
    final key = locationCacheDayKey(timestamp);
    state = {...state, key: (state[key] ?? 0) + 1};
  }

  void invalidateDays(Iterable<DateTime> timestamps) {
    final uniqueKeys = timestamps.map(locationCacheDayKey).toSet();
    var nextState = state;
    for (final key in uniqueKeys) {
      nextState = {...nextState, key: (nextState[key] ?? 0) + 1};
    }
    state = nextState;
  }

  void invalidateAll() {
    state = {
      ...state,
      allLocationDaysInvalidationKey:
          (state[allLocationDaysInvalidationKey] ?? 0) + 1,
    };
  }
}

final locationDayInvalidationProvider =
    StateNotifierProvider<LocationDayInvalidationNotifier, Map<String, int>>(
      (ref) => LocationDayInvalidationNotifier(),
    );

final locationWriteInvalidationBindingProvider = Provider<void>((ref) {
  final db = ref.watch(locationDatabaseProvider);
  final notifier = ref.read(locationDayInvalidationProvider.notifier);
  void invalidateDays(Iterable<DateTime> timestamps) {
    notifier.invalidateDays(timestamps);
  }

  db.onLocationDaysChanged = invalidateDays;

  ref.onDispose(() {
    if (identical(db.onLocationDaysChanged, invalidateDays)) {
      db.onLocationDaysChanged = null;
    }
  });
});

// Singleton provider for the location database
final locationDatabaseProvider = Provider<LocationDatabase>((ref) {
  final database = LocationDatabase();

  // Dispose the database when the provider is disposed
  ref.onDispose(() {
    database.close();
  });

  return database;
});

// Provider for watching recent location points
final recentLocationPointsProvider =
    StreamProvider.family<List<LocationPoint>, Duration>((ref, duration) {
      final db = ref.watch(locationDatabaseProvider);
      return db.watchRecentLocationPoints(duration: duration);
    });

// Provider for getting location points for a specific date (user's timezone)
// Limited to prevent excessive data loading and improve performance
final locationPointsForDateProvider =
    FutureProvider.family<List<LocationPoint>, DateTime>((ref, date) async {
      ref.watch(locationWriteInvalidationBindingProvider);
      ref.watch(
        locationDayInvalidationProvider.select(
          (versions) => versions[locationCacheDayKey(date)] ?? 0,
        ),
      );
      ref.watch(
        locationDayInvalidationProvider.select(
          (versions) => versions[allLocationDaysInvalidationKey] ?? 0,
        ),
      );

      final db = ref.watch(locationDatabaseProvider);
      final localDay = DateTimeUtils.getLocalDateOnly(date);

      // Get the start and end of the day in the user's local timezone
      final dayStart = localDay;
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Limit location points to 1000 per day to prevent performance issues
      // Downsample evenly instead of taking only the most recent points so the
      // day-level map and journey view still represent the whole day.
      final allPoints = await db.getLocationPointsBetween(dayStart, dayEnd);
      if (allPoints.length > 1000) {
        return _downsampleLocationPoints(allPoints, maxPoints: 1000);
      }
      return allPoints;
    });

List<LocationPoint> _downsampleLocationPoints(
  List<LocationPoint> points, {
  required int maxPoints,
}) {
  if (points.length <= maxPoints) {
    return points;
  }

  final step = (points.length - 1) / (maxPoints - 1);
  final result = <LocationPoint>[];

  for (var i = 0; i < maxPoints; i++) {
    final index = (i * step).round().clamp(0, points.length - 1);
    result.add(points[index]);
  }

  return result;
}

// Provider for watching active geofences
final activeGeofencesProvider = StreamProvider<List<GeofenceArea>>((ref) {
  final db = ref.watch(locationDatabaseProvider);
  return db.watchActiveGeofences();
});

// Provider for watching recent geofence events
final recentGeofenceEventsProvider =
    StreamProvider.family<List<GeofenceEvent>, Duration>((ref, duration) {
      final db = ref.watch(locationDatabaseProvider);
      return db.watchRecentGeofenceEvents(duration: duration);
    });

// Provider for watching location notes
final locationNotesProvider =
    StreamProvider.family<
      List<LocationNote>,
      ({String? geofenceId, bool? isPublished})
    >((ref, params) {
      final db = ref.watch(locationDatabaseProvider);
      return db.watchLocationNotes(
        geofenceId: params.geofenceId,
        isPublished: params.isPublished,
      );
    });

// Provider for data cleanup service
final locationDataCleanupProvider = Provider((ref) {
  return LocationDataCleanupService(ref);
});

class LocationDataCleanupService {
  final Ref ref;

  LocationDataCleanupService(this.ref);

  Future<void> performCleanup({
    Duration retentionPeriod = const Duration(days: 30),
    Duration movementRetentionPeriod = const Duration(days: 7),
    bool keepSignificantPoints = true,
  }) async {
    final db = ref.read(locationDatabaseProvider);

    // Clean up old location data
    await db.cleanupOldLocationData(
      retentionPeriod: retentionPeriod,
      keepSignificantPoints: keepSignificantPoints,
    );

    // Clean up old movement data (keep for less time as it's higher volume)
    await db.cleanupOldMovementData(retentionPeriod: movementRetentionPeriod);
  }

  Future<void> generateDailySummaries() async {
    final db = ref.read(locationDatabaseProvider);

    // Generate summaries for the last 7 days
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      await db.generateDailySummary(date);
    }
  }
}
