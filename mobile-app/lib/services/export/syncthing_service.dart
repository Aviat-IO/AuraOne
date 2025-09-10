import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'export_service.dart';

/// Service for exporting data to a Syncthing-monitored folder
/// 
/// This service exports journal data to a dedicated folder that can be
/// monitored and synchronized by Syncthing across devices. The approach
/// enables automatic backup and sync without direct Syncthing API integration.
class SyncthingService {
  static const String defaultSyncFolderName = 'AuraOne_Sync';
  static const String configFileName = '.syncthing_config.json';
  
  /// Get or create the Syncthing sync folder
  /// 
  /// Returns the directory path that Syncthing should monitor.
  /// On Android: /storage/emulated/0/AuraOne_Sync
  /// On iOS: Documents/AuraOne_Sync
  /// On other platforms: Documents/AuraOne_Sync
  static Future<Directory> getSyncFolder({String? customFolderName}) async {
    final folderName = customFolderName ?? defaultSyncFolderName;
    Directory syncDir;
    
    if (Platform.isAndroid) {
      // On Android, use external storage for easy Syncthing access
      syncDir = Directory('/storage/emulated/0/$folderName');
      if (!await syncDir.exists()) {
        // Fallback to app's external storage if primary path fails
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          syncDir = Directory(path.join(externalDir.parent.parent.parent.parent.path, folderName));
        }
      }
    } else if (Platform.isIOS) {
      // On iOS, use Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      syncDir = Directory(path.join(documentsDir.path, folderName));
    } else {
      // For other platforms, use Documents folder
      final documentsDir = await getApplicationDocumentsDirectory();
      syncDir = Directory(path.join(documentsDir.path, folderName));
    }
    
    // Create directory if it doesn't exist
    if (!await syncDir.exists()) {
      await syncDir.create(recursive: true);
      
      // Create README for Syncthing folder
      final readmeFile = File(path.join(syncDir.path, 'README.md'));
      await readmeFile.writeAsString('''
# AuraOne Syncthing Sync Folder

This folder is monitored by AuraOne for automatic backup and synchronization using Syncthing.

## Setup Instructions

1. Install Syncthing on all devices you want to sync
2. Add this folder to Syncthing with the following settings:
   - Folder ID: auraone-sync
   - Folder Type: Send & Receive
   - File Versioning: Staggered (recommended)
   
3. Configure ignore patterns in Syncthing:
   ```
   .tmp*
   *.partial
   .syncthing_config.json
   ```

## Folder Structure

- `/exports/` - Manual exports from the app
- `/scheduled/` - Automated scheduled backups
- `/media/` - Media files (photos, videos)
- `README.md` - This file

## Important Notes

- Do not manually modify files in this folder
- Ensure Syncthing has proper permissions to access this folder
- Keep at least one device online for continuous sync
- Monitor Syncthing logs for any sync conflicts

## Recovery

To restore from a Syncthing backup:
1. Open AuraOne app
2. Go to Settings > Import
3. Select "Import from Syncthing Folder"
4. Choose the backup file to restore

Last updated: ${DateTime.now().toIso8601String()}
''');
    }
    
