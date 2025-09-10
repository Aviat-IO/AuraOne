import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';

import '../database/location_database.dart';
import '../database/media_database.dart';
import '../providers/location_database_provider.dart';
import '../providers/media_database_provider.dart';
import '../services/export/export_service.dart';

enum DataType {
  journalEntries,
  locations,
  photos,
  videos,
  calendar,
  all,
}

class DeletionPreview {
  final int journalEntryCount;
  final int locationPointCount;
  final int photoCount;
  final int videoCount;
  final int calendarEventCount;
  final int totalSizeMB;
  final DateTime? oldestDate;
  final DateTime? newestDate;

  DeletionPreview({
    required this.journalEntryCount,
    required this.locationPointCount,
    required this.photoCount,
    required this.videoCount,
    required this.calendarEventCount,
    required this.totalSizeMB,
    this.oldestDate,
    this.newestDate,
  });

  int get totalItemCount =>
      journalEntryCount +
      locationPointCount +
      photoCount +
      videoCount +
      calendarEventCount;

  bool get isEmpty => totalItemCount == 0;
}

class DataDeletionService {
  final LocationDatabase _locationDb;
  final MediaDatabase _mediaDb;

  DataDeletionService({
    required LocationDatabase locationDb,
    required MediaDatabase mediaDb,
  })  : _locationDb = locationDb,
        _mediaDb = mediaDb;

  // Preview what will be deleted
  Future<DeletionPreview> previewDeletion({
    DateTime? startDate,
    DateTime? endDate,
    Set<DataType> dataTypes = const {DataType.all},
    bool keepSignificantLocations = true,
  }) async {
    int journalEntryCount = 0;
    int locationPointCount = 0;
    int photoCount = 0;
    int videoCount = 0;
    int calendarEventCount = 0;
    int totalSizeMB = 0;
    DateTime? oldestDate;
    DateTime? newestDate;

    final effectiveDataTypes = dataTypes.contains(DataType.all)
        ? DataType.values.toSet()
        : dataTypes;

    // Count location data
    if (effectiveDataTypes.contains(DataType.locations)) {
      final locations = await _getLocationsBetween(
        startDate,
        endDate,
        keepSignificantLocations,
      );
      locationPointCount = locations.length;
      
      if (locations.isNotEmpty) {
        final dates = locations.map((l) => l.timestamp).toList()..sort();
        oldestDate = _updateOldestDate(oldestDate, dates.first);
        newestDate = _updateNewestDate(newestDate, dates.last);
      }
    }

    // Count media data
    if (effectiveDataTypes.contains(DataType.photos) ||
        effectiveDataTypes.contains(DataType.videos)) {
      final media = await _getMediaBetween(startDate, endDate);
      
      for (final item in media) {
        if (item.mimeType.startsWith('image/') &&
            effectiveDataTypes.contains(DataType.photos)) {
          photoCount++;
          totalSizeMB += (item.fileSize / (1024 * 1024)).round();
        } else if (item.mimeType.startsWith('video/') &&
            effectiveDataTypes.contains(DataType.videos)) {
          videoCount++;
          totalSizeMB += (item.fileSize / (1024 * 1024)).round();
        }
        
        oldestDate = _updateOldestDate(oldestDate, item.createdDate);
        newestDate = _updateNewestDate(newestDate, item.createdDate);
      }
    }

    // Count calendar events (from location notes for now)
    if (effectiveDataTypes.contains(DataType.calendar)) {
      final notes = await _getLocationNotesBetween(startDate, endDate);
      calendarEventCount = notes.length;
      
      if (notes.isNotEmpty) {
        final dates = notes.map((n) => n.timestamp).toList()..sort();
        oldestDate = _updateOldestDate(oldestDate, dates.first);
        newestDate = _updateNewestDate(newestDate, dates.last);
      }
    }

    return DeletionPreview(
      journalEntryCount: journalEntryCount,
      locationPointCount: locationPointCount,
      photoCount: photoCount,
      videoCount: videoCount,
      calendarEventCount: calendarEventCount,
      totalSizeMB: totalSizeMB,
      oldestDate: oldestDate,
      newestDate: newestDate,
    );
  }

