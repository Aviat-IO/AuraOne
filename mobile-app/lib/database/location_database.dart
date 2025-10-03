import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

part 'location_database.g.dart';

// Table for storing location points
class LocationPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real().nullable()();
  RealColumn get altitude => real().nullable()();
  RealColumn get speed => real().nullable()();
  RealColumn get heading => real().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get activityType => text().nullable()(); // walking, driving, stationary
  BoolColumn get isSignificant => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Table for geofence definitions
class GeofenceAreas extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radius => real()(); // in meters
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get metadata => text().nullable()(); // JSON string for extra data
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table for geofence events
class GeofenceEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get geofenceId => text().references(GeofenceAreas, #id)();
  TextColumn get eventType => text()(); // 'enter', 'exit', 'dwell'
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get dwellTime => integer().nullable()(); // in seconds for dwell events
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Table for location-based notes/memories
class LocationNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get noteId => text().nullable()(); // Reference to Nostr note if published
  TextColumn get content => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get placeName => text().nullable()();
  TextColumn get geofenceId => text().nullable().references(GeofenceAreas, #id)();
  TextColumn get tags => text().nullable()(); // JSON array of tags
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isPublished => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Table for daily location summaries
class LocationSummaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalPoints => integer()();
  RealColumn get totalDistance => real()(); // in meters
  IntColumn get placesVisited => integer()();
  TextColumn get mainLocations => text()(); // JSON array of top locations
  IntColumn get activeMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {date},
  ];
}

// Table for movement tracking data from gyroscope/accelerometer
class MovementData extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get state => text()(); // still, walking, running, driving, unknown
  RealColumn get averageMagnitude => real()();
  IntColumn get sampleCount => integer()();
  RealColumn get stillPercentage => real()();
  RealColumn get walkingPercentage => real()();
  RealColumn get runningPercentage => real()();
  RealColumn get drivingPercentage => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  LocationPoints,
  GeofenceAreas,
  GeofenceEvents,
  LocationNotes,
  LocationSummaries,
  MovementData,
])
class LocationDatabase extends _$LocationDatabase {
  LocationDatabase() : super(_openConnection());

  // Constructor that accepts a custom connection for background tasks
  LocationDatabase.withConnection({required QueryExecutor openConnection})
      : super(openConnection);