    return syncDir;
  }
  
  /// Export journal data to Syncthing folder
  static Future<SyncthingExportResult> exportToSyncthingFolder({
    required String appVersion,
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> journalEntries,
    required List<Map<String, dynamic>> mediaReferences,
    required Map<String, dynamic> metadata,
    required DateTime exportDate,
    List<File>? mediaFiles,
    String? customFolderName,
    bool isScheduledBackup = false,
    String? password,
    void Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);
      
      // Get Syncthing folder
      final syncDir = await getSyncFolder(customFolderName: customFolderName);
      
      // Create appropriate subdirectory
      final subDir = isScheduledBackup ? 'scheduled' : 'exports';
      final exportDir = Directory(path.join(syncDir.path, subDir));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      onProgress?.call(0.2);
      
      // Generate filename with timestamp
      final timestamp = exportDate.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final prefix = isScheduledBackup ? 'auto_backup' : 'manual_export';
      final fileName = '${prefix}_$timestamp.aura';
      
      // Export to file
      final exportPath = path.join(exportDir.path, fileName);
      
      String filePath;
      if (password != null && password.isNotEmpty) {
        // Use encrypted export
        filePath = await ExportService.exportToEncryptedFile(
          appVersion: appVersion,
          userData: userData,
          journalEntries: journalEntries,
          mediaReferences: mediaReferences,
          metadata: metadata,
          exportDate: exportDate,
          mediaFiles: mediaFiles,
          password: password,
          onProgress: (progress) {
            // Scale progress from 0.2 to 0.9
            onProgress?.call(0.2 + (progress * 0.7));
          },
        );
        // Move the encrypted file to the desired location
        final encryptedFile = File(filePath);
        await encryptedFile.copy(exportPath);
        await encryptedFile.delete();
        filePath = exportPath;
      } else {
        // Use regular export
        filePath = await ExportService.exportToLocalFile(
          appVersion: appVersion,
          userData: userData,
          journalEntries: journalEntries,
          mediaReferences: mediaReferences,
          metadata: metadata,
          exportDate: exportDate,
          mediaFiles: mediaFiles,
          onProgress: (progress) {
            // Scale progress from 0.2 to 0.9
            onProgress?.call(0.2 + (progress * 0.7));
          },
        );
        // Move the file to the desired location
        final localFile = File(filePath);
        await localFile.copy(exportPath);
        await localFile.delete();
        filePath = exportPath;
      }
      
      // Create metadata file for sync tracking
      final metadataFile = File(path.join(exportDir.path, '.$fileName.meta'));
      await metadataFile.writeAsString('''{
  "exportDate": "${exportDate.toIso8601String()}",
  "appVersion": "$appVersion",
  "encrypted": ${password != null},
  "scheduled": $isScheduledBackup,
  "fileSize": ${File(filePath).lengthSync()},
  "entriesCount": ${journalEntries.length},
  "mediaCount": ${mediaFiles?.length ?? 0},
  "syncStatus": "pending",
  "deviceId": "${Platform.localHostname}",
  "platform": "${Platform.operatingSystem}"
}''');
      
      onProgress?.call(0.95);
      
      // Update sync config
      await _updateSyncConfig(syncDir, exportDate, isScheduledBackup);
      
      onProgress?.call(1.0);
      
      return SyncthingExportResult(
        success: true,
        filePath: filePath,
        syncFolderPath: syncDir.path,
        fileName: fileName,
        isScheduled: isScheduledBackup,
      );
    } catch (e) {
      return SyncthingExportResult(
        success: false,
        error: e.toString(),
        syncFolderPath: '',
      );
    }
  }
  
  /// Import from Syncthing folder
  static Future<List<SyncthingBackupInfo>> getAvailableBackups({
    String? customFolderName,
  }) async {
    try {
      final syncDir = await getSyncFolder(customFolderName: customFolderName);
      final backups = <SyncthingBackupInfo>[];
      
      // Check both exports and scheduled directories
      for (final subDir in ['exports', 'scheduled']) {
        final dir = Directory(path.join(syncDir.path, subDir));
        if (await dir.exists()) {
          final files = await dir.list().where((entity) {
            return entity is File && entity.path.endsWith('.aura');
          }).toList();
          
          for (final file in files) {
            final fileName = path.basename(file.path);
            final metaFile = File(path.join(dir.path, '.$fileName.meta'));
            
            Map<String, dynamic>? metadata;
            if (await metaFile.exists()) {
              try {
                final metaContent = await metaFile.readAsString();
                // Parse JSON content, not DateTime
                metadata = Map<String, dynamic>.from(
                  json.decode(metaContent),
                );
              } catch (_) {}
            }
            
            backups.add(SyncthingBackupInfo(
              filePath: file.path,
              fileName: fileName,
              fileSize: (file as File).lengthSync(),
              isScheduled: subDir == 'scheduled',
              exportDate: metadata?['exportDate'] != null
                  ? DateTime.parse(metadata!['exportDate'])
                  : File(file.path).lastModifiedSync(),
              isEncrypted: metadata?['encrypted'] ?? false,
              entriesCount: metadata?['entriesCount'],
              deviceId: metadata?['deviceId'],
              platform: metadata?['platform'],
            ));
          }
        }
      }
      
      // Sort by date, newest first
      backups.sort((a, b) => b.exportDate.compareTo(a.exportDate));
      
      return backups;
    } catch (e) {
      print('Error getting Syncthing backups: $e');
      return [];
    }
  }
  
  /// Clean old backups to save space
  static Future<void> cleanOldBackups({
    String? customFolderName,
    int keepLastCount = 10,
    Duration? olderThan,
  }) async {
    try {
      final backups = await getAvailableBackups(customFolderName: customFolderName);
      final now = DateTime.now();
      
      // Group by scheduled vs manual
      final scheduled = backups.where((b) => b.isScheduled).toList();
      final manual = backups.where((b) => !b.isScheduled).toList();
      
      // Clean scheduled backups (keep fewer)
      for (int i = keepLastCount; i < scheduled.length; i++) {
        final backup = scheduled[i];
        if (olderThan == null || now.difference(backup.exportDate) > olderThan) {
          await File(backup.filePath).delete();
          // Delete metadata file if exists
          final metaPath = path.join(
            path.dirname(backup.filePath),
            '.${backup.fileName}.meta',
          );
          final metaFile = File(metaPath);
          if (await metaFile.exists()) {
            await metaFile.delete();
          }
        }
      }
      
      // Clean manual backups (keep more)
      for (int i = keepLastCount * 2; i < manual.length; i++) {
        final backup = manual[i];
        if (olderThan == null || now.difference(backup.exportDate) > olderThan) {
          await File(backup.filePath).delete();
          // Delete metadata file if exists
          final metaPath = path.join(
            path.dirname(backup.filePath),
            '.${backup.fileName}.meta',
          );
          final metaFile = File(metaPath);
          if (await metaFile.exists()) {
            await metaFile.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning old Syncthing backups: $e');
    }
  }
  
  /// Update sync configuration file
  static Future<void> _updateSyncConfig(
    Directory syncDir,
    DateTime lastExport,
    bool isScheduled,
  ) async {
    try {
      final configFile = File(path.join(syncDir.path, configFileName));
      final config = <String, dynamic>{
        'lastExport': lastExport.toIso8601String(),
        'lastScheduledBackup': isScheduled ? lastExport.toIso8601String() : null,
        'deviceId': Platform.localHostname,
        'platform': Platform.operatingSystem,
        'appVersion': '0.1.0', // TODO: Get from package info
      };
      
      // Merge with existing config if it exists
      if (await configFile.exists()) {
        try {
          final existing = await configFile.readAsString();
          final existingConfig = Map<String, dynamic>.from(
            json.decode(existing),
          );
          config.addAll(existingConfig);
          if (!isScheduled && existingConfig['lastScheduledBackup'] != null) {
            config['lastScheduledBackup'] = existingConfig['lastScheduledBackup'];
          }
        } catch (_) {}
      }
      
      await configFile.writeAsString(
        json.encode(config),
      );
    } catch (e) {
      print('Error updating sync config: $e');
    }
  }
}

/// Result of Syncthing folder export operation
class SyncthingExportResult {
  final bool success;
  final String? filePath;
  final String syncFolderPath;
  final String? fileName;
  final bool? isScheduled;
  final String? error;
  
  SyncthingExportResult({
    required this.success,
    this.filePath,
    required this.syncFolderPath,
    this.fileName,
    this.isScheduled,
    this.error,
  });
}

/// Information about a backup in the Syncthing folder
class SyncthingBackupInfo {
  final String filePath;
  final String fileName;
  final int fileSize;
  final bool isScheduled;
  final DateTime exportDate;
  final bool isEncrypted;
  final int? entriesCount;
  final String? deviceId;
  final String? platform;
  
  SyncthingBackupInfo({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.isScheduled,
    required this.exportDate,
    required this.isEncrypted,
    this.entriesCount,
    this.deviceId,
    this.platform,
  });
  
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}