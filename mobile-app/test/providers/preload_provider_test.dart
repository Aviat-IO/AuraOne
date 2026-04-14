import 'package:aura_one/database/location_database.dart' as loc_db;
import 'package:aura_one/database/media_database.dart' as media_db;
import 'package:aura_one/providers/location_clustering_provider.dart';
import 'package:aura_one/providers/location_database_provider.dart';
import 'package:aura_one/providers/media_database_provider.dart';
import 'package:aura_one/providers/preload_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preloadProvider', () {
    late loc_db.LocationDatabase locationDatabase;
    late media_db.MediaDatabase mediaDatabase;
    late ProviderContainer container;

    setUp(() {
      locationDatabase = loc_db.LocationDatabase.forTesting(
        NativeDatabase.memory(),
      );
      mediaDatabase = media_db.MediaDatabase.forTesting(
        NativeDatabase.memory(),
      );
    });

    tearDown(() async {
      container.dispose();
      await locationDatabase.close();
      await mediaDatabase.close();
    });

    test('path-only preload skips clustering', () async {
      var clusterReads = 0;

      container = ProviderContainer(
        overrides: [
          locationDatabaseProvider.overrideWithValue(locationDatabase),
          mediaDatabaseProvider.overrideWithValue(mediaDatabase),
          clusteredLocationsProvider(DateTime(2026, 1, 10)).overrideWith((
            ref,
          ) async {
            clusterReads += 1;
            return [];
          }),
        ],
      );

      container.read(preloadProvider(DateTime(2026, 1, 10)));
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(clusterReads, 0);
    });

    test('clustered preload still allows explicit cluster warming', () async {
      var clusterReads = 0;

      container = ProviderContainer(
        overrides: [
          locationDatabaseProvider.overrideWithValue(locationDatabase),
          mediaDatabaseProvider.overrideWithValue(mediaDatabase),
          clusteredLocationsProvider(DateTime(2026, 1, 10)).overrideWith((
            ref,
          ) async {
            clusterReads += 1;
            return [];
          }),
        ],
      );

      container.read(clusteredPreloadProvider(DateTime(2026, 1, 10)));
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(clusterReads, 1);
    });
  });
}
