import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../database/location_database.dart';

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
final recentLocationPointsProvider = StreamProvider.family<List<LocationPoint>, Duration>(
  (ref, duration) {
    final db = ref.watch(locationDatabaseProvider);
    return db.watchRecentLocationPoints(duration: duration);
  },
);

// Provider for watching active geofences
final activeGeofencesProvider = StreamProvider<List<GeofenceArea>>((ref) {
  final db = ref.watch(locationDatabaseProvider);
  return db.watchActiveGeofences();
});

// Provider for watching recent geofence events
final recentGeofenceEventsProvider = StreamProvider.family<List<GeofenceEvent>, Duration>(
  (ref, duration) {
    final db = ref.watch(locationDatabaseProvider);
    return db.watchRecentGeofenceEvents(duration: duration);
  },
);

// Provider for watching location notes
final locationNotesProvider = StreamProvider.family<List<LocationNote>, ({String? geofenceId, bool? isPublished})>(
  (ref, params) {
    final db = ref.watch(locationDatabaseProvider);
    return db.watchLocationNotes(
      geofenceId: params.geofenceId,
      isPublished: params.isPublished,
    );
  },
);

// Provider for data cleanup service
final locationDataCleanupProvider = Provider((ref) {
  return LocationDataCleanupService(ref);
});

class LocationDataCleanupService {
  final Ref ref;

  LocationDataCleanupService(this.ref);

  Future<void> performCleanup({
    Duration retentionPeriod = const Duration(days: 30),
    bool keepSignificantPoints = true,
  }) async {
    final db = ref.read(locationDatabaseProvider);
    await db.cleanupOldLocationData(
      retentionPeriod: retentionPeriod,
      keepSignificantPoints: keepSignificantPoints,
    );
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