  // Delete data with optional export
  Future<void> deleteData({
    DateTime? startDate,
    DateTime? endDate,
    Set<DataType> dataTypes = const {DataType.all},
    bool keepSignificantLocations = true,
    bool exportBeforeDeletion = false,
    String? exportPath,
    void Function(double)? onProgress,
  }) async {
    final effectiveDataTypes = dataTypes.contains(DataType.all)
        ? DataType.values.toSet()
        : dataTypes;

    // Export data if requested
    if (exportBeforeDeletion) {
      onProgress?.call(0.1);
      await _exportData(
        startDate: startDate,
        endDate: endDate,
        dataTypes: effectiveDataTypes,
        exportPath: exportPath,
      );
      onProgress?.call(0.3);
    }

    double progress = exportBeforeDeletion ? 0.3 : 0.0;
    final progressStep = (1.0 - progress) / effectiveDataTypes.length;

    // Delete location data
    if (effectiveDataTypes.contains(DataType.locations)) {
      await _deleteLocationData(
        startDate,
        endDate,
        keepSignificantLocations,
      );
      progress += progressStep;
      onProgress?.call(progress);
    }

    // Delete media data
    if (effectiveDataTypes.contains(DataType.photos)) {
      await _deleteMediaByType(
        startDate,
        endDate,
        'image/',
      );
      progress += progressStep;
      onProgress?.call(progress);
    }

    if (effectiveDataTypes.contains(DataType.videos)) {
      await _deleteMediaByType(
        startDate,
        endDate,
        'video/',
      );
      progress += progressStep;
      onProgress?.call(progress);
    }

    // Delete calendar/notes data
    if (effectiveDataTypes.contains(DataType.calendar)) {
      await _deleteLocationNotes(startDate, endDate);
      progress += progressStep;
      onProgress?.call(progress);
    }

    // Optimize databases after deletion
    await _optimizeDatabases();
    onProgress?.call(1.0);
  }

  // Complete data wipe
  Future<void> wipeAllData({
    bool exportBeforeDeletion = false,
    String? exportPath,
  }) async {
    if (exportBeforeDeletion) {
      await _exportData(
        dataTypes: {DataType.all},
        exportPath: exportPath,
      );
    }

    // Clear all location data
    await _locationDb.customStatement('DELETE FROM location_points');
    await _locationDb.customStatement('DELETE FROM geofence_events');
    await _locationDb.customStatement('DELETE FROM location_notes');
    await _locationDb.customStatement('DELETE FROM location_summaries');
    await _locationDb.customStatement('DELETE FROM movement_data');

    // Clear all media data
    await _mediaDb.customStatement('DELETE FROM media_items');
    // Cascading deletes will handle related tables

    // Clear app cache
    await _clearAppCache();

    // Optimize databases
    await _optimizeDatabases();
  }

  // Helper methods
  Future<List<LocationPoint>> _getLocationsBetween(
    DateTime? startDate,
    DateTime? endDate,
    bool keepSignificantLocations,
  ) async {
    if (startDate == null && endDate == null) {
      // Get all locations
      return await (_locationDb.select(_locationDb.locationPoints)
            ..where((tbl) {
              if (keepSignificantLocations) {
                return tbl.isSignificant.equals(false);
              }
              return const Constant(true);
            }))
          .get();
    }

    final effectiveStart = startDate ?? DateTime(1970);
    final effectiveEnd = endDate ?? DateTime.now();

    return await _locationDb.getLocationPointsBetween(effectiveStart, effectiveEnd);
  }

  Future<List<MediaItem>> _getMediaBetween(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    if (startDate == null && endDate == null) {
      // Use the existing method for getting recent media
      return await _mediaDb.getRecentMedia(
        duration: const Duration(days: 36500), // ~100 years to get all
        limit: 100000,
      );
    }

    // For date range queries, we'll use a simple approach
    final effectiveStart = startDate ?? DateTime(1970);
    final effectiveEnd = endDate ?? DateTime.now();
    
    // Get recent media and filter by date
    final allMedia = await _mediaDb.getRecentMedia(
      duration: Duration(
        days: DateTime.now().difference(effectiveStart).inDays + 1,
      ),
      limit: 100000,
    );
    
    return allMedia.where((item) => 
      item.createdDate.isAfter(effectiveStart) && 
      item.createdDate.isBefore(effectiveEnd)
    ).toList();
  }

  Future<List<LocationNote>> _getLocationNotesBetween(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    if (startDate == null && endDate == null) {
      return await _locationDb.select(_locationDb.locationNotes).get();
    }

    final effectiveStart = startDate ?? DateTime(1970);
    final effectiveEnd = endDate ?? DateTime.now();

    // Get all location notes and filter manually
    final allNotes = await _locationDb.select(_locationDb.locationNotes).get();
    return allNotes.where((note) => 
      note.timestamp.isAfter(effectiveStart) && 
      note.timestamp.isBefore(effectiveEnd)
    ).toList();
  }

