import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../export/encryption_service.dart' as legacy_encryption;
import '../export/enhanced_encryption_service.dart';
import '../database/database_provider.dart';
import 'backup_manager.dart';
import '../../database/journal_database.dart';
import '../../database/media_database.dart';
import '../../database/location_database.dart';

/// Backup restoration strategies
enum RestoreStrategy {
  /// Replace all existing data with backup
  replace,
  /// Merge backup with existing data (no duplicates)
  merge,
  /// Append backup data (may create duplicates)
  append,
}

/// Conflict resolution for merge strategy
enum ConflictResolution {
  /// Keep existing data when conflict occurs
  keepExisting,
  /// Use backup data when conflict occurs
  useBackup,
  /// Use the newer data based on timestamp
  useNewer,
}

/// Restoration progress tracking
class RestoreProgress {
  final String currentPhase;
  final double overallProgress;
  final int processedEntries;
  final int totalEntries;
  final int processedMedia;
  final int totalMedia;
  final String? currentItem;
  
  RestoreProgress({
    required this.currentPhase,
    required this.overallProgress,
    this.processedEntries = 0,
    this.totalEntries = 0,
    this.processedMedia = 0,
    this.totalMedia = 0,
    this.currentItem,
  });
}

/// Service for restoring backups to the app storage
class BackupRestorationService {
  
  final StreamController<RestoreProgress> _progressController = 
      StreamController<RestoreProgress>.broadcast();
  
  BackupRestorationService();
  
  Stream<RestoreProgress> get progressStream => _progressController.stream;
  
