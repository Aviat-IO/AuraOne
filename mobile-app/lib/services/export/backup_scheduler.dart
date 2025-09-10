import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'export_service.dart';
import 'export_schema.dart';
import 'syncthing_service.dart';
import 'blossom_storage_service.dart';

/// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'scheduled_backup':
          await BackupScheduler._performScheduledBackup(inputData ?? {});
          return true;
        case 'cleanup_old_backups':
          await BackupScheduler._cleanupOldBackups(inputData ?? {});
          return true;
        default:
          return false;
      }
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  });
}

/// Backup frequency options
enum BackupFrequency {
  daily('Daily', Duration(days: 1)),
  weekly('Weekly', Duration(days: 7)),
  biweekly('Bi-weekly', Duration(days: 14)),
  monthly('Monthly', Duration(days: 30)),
  disabled('Disabled', Duration.zero);

  final String label;
  final Duration duration;
  const BackupFrequency(this.label, this.duration);
}

/// Backup configuration
class BackupConfig {
  final BackupFrequency frequency;
  final TimeOfDay preferredTime;
  final bool includeMedia;
  final bool includeLocation;
  final bool includeHealthData;
  final bool includeCalendarData;
  final bool enableEncryption;
  final String? encryptionPassword;
  final bool useBlossomStorage;
  final String? blossomServerUrl;
  final String? blossomNsec; // Encrypted/secured storage required
  final bool useSyncthingFolder;
  final String? syncthingFolderPath;
  final int maxBackupsToKeep;
  final bool onlyOnWifi;
  final bool onlyWhenCharging;
  
  BackupConfig({
    this.frequency = BackupFrequency.weekly,
    this.preferredTime = const TimeOfDay(hour: 2, minute: 0),
    this.includeMedia = true,
    this.includeLocation = true,
    this.includeHealthData = true,
    this.includeCalendarData = true,
    this.enableEncryption = false,
    this.encryptionPassword,
    this.useBlossomStorage = false,
    this.blossomServerUrl,
    this.blossomNsec,
    this.useSyncthingFolder = false,
    this.syncthingFolderPath,
    this.maxBackupsToKeep = 10,
    this.onlyOnWifi = true,
    this.onlyWhenCharging = false,
  });
  
  Map<String, dynamic> toJson() => {
    'frequency': frequency.name,
    'preferredTime': '${preferredTime.hour}:${preferredTime.minute}',
    'includeMedia': includeMedia,
    'includeLocation': includeLocation,
    'includeHealthData': includeHealthData,
    'includeCalendarData': includeCalendarData,
    'enableEncryption': enableEncryption,
    'encryptionPassword': encryptionPassword,
    'useBlossomStorage': useBlossomStorage,
    'blossomServerUrl': blossomServerUrl,
    'blossomNsec': blossomNsec,
    'useSyncthingFolder': useSyncthingFolder,
    'syncthingFolderPath': syncthingFolderPath,
    'maxBackupsToKeep': maxBackupsToKeep,
    'onlyOnWifi': onlyOnWifi,
    'onlyWhenCharging': onlyWhenCharging,
  };
  
  factory BackupConfig.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['preferredTime'] as String).split(':');
    return BackupConfig(
      frequency: BackupFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => BackupFrequency.weekly,
      ),
      preferredTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      includeMedia: json['includeMedia'] ?? true,
      includeLocation: json['includeLocation'] ?? true,
      // For backward compatibility, use includeSensorData if new fields aren't present
      includeHealthData: json['includeHealthData'] ?? json['includeSensorData'] ?? true,
      includeCalendarData: json['includeCalendarData'] ?? json['includeSensorData'] ?? true,
      enableEncryption: json['enableEncryption'] ?? false,
      encryptionPassword: json['encryptionPassword'],
      useBlossomStorage: json['useBlossomStorage'] ?? false,
      blossomServerUrl: json['blossomServerUrl'],
      blossomNsec: json['blossomNsec'],
      useSyncthingFolder: json['useSyncthingFolder'] ?? false,
      syncthingFolderPath: json['syncthingFolderPath'],
      maxBackupsToKeep: json['maxBackupsToKeep'] ?? 10,
      onlyOnWifi: json['onlyOnWifi'] ?? true,
      onlyWhenCharging: json['onlyWhenCharging'] ?? false,
    );
  }
}

