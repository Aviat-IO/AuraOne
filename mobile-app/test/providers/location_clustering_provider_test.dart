import 'package:aura_one/database/location_database.dart';
import 'package:aura_one/providers/location_clustering_provider.dart';
import 'package:aura_one/providers/location_database_provider.dart';
import 'package:aura_one/services/ai/dbscan_clustering.dart';
import 'package:aura_one/utils/date_utils.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Location clustering provider', () {
    late LocationDatabase database;
    late ProviderContainer container;

    setUp(() {
      database = LocationDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [locationDatabaseProvider.overrideWithValue(database)],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('location writes invalidate only the affected day cache', () async {
      final firstDay = DateTime(2026, 1, 10);
      final secondDay = DateTime(2026, 1, 11);

      await _insertClusterPoint(
        database,
        firstDay.add(const Duration(hours: 9)),
      );
      await _insertClusterPoint(
        database,
        firstDay.add(const Duration(hours: 9, minutes: 1)),
      );
      await _insertClusterPoint(
        database,
        secondDay.add(const Duration(hours: 9)),
      );
      await _insertClusterPoint(
        database,
        secondDay.add(const Duration(hours: 9, minutes: 1)),
      );

      final initialFirstDayClusters = await container.read(
        clusteredLocationsProvider(firstDay).future,
      );
      final initialSecondDayClusters = await container.read(
        clusteredLocationsProvider(secondDay).future,
      );
      await container.read(journeySegmentsProvider(firstDay).future);
      await container.read(journeySegmentsProvider(secondDay).future);

      expect(initialFirstDayClusters.single.points.length, 2);
      expect(initialSecondDayClusters.single.points.length, 2);

      final firstDayClusterEvents = <AsyncValue<List<LocationCluster>>>[];
      final secondDayClusterEvents = <AsyncValue<List<LocationCluster>>>[];
      final firstDayJourneyEvents = <AsyncValue<List<JourneySegment>>>[];
      final secondDayJourneyEvents = <AsyncValue<List<JourneySegment>>>[];

      final firstDayClusterSub = container
          .listen<AsyncValue<List<LocationCluster>>>(
            clusteredLocationsProvider(firstDay),
            (previous, next) {
              if (previous != null) {
                firstDayClusterEvents.add(next);
              }
            },
            fireImmediately: false,
          );
      final secondDayClusterSub = container
          .listen<AsyncValue<List<LocationCluster>>>(
            clusteredLocationsProvider(secondDay),
            (previous, next) {
              if (previous != null) {
                secondDayClusterEvents.add(next);
              }
            },
            fireImmediately: false,
          );
      final firstDayJourneySub = container
          .listen<AsyncValue<List<JourneySegment>>>(
            journeySegmentsProvider(firstDay),
            (previous, next) {
              if (previous != null) {
                firstDayJourneyEvents.add(next);
              }
            },
            fireImmediately: false,
          );
      final secondDayJourneySub = container
          .listen<AsyncValue<List<JourneySegment>>>(
            journeySegmentsProvider(secondDay),
            (previous, next) {
              if (previous != null) {
                secondDayJourneyEvents.add(next);
              }
            },
            fireImmediately: false,
          );

      addTearDown(firstDayClusterSub.close);
      addTearDown(secondDayClusterSub.close);
      addTearDown(firstDayJourneySub.close);
      addTearDown(secondDayJourneySub.close);

      await _insertClusterPoint(
        database,
        firstDay.add(const Duration(hours: 9, minutes: 2)),
      );

      await _waitForCondition(
        () => firstDayClusterEvents.any((event) => event.hasValue),
      );
      await _waitForCondition(
        () => firstDayJourneyEvents.any((event) => event.hasValue),
      );

      final updatedFirstDayClusters = await container.read(
        clusteredLocationsProvider(firstDay).future,
      );
      final updatedSecondDayClusters = await container.read(
        clusteredLocationsProvider(secondDay).future,
      );

      expect(updatedFirstDayClusters.single.points.length, 3);
      expect(updatedSecondDayClusters.single.points.length, 2);
      expect(firstDayClusterEvents, isNotEmpty);
      expect(firstDayJourneyEvents, isNotEmpty);
      expect(secondDayClusterEvents, isEmpty);
      expect(secondDayJourneyEvents, isEmpty);
    });

    test('walking outlier filtering uses real meter distances', () async {
      final day = DateTime(2026, 1, 12);
      final originLatitude = 37.7749;
      const longitude = -122.4194;
      const metersPerLatitudeDegree = 111320.0;
      final latitudeStep = 60 / metersPerLatitudeDegree;

      for (var i = 0; i < 4; i++) {
        await database.insertLocationPoint(
          LocationPointsCompanion.insert(
            latitude: originLatitude + (latitudeStep * i),
            longitude: longitude,
            timestamp: day.add(Duration(hours: 8, seconds: i * 10)),
            accuracy: const Value(5),
            activityType: const Value('walking'),
          ),
        );
      }

      final clusters = await container.read(
        clusteredLocationsProvider(day).future,
      );

      expect(
        clusters,
        isEmpty,
        reason:
            'Walking samples that jump 60 meters every 10 seconds should be filtered as distance outliers.',
      );
    });

    test(
      'day point loading downsamples while preserving first and last points',
      () async {
        final day = DateTime(2026, 1, 13);

        for (var i = 0; i < 1205; i++) {
          await database.insertLocationPoint(
            LocationPointsCompanion.insert(
              latitude: 37.7749 + (i * 0.00001),
              longitude: -122.4194,
              timestamp: day.add(Duration(seconds: i)),
              accuracy: const Value(5),
            ),
          );
        }

        final points = await container.read(
          locationPointsForDateProvider(day).future,
        );

        expect(points.length, 1000);
        expect(points.first.timestamp, day);
        expect(points.last.timestamp, day.add(const Duration(seconds: 1204)));
      },
    );

    test(
      'cleanup invalidates only days whose location points were deleted',
      () async {
        final today = DateTimeUtils.getLocalDateOnly(DateTime.now());
        final oldDaySeed = today.subtract(const Duration(days: 40));
        final recentDaySeed = today.subtract(const Duration(days: 1));
        final oldDay = DateTime(
          oldDaySeed.year,
          oldDaySeed.month,
          oldDaySeed.day,
        );
        final recentDay = DateTime(
          recentDaySeed.year,
          recentDaySeed.month,
          recentDaySeed.day,
        );

        await _insertClusterPoint(
          database,
          oldDay.add(const Duration(hours: 9)),
        );
        await _insertClusterPoint(
          database,
          oldDay.add(const Duration(hours: 9, minutes: 1)),
        );
        await _insertClusterPoint(
          database,
          recentDay.add(const Duration(hours: 9)),
        );
        await _insertClusterPoint(
          database,
          recentDay.add(const Duration(hours: 9, minutes: 1)),
        );

        final initialOldDayClusters = await container.read(
          clusteredLocationsProvider(oldDay).future,
        );
        final initialRecentDayClusters = await container.read(
          clusteredLocationsProvider(recentDay).future,
        );

        expect(initialOldDayClusters.single.points.length, 2);
        expect(initialRecentDayClusters.single.points.length, 2);

        final oldDayEvents = <AsyncValue<List<LocationCluster>>>[];
        final recentDayEvents = <AsyncValue<List<LocationCluster>>>[];

        final oldDaySub = container.listen<AsyncValue<List<LocationCluster>>>(
          clusteredLocationsProvider(oldDay),
          (previous, next) {
            if (previous != null) {
              oldDayEvents.add(next);
            }
          },
          fireImmediately: false,
        );
        final recentDaySub = container
            .listen<AsyncValue<List<LocationCluster>>>(
              clusteredLocationsProvider(recentDay),
              (previous, next) {
                if (previous != null) {
                  recentDayEvents.add(next);
                }
              },
              fireImmediately: false,
            );

        addTearDown(oldDaySub.close);
        addTearDown(recentDaySub.close);

        await database.cleanupOldLocationData(
          retentionPeriod: const Duration(days: 30),
          keepSignificantPoints: false,
        );

        await _waitForCondition(
          () => oldDayEvents.any((event) => event.hasValue),
        );

        final updatedOldDayClusters = await container.read(
          clusteredLocationsProvider(oldDay).future,
        );
        final updatedRecentDayClusters = await container.read(
          clusteredLocationsProvider(recentDay).future,
        );

        expect(updatedOldDayClusters, isEmpty);
        expect(updatedRecentDayClusters.single.points.length, 2);
        expect(oldDayEvents, isNotEmpty);
        expect(recentDayEvents, isEmpty);
      },
    );
  });
}

Future<void> _insertClusterPoint(
  LocationDatabase database,
  DateTime timestamp,
) async {
  await database.insertLocationPoint(
    LocationPointsCompanion.insert(
      latitude: 37.7749,
      longitude: -122.4194,
      timestamp: timestamp,
      accuracy: const Value(5),
      activityType: const Value('still'),
    ),
  );
}

Future<void> _waitForCondition(bool Function() condition) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }

  fail('Condition was not met before timeout.');
}