  /// Restore a backup from BackupMetadata
  Future<BackupRestoreResult> restoreFromMetadata(
    BackupMetadata metadata, {
    RestoreStrategy strategy = RestoreStrategy.merge,
    ConflictResolution conflictResolution = ConflictResolution.useNewer,
    String? encryptionPassword,
    void Function(RestoreProgress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Phase 1: Download backup
      _updateProgress(
        phase: 'Downloading backup',
        progress: 0.1,
        onProgress: onProgress,
      );
      
      final backupData = await _downloadBackupData(metadata, encryptionPassword);
      
      // Phase 2: Validate backup
      _updateProgress(
        phase: 'Validating backup',
        progress: 0.2,
        onProgress: onProgress,
      );
      
      final validation = await _validateBackupData(backupData);
      if (!validation.isValid) {
        throw Exception('Invalid backup data: ${validation.errors.join(', ')}');
      }
      
      // Phase 3: Prepare restoration
      _updateProgress(
        phase: 'Preparing restoration',
        progress: 0.3,
        onProgress: onProgress,
      );

      // Support both old and new backup formats
      final totalEntries = (backupData['journalEntries'] as List?)?.length ??
                          (backupData['journal']?['entries'] as List?)?.length ?? 0;
      final totalMedia = (backupData['mediaReferences'] as List?)?.length ??
                        (backupData['media']?['references'] as List?)?.length ?? 0;
      
      // Phase 4: Restore data based on strategy
      _updateProgress(
        phase: 'Restoring data',
        progress: 0.4,
        totalEntries: totalEntries,
        totalMedia: totalMedia,
        onProgress: onProgress,
      );
      
      final restoredCounts = await executeRestore(
        backupData: backupData,
        strategy: strategy,
        conflictResolution: conflictResolution,
        onProgress: (processed, total, item) {
          _updateProgress(
            phase: 'Restoring data',
            progress: 0.4 + (0.5 * (processed / total)),
            processedEntries: processed,
            totalEntries: totalEntries,
            totalMedia: totalMedia,
            currentItem: item,
            onProgress: onProgress,
          );
        },
      );
      
      // Phase 5: Complete (media restoration handled in executeRestore)
      final mediaCount = restoredCounts['media'] ?? 0;
      
      // Phase 6: Complete
      _updateProgress(
        phase: 'Restoration complete',
        progress: 1.0,
        processedEntries: restoredCounts['entries'] ?? 0,
        totalEntries: totalEntries,
        processedMedia: mediaCount,
        totalMedia: totalMedia,
        onProgress: onProgress,
      );
      
      stopwatch.stop();
      
      return BackupRestoreResult(
        success: true,
        restoredEntries: restoredCounts['entries'] ?? 0,
        restoredMedia: mediaCount,
        duration: stopwatch.elapsed,
      );
      
    } catch (e) {
      stopwatch.stop();
      return BackupRestoreResult(
        success: false,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }
  
  /// Restore from a file path
  Future<BackupRestoreResult> restoreFromFile(
    String filePath, {
    RestoreStrategy strategy = RestoreStrategy.merge,
    ConflictResolution conflictResolution = ConflictResolution.useNewer,
    String? encryptionPassword,
    void Function(RestoreProgress)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return BackupRestoreResult(
        success: false,
        error: 'Backup file not found',
        duration: Duration.zero,
      );
    }
    
    try {
      var bytes = await file.readAsBytes();
      
      // Decrypt if needed
      if (encryptionPassword != null) {
        // Get backup key info for decryption
        final keyInfo = await EnhancedEncryptionService.getStoredBackupKey();
        if (keyInfo != null) {
          bytes = await EnhancedEncryptionService.decryptLargeFile(bytes, keyInfo);
        } else {
          // Fallback to legacy encryption
          bytes = await legacy_encryption.EncryptionService.decryptFile(bytes, password: encryptionPassword);
        }
      } else if (_isEncrypted(bytes)) {
        return BackupRestoreResult(
          success: false,
          error: 'Backup is encrypted but no password provided',
          duration: Duration.zero,
        );
      }
      
      final content = utf8.decode(bytes);
      final backupData = json.decode(content) as Map<String, dynamic>;
      
      // Create temporary metadata for restoration
      final metadata = BackupMetadata(
        backupId: 'file_restore_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        checksum: '',
        entryCount: (backupData['journal']?['entries'] as List?)?.length ?? 0,
        mediaCount: (backupData['media']?['references'] as List?)?.length ?? 0,
        sizeMB: bytes.length / (1024 * 1024),
        provider: BackupProvider.local,
        location: filePath,
      );
      
      return restoreFromMetadata(
        metadata,
        strategy: strategy,
        conflictResolution: conflictResolution,
        encryptionPassword: encryptionPassword,
        onProgress: onProgress,
      );
      
    } catch (e) {
      return BackupRestoreResult(
        success: false,
        error: 'Failed to read backup file: $e',
        duration: Duration.zero,
      );
    }
  }
  
  /// Preview backup contents without restoring
  Future<BackupPreview> previewBackup(
    BackupMetadata metadata, {
    String? encryptionPassword,
  }) async {
    try {
      final backupData = await _downloadBackupData(metadata, encryptionPassword);
      
      final entries = backupData['journal']?['entries'] as List<dynamic>? ?? [];
      final media = backupData['media']?['references'] as List<dynamic>? ?? [];
      final backupMetadata = backupData['metadata'] as Map<String, dynamic>? ?? {};
      
      // Get date range
      DateTime? startDate;
      DateTime? endDate;
      
      for (final entry in entries) {
        final date = DateTime.tryParse(entry['date'] ?? '');
        if (date != null) {
          startDate = startDate == null || date.isBefore(startDate) 
              ? date : startDate;
          endDate = endDate == null || date.isAfter(endDate) 
              ? date : endDate;
        }
      }
      
      // Get tag summary
      final tags = <String>{};
      for (final entry in entries) {
        final entryTags = entry['tags'] as List<dynamic>? ?? [];
        tags.addAll(entryTags.cast<String>());
      }
      
      return BackupPreview(
        entryCount: entries.length,
        mediaCount: media.length,
        dateRange: startDate != null && endDate != null 
            ? DateTimeRange(start: startDate, end: endDate)
            : null,
        tags: tags.toList()..sort(),
        totalSizeMB: (backupMetadata['total_size_bytes'] ?? 0) / (1024 * 1024),
        schemaVersion: backupData['schema']?['version'] ?? 'unknown',
        exportDate: DateTime.tryParse(backupData['schema']?['exported'] ?? ''),
      );
      
    } catch (e) {
      throw Exception('Failed to preview backup: $e');
    }
  }
  
  // Private methods
  
  Future<Map<String, dynamic>> _downloadBackupData(
    BackupMetadata metadata,
    String? encryptionPassword,
  ) async {
    try {
      // Download backup data based on provider
      Map<String, dynamic> data;

      if (metadata.provider == BackupProvider.local) {
        final file = File(metadata.location!);
        if (!await file.exists()) {
          throw Exception('Backup file not found at ${metadata.location}');
        }

        var bytes = await file.readAsBytes();

        // Check if this is an enhanced encrypted backup (.aura file)
        if (metadata.location!.endsWith('.aura') ||
            (bytes.isNotEmpty && (bytes[0] == 2 || bytes[0] == 3))) {
          // Enhanced encryption format
          final keyInfo = await EnhancedEncryptionService.getStoredBackupKey();

          if (keyInfo == null) {
            throw Exception('Backup encryption key not available');
          }

          // Decrypt using enhanced service
          final decryptedBytes = await EnhancedEncryptionService.decryptLargeFile(
            bytes,
            keyInfo,
          );

          final content = utf8.decode(decryptedBytes);
          data = json.decode(content);
        } else {
          // Try unencrypted first
          try {
            final content = utf8.decode(bytes);
            data = json.decode(content);
          } catch (e) {
            throw Exception('Failed to decode backup data: ${e.toString()}');
          }
        }

      } else if (metadata.provider == BackupProvider.blossom) {
        // Download from Blossom using HTTP
        final response = await http.get(Uri.parse(metadata.location!));
        if (response.statusCode != 200) {
          throw Exception('Failed to download backup: HTTP ${response.statusCode}');
        }

        try {
          data = json.decode(response.body);
        } catch (e) {
          throw Exception('Failed to parse backup data from Blossom: ${e.toString()}');
        }

      } else {
        throw UnsupportedError('Provider ${metadata.provider} not supported for restoration');
      }

      return data;

    } catch (e) {
      debugPrint('Error downloading backup data: $e');
      rethrow;
    }
  }
  
  Future<BackupValidation> _validateBackupData(Map<String, dynamic> data) async {
    final errors = <String>[];
    
    // Check required fields
    if (!data.containsKey('schema')) {
      errors.add('Missing schema information');
    }
    
    if (!data.containsKey('journal')) {
      errors.add('Missing journal data');
    }
    
    // Validate schema version compatibility
    final schemaVersion = data['schema']?['version'] ?? '';
    if (!_isCompatibleVersion(schemaVersion)) {
      errors.add('Incompatible schema version: $schemaVersion');
    }
    
    // Validate data structure
    final entries = data['journal']?['entries'];
    if (entries != null && entries is! List) {
      errors.add('Invalid journal entries format');
    }
    
    return BackupValidation(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  Future<Map<String, int>> executeRestore({
    required Map<String, dynamic> backupData,
    required RestoreStrategy strategy,
    required ConflictResolution conflictResolution,
    required void Function(int processed, int total, String? item) onProgress,
  }) async {
    // Support both old and new backup formats
    // New format: direct lists at root level
    // Old format: nested in journal/media objects
    final journalEntries = (backupData['journalEntries'] as List<dynamic>?) ??
                          (backupData['journal']?['entries'] as List<dynamic>?) ?? [];
    final journalActivities = backupData['journalActivities'] as List<dynamic>? ?? [];
    final mediaReferences = (backupData['mediaReferences'] as List<dynamic>?) ??
                           (backupData['media']?['references'] as List<dynamic>?) ?? [];
    final locationSummaries = backupData['locationSummaries'] as List<dynamic>? ?? [];
    final locationNotes = backupData['locationNotes'] as List<dynamic>? ?? [];

    final totalItems = journalEntries.length + mediaReferences.length + locationSummaries.length + locationNotes.length;
    int processedItems = 0;
    int restoredEntries = 0;
    int restoredMedia = 0;
    int restoredLocations = 0;

    // Get database instances from provider
    final journalDb = await DatabaseProvider.instance.journalDatabase;
    final mediaDb = await DatabaseProvider.instance.mediaDatabase;
    final locationDb = await DatabaseProvider.instance.locationDatabase;

    try {
      // Handle strategy-specific preparation
      if (strategy == RestoreStrategy.replace) {
        // Clear existing data from all databases
        await journalDb.delete(journalDb.journalActivities).go();
        await journalDb.delete(journalDb.journalEntries).go();
        await mediaDb.delete(mediaDb.mediaItems).go();
        await locationDb.delete(locationDb.locationPoints).go();
        await locationDb.delete(locationDb.locationSummaries).go();
        await locationDb.delete(locationDb.locationNotes).go();
      }

      // Restore journal entries
      final entryIdMapping = <String, int>{}; // Map old IDs to new IDs

      for (final entryData in journalEntries) {
        try {
          final entry = entryData as Map<String, dynamic>;
          final date = DateTime.parse(entry['date']);

          // Check for existing entry on this date
          final existing = await journalDb.getJournalEntryForDate(date);

          bool shouldRestore = false;
          JournalEntriesCompanion? companion;

          if (existing != null) {
            // Handle conflict based on strategy and resolution
            if (strategy == RestoreStrategy.merge) {
              switch (conflictResolution) {
                case ConflictResolution.keepExisting:
                  shouldRestore = false;
                  entryIdMapping[entry['id'].toString()] = existing.id;
                  break;
                case ConflictResolution.useBackup:
                  shouldRestore = true;
                  companion = JournalEntriesCompanion(
                    id: Value(existing.id),
                    date: Value(date),
                    title: Value(entry['title']),
                    content: Value(entry['content']),
                    mood: Value(entry['mood']),
                    tags: Value(entry['tags'] != null ? json.encode(entry['tags']) : null),
                    summary: Value(entry['summary']),
                    isAutoGenerated: Value(entry['isAutoGenerated'] ?? true),
                    isEdited: Value(entry['isEdited'] ?? false),
                    createdAt: Value(DateTime.parse(entry['createdAt'])),
                    updatedAt: Value(DateTime.now()),
                  );
                  break;
                case ConflictResolution.useNewer:
                  final existingUpdate = existing.updatedAt;
                  final backupUpdate = DateTime.parse(entry['updatedAt']);
                  if (backupUpdate.isAfter(existingUpdate)) {
                    shouldRestore = true;
                    companion = JournalEntriesCompanion(
                      id: Value(existing.id),
                      date: Value(date),
                      title: Value(entry['title']),
                      content: Value(entry['content']),
                      mood: Value(entry['mood']),
                      tags: Value(entry['tags'] != null ? json.encode(entry['tags']) : null),
                      summary: Value(entry['summary']),
                      isAutoGenerated: Value(entry['isAutoGenerated'] ?? true),
                      isEdited: Value(entry['isEdited'] ?? false),
                      createdAt: Value(DateTime.parse(entry['createdAt'])),
                      updatedAt: Value(DateTime.now()),
                    );
                  } else {
                    shouldRestore = false;
                    entryIdMapping[entry['id'].toString()] = existing.id;
                  }
                  break;
              }
            } else if (strategy == RestoreStrategy.append) {
              // For append, create new entry with different date
              final newDate = date.add(Duration(microseconds: DateTime.now().microsecondsSinceEpoch % 1000));
              shouldRestore = true;
              companion = JournalEntriesCompanion.insert(
                date: newDate,
                title: entry['title'],
                content: entry['content'],
                mood: Value(entry['mood']),
                tags: Value(entry['tags'] != null ? json.encode(entry['tags']) : null),
                summary: Value(entry['summary']),
                isAutoGenerated: Value(entry['isAutoGenerated'] ?? true),
                isEdited: Value(entry['isEdited'] ?? false),
                createdAt: Value(DateTime.parse(entry['createdAt'])),
                updatedAt: Value(DateTime.now()),
              );
            }
          } else {
            // No conflict, create new entry
            shouldRestore = true;
            companion = JournalEntriesCompanion.insert(
              date: date,
              title: entry['title'],
              content: entry['content'],
              mood: Value(entry['mood']),
              tags: Value(entry['tags'] != null ? json.encode(entry['tags']) : null),
              summary: Value(entry['summary']),
              isAutoGenerated: Value(entry['isAutoGenerated'] ?? true),
              isEdited: Value(entry['isEdited'] ?? false),
              createdAt: Value(DateTime.parse(entry['createdAt'])),
              updatedAt: Value(DateTime.now()),
            );
          }

          if (shouldRestore && companion != null) {
            final newId = await journalDb.insertJournalEntry(companion);
            entryIdMapping[entry['id'].toString()] = newId;
            restoredEntries++;
          }

          processedItems++;
          onProgress(processedItems, totalItems, 'Journal: ${entry['title']}');

        } catch (e) {
          debugPrint('Failed to restore journal entry: $e');
        }
      }

      // Restore journal activities
      for (final activityData in journalActivities) {
        try {
          final activity = activityData as Map<String, dynamic>;
          final oldEntryId = activity['journalEntryId'].toString();
          final newEntryId = entryIdMapping[oldEntryId];

          if (newEntryId != null) {
            await journalDb.insertJournalActivity(
              JournalActivitiesCompanion.insert(
                journalEntryId: newEntryId,
                activityType: activity['activityType'],
                description: activity['description'],
                metadata: Value(activity['metadata']),
                timestamp: DateTime.parse(activity['timestamp']),
                createdAt: Value(DateTime.parse(activity['createdAt'])),
              ),
            );
          }
        } catch (e) {
          debugPrint('Failed to restore journal activity: $e');
        }
      }

      // Restore media items
      for (final mediaData in mediaReferences) {
        try {
          final media = mediaData as Map<String, dynamic>;
          final mediaId = media['id'].toString();

          // Check if media already exists
          final existing = await (mediaDb.select(mediaDb.mediaItems)
            ..where((t) => t.id.equals(mediaId)))
            .getSingleOrNull();

          if (existing == null || strategy == RestoreStrategy.replace ||
              (strategy == RestoreStrategy.merge && conflictResolution == ConflictResolution.useBackup)) {
            await mediaDb.into(mediaDb.mediaItems).insertOnConflictUpdate(
              MediaItemsCompanion(
                id: Value(mediaId),
                filePath: Value(media['filePath']),
                fileName: Value(media['fileName']),
                mimeType: Value(media['mimeType']),
                fileSize: Value(media['fileSize']),
                fileHash: Value(media['fileHash']),
                createdDate: Value(DateTime.parse(media['createdDate'])),
                modifiedDate: Value(DateTime.parse(media['modifiedDate'])),
                addedDate: Value(DateTime.parse(media['addedDate'])),
                width: Value(media['width']),
                height: Value(media['height']),
                duration: Value(media['duration']),
              ),
            );
            restoredMedia++;
          }

          processedItems++;
          onProgress(processedItems, totalItems, 'Media: ${media['fileName']}');

        } catch (e) {
          debugPrint('Failed to restore media item: $e');
        }
      }

      // Restore location summaries
      for (final summaryData in locationSummaries) {
        try {
          final summary = summaryData as Map<String, dynamic>;
          final date = DateTime.parse(summary['date']);

          // Check if summary for this date already exists
          final existing = await (locationDb.select(locationDb.locationSummaries)
            ..where((t) => t.date.equals(date)))
            .getSingleOrNull();

          if (existing == null || strategy == RestoreStrategy.replace ||
              (strategy == RestoreStrategy.merge && conflictResolution == ConflictResolution.useBackup)) {
            await locationDb.into(locationDb.locationSummaries).insertOnConflictUpdate(
              LocationSummariesCompanion.insert(
                date: date,
                totalPoints: summary['totalPoints'],
                totalDistance: summary['totalDistance'].toDouble(),
                placesVisited: summary['placesVisited'],
                mainLocations: summary['mainLocations'],
                activeMinutes: Value(summary['activeMinutes']),
                createdAt: Value(DateTime.parse(summary['createdAt'])),
              ),
            );
            restoredLocations++;
          }

          processedItems++;
          onProgress(processedItems, totalItems, 'Location summary');

        } catch (e) {
          debugPrint('Failed to restore location summary: $e');
        }
      }

      // Restore location notes
      for (final noteData in locationNotes) {
        try {
          final note = noteData as Map<String, dynamic>;

          await locationDb.into(locationDb.locationNotes).insertOnConflictUpdate(
            LocationNotesCompanion.insert(
              noteId: Value(note['noteId']),
              content: note['content'],
              latitude: note['latitude'].toDouble(),
              longitude: note['longitude'].toDouble(),
              placeName: Value(note['placeName']),
              geofenceId: Value(note['geofenceId']),
              tags: Value(note['tags']),
              timestamp: DateTime.parse(note['timestamp']),
              isPublished: Value(note['isPublished'] ?? false),
              createdAt: Value(DateTime.parse(note['createdAt'])),
            ),
          );
          restoredLocations++;

          processedItems++;
          onProgress(processedItems, totalItems, 'Location note');

        } catch (e) {
          debugPrint('Failed to restore location note: $e');
        }
      }

      // Rebuild search indices
      await journalDb.rebuildSearchIndex();

    } finally {
      // Note: Don't close database connections since they're shared instances
    }

    return {
      'entries': restoredEntries,
      'media': restoredMedia,
      'locations': restoredLocations,
    };
  }
  
  
  // Unused: Kept for compatibility with old backup formats
  /* Future<int> _restoreMediaFiles(
    List<dynamic> mediaReferences) async {
    // This method is now handled in executeRestore
    // Keeping for compatibility with old backup formats
    return 0;
  } */
  
  void _updateProgress({
    required String phase,
    required double progress,
    int processedEntries = 0,
    int totalEntries = 0,
    int processedMedia = 0,
    int totalMedia = 0,
    String? currentItem,
    void Function(RestoreProgress)? onProgress,
  }) {
    final restoreProgress = RestoreProgress(
      currentPhase: phase,
      overallProgress: progress,
      processedEntries: processedEntries,
      totalEntries: totalEntries,
      processedMedia: processedMedia,
      totalMedia: totalMedia,
      currentItem: currentItem,
    );
    
    _progressController.add(restoreProgress);
    onProgress?.call(restoreProgress);
  }
  
  bool _isEncrypted(Uint8List bytes) {
    // Simple heuristic: JSON should start with '{'
    return bytes.isNotEmpty && bytes[0] != 123; // 123 is '{'
  }
  
  bool _isCompatibleVersion(String version) {
    // Check if version is compatible with current schema
    final parts = version.split('.');
    if (parts.isEmpty) return false;
    
    final major = int.tryParse(parts[0]) ?? 0;
    return major == 1; // Currently only v1.x.x is supported
  }
  
  void dispose() {
    _progressController.close();
  }
}

/// Backup preview information
class BackupPreview {
  final int entryCount;
  final int mediaCount;
  final DateTimeRange? dateRange;
  final List<String> tags;
  final double totalSizeMB;
  final String schemaVersion;
  final DateTime? exportDate;
  
  BackupPreview({
    required this.entryCount,
    required this.mediaCount,
    this.dateRange,
    required this.tags,
    required this.totalSizeMB,
    required this.schemaVersion,
    this.exportDate,
  });
}

/// Backup validation result
class BackupValidation {
  final bool isValid;
  final List<String> errors;
  
  BackupValidation({
    required this.isValid,
    required this.errors,
  });
}

/// Date range helper
class DateTimeRange {
  final DateTime start;
  final DateTime end;
  
  DateTimeRange({required this.start, required this.end});
  
  Duration get duration => end.difference(start);
}