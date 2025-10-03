import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../export/backup_scheduler.dart';
import '../export/export_service.dart';
import '../export/export_schema.dart';
import '../export/enhanced_encryption_service.dart';
import '../export/syncthing_service.dart';
import '../export/blossom_storage_service.dart';
import '../database/database_provider.dart';
import 'backup_restoration_service.dart';
import '../../database/journal_database.dart';
import '../../database/media_database.dart';

/// Backup provider types
enum BackupProvider {
  local('Local Storage'),
  syncthing('Syncthing'),
  blossom('Blossom');
  
  final String displayName;
  const BackupProvider(this.displayName);
}

/// Backup metadata for tracking and incremental backups
class BackupMetadata {
  final String backupId;
  final DateTime timestamp;
  final String checksum;
  final int entryCount;
  final int mediaCount;
  final double sizeMB;
  final BackupProvider provider;
  final String? location; // File path or server location
  final Map<String, dynamic> incrementalData;
  final bool isFullBackup;
  final String? parentBackupId; // For incremental backups
  
  BackupMetadata({
    required this.backupId,
    required this.timestamp,
    required this.checksum,
    required this.entryCount,
    required this.mediaCount,
    required this.sizeMB,
    required this.provider,
    this.location,
    Map<String, dynamic>? incrementalData,
    this.isFullBackup = true,
    this.parentBackupId,
  }) : incrementalData = incrementalData ?? {};
  
  Map<String, dynamic> toJson() => {
    'backupId': backupId,
    'timestamp': timestamp.toIso8601String(),
    'checksum': checksum,
    'entryCount': entryCount,
    'mediaCount': mediaCount,
    'sizeMB': sizeMB,
    'provider': provider.name,
    'location': location,
    'incrementalData': incrementalData,
    'isFullBackup': isFullBackup,
    'parentBackupId': parentBackupId,
  };
  
  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      backupId: json['backupId'],
      timestamp: DateTime.parse(json['timestamp']),
      checksum: json['checksum'],
      entryCount: json['entryCount'] ?? 0,
      mediaCount: json['mediaCount'] ?? 0,
      sizeMB: (json['sizeMB'] ?? 0.0).toDouble(),
      provider: BackupProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => BackupProvider.local,
      ),
      location: json['location'],
      incrementalData: json['incrementalData'] ?? {},
      isFullBackup: json['isFullBackup'] ?? true,
      parentBackupId: json['parentBackupId'],
    );
  }
}

/// Backup restoration result
class BackupRestoreResult {
  final bool success;
  final String? error;
  final int restoredEntries;
  final int restoredMedia;
  final Duration duration;
  
  BackupRestoreResult({
    required this.success,
    this.error,
    this.restoredEntries = 0,
    this.restoredMedia = 0,
    required this.duration,
  });
}

/// Main BackupManager service for coordinating all backup operations
class BackupManager {
  static BackupManager? _instance;
  static BackupManager get instance => _instance ??= BackupManager._();
  
  BackupManager._();
  
  // Storage keys
  static const String _metadataKey = 'backup_metadata_list';
  static const String _lastIncrementalKey = 'last_incremental_data';
  
  // Backup metadata cache
  List<BackupMetadata> _backupHistory = [];
  
  /// Initialize the backup manager
  Future<void> initialize() async {
    await _loadBackupHistory();
    await BackupScheduler.initialize();

    // Initialize secure backup encryption in background (non-blocking)
    initializeSecureEncryption().catchError((e) {
      debugPrint('Background encryption initialization failed: $e');
    });
  }

  /// Initialize secure backup encryption
  Future<void> initializeSecureEncryption() async {
    if (!await EnhancedEncryptionService.isBackupEncryptionConfigured()) {
      // Generate and store secure backup encryption key automatically
      await EnhancedEncryptionService.generateSecureBackupPassword();
      debugPrint('Secure backup encryption configured automatically');
    }
  }