/// Backup status information
class BackupStatus {
  final DateTime? lastBackupTime;
  final bool lastBackupSuccess;
  final String? lastBackupError;
  final int totalBackups;
  final int successfulBackups;
  final int failedBackups;
  final double totalSizeMB;
  final DateTime? nextScheduledBackup;
  
  BackupStatus({
    this.lastBackupTime,
    this.lastBackupSuccess = false,
    this.lastBackupError,
    this.totalBackups = 0,
    this.successfulBackups = 0,
    this.failedBackups = 0,
    this.totalSizeMB = 0.0,
    this.nextScheduledBackup,
  });
  
  Map<String, dynamic> toJson() => {
    'lastBackupTime': lastBackupTime?.toIso8601String(),
    'lastBackupSuccess': lastBackupSuccess,
    'lastBackupError': lastBackupError,
    'totalBackups': totalBackups,
    'successfulBackups': successfulBackups,
    'failedBackups': failedBackups,
    'totalSizeMB': totalSizeMB,
    'nextScheduledBackup': nextScheduledBackup?.toIso8601String(),
  };
  
  factory BackupStatus.fromJson(Map<String, dynamic> json) {
    return BackupStatus(
      lastBackupTime: json['lastBackupTime'] != null
          ? DateTime.parse(json['lastBackupTime'])
          : null,
      lastBackupSuccess: json['lastBackupSuccess'] ?? false,
      lastBackupError: json['lastBackupError'],
      totalBackups: json['totalBackups'] ?? 0,
      successfulBackups: json['successfulBackups'] ?? 0,
      failedBackups: json['failedBackups'] ?? 0,
      totalSizeMB: (json['totalSizeMB'] ?? 0.0).toDouble(),
      nextScheduledBackup: json['nextScheduledBackup'] != null
          ? DateTime.parse(json['nextScheduledBackup'])
          : null,
    );
  }
}

/// Service for scheduling and managing automated backups
class BackupScheduler {
  static const String _configKey = 'backup_config';
  static const String _statusKey = 'backup_status';
  static const String _historyKey = 'backup_history';
  
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  /// Initialize the backup scheduler
  static Future<void> initialize() async {
    // Initialize workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
    
    // Check if we need to reschedule tasks
    final config = await getConfig();
    if (config.frequency != BackupFrequency.disabled) {
      await scheduleBackup(config);
    }
  }
  
