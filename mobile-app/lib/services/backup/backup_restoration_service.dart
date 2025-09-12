import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../export/export_schema.dart';
import '../export/encryption_service.dart' as legacy_encryption;
import '../export/enhanced_encryption_service.dart';
import 'backup_manager.dart';

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
  static const String _journalEntriesKey = 'journal_entries';
  static const String _mediaReferencesKey = 'media_references';
  
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
      
      final totalEntries = (backupData['journal']?['entries'] as List?)?.length ?? 0;
      final totalMedia = (backupData['media']?['references'] as List?)?.length ?? 0;
      
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
      
      // Phase 5: Restore media files
      _updateProgress(
        phase: 'Restoring media',
        progress: 0.9,
        processedEntries: restoredCounts['entries'] ?? 0,
        totalEntries: totalEntries,
        onProgress: onProgress,
      );
      
      final mediaCount = await _restoreMediaFiles(
        backupData['media']?['references'] as List<dynamic>? ?? [],
        onProgress: (processed, total) {
          _updateProgress(
            phase: 'Restoring media',
            progress: 0.9 + (0.1 * (processed / total)),
            processedEntries: restoredCounts['entries'] ?? 0,
            totalEntries: totalEntries,
            processedMedia: processed,
            totalMedia: total,
            onProgress: onProgress,
          );
        },
      );
      
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
    // Download backup data based on provider
    Map<String, dynamic> data;
    
    if (metadata.provider == BackupProvider.local) {
      final file = File(metadata.location!);
      final content = await file.readAsString();
      data = json.decode(content);
    } else if (metadata.provider == BackupProvider.blossom) {
      // Download from Blossom using HTTP
      final response = await http.get(Uri.parse(metadata.location!));
      if (response.statusCode != 200) {
        throw Exception('Failed to download backup: HTTP ${response.statusCode}');
      }
      data = json.decode(response.body);
    } else {
      throw UnsupportedError('Provider ${metadata.provider} not supported for restoration');
    }
    
    // Handle encrypted data
    if (encryptionPassword != null) {
      final jsonStr = json.encode(data);
      final encrypted = utf8.encode(jsonStr);
      // Try enhanced encryption first
      final keyInfo = await EnhancedEncryptionService.getStoredBackupKey();
      final decrypted = keyInfo != null
          ? await EnhancedEncryptionService.decryptLargeFile(Uint8List.fromList(encrypted), keyInfo)
          : await legacy_encryption.EncryptionService.decryptFile(Uint8List.fromList(encrypted), password: encryptionPassword);
      data = json.decode(utf8.decode(decrypted));
    }
    
    return data;
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
    final entries = backupData['journal']?['entries'] as List<dynamic>? ?? [];
    final totalEntries = entries.length;
    int restoredCount = 0;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Handle strategy-specific preparation
    if (strategy == RestoreStrategy.replace) {
      // Clear existing data
      await prefs.remove(_journalEntriesKey);
    }
    
    // Get existing entries
    final existingData = prefs.getString(_journalEntriesKey);
    final existingEntries = existingData != null 
        ? (json.decode(existingData) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    
    // Restore each entry
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i] as Map<String, dynamic>;
      
      try {
        final restored = await _restoreJournalEntry(
          entry,
          existingEntries: existingEntries,
          strategy: strategy,
          conflictResolution: conflictResolution,
        );
        
        if (restored) {
          restoredCount++;
        }
        
        onProgress(i + 1, totalEntries, entry['id']?.toString());
        
      } catch (e) {
        debugPrint('Failed to restore entry ${entry['id']}: $e');
      }
    }
    
    // Save updated entries
    await prefs.setString(_journalEntriesKey, json.encode(existingEntries));
    
    return {'entries': restoredCount};
  }
  
  Future<bool> _restoreJournalEntry(
    Map<String, dynamic> entryData,
    {required List<Map<String, dynamic>> existingEntries,
    required RestoreStrategy strategy,
    required ConflictResolution conflictResolution}
  ) async {
    final id = entryData['id']?.toString() ?? '';
    final date = DateTime.tryParse(entryData['date'] ?? '') ?? DateTime.now();
    
    // Check for existing entry
    final existingIndex = existingEntries.indexWhere(
      (e) => e['id'] == id,
    );
    final existing = existingIndex >= 0 ? existingEntries[existingIndex] : null;
    
    if (existing != null) {
      // Handle conflict based on strategy
      if (strategy == RestoreStrategy.merge) {
        switch (conflictResolution) {
          case ConflictResolution.keepExisting:
            return false;
          case ConflictResolution.useBackup:
            existingEntries[existingIndex] = entryData;
            return true;
          case ConflictResolution.useNewer:
            final existingDate = DateTime.tryParse(
              existing['timestamps']?['updated'] ?? existing['date'] ?? ''
            ) ?? date;
            final backupDate = DateTime.tryParse(
              entryData['timestamps']?['updated'] ?? entryData['date'] ?? ''
            ) ?? date;
            if (backupDate.isAfter(existingDate)) {
              existingEntries[existingIndex] = entryData;
              return true;
            }
            return false;
        }
      } else if (strategy == RestoreStrategy.append) {
        // Create new entry with different ID
        final newEntry = Map<String, dynamic>.from(entryData);
        newEntry['id'] = '${id}_restored_${DateTime.now().millisecondsSinceEpoch}';
        existingEntries.add(newEntry);
        return true;
      }
    } else {
      // No conflict, add new entry
      existingEntries.add(entryData);
      return true;
    }
    
    return false;
  }
  
  // Helper methods for managing journal entries in memory
  Future<List<Map<String, dynamic>>> _loadJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_journalEntriesKey);
    if (data != null) {
      return (json.decode(data) as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
  
  Future<void> _saveJournalEntries(List<Map<String, dynamic>> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_journalEntriesKey, json.encode(entries));
  }
  
  Future<int> _restoreMediaFiles(
    List<dynamic> mediaReferences,
    {void Function(int processed, int total)? onProgress}
  ) async {
    int restoredCount = 0;
    
    // Get app documents directory for media storage
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path.join(directory.path, 'media'));
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    
    // Store media references in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final existingMedia = prefs.getString(_mediaReferencesKey);
    final mediaList = existingMedia != null
        ? (json.decode(existingMedia) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    
    for (int i = 0; i < mediaReferences.length; i++) {
      final media = mediaReferences[i] as Map<String, dynamic>;
      
      try {
        // Check if media already exists
        final existingIndex = mediaList.indexWhere(
          (m) => m['id'] == media['id'],
        );
        
        if (existingIndex < 0) {
          // Add new media reference
          mediaList.add(media);
          restoredCount++;
        } else {
          // Update existing media reference
          mediaList[existingIndex] = media;
          restoredCount++;
        }
        
        // TODO: If backup includes actual media files,
        // extract and save them to mediaDir
        
        onProgress?.call(i + 1, mediaReferences.length);
        
      } catch (e) {
        debugPrint('Failed to restore media ${media['id']}: $e');
      }
    }
    
    // Save updated media references
    await prefs.setString(_mediaReferencesKey, json.encode(mediaList));
    
    return restoredCount;
  }
  
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