  /// Get secure backup encryption information
  Future<BackupKeyInfo?> getBackupEncryptionInfo() async {
    return await EnhancedEncryptionService.getStoredBackupKey();
  }

  /// Regenerate backup encryption keys (for security refresh)
  Future<BackupKeyInfo> regenerateBackupEncryption() async {
    // Clear existing keys
    await EnhancedEncryptionService.clearAllBackupKeys();
    
    // Generate new secure backup password
    final keyInfo = await EnhancedEncryptionService.generateSecureBackupPassword();
    debugPrint('Backup encryption keys regenerated');
    
    return keyInfo;
  }
  
  /// Perform a backup to specified providers
  Future<Map<BackupProvider, BackupMetadata>> performBackup({
    List<BackupProvider>? providers,
    bool isManual = false,
    bool incremental = false,
    String? encryptionPassword,
    void Function(double)? onProgress,
  }) async {
    final targetProviders = providers ?? [BackupProvider.local];
    final results = <BackupProvider, BackupMetadata>{};
    
    // Prepare backup data
    final backupData = await _prepareBackupData(incremental: incremental);
    
    // Calculate total steps for progress
    final totalSteps = targetProviders.length;
    int completedSteps = 0;
    
    // Backup to each provider
    for (final provider in targetProviders) {
      try {
        final metadata = await _backupToProvider(
          provider: provider,
          data: backupData,
          incremental: incremental,
          encryptionPassword: encryptionPassword,
          onProgress: (progress) {
            final overallProgress = (completedSteps + progress) / totalSteps;
            onProgress?.call(overallProgress);
          },
        );
        
        results[provider] = metadata;
        completedSteps++;
        
        // Save metadata
        _backupHistory.add(metadata);
        await _saveBackupHistory();
        
      } catch (e) {
        debugPrint('Backup failed for ${provider.displayName}: $e');
        // Continue with other providers
      }
    }
    
    // Update incremental tracking if successful
    if (results.isNotEmpty && incremental) {
      await _updateIncrementalTracking(backupData);
    }
    
    return results;
  }
  