  /// Get current backup configuration
  static Future<BackupConfig> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);
    if (configJson != null) {
      return BackupConfig.fromJson(json.decode(configJson));
    }
    return BackupConfig();
  }
  
  /// Save backup configuration
  static Future<void> saveConfig(BackupConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, json.encode(config.toJson()));
  }
  
  /// Get backup status
  static Future<BackupStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final statusJson = prefs.getString(_statusKey);
    if (statusJson != null) {
      return BackupStatus.fromJson(json.decode(statusJson));
    }
    return BackupStatus();
  }
  
  /// Update backup status
  static Future<void> _updateStatus(BackupStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, json.encode(status.toJson()));
  }
  
  /// Schedule automatic backup
  static Future<void> scheduleBackup(BackupConfig config) async {
    // Cancel existing scheduled backups
    await cancelScheduledBackup();
    
    if (config.frequency == BackupFrequency.disabled) {
      return;
    }
    
    // Calculate next backup time
    final now = DateTime.now();
    var nextBackup = DateTime(
      now.year,
      now.month,
      now.day,
      config.preferredTime.hour,
      config.preferredTime.minute,
    );
    
    // If the time has passed today, schedule for next occurrence
    if (nextBackup.isBefore(now)) {
      nextBackup = nextBackup.add(config.frequency.duration);
    }
    
    // Schedule the task
    await Workmanager().registerPeriodicTask(
      'scheduled_backup',
      'scheduled_backup',
      frequency: config.frequency.duration,
      initialDelay: nextBackup.difference(now),
      constraints: Constraints(
        networkType: config.onlyOnWifi ? NetworkType.unmetered : NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresCharging: config.onlyWhenCharging,
      ),
      inputData: config.toJson(),
    );
    
    // Update status with next scheduled time
    final status = await getStatus();
    await _updateStatus(BackupStatus(
      lastBackupTime: status.lastBackupTime,
      lastBackupSuccess: status.lastBackupSuccess,
      lastBackupError: status.lastBackupError,
      totalBackups: status.totalBackups,
      successfulBackups: status.successfulBackups,
      failedBackups: status.failedBackups,
      totalSizeMB: status.totalSizeMB,
      nextScheduledBackup: nextBackup,
    ));
    
    // Schedule cleanup task
    await Workmanager().registerPeriodicTask(
      'cleanup_old_backups',
      'cleanup_old_backups',
      frequency: const Duration(days: 1),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
      ),
      inputData: {'maxBackupsToKeep': config.maxBackupsToKeep},
    );
  }
  
  /// Cancel scheduled backup
  static Future<void> cancelScheduledBackup() async {
    await Workmanager().cancelByUniqueName('scheduled_backup');
    await Workmanager().cancelByUniqueName('cleanup_old_backups');
    
    // Update status to clear next scheduled time
    final status = await getStatus();
    await _updateStatus(BackupStatus(
      lastBackupTime: status.lastBackupTime,
      lastBackupSuccess: status.lastBackupSuccess,
      lastBackupError: status.lastBackupError,
      totalBackups: status.totalBackups,
      successfulBackups: status.successfulBackups,
      failedBackups: status.failedBackups,
      totalSizeMB: status.totalSizeMB,
      nextScheduledBackup: null,
    ));
  }
  
  /// Perform a scheduled backup (called from background task)
  static Future<void> _performScheduledBackup(Map<String, dynamic> inputData) async {
    // Check storage permissions first
    final hasPermissions = await hasStoragePermissions();
    if (!hasPermissions) {
      throw Exception('Storage permission denied');
    }
    
    final config = BackupConfig.fromJson(inputData);
    final status = await getStatus();
    
    try {
      // Show progress notification
      await _showNotification(
        'Backup in Progress',
        'Creating backup of your journal...',
        progress: 0,
        maxProgress: 100,
      );
      
      // TODO: Fetch actual journal data from database
      // For now, using sample data
      final journalEntries = <Map<String, dynamic>>[];
      final mediaReferences = <Map<String, dynamic>>[];
      final metadata = ExportSchema.createMetadata(
        exportStartDate: DateTime.now().subtract(const Duration(days: 30)),
        exportEndDate: DateTime.now(),
        totalEntries: journalEntries.length,
        totalMedia: mediaReferences.length,
        totalSizeBytes: 0,
        exportReason: 'Scheduled backup',
      );
      
      final userData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'appVersion': '0.1.0',
      };
      
      // Perform backup based on configuration
      String? backupLocation;
      double backupSizeMB = 0;
      
      if (config.useSyncthingFolder) {
        // Use configured folder path if available
        final customFolderName = config.syncthingFolderPath?.isNotEmpty == true 
            ? config.syncthingFolderPath 
            : null;
        
        final result = await SyncthingService.exportToSyncthingFolder(
          appVersion: '0.1.0',
          userData: userData,
          journalEntries: journalEntries,
          mediaReferences: mediaReferences,
          metadata: metadata,
          exportDate: DateTime.now(),
          password: config.enableEncryption ? config.encryptionPassword : null,
          isScheduledBackup: true,
          customFolderName: customFolderName,
          onProgress: (progress) async {
            await _showNotification(
              'Backup in Progress',
              'Creating backup... ${(progress * 100).toInt()}%',
              progress: (progress * 100).toInt(),
              maxProgress: 100,
            );
          },
        );
        
        if (result.success && result.filePath != null) {
          backupLocation = result.syncFolderPath;
          final file = File(result.filePath!);
          if (await file.exists()) {
            backupSizeMB = (await file.length()) / 1024 / 1024;
          }
        } else {
          throw Exception(result.error ?? 'Syncthing backup failed');
        }
      } else if (config.useBlossomStorage) {
        // For now, create a temporary local file and upload to Blossom
        // In the future, this should be updated to use ExportService.exportToBlossom
        // when that method is properly implemented
        
        // First create the export file locally
        final tempFilePath = await ExportService.exportToLocalFile(
          appVersion: '0.1.0',
          userData: userData,
          journalEntries: journalEntries,
          mediaReferences: mediaReferences,
          metadata: metadata,
          exportDate: DateTime.now(),
          onProgress: (progress) async {
            await _showNotification(
              'Backup in Progress',
              'Creating backup... ${(progress * 50).toInt()}%',
              progress: (progress * 50).toInt(),
              maxProgress: 100,
            );
          },
        );
        
        // Upload to Blossom server
        if (config.blossomServerUrl?.isNotEmpty == true) {
          final uploadUrl = await BlossomStorageService.uploadFile(
            serverUrl: config.blossomServerUrl!,
            filePath: tempFilePath,
            nsec: config.blossomNsec,
          );
          
          if (uploadUrl != null) {
            backupLocation = 'Blossom: $uploadUrl';
            final file = File(tempFilePath);
            if (await file.exists()) {
              backupSizeMB = (await file.length()) / 1024 / 1024;
            }
            
            // Clean up temporary file after successful upload
            await file.delete();
          } else {
            throw Exception('Failed to upload to Blossom server');
          }
        } else {
          throw Exception('Blossom server URL not configured');
        }
      } else {
        // Local backup
        final filePath = await ExportService.exportToLocalFile(
          appVersion: '0.1.0',
          userData: userData,
          journalEntries: journalEntries,
          mediaReferences: mediaReferences,
          metadata: metadata,
          exportDate: DateTime.now(),
          onProgress: (progress) async {
            await _showNotification(
              'Backup in Progress',
              'Creating backup... ${(progress * 100).toInt()}%',
              progress: (progress * 100).toInt(),
              maxProgress: 100,
            );
          },
        );
        
        backupLocation = filePath;
        final file = File(filePath);
        if (await file.exists()) {
          backupSizeMB = (await file.length()) / 1024 / 1024;
        }
      }
      
      // Update status
      await _updateStatus(BackupStatus(
        lastBackupTime: DateTime.now(),
        lastBackupSuccess: true,
        lastBackupError: null,
        totalBackups: status.totalBackups + 1,
        successfulBackups: status.successfulBackups + 1,
        failedBackups: status.failedBackups,
        totalSizeMB: status.totalSizeMB + backupSizeMB,
        nextScheduledBackup: DateTime.now().add(config.frequency.duration),
      ));
      
      // Add to history
      await _addToHistory(BackupHistoryEntry(
        timestamp: DateTime.now(),
        success: true,
        location: backupLocation ?? 'Unknown',
        sizeMB: backupSizeMB,
        entriesCount: journalEntries.length,
        encrypted: config.enableEncryption,
      ));
      
      // Show success notification
      await _showNotification(
        'Backup Complete',
        'Your journal has been backed up successfully',
      );
      
    } catch (e) {
      // Update status with error
      await _updateStatus(BackupStatus(
        lastBackupTime: DateTime.now(),
        lastBackupSuccess: false,
        lastBackupError: e.toString(),
        totalBackups: status.totalBackups + 1,
        successfulBackups: status.successfulBackups,
        failedBackups: status.failedBackups + 1,
        totalSizeMB: status.totalSizeMB,
        nextScheduledBackup: DateTime.now().add(config.frequency.duration),
      ));
      
      // Add to history
      await _addToHistory(BackupHistoryEntry(
        timestamp: DateTime.now(),
        success: false,
        error: e.toString(),
      ));
      
      // Show error notification
      await _showNotification(
        'Backup Failed',
        'Failed to create backup: $e',
        isError: true,
      );
    }
  }
  
  /// Clean up old backups
  static Future<void> _cleanupOldBackups(Map<String, dynamic> inputData) async {
    final maxBackupsToKeep = inputData['maxBackupsToKeep'] ?? 10;
    final syncthingFolderPath = inputData['syncthingFolderPath'] as String?;
    
    // Clean up Syncthing backups with configured folder path
    await SyncthingService.cleanOldBackups(
      customFolderName: syncthingFolderPath,
      keepLastCount: maxBackupsToKeep,
      olderThan: const Duration(days: 30),
    );
    
    // TODO: Clean up local backups based on retention settings
  }
  
  /// Show notification
  static Future<void> _showNotification(
    String title,
    String body, {
    bool isError = false,
    int? progress,
    int? maxProgress,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'backup_channel',
      'Backup Notifications',
      channelDescription: 'Notifications for backup operations',
      importance: Importance.high,
      priority: Priority.high,
      showProgress: progress != null,
      maxProgress: maxProgress ?? 100,
      progress: progress ?? 0,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      1,
      title,
      body,
      details,
    );
  }
  
  /// Get backup history
  static Future<List<BackupHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    if (historyJson != null) {
      final List<dynamic> historyList = json.decode(historyJson);
      return historyList
          .map((e) => BackupHistoryEntry.fromJson(e))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return [];
  }
  
  /// Add entry to backup history
  static Future<void> _addToHistory(BackupHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    // Add new entry
    history.insert(0, entry);
    
    // Keep only last 50 entries
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    
    await prefs.setString(
      _historyKey,
      json.encode(history.map((e) => e.toJson()).toList()),
    );
  }
  
  /// Clear backup history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
  
  /// Check and request storage permissions
  static Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      // Check current permission status first
      bool hasBasicAccess = false;
      
      // For Android 13+ (API 33+), check multiple permission types
      if (await _isAndroid13OrHigher()) {
        // Check if we already have any of the needed permissions
        final currentStatuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
          Permission.manageExternalStorage,
        ].request();
        
        hasBasicAccess = currentStatuses[Permission.manageExternalStorage]?.isGranted == true ||
                        currentStatuses[Permission.photos]?.isGranted == true ||
                        currentStatuses[Permission.videos]?.isGranted == true ||
                        currentStatuses[Permission.audio]?.isGranted == true;
        
        // If we don't have access, try requesting storage permission
        if (!hasBasicAccess) {
          final storageStatus = await Permission.storage.request();
          hasBasicAccess = storageStatus.isGranted;
        }
      } else {
        // For older Android versions, use storage permission
        final status = await Permission.storage.request();
        hasBasicAccess = status.isGranted;
      }
      
      return hasBasicAccess;
    }
    
    // On iOS and other platforms, assume permission is granted
    return true;
  }
  
  /// Check current storage permissions without requesting
  static Future<bool> hasStoragePermissions() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        // Check if we have any of the needed permissions
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
          Permission.manageExternalStorage,
          Permission.storage,
        ];
        
        for (final permission in permissions) {
          final status = await permission.status;
          if (status.isGranted) {
            return true;
          }
        }
        return false;
      } else {
        // For older Android versions
        final status = await Permission.storage.status;
        return status.isGranted;
      }
    }
    
    return true; // iOS and other platforms
  }
  
  /// Check if running on Android 13+
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    // Simple check - in a real app you'd use device_info_plus
    // For now, assume we need the newer permissions
    return true;
  }

  /// Perform manual backup
  static Future<void> performManualBackup({
    void Function(double)? onProgress,
  }) async {
    final config = await getConfig();
    final status = await getStatus();
    
    // Create a temporary config for manual backup
    final manualConfig = config.toJson();
    
    // Perform the backup
    await _performScheduledBackup(manualConfig);
  }
}

/// Backup history entry
class BackupHistoryEntry {
  final DateTime timestamp;
  final bool success;
  final String? location;
  final double? sizeMB;
  final int? entriesCount;
  final bool? encrypted;
  final String? error;
  
  BackupHistoryEntry({
    required this.timestamp,
    required this.success,
    this.location,
    this.sizeMB,
    this.entriesCount,
    this.encrypted,
    this.error,
  });
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'success': success,
    'location': location,
    'sizeMB': sizeMB,
    'entriesCount': entriesCount,
    'encrypted': encrypted,
    'error': error,
  };
  
  factory BackupHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BackupHistoryEntry(
      timestamp: DateTime.parse(json['timestamp']),
      success: json['success'] ?? false,
      location: json['location'],
      sizeMB: json['sizeMB']?.toDouble(),
      entriesCount: json['entriesCount'],
      encrypted: json['encrypted'],
      error: json['error'],
    );
  }
}