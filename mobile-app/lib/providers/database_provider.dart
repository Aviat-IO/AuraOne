import 'package:drift/drift.dart' as drift;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../database/location_database.dart';
import '../database/media_database.dart';
import '../models/collected_data.dart';
import 'location_database_provider.dart';
import 'media_database_provider.dart';

// This file provides unified database access for backward compatibility

// Re-export location database provider
export 'location_database_provider.dart' show locationDatabaseProvider;

// Re-export media database provider
export 'media_database_provider.dart' show mediaDatabaseProvider;

// Create a simple database service wrapper for the context and fusion engines
class DatabaseService {
  final LocationDatabase locationDb;
  final MediaDatabase mediaDb;

  DatabaseService({
    required this.locationDb,
    required this.mediaDb,
  });

  // Add collected data (generic method for backward compatibility)
  Future<void> addCollectedData(Map<String, dynamic> data) async {
    // Route to appropriate database based on data type
    final type = data['type'] as String?;

    if (type == 'location' || type == 'fused_context') {
      // Store in location database as a location point with metadata
      await locationDb.insertLocationPoint(
        LocationPointsCompanion(
          latitude: drift.Value(data['latitude'] ?? 0.0),
          longitude: drift.Value(data['longitude'] ?? 0.0),
          altitude: drift.Value(data['altitude']),
          accuracy: drift.Value(data['accuracy']),
          speed: drift.Value(data['speed']),
          heading: drift.Value(data['heading']),
          timestamp: drift.Value(DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String())),
          activityType: drift.Value(data['activity']),
          isSignificant: const drift.Value(false),
        ),
      );
    } else if (type == 'photo' || type == 'media') {
      // Store in media database as a media item
      final id = data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await mediaDb.into(mediaDb.mediaItems).insert(
        MediaItemsCompanion(
          id: drift.Value(id),
          filePath: drift.Value(data['filePath']),
          fileName: drift.Value(data['filename'] ?? 'unknown'),
          mimeType: drift.Value(data['mimeType'] ?? 'image/jpeg'),
          fileSize: drift.Value(data['fileSize'] ?? 0),
          createdDate: drift.Value(DateTime.parse(data['createDateTime'] ?? DateTime.now().toIso8601String())),
          modifiedDate: drift.Value(DateTime.parse(data['modifiedDateTime'] ?? DateTime.now().toIso8601String())),
          width: drift.Value(data['width']),
          height: drift.Value(data['height']),
          duration: drift.Value(data['duration']),
        ),
      );
    }
  }

  // Get data by date range (for PersonalContextEngine)
  Future<List<CollectedData>> getDataByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await queryCollectedData(
      startDate: startDate,
      endDate: endDate,
    );

    return results.map((data) => CollectedData(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: data['type'] ?? 'unknown',
      timestamp: DateTime.parse(data['timestamp']),
      data: data,
    )).toList();
  }

  // Query collected data for the fusion engine
  Future<List<Map<String, dynamic>>> queryCollectedData({
    required DateTime startDate,
    required DateTime endDate,
    String? type,
  }) async {
    final results = <Map<String, dynamic>>[];

    // Query location data
    if (type == null || type == 'location' || type == 'fused_context') {
      final locations = await locationDb.getLocationPointsBetween(
        startDate,
        endDate,
      );

      for (final loc in locations) {
        results.add({
          'type': 'location',
          'timestamp': loc.timestamp.toIso8601String(),
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'accuracy': loc.accuracy,
          'activityType': loc.activityType,
          'altitude': loc.altitude,
          'speed': loc.speed,
          'heading': loc.heading,
        });
      }
    }

    // Query media data
    if (type == null || type == 'photo' || type == 'media') {
      final media = await (mediaDb.select(mediaDb.mediaItems)
        ..where((tbl) => tbl.createdDate.isBetweenValues(startDate, endDate)))
        .get();

      for (final asset in media) {
        results.add({
          'type': 'media',
          'timestamp': asset.createdDate.toIso8601String(),
          'filename': asset.fileName,
          'mimeType': asset.mimeType,
          'width': asset.width,
          'height': asset.height,
          'duration': asset.duration,
        });
      }
    }

    // Sort by timestamp
    results.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    return results;
  }
}

// Database service provider that combines both databases
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final locationDb = ref.watch(locationDatabaseProvider);
  final mediaDb = ref.watch(mediaDatabaseProvider);

  return DatabaseService(
    locationDb: locationDb,
    mediaDb: mediaDb,
  );
});