import 'package:aura_one/database/location_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationDatabase indexes', () {
    late LocationDatabase database;

    setUp(() {
      database = LocationDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('fresh schema creates hot timestamp and geofence indexes', () async {
      final result = await database
          .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE type = 'index' AND name NOT LIKE 'sqlite_%'",
          )
          .get();

      final indexes = {
        for (final row in result)
          row.read<String>('name'): row.read<String>('sql'),
      };

      expect(indexes.keys, contains('idx_location_points_timestamp'));
      expect(indexes.keys, contains('idx_geofence_areas_is_active'));
      expect(indexes.keys, contains('idx_geofence_events_timestamp'));
      expect(indexes.keys, contains('idx_geofence_events_geofence_timestamp'));
      expect(indexes.keys, contains('idx_location_notes_geofence_timestamp'));
      expect(indexes.keys, contains('idx_movement_data_timestamp'));

      expect(
        indexes['idx_location_points_timestamp'],
        contains('location_points'),
      );
      expect(indexes['idx_location_points_timestamp'], contains('(timestamp)'));
      expect(
        indexes['idx_geofence_events_geofence_timestamp'],
        contains('(geofence_id, timestamp)'),
      );
    });
  });
}