  Future<void> _deleteLocationData(
    DateTime? startDate,
    DateTime? endDate,
    bool keepSignificantLocations,
  ) async {
    if (startDate == null && endDate == null) {
      // Use cleanup method for all data
      await _locationDb.cleanupOldLocationData(
        retentionPeriod: const Duration(days: 0),
        keepSignificantPoints: keepSignificantLocations,
      );
      await _locationDb.delete(_locationDb.geofenceEvents).go();
      await _locationDb.delete(_locationDb.movementData).go();
    } else {
      // Get locations in range and delete by ID
      final locationsToDelete = await _getLocationsBetween(
        startDate, 
        endDate, 
        keepSignificantLocations,
      );
      
      for (final location in locationsToDelete) {
        await (_locationDb.delete(_locationDb.locationPoints)
              ..where((tbl) => tbl.id.equals(location.id)))
            .go();
      }

      // Delete events in date range using custom SQL for now
      if (startDate != null && endDate != null) {
        await _locationDb.customStatement(
          'DELETE FROM geofence_events WHERE timestamp BETWEEN ? AND ?',
          [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
        );
        await _locationDb.customStatement(
          'DELETE FROM movement_data WHERE timestamp BETWEEN ? AND ?',
          [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
        );
      }
    }

    // Regenerate summaries
    await _locationDb.delete(_locationDb.locationSummaries).go();
  }

  Future<void> _deleteMediaByType(
    DateTime? startDate,
    DateTime? endDate,
    String mimeTypePrefix,
  ) async {
    final media = await _getMediaBetween(startDate, endDate);
    final mediaToDelete = media
        .where((item) => item.mimeType.startsWith(mimeTypePrefix))
        .toList();

    for (final item in mediaToDelete) {
      // Soft delete in database
      await _mediaDb.softDeleteMediaItem(item.id);

      // Try to delete actual file if it exists
      if (item.filePath != null) {
        final file = File(item.filePath!);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            // File might be in use or protected
            debugPrint('Could not delete file: ${item.filePath}');
          }
        }
      }
    }
  }

  Future<void> _deleteLocationNotes(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    if (startDate == null && endDate == null) {
      await _locationDb.delete(_locationDb.locationNotes).go();
    } else {
      final notesToDelete = await _getLocationNotesBetween(startDate, endDate);
      
      for (final note in notesToDelete) {
        await (_locationDb.delete(_locationDb.locationNotes)
              ..where((tbl) => tbl.id.equals(note.id)))
            .go();
      }
    }
  }

  Future<void> _exportData({
    DateTime? startDate,
    DateTime? endDate,
    required Set<DataType> dataTypes,
    String? exportPath,
  }) async {
    // Create basic data for export using static ExportService
    final userData = <String, dynamic>{
      'user_id': 'local_user',
      'export_timestamp': DateTime.now().toIso8601String(),
    };

    final journalEntries = <Map<String, dynamic>>[];
    final mediaReferences = <Map<String, dynamic>>[];

    // Get location data if requested
    if (dataTypes.contains(DataType.locations) || dataTypes.contains(DataType.all)) {
      final locations = await _getLocationsBetween(startDate, endDate, false);
      for (final location in locations) {
        journalEntries.add({
          'id': location.id,
          'timestamp': location.timestamp.toIso8601String(),
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
          'type': 'location',
        });
      }
    }

    // Get media data if requested
    if (dataTypes.contains(DataType.photos) || 
        dataTypes.contains(DataType.videos) || 
        dataTypes.contains(DataType.all)) {
      final media = await _getMediaBetween(startDate, endDate);
      for (final item in media) {
        mediaReferences.add({
          'id': item.id,
          'file_path': item.filePath,
          'file_name': item.fileName,
          'mime_type': item.mimeType,
          'file_size': item.fileSize,
          'created_date': item.createdDate.toIso8601String(),
        });
      }
    }

    final metadata = <String, dynamic>{
      'export_reason': 'pre_deletion_backup',
      'date_range': {
        'start': startDate?.toIso8601String(),
        'end': endDate?.toIso8601String(),
      },
      'data_types': dataTypes.map((e) => e.name).toList(),
    };

    // Export using the static method
    await ExportService.exportToLocalFile(
      appVersion: '1.0.0',
      userData: userData,
      journalEntries: journalEntries,
      mediaReferences: mediaReferences,
      metadata: metadata,
      exportDate: DateTime.now(),
      mediaFiles: [], // Empty list for now
    );
  }

  Future<void> _clearAppCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing app cache: $e');
    }
  }

  Future<void> _optimizeDatabases() async {
    await _locationDb.customStatement('VACUUM');
    await _locationDb.customStatement('ANALYZE');
    await _mediaDb.optimizeDatabase();
  }

  DateTime? _updateOldestDate(DateTime? current, DateTime candidate) {
    if (current == null) return candidate;
    return candidate.isBefore(current) ? candidate : current;
  }

  DateTime? _updateNewestDate(DateTime? current, DateTime candidate) {
    if (current == null) return candidate;
    return candidate.isAfter(current) ? candidate : current;
  }
}

// Provider for the DataDeletionService
final dataDeletionServiceProvider = Provider<DataDeletionService>((ref) {
  final locationDb = ref.watch(locationDatabaseProvider);
  final mediaDb = ref.watch(mediaDatabaseProvider);

  return DataDeletionService(
    locationDb: locationDb,
    mediaDb: mediaDb,
  );
});