  // Constructor for testing with custom executor
  LocationDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'location_database');
  }

  // Location Points Methods
  Future<int> insertLocationPoint(LocationPointsCompanion point) {
    return into(locationPoints).insert(point);
  }

  Stream<List<LocationPoint>> watchRecentLocationPoints({
    Duration duration = const Duration(hours: 24),
  }) {
    final cutoff = DateTime.now().subtract(duration);
    return (select(locationPoints)
          ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(cutoff))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }

  Future<List<LocationPoint>> getLocationPointsBetween(
    DateTime start,
    DateTime end,
  ) {
    return (select(locationPoints)
          ..where((tbl) =>
              tbl.timestamp.isBetweenValues(start, end))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]))
        .get();
  }

  // Geofence Methods
  Future<int> insertGeofence(GeofenceAreasCompanion geofence) {
    return into(geofenceAreas).insert(geofence);
  }

  Future<bool> updateGeofence(GeofenceAreasCompanion geofence) {
    return update(geofenceAreas).replace(geofence);
  }

  Future<int> deleteGeofence(String id) {
    return (delete(geofenceAreas)..where((tbl) => tbl.id.equals(id))).go();
  }

  Stream<List<GeofenceArea>> watchActiveGeofences() {
    return (select(geofenceAreas)
          ..where((tbl) => tbl.isActive.equals(true)))
        .watch();
  }

  // Geofence Events Methods
  Future<int> insertGeofenceEvent(GeofenceEventsCompanion event) {
    return into(geofenceEvents).insert(event);
  }

  Stream<List<GeofenceEvent>> watchRecentGeofenceEvents({
    Duration duration = const Duration(days: 7),
  }) {
    final cutoff = DateTime.now().subtract(duration);
    return (select(geofenceEvents)
          ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(cutoff))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }

  // Location Notes Methods
  Future<int> insertLocationNote(LocationNotesCompanion note) {
    return into(locationNotes).insert(note);
  }

  Stream<List<LocationNote>> watchLocationNotes({
    String? geofenceId,
    bool? isPublished,
  }) {
    return (select(locationNotes)
          ..where((tbl) {
            Expression<bool> filter = const Constant(true);
            if (geofenceId != null) {
              filter = filter & tbl.geofenceId.equals(geofenceId);
            }
            if (isPublished != null) {
              filter = filter & tbl.isPublished.equals(isPublished);
            }
            return filter;
          })
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }

  // Data Retention Methods
  Future<void> cleanupOldLocationData({
    Duration retentionPeriod = const Duration(days: 30),
    bool keepSignificantPoints = true,
  }) async {
    final cutoff = DateTime.now().subtract(retentionPeriod);

    // Delete old location points (except significant ones if specified)
    await (delete(locationPoints)
          ..where((tbl) {
            Expression<bool> filter = tbl.timestamp.isSmallerThanValue(cutoff);
            if (keepSignificantPoints) {
              filter = filter & tbl.isSignificant.equals(false);
            }
            return filter;
          }))
        .go();

    // Delete old geofence events
    await (delete(geofenceEvents)
          ..where((tbl) => tbl.timestamp.isSmallerThanValue(cutoff)))
        .go();
  }

  // Get locations between two dates
  Future<List<LocationPoint>> getLocationsBetween(DateTime start, DateTime end) async {
    return await (select(locationPoints)
          ..where((tbl) => tbl.timestamp.isBetweenValues(start, end))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]))
        .get();
  }

  // Summary Methods
  Future<void> generateDailySummary(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final points = await getLocationPointsBetween(startOfDay, endOfDay);

    if (points.isEmpty) return;

    // Calculate statistics
    double totalDistance = 0;
    for (int i = 1; i < points.length; i++) {
      totalDistance += _calculateDistance(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }

    // Get unique geofence visits
    final geofenceVisits = await (select(geofenceEvents)
          ..where((tbl) => tbl.timestamp.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]))
        .get();

    final uniquePlaces = geofenceVisits
        .map((e) => e.geofenceId)
        .toSet()
        .length;

    // Insert summary
    await into(locationSummaries).insertOnConflictUpdate(
      LocationSummariesCompanion(
        date: Value(startOfDay),
        totalPoints: Value(points.length),
        totalDistance: Value(totalDistance),
        placesVisited: Value(uniquePlaces),
        mainLocations: Value('[]'), // TODO: Implement top locations
        activeMinutes: const Value.absent(),
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
        math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) *
        math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Movement Data Methods
  Future<int> insertMovementData(MovementDataCompanion data) {
    return into(movementData).insert(data);
  }

  Stream<List<MovementDataData>> watchRecentMovementData({
    Duration duration = const Duration(hours: 24),
  }) {
    final cutoff = DateTime.now().subtract(duration);
    return (select(movementData)
          ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(cutoff))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }

  Future<List<MovementDataData>> getMovementDataBetween(
    DateTime start,
    DateTime end,
  ) {
    return (select(movementData)
          ..where((tbl) =>
              tbl.timestamp.isBetweenValues(start, end))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]))
        .get();
  }

  Future<void> cleanupOldMovementData({
    Duration retentionPeriod = const Duration(days: 7),
  }) async {
    final cutoff = DateTime.now().subtract(retentionPeriod);
    await (delete(movementData)
          ..where((tbl) => tbl.timestamp.isSmallerThanValue(cutoff)))
        .go();
  }

  // Migration and schema updates
  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // Handle database version mismatches gracefully
          if (details.wasCreated) {
            // Database was just created, no issues
            return;
          }

          // Check if we're dealing with a version mismatch
          if (details.versionBefore != null && details.versionNow != details.versionBefore) {
            debugPrint('Location database migration: v${details.versionBefore} -> v${details.versionNow}');
          }
        },
        onCreate: (Migrator m) async {
          try {
            await m.createAll();
          } catch (e) {
            // If createAll fails, it might be because tables already exist from a previous installation
            debugPrint('Warning: Could not create all tables (may already exist): $e');
            // Try to continue anyway - the app should still work
          }
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Migration from version 1 to 2: Added MovementData table
          if (from < 2) {
            await m.createTable(movementData);
          }

          // Migration from version 2 to 3: Ensure MovementData table exists
          // This handles cases where the table wasn't created properly
          if (from < 3) {
            // Check if table exists and create if it doesn't
            try {
              // Try to count rows to check if table exists
              await customSelect('SELECT COUNT(*) FROM movement_data').getSingle();
            } catch (e) {
              // Table doesn't exist, create it
              await m.createTable(movementData);
            }
          }
        },
      );
}