  /// Restore from a specific backup
  Future<BackupRestoreResult> restoreBackup({
    required BackupMetadata metadata,
    void Function(double)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Download backup data
      onProgress?.call(0.1);
      final backupData = await _downloadBackup(metadata);
      
      // Verify backup integrity
      onProgress?.call(0.3);
      final isValid = await _verifyBackupIntegrity(
        data: backupData,
        expectedChecksum: metadata.checksum,
      );
      
      if (!isValid) {
        throw Exception('Backup integrity verification failed');
      }
      
      // Restore data
      onProgress?.call(0.5);
      final result = await _restoreBackupData(
        backupData,
        onProgress: (progress) {
          onProgress?.call(0.5 + progress * 0.5);
        },
      );
      
      stopwatch.stop();
      
      return BackupRestoreResult(
        success: true,
        restoredEntries: result['entries'] ?? 0,
        restoredMedia: result['media'] ?? 0,
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
  
  /// Get backup history
  List<BackupMetadata> getBackupHistory({BackupProvider? provider}) {
    if (provider != null) {
      return _backupHistory
          .where((b) => b.provider == provider)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return List.from(_backupHistory)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Verify backup integrity
  Future<bool> verifyBackup(BackupMetadata metadata) async {
    try {
      final data = await _downloadBackup(metadata);
      return await _verifyBackupIntegrity(
        data: data,
        expectedChecksum: metadata.checksum,
      );
    } catch (e) {
      debugPrint('Backup verification failed: $e');
      return false;
    }
  }
  
  /// Schedule automatic backups
  Future<void> scheduleAutomaticBackups(BackupConfig config) async {
    await BackupScheduler.saveConfig(config);
    await BackupScheduler.scheduleBackup(config);
  }
  
  /// Clean up old backups
  Future<void> cleanupOldBackups({
    int keepLastCount = 10,
    Duration? olderThan,
  }) async {
    final cutoffDate = olderThan != null
        ? DateTime.now().subtract(olderThan)
        : null;

    // Sort by timestamp (newest first)
    _backupHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Determine which backups to keep
    final toKeep = <BackupMetadata>[];
    final toDelete = <BackupMetadata>[];

    for (int i = 0; i < _backupHistory.length; i++) {
      final backup = _backupHistory[i];

      if (i < keepLastCount &&
          (cutoffDate == null || backup.timestamp.isAfter(cutoffDate))) {
        toKeep.add(backup);
      } else {
        toDelete.add(backup);
      }
    }

    // Delete old backup files
    for (final backup in toDelete) {
      await _deleteBackupFile(backup);
    }

    // Update history
    _backupHistory = toKeep;
    await _saveBackupHistory();
  }

  /// Delete a specific backup
  Future<bool> deleteBackup(BackupMetadata backup) async {
    try {
      await _deleteBackupFile(backup);
      _backupHistory.removeWhere((b) => b.backupId == backup.backupId);
      await _saveBackupHistory();
      return true;
    } catch (e) {
      debugPrint('Failed to delete backup: $e');
      return false;
    }
  }
  
  // Private methods
  
  Future<Map<String, dynamic>> _prepareBackupData({
    required bool incremental,
  }) async {
    // Get database instances from provider
    final journalDb = await DatabaseProvider.instance.journalDatabase;
    final mediaDb = await DatabaseProvider.instance.mediaDatabase;
    final locationDb = await DatabaseProvider.instance.locationDatabase;

    Map<String, dynamic>? lastIncremental;
    DateTime? lastBackupDate;

    if (incremental) {
      final prefs = await SharedPreferences.getInstance();
      final lastData = prefs.getString(_lastIncrementalKey);
      if (lastData != null) {
        lastIncremental = json.decode(lastData);
        lastBackupDate = DateTime.tryParse(lastIncremental?['timestamp'] ?? '');
      }
    }

    // Fetch journal entries
    List<JournalEntry> entries;
    if (incremental && lastBackupDate != null) {
      // Only get entries modified after last backup
      entries = await journalDb.getJournalEntriesBetween(
        lastBackupDate,
        DateTime.now(),
      );
    } else {
      // Get all entries for full backup
      final firstEntry = await (journalDb.select(journalDb.journalEntries)
        ..orderBy([(t) => OrderingTerm.asc(t.date)])
        ..limit(1))
        .getSingleOrNull();

      if (firstEntry != null) {
        entries = await journalDb.getJournalEntriesBetween(
          firstEntry.date,
          DateTime.now(),
        );
      } else {
        entries = [];
      }
    }

    // Convert entries to export format
    final journalEntries = <Map<String, dynamic>>[];
    final journalActivities = <Map<String, dynamic>>[];

    for (final entry in entries) {
      // Get activities for this entry
      final activities = await journalDb.getActivitiesForEntry(entry.id);

      journalEntries.add({
        'id': entry.id.toString(),
        'date': entry.date.toIso8601String(),
        'title': entry.title,
        'content': entry.content,
        'mood': entry.mood,
        'tags': entry.tags != null ? json.decode(entry.tags!) : [],
        'summary': entry.summary,
        'isAutoGenerated': entry.isAutoGenerated,
        'isEdited': entry.isEdited,
        'createdAt': entry.createdAt.toIso8601String(),
        'updatedAt': entry.updatedAt.toIso8601String(),
      });

      for (final activity in activities) {
        journalActivities.add({
          'id': activity.id.toString(),
          'journalEntryId': activity.journalEntryId.toString(),
          'activityType': activity.activityType,
          'description': activity.description,
          'metadata': activity.metadata,
          'timestamp': activity.timestamp.toIso8601String(),
          'createdAt': activity.createdAt.toIso8601String(),
        });
      }
    }

    // Fetch media items
    List<MediaItem> mediaItems;
    if (incremental && lastBackupDate != null) {
      // Only get media added after last backup
      mediaItems = await (mediaDb.select(mediaDb.mediaItems)
        ..where((t) => t.addedDate.isBiggerThan(Variable(lastBackupDate)))
        ..where((t) => t.isDeleted.equals(false)))
        .get();
    } else {
      // Get all non-deleted media
      mediaItems = await (mediaDb.select(mediaDb.mediaItems)
        ..where((t) => t.isDeleted.equals(false)))
        .get();
    }

    // Convert media to export format
    final mediaReferences = <Map<String, dynamic>>[];
    for (final item in mediaItems) {
      mediaReferences.add({
        'id': item.id,
        'filePath': item.filePath,
        'fileName': item.fileName,
        'mimeType': item.mimeType,
        'fileSize': item.fileSize,
        'fileHash': item.fileHash,
        'createdDate': item.createdDate.toIso8601String(),
        'modifiedDate': item.modifiedDate.toIso8601String(),
        'addedDate': item.addedDate.toIso8601String(),
        'width': item.width,
        'height': item.height,
        'duration': item.duration,
      });
    }

    // Fetch location summaries instead of visits
    final locationSummaries = <Map<String, dynamic>>[];
    if (incremental && lastBackupDate != null) {
      final summaries = await (locationDb.select(locationDb.locationSummaries)
        ..where((t) => t.date.isBiggerThan(Variable(lastBackupDate))))
        .get();

      for (final summary in summaries) {
        locationSummaries.add({
          'id': summary.id.toString(),
          'date': summary.date.toIso8601String(),
          'totalPoints': summary.totalPoints,
          'totalDistance': summary.totalDistance,
          'placesVisited': summary.placesVisited,
          'mainLocations': summary.mainLocations,
          'activeMinutes': summary.activeMinutes,
          'createdAt': summary.createdAt.toIso8601String(),
        });
      }
    } else {
      // Get all summaries for full backup
      final summaries = await locationDb.select(locationDb.locationSummaries).get();
      for (final summary in summaries) {
        locationSummaries.add({
          'id': summary.id.toString(),
          'date': summary.date.toIso8601String(),
          'totalPoints': summary.totalPoints,
          'totalDistance': summary.totalDistance,
          'placesVisited': summary.placesVisited,
          'mainLocations': summary.mainLocations,
          'activeMinutes': summary.activeMinutes,
          'createdAt': summary.createdAt.toIso8601String(),
        });
      }
    }

    // Fetch location notes
    final locationNotes = <Map<String, dynamic>>[];
    if (incremental && lastBackupDate != null) {
      final notes = await (locationDb.select(locationDb.locationNotes)
        ..where((t) => t.createdAt.isBiggerThan(Variable(lastBackupDate))))
        .get();

      for (final note in notes) {
        locationNotes.add({
          'id': note.id.toString(),
          'noteId': note.noteId,
          'content': note.content,
          'latitude': note.latitude,
          'longitude': note.longitude,
          'placeName': note.placeName,
          'geofenceId': note.geofenceId,
          'tags': note.tags,
          'timestamp': note.timestamp.toIso8601String(),
          'isPublished': note.isPublished,
          'createdAt': note.createdAt.toIso8601String(),
        });
      }
    } else {
      // Get all notes for full backup
      final notes = await locationDb.select(locationDb.locationNotes).get();
      for (final note in notes) {
        locationNotes.add({
          'id': note.id.toString(),
          'noteId': note.noteId,
          'content': note.content,
          'latitude': note.latitude,
          'longitude': note.longitude,
          'placeName': note.placeName,
          'geofenceId': note.geofenceId,
          'tags': note.tags,
          'timestamp': note.timestamp.toIso8601String(),
          'isPublished': note.isPublished,
          'createdAt': note.createdAt.toIso8601String(),
        });
      }
    }

    // Calculate export date range
    DateTime? exportStartDate;
    DateTime? exportEndDate;
    if (entries.isNotEmpty) {
      exportStartDate = entries.first.date;
      exportEndDate = entries.last.date;
    } else {
      exportStartDate = DateTime.now().subtract(const Duration(days: 30));
      exportEndDate = DateTime.now();
    }

    final metadata = ExportSchema.createMetadata(
      exportStartDate: exportStartDate,
      exportEndDate: exportEndDate,
      totalEntries: journalEntries.length,
      totalMedia: mediaReferences.length,
      totalSizeBytes: 0, // Will be calculated during backup
      exportReason: incremental ? 'Incremental backup' : 'Full backup',
    );

    // Note: Don't close database connections since they're shared instances

    return {
      'journalEntries': journalEntries,
      'journalActivities': journalActivities,
      'mediaReferences': mediaReferences,
      'locationSummaries': locationSummaries,
      'locationNotes': locationNotes,
      'metadata': metadata,
      'incremental': incremental,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  Future<BackupMetadata> _backupToProvider({
    required BackupProvider provider,
    required Map<String, dynamic> data,
    required bool incremental,
    String? encryptionPassword,
    void Function(double)? onProgress,
  }) async {
    final backupId = _generateBackupId();
    final timestamp = DateTime.now();
    
    switch (provider) {
      case BackupProvider.local:
        return await _backupToLocal(
          backupId: backupId,
          timestamp: timestamp,
          data: data,
          incremental: incremental,
          encryptionPassword: encryptionPassword,
          onProgress: onProgress,
        );
        
      case BackupProvider.syncthing:
        return await _backupToSyncthing(
          backupId: backupId,
          timestamp: timestamp,
          data: data,
          incremental: incremental,
          encryptionPassword: encryptionPassword,
          onProgress: onProgress,
        );
        
      case BackupProvider.blossom:
        return await _backupToBlossom(
          backupId: backupId,
          timestamp: timestamp,
          data: data,
          incremental: incremental,
          encryptionPassword: encryptionPassword,
          onProgress: onProgress,
        );
    }
  }
  
  Future<BackupMetadata> _backupToLocal({
    required String backupId,
    required DateTime timestamp,
    required Map<String, dynamic> data,
    required bool incremental,
    String? encryptionPassword,
    void Function(double)? onProgress,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(directory.path, 'backups'));
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    final backupFile = File(path.join(
      backupDir.path,
      'backup_${timestamp.millisecondsSinceEpoch}.aura',
    ));
    
    onProgress?.call(0.2);
    
    // Get or create backup encryption key
    final keyInfo = await EnhancedEncryptionService.getStoredBackupKey() 
        ?? await EnhancedEncryptionService.generateSecureBackupPassword();
    
    onProgress?.call(0.4);
    
    // Encrypt backup metadata with enhanced security
    final encryptedMetadata = await EnhancedEncryptionService.encryptBackupMetadata(
      data['metadata'] ?? {},
      customKey: keyInfo,
    );
    
    // Prepare full backup data
    final fullBackupData = Map<String, dynamic>.from(data);
    fullBackupData['encryptedMetadata'] = {
      'ciphertext': base64.encode(encryptedMetadata.encryptedData.ciphertext),
      'iv': base64.encode(encryptedMetadata.encryptedData.iv),
    };
    
    final backupContent = json.encode(fullBackupData);
    final backupBytes = utf8.encode(backupContent);

    // Calculate checksum on unencrypted data for verification
    final checksum = sha256.convert(backupBytes).toString();

    onProgress?.call(0.6);

    // Use enhanced encryption for large file optimization
    final encryptedBytes = await EnhancedEncryptionService.encryptLargeFile(
      backupBytes,
      customKey: keyInfo,
      onProgress: (progress) {
        onProgress?.call(0.6 + progress * 0.3);
      },
    );
    
    await backupFile.writeAsBytes(encryptedBytes);
    
    onProgress?.call(1.0);
    
    return BackupMetadata(
      backupId: backupId,
      timestamp: timestamp,
      checksum: checksum,
      entryCount: (data['journalEntries'] as List).length,
      mediaCount: (data['mediaReferences'] as List).length,
      sizeMB: encryptedBytes.length / 1024 / 1024,
      provider: BackupProvider.local,
      location: backupFile.path,
      isFullBackup: !incremental,
    );
  }
  
  Future<BackupMetadata> _backupToSyncthing({
    required String backupId,
    required DateTime timestamp,
    required Map<String, dynamic> data,
    required bool incremental,
    String? encryptionPassword,
    void Function(double)? onProgress,
  }) async {
    // Use SyncthingService to export
    final result = await SyncthingService.exportToSyncthingFolder(
      appVersion: '0.1.0',
      userData: data['userData'] ?? {},
      journalEntries: data['journalEntries'] ?? [],
      mediaReferences: data['mediaReferences'] ?? [],
      metadata: data['metadata'] ?? {},
      exportDate: timestamp,
      password: encryptionPassword,
      isScheduledBackup: false,
      onProgress: onProgress,
    );
    
    if (!result.success) {
      throw Exception(result.error ?? 'Syncthing backup failed');
    }
    
    final file = File(result.filePath!);
    final fileBytes = await file.readAsBytes();
    final checksum = sha256.convert(fileBytes).toString();
    
    return BackupMetadata(
      backupId: backupId,
      timestamp: timestamp,
      checksum: checksum,
      entryCount: (data['journalEntries'] as List).length,
      mediaCount: (data['mediaReferences'] as List).length,
      sizeMB: fileBytes.length / 1024 / 1024,
      provider: BackupProvider.syncthing,
      location: result.syncFolderPath,
      isFullBackup: !incremental,
    );
  }
  
  Future<BackupMetadata> _backupToBlossom({
    required String backupId,
    required DateTime timestamp,
    required Map<String, dynamic> data,
    required bool incremental,
    String? encryptionPassword,
    void Function(double)? onProgress,
  }) async {
    // First create a local file
    final tempFilePath = await ExportService.exportToLocalFile(
      appVersion: '0.1.0',
      userData: data['userData'] ?? {},
      journalEntries: data['journalEntries'] ?? [],
      mediaReferences: data['mediaReferences'] ?? [],
      metadata: data['metadata'] ?? {},
      exportDate: timestamp,
      onProgress: (progress) => onProgress?.call(progress * 0.5),
    );
    
    // Get Blossom configuration from preferences
    final prefs = await SharedPreferences.getInstance();
    final blossomServerUrl = prefs.getString('blossom_server_url');
    final blossomNsec = prefs.getString('blossom_nsec');
    
    if (blossomServerUrl == null || blossomServerUrl.isEmpty) {
      throw Exception('Blossom server URL not configured');
    }
    
    // Upload to Blossom
    final uploadUrl = await BlossomStorageService.uploadFile(
      serverUrl: blossomServerUrl,
      filePath: tempFilePath,
      nsec: blossomNsec,
    );
    
    if (uploadUrl == null) {
      throw Exception('Failed to upload to Blossom server');
    }
    
    onProgress?.call(1.0);
    
    final file = File(tempFilePath);
    final fileBytes = await file.readAsBytes();
    final checksum = sha256.convert(fileBytes).toString();
    final sizeMB = fileBytes.length / 1024 / 1024;
    
    // Clean up temporary file
    await file.delete();
    
    return BackupMetadata(
      backupId: backupId,
      timestamp: timestamp,
      checksum: checksum,
      entryCount: (data['journalEntries'] as List).length,
      mediaCount: (data['mediaReferences'] as List).length,
      sizeMB: sizeMB,
      provider: BackupProvider.blossom,
      location: uploadUrl,
      isFullBackup: !incremental,
    );
  }
  
  Future<Map<String, dynamic>> _downloadBackup(BackupMetadata metadata) async {
    switch (metadata.provider) {
      case BackupProvider.local:
        return await _downloadFromLocal(metadata);
        
      case BackupProvider.syncthing:
        return await _downloadFromSyncthing(metadata);
        
      case BackupProvider.blossom:
        return await _downloadFromBlossom(metadata);
    }
  }
  
  Future<Map<String, dynamic>> _downloadFromLocal(
    BackupMetadata metadata,
  ) async {
    if (metadata.location == null) {
      throw Exception('No file path for local backup');
    }

    final file = File(metadata.location!);
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }

    var bytes = await file.readAsBytes();

    try {
      // Check if this is an enhanced encrypted backup (.aura file)
      if (metadata.location!.endsWith('.aura') ||
          (bytes.isNotEmpty && (bytes[0] == 2 || bytes[0] == 3))) {
        // Enhanced encryption format
        final keyInfo = await EnhancedEncryptionService.getStoredBackupKey();

        if (keyInfo == null) {
          throw Exception('Backup encryption key not available - please check your encryption settings');
        }

        try {
          // Decrypt using enhanced service
          final decryptedBytes = await EnhancedEncryptionService.decryptLargeFile(
            bytes,
            keyInfo,
          );

          final content = utf8.decode(decryptedBytes);
          final data = Map<String, dynamic>.from(json.decode(content));

          // Decrypt metadata if present
          if (data.containsKey('encryptedMetadata')) {
            try {
              final encryptedMeta = data['encryptedMetadata'];
              final encryptedData = EncryptedData(
                ciphertext: base64.decode(encryptedMeta['ciphertext']),
                iv: base64.decode(encryptedMeta['iv']),
              );

              final encryptedMetadata = EncryptedBackupMetadata(
                encryptedData: encryptedData,
                keyInfo: keyInfo,
              );

              final decryptedMetadata = await EnhancedEncryptionService
                  .decryptBackupMetadata(encryptedMetadata);

              data['metadata'] = decryptedMetadata;
            } catch (e) {
              debugPrint('Failed to decrypt backup metadata: $e');
              // Continue without decrypted metadata
            }
          }

          return data;
        } catch (e) {
          throw Exception('Failed to decrypt backup: ${e.toString()}');
        }

      } else {
        // Try to parse as unencrypted JSON first
        try {
          final content = utf8.decode(bytes);
          return json.decode(content);
        } catch (e) {
          // If JSON parsing fails, it might be legacy encrypted
          throw Exception('Failed to decode backup data: The file may be corrupted or in an unsupported format');
        }
      }
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('Backup encryption key not available')) {
        rethrow;
      } else if (e.toString().contains('Failed to decrypt')) {
        rethrow;
      } else {
        throw Exception('Failed to read backup file: ${e.toString()}');
      }
    }
  }
  
  Future<Map<String, dynamic>> _downloadFromSyncthing(
    BackupMetadata metadata,
  ) async {
    if (metadata.location == null) {
      throw Exception('No Syncthing folder path for backup');
    }
    
    // Find the backup file in Syncthing folder
    final syncDir = Directory(metadata.location!);
    if (!await syncDir.exists()) {
      throw Exception('Syncthing folder not found');
    }
    
    // Look for backup file by timestamp
    final files = await syncDir.list().toList();
    for (final entity in files) {
      if (entity is File && entity.path.contains(metadata.timestamp.millisecondsSinceEpoch.toString())) {
        final content = await entity.readAsString();
        return json.decode(content);
      }
    }
    
    throw Exception('Backup file not found in Syncthing folder');
  }
  
  Future<Map<String, dynamic>> _downloadFromBlossom(
    BackupMetadata metadata,
  ) async {
    if (metadata.location == null) {
      throw Exception('No Blossom URL for backup');
    }
    
    // Download from Blossom URL using HTTP GET
    final response = await http.get(Uri.parse(metadata.location!));
    if (response.statusCode != 200) {
      throw Exception('Failed to download backup: HTTP ${response.statusCode}');
    }
    
    // Create temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(path.join(tempDir.path, 'backup_${DateTime.now().millisecondsSinceEpoch}.backup'));
    await tempFile.writeAsBytes(response.bodyBytes);
    
    final content = await tempFile.readAsString();
    return json.decode(content);
  }
  
  Future<bool> _verifyBackupIntegrity({
    required Map<String, dynamic> data,
    required String expectedChecksum,
  }) async {
    try {
      // For verification, recreate the exact format that was used for checksum generation
      final content = json.encode(data);
      final bytes = utf8.encode(content);
      final actualChecksum = sha256.convert(bytes).toString();

      final isValid = actualChecksum == expectedChecksum;
      if (!isValid) {
        debugPrint('Backup verification failed:');
        debugPrint('Expected: $expectedChecksum');
        debugPrint('Actual: $actualChecksum');
      }

      return isValid;
    } catch (e) {
      debugPrint('Error during backup verification: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>> _restoreBackupData(
    Map<String, dynamic> data, {
    void Function(double)? onProgress,
  }) async {
    // Use the BackupRestorationService for proper restoration
    final restorationService = BackupRestorationService();
    
    // Create a temporary metadata for the restoration
    final tempMetadata = BackupMetadata(
      backupId: 'direct_restore_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      checksum: '',
      entryCount: (data['journalEntries'] as List?)?.length ?? 0,
      mediaCount: (data['mediaReferences'] as List?)?.length ?? 0,
      sizeMB: 0.0,
      provider: BackupProvider.local,
    );
    
    // Execute restoration with merge strategy
    final result = await restorationService.executeRestore(
      backupData: {
        'journal': {
          'entries': data['journalEntries'] ?? [],
        },
        'media': {
          'references': data['mediaReferences'] ?? [],
        },
        'metadata': data['metadata'] ?? {},
      },
      strategy: RestoreStrategy.merge,
      conflictResolution: ConflictResolution.useNewer,
      onProgress: (processed, total, item) {
        if (total > 0) {
          onProgress?.call(processed / total);
        }
      },
    );
    
    return result;
  }
  
  Future<void> _deleteBackupFile(BackupMetadata metadata) async {
    try {
      switch (metadata.provider) {
        case BackupProvider.local:
          if (metadata.location != null) {
            final file = File(metadata.location!);
            if (await file.exists()) {
              await file.delete();
            }
          }
          break;
          
        case BackupProvider.syncthing:
          // Syncthing manages its own cleanup
          break;
          
        case BackupProvider.blossom:
          // Blossom deletion would require API call
          break;
      }
    } catch (e) {
      debugPrint('Failed to delete backup file: $e');
    }
  }
  
  Future<void> _updateIncrementalTracking(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Store current state for next incremental backup
    final trackingData = {
      'timestamp': data['timestamp'],
      'entryCount': (data['journalEntries'] as List).length,
      'lastEntryIds': [], // TODO: Track actual entry IDs
    };
    
    await prefs.setString(_lastIncrementalKey, json.encode(trackingData));
  }
  
  String _generateBackupId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }
  
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      length,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }
  
  Future<void> _loadBackupHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_metadataKey);
    
    if (historyJson != null) {
      final history = json.decode(historyJson) as List;
      _backupHistory = history
          .map((h) => BackupMetadata.fromJson(h))
          .toList();
    }
  }
  
  Future<void> _saveBackupHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Keep only last 100 entries
    if (_backupHistory.length > 100) {
      _backupHistory = _backupHistory.sublist(0, 100);
    }
    
    final history = _backupHistory.map((h) => h.toJson()).toList();
    await prefs.setString(_metadataKey, json.encode(history));
  }
}