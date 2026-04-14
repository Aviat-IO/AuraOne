import 'package:aura_one/database/location_database.dart';
import 'package:aura_one/database/media_database.dart';
import 'package:aura_one/services/data_deletion_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataDeletionService', () {
    late LocationDatabase locationDb;
    late MediaDatabase mediaDb;
    late DataDeletionService service;

    setUp(() {
      locationDb = LocationDatabase.forTesting(NativeDatabase.memory());
      mediaDb = MediaDatabase.forTesting(NativeDatabase.memory());
      service = DataDeletionService(locationDb: locationDb, mediaDb: mediaDb);
    });

    tearDown(() async {
      await locationDb.close();
      await mediaDb.close();
    });

    test('bounded delete respects keepSignificantLocations', () async {
      final start = DateTime(2026, 2, 1, 0, 0);
      final end = DateTime(2026, 2, 1, 23, 59);

      await locationDb.insertLocationPoint(
        LocationPointsCompanion.insert(
          latitude: 37.7749,
          longitude: -122.4194,
          timestamp: start.add(const Duration(hours: 8)),
          isSignificant: const Value(false),
        ),
      );
      await locationDb.insertLocationPoint(
        LocationPointsCompanion.insert(
          latitude: 37.7750,
          longitude: -122.4195,
          timestamp: start.add(const Duration(hours: 9)),
          isSignificant: const Value(true),
        ),
      );

      await service.deleteData(
        startDate: start,
        endDate: end,
        dataTypes: const {DataType.locations},
        keepSignificantLocations: true,
      );

      final remaining = await locationDb.getLocationPointsBetween(start, end);

      expect(remaining.length, 1);
      expect(remaining.single.isSignificant, isTrue);
    });

    test(
      'one-sided delete removes matching geofence and movement rows',
      () async {
        final oldTime = DateTime(2026, 1, 1, 10, 0);
        final newTime = DateTime(2026, 3, 1, 10, 0);

        await locationDb.insertGeofence(
          GeofenceAreasCompanion.insert(
            id: 'home',
            name: 'Home',
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 100,
          ),
        );

        await locationDb.insertLocationPoint(
          LocationPointsCompanion.insert(
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: oldTime,
          ),
        );
        await locationDb.insertLocationPoint(
          LocationPointsCompanion.insert(
            latitude: 37.7750,
            longitude: -122.4195,
            timestamp: newTime,
          ),
        );

        await locationDb.insertGeofenceEvent(
          GeofenceEventsCompanion.insert(
            geofenceId: 'home',
            eventType: 'enter',
            timestamp: oldTime,
            latitude: 37.7749,
            longitude: -122.4194,
          ),
        );
        await locationDb.insertGeofenceEvent(
          GeofenceEventsCompanion.insert(
            geofenceId: 'home',
            eventType: 'exit',
            timestamp: newTime,
            latitude: 37.7750,
            longitude: -122.4195,
          ),
        );

        await locationDb
            .into(locationDb.movementData)
            .insert(
              MovementDataCompanion.insert(
                timestamp: oldTime,
                state: 'walking',
                averageMagnitude: 1.0,
                sampleCount: 5,
                stillPercentage: 0.0,
                walkingPercentage: 100.0,
                runningPercentage: 0.0,
                drivingPercentage: 0.0,
              ),
            );
        await locationDb
            .into(locationDb.movementData)
            .insert(
              MovementDataCompanion.insert(
                timestamp: newTime,
                state: 'walking',
                averageMagnitude: 1.0,
                sampleCount: 5,
                stillPercentage: 0.0,
                walkingPercentage: 100.0,
                runningPercentage: 0.0,
                drivingPercentage: 0.0,
              ),
            );

        await service.deleteData(
          endDate: DateTime(2026, 1, 31, 23, 59),
          dataTypes: const {DataType.locations},
          keepSignificantLocations: false,
        );

        final remainingLocations = await locationDb
            .select(locationDb.locationPoints)
            .get();
        final remainingEvents = await locationDb
            .select(locationDb.geofenceEvents)
            .get();
        final remainingMovement = await locationDb
            .select(locationDb.movementData)
            .get();

        expect(remainingLocations.length, 1);
        expect(remainingLocations.single.timestamp, newTime);
        expect(remainingEvents.length, 1);
        expect(remainingEvents.single.timestamp, newTime);
        expect(remainingMovement.length, 1);
        expect(remainingMovement.single.timestamp, newTime);
      },
    );

    test('bounded delete only removes summaries for affected days', () async {
      final affectedDay = DateTime(2026, 2, 2);
      final untouchedDay = DateTime(2026, 2, 3);

      await locationDb
          .into(locationDb.locationSummaries)
          .insert(
            LocationSummariesCompanion.insert(
              date: affectedDay,
              totalPoints: 2,
              totalDistance: 10,
              placesVisited: 1,
              mainLocations: '[]',
            ),
          );
      await locationDb
          .into(locationDb.locationSummaries)
          .insert(
            LocationSummariesCompanion.insert(
              date: untouchedDay,
              totalPoints: 2,
              totalDistance: 10,
              placesVisited: 1,
              mainLocations: '[]',
            ),
          );

      await locationDb.insertLocationPoint(
        LocationPointsCompanion.insert(
          latitude: 37.7749,
          longitude: -122.4194,
          timestamp: affectedDay.add(const Duration(hours: 8)),
          isSignificant: const Value(false),
        ),
      );

      await service.deleteData(
        startDate: affectedDay,
        endDate: affectedDay.add(const Duration(days: 1)),
        dataTypes: const {DataType.locations},
        keepSignificantLocations: false,
      );

      final summaries = await locationDb
          .select(locationDb.locationSummaries)
          .get();

      expect(summaries.length, 1);
      expect(summaries.single.date, untouchedDay);
    });

    test('wipeAllData triggers geofence runtime reload callback', () async {
      var reloadCalls = 0;
      final serviceWithReload = DataDeletionService(
        locationDb: locationDb,
        mediaDb: mediaDb,
        reloadGeofences: () async {
          reloadCalls += 1;
        },
      );

      await serviceWithReload.wipeAllData();

      expect(reloadCalls, 1);
    });

    test('unbounded delete removes future-dated location points too', () async {
      await locationDb.insertLocationPoint(
        LocationPointsCompanion.insert(
          latitude: 37.7749,
          longitude: -122.4194,
          timestamp: DateTime.now().add(const Duration(days: 2)),
          isSignificant: const Value(false),
        ),
      );

      await service.deleteData(
        dataTypes: const {DataType.locations},
        keepSignificantLocations: false,
      );

      final remaining = await locationDb
          .select(locationDb.locationPoints)
          .get();
      expect(remaining, isEmpty);
    });
  });
}
