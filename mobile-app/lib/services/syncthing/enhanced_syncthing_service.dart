import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../export/syncthing_service.dart';

/// Enhanced Syncthing service with REST API integration and device management
class EnhancedSyncthingService {
  static const String _prefsKeyApiKey = 'syncthing_api_key';
  static const String _prefsKeyDeviceId = 'syncthing_device_id';
  
  // Default Syncthing REST API endpoints
  static const String _defaultApiUrl = 'http://127.0.0.1:8384';
  static const Duration _apiTimeout = Duration(seconds: 10);
  
  // Syncthing folder configuration
  static const String _folderIdPrefix = 'auraone-';
  static const String _journalFolderId = 'auraone-journal';
  static const String _mediaFolderId = 'auraone-media';
  static const String _settingsFolderId = 'auraone-settings';
  
  final String apiUrl;
  String? _apiKey;
  String? _deviceId;
  
  // Stream controllers for real-time updates
  final _syncStatusController = StreamController<SyncthingStatus>.broadcast();
  final _deviceDiscoveryController = StreamController<List<SyncthingDevice>>.broadcast();
  final _syncProgressController = StreamController<SyncProgress>.broadcast();
  
  Timer? _statusPollingTimer;
  Timer? _discoveryTimer;
  
  EnhancedSyncthingService({
    String? apiUrl,
  }) : apiUrl = apiUrl ?? _defaultApiUrl;
  
  /// Initialize the service and load configuration
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_prefsKeyApiKey);
    _deviceId = prefs.getString(_prefsKeyDeviceId);
    
    // Try to auto-discover API key if not set
    if (_apiKey == null) {
      await _autoDiscoverApiKey();
    }
    
    // Get device ID from Syncthing
    if (_apiKey != null) {
      await _fetchDeviceId();
    }
    
    // Start monitoring if configured
    if (_apiKey != null && _deviceId != null) {
      startMonitoring();
    }
  }
  
  /// Check if Syncthing is configured and running
  Future<bool> isConfigured() async {
    return _apiKey != null && await _checkConnection();
  }

  /// Check if connected to Syncthing
  Future<bool> isConnected() async {
    return await _checkConnection();
  }

  /// Get sync folder directory
  Future<Directory> getSyncFolder() async {
    return await SyncthingService.getSyncFolder();
  }

  /// Connect to a specific device
  Future<bool> connectDevice(String deviceId) async {
    return await resumeDevice(deviceId);
  }

  /// Pause a folder
  Future<bool> pauseFolder(String folderId) async {
    final response = await _apiRequest(
      'POST',
      '/rest/db/pause',
      body: {'folder': folderId},
    );
    return response != null;
  }

  /// Resume a folder
  Future<bool> resumeFolder(String folderId) async {
    final response = await _apiRequest(
      'POST',
      '/rest/db/resume',
      body: {'folder': folderId},
    );
    return response != null;
  }

  /// Scan a folder for changes
  Future<bool> scanFolder(String folderId) async {
    return await rescanFolder(folderId);
  }

  /// Pause all synchronization
  Future<bool> pauseAll() async {
    final response = await _apiRequest('POST', '/rest/system/pause');
    return response != null;
  }

  /// Resume all synchronization
  Future<bool> resumeAll() async {
    final response = await _apiRequest('POST', '/rest/system/resume');
    return response != null;
  }

  /// Restart Syncthing
  Future<bool> restart() async {
    final response = await _apiRequest('POST', '/rest/system/restart');
    return response != null;
  }
  
  /// Configure Syncthing API access
  Future<bool> configureApi(String apiKey, {String? apiUrl}) async {
    _apiKey = apiKey;
    
    if (await _checkConnection()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyApiKey, apiKey);
      
      await _fetchDeviceId();
      startMonitoring();
      return true;
    }
    
    return false;
  }
  
  /// Auto-discover API key from Syncthing config
  Future<void> _autoDiscoverApiKey() async {
    try {
      // Try to read Syncthing config file
      String configPath;
      if (Platform.isAndroid) {
        configPath = '/data/data/com.nutomic.syncthingandroid/files/config.xml';
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        configPath = path.join(docsDir.path, '.config', 'syncthing', 'config.xml');
      } else {
        return;
      }
      
      final configFile = File(configPath);
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        // Parse XML to extract API key
        final apiKeyMatch = RegExp(r'<apikey>([^<]+)</apikey>').firstMatch(content);
        if (apiKeyMatch != null) {
          _apiKey = apiKeyMatch.group(1);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsKeyApiKey, _apiKey!);
        }
      }
    } catch (e) {
      debugPrint('Failed to auto-discover API key: $e');
    }
  }
  
  /// Fetch device ID from Syncthing
  Future<void> _fetchDeviceId() async {
    try {
      final response = await _apiRequest('GET', '/rest/system/status');
      if (response != null) {
        _deviceId = response['myID'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKeyDeviceId, _deviceId!);
      }
    } catch (e) {
      debugPrint('Failed to fetch device ID: $e');
    }
  }
  
  /// Check connection to Syncthing API
  Future<bool> _checkConnection() async {
    try {
      final response = await _apiRequest('GET', '/rest/system/ping');
      return response != null && response['ping'] == 'pong';
    } catch (e) {
      return false;
    }
  }
  
  /// Make API request to Syncthing
  Future<dynamic> _apiRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    if (_apiKey == null) return null;
    
    try {
      final uri = Uri.parse('$apiUrl$endpoint');
      final headers = {
        'X-API-Key': _apiKey!,
        if (body != null) 'Content-Type': 'application/json',
      };
      
      http.Response response;
      
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_apiTimeout);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(_apiTimeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(_apiTimeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(_apiTimeout);
          break;
        default:
          return null;
      }
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('API request failed: $e');
    }
    
    return null;
  }
  
  /// Get list of configured folders
  Future<List<SyncthingFolder>> getFolders() async {
    final response = await _apiRequest('GET', '/rest/config/folders');
    if (response == null) return [];
    
    final folders = <SyncthingFolder>[];
    if (response is List<dynamic>) {
      for (final folder in response) {
        if (folder is Map<String, dynamic>) {
          folders.add(SyncthingFolder.fromJson(folder));
        }
      }
    }
    
    return folders;
  }
  
  /// Create or update a Syncthing folder
  Future<bool> configureFolder({
    required String folderId,
    required String folderPath,
    required String label,
    List<String>? deviceIds,
    bool versioning = true,
    bool ignorePermissions = true,
    int rescanIntervalS = 3600,
  }) async {
    
    // Update folder configuration
    final folderConfig = {
      'id': folderId,
      'label': label,
      'path': folderPath,
      'type': 'sendreceive',
      'rescanIntervalS': rescanIntervalS,
      'ignorePerms': ignorePermissions,
      'autoNormalize': true,
      'minDiskFree': {'value': 1, 'unit': '%'},
      'versioning': versioning
          ? {
              'type': 'staggered',
              'params': {
                'cleanInterval': '3600',
                'maxAge': '2592000', // 30 days
              },
            }
          : {},
      'devices': [
        {'deviceID': _deviceId, 'introducedBy': ''},
        ...?deviceIds?.map((id) => {'deviceID': id, 'introducedBy': ''}),
      ],
    };
    
    // Update folder via API
    final response = await _apiRequest(
      'PUT',
      '/rest/config/folders/$folderId',
      body: folderConfig,
    );
    
    if (response != null) {
      // Restart Syncthing to apply changes
      await _apiRequest('POST', '/rest/system/restart');
      return true;
    }
    
    return false;
  }
  
  /// Setup default folders for AuraOne
  Future<void> setupDefaultFolders() async {
    final baseDir = await SyncthingService.getSyncFolder();
    
    // Journal folder
    await configureFolder(
      folderId: _journalFolderId,
      folderPath: path.join(baseDir.path, 'journal'),
      label: 'AuraOne Journal',
      versioning: true,
    );
    
    // Media folder
    await configureFolder(
      folderId: _mediaFolderId,
      folderPath: path.join(baseDir.path, 'media'),
      label: 'AuraOne Media',
      versioning: false, // Media files are usually large
      rescanIntervalS: 7200, // Less frequent for media
    );
    
    // Settings folder
    await configureFolder(
      folderId: _settingsFolderId,
      folderPath: path.join(baseDir.path, 'settings'),
      label: 'AuraOne Settings',
      versioning: true,
      rescanIntervalS: 600, // More frequent for settings
    );
  }
  
  /// Get connected devices
  Future<List<SyncthingDevice>> getDevices() async {
    final configResponse = await _apiRequest('GET', '/rest/config/devices');
    final connectionsResponse = await _apiRequest('GET', '/rest/system/connections');
    
    if (configResponse == null) return [];
    
    final devices = <SyncthingDevice>[];
    if (configResponse is List<dynamic>) {
      for (final device in configResponse) {
        if (device is Map<String, dynamic>) {
          final deviceId = device['deviceID'];
          final connectionInfo = connectionsResponse?['connections']?[deviceId];
          
          devices.add(SyncthingDevice(
            deviceId: deviceId,
            name: device['name'] ?? 'Unknown',
            addresses: List<String>.from(device['addresses'] ?? []),
            connected: connectionInfo?['connected'] ?? false,
            paused: connectionInfo?['paused'] ?? false,
            syncCompletion: (connectionInfo?['completion'] ?? 0).toDouble(),
            lastSeen: connectionInfo?['lastSeen'] != null
                ? DateTime.parse(connectionInfo!['lastSeen'])
                : null,
          ));
        }
      }
    }
    
    return devices;
  }
  
  /// Add a new device for syncing
  Future<bool> addDevice(String deviceId, String name) async {
    final deviceConfig = {
      'deviceID': deviceId,
      'name': name,
      'addresses': ['dynamic'],
      'compression': 'metadata',
      'introducer': false,
      'paused': false,
      'allowedNetworks': [],
      'autoAcceptFolders': false,
      'maxSendKbps': 0,
      'maxRecvKbps': 0,
    };
    
    final response = await _apiRequest(
      'PUT',
      '/rest/config/devices/$deviceId',
      body: deviceConfig,
    );
    
    if (response != null) {
      // Share folders with new device
      await _shareAllFoldersWithDevice(deviceId);
      
      // Restart to apply changes
      await _apiRequest('POST', '/rest/system/restart');
      return true;
    }
    
    return false;
  }
  
  /// Share all AuraOne folders with a device
  Future<void> _shareAllFoldersWithDevice(String deviceId) async {
    final folders = await getFolders();
    
    for (final folder in folders) {
      if (folder.id.startsWith(_folderIdPrefix)) {
        // Add device to folder
        await configureFolder(
          folderId: folder.id,
          folderPath: folder.path,
          label: folder.label,
          deviceIds: [...folder.devices.map((d) => d.deviceId), deviceId],
        );
      }
    }
  }
  
  /// Get sync status for all folders
  Future<SyncthingStatus> getSyncStatus() async {
    final statusResponse = await _apiRequest('GET', '/rest/system/status');
    final connectionsResponse = await _apiRequest('GET', '/rest/system/connections');
    final dbStatusResponse = await _apiRequest('GET', '/rest/db/status');
    
    int totalFiles = 0;
    int syncedFiles = 0;
    int totalBytes = 0;
    int syncedBytes = 0;
    bool syncing = false;
    
    if (dbStatusResponse != null) {
      totalFiles = dbStatusResponse['globalFiles'] ?? 0;
      syncedFiles = dbStatusResponse['localFiles'] ?? 0;
      totalBytes = dbStatusResponse['globalBytes'] ?? 0;
      syncedBytes = dbStatusResponse['localBytes'] ?? 0;
      syncing = dbStatusResponse['state'] == 'syncing';
    }
    
    final connectedDevices = connectionsResponse?['connections']?.values
            .where((c) => c['connected'] == true)
            .length ?? 0;
    
    return SyncthingStatus(
      isRunning: await _checkConnection(),
      isSyncing: syncing,
      totalFiles: totalFiles,
      syncedFiles: syncedFiles,
      totalBytes: totalBytes,
      syncedBytes: syncedBytes,
      connectedDevices: connectedDevices,
      lastSync: DateTime.now(),
      globalState: statusResponse?['globalState'] ?? 'unknown',
      myId: statusResponse?['myID'] ?? (_deviceId ?? 'unknown'),
      inSyncBytes: dbStatusResponse?['inSyncBytes'],
      needBytes: dbStatusResponse?['needBytes'],
    );
  }
  
  /// Start monitoring Syncthing status
  void startMonitoring() {
    stopMonitoring();
    
    // Poll status every 5 seconds
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final status = await getSyncStatus();
      _syncStatusController.add(status);
      
      // Update sync progress
      if (status.isSyncing) {
        final progress = status.totalFiles > 0
            ? status.syncedFiles / status.totalFiles
            : 0.0;
        
        _syncProgressController.add(SyncProgress(
          currentFile: '',
          totalFiles: status.totalFiles,
          syncedFiles: status.syncedFiles,
          progress: progress,
        ));
      }
    });
    
    // Device discovery every 30 seconds
    _discoveryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final devices = await getDevices();
      _deviceDiscoveryController.add(devices);
    });
  }
  
  /// Stop monitoring
  void stopMonitoring() {
    _statusPollingTimer?.cancel();
    _discoveryTimer?.cancel();
  }
  
  /// Get sync status stream
  Stream<SyncthingStatus> get syncStatusStream => _syncStatusController.stream;
  
  /// Get device discovery stream
  Stream<List<SyncthingDevice>> get deviceDiscoveryStream => _deviceDiscoveryController.stream;
  
  /// Get sync progress stream
  Stream<SyncProgress> get syncProgressStream => _syncProgressController.stream;
  
  /// Pause syncing for a device
  Future<bool> pauseDevice(String deviceId) async {
    final response = await _apiRequest(
      'POST',
      '/rest/system/pause',
      body: {'device': deviceId},
    );
    return response != null;
  }
  
  /// Resume syncing for a device
  Future<bool> resumeDevice(String deviceId) async {
    final response = await _apiRequest(
      'POST',
      '/rest/system/resume',
      body: {'device': deviceId},
    );
    return response != null;
  }
  
  /// Remove a device
  Future<bool> removeDevice(String deviceId) async {
    final response = await _apiRequest(
      'DELETE',
      '/rest/config/devices/$deviceId',
    );
    
    if (response != null) {
      await _apiRequest('POST', '/rest/system/restart');
      return true;
    }
    
    return false;
  }
  
  /// Rescan a folder
  Future<bool> rescanFolder(String folderId) async {
    final response = await _apiRequest(
      'POST',
      '/rest/db/scan',
      body: {'folder': folderId},
    );
    return response != null;
  }
  
  /// Get folder statistics
  Future<FolderStats?> getFolderStats(String folderId) async {
    final response = await _apiRequest('GET', '/rest/db/status?folder=$folderId');
    if (response == null) return null;
    
    return FolderStats(
      globalFiles: response['globalFiles'] ?? 0,
      globalDirectories: response['globalDirectories'] ?? 0,
      globalBytes: response['globalBytes'] ?? 0,
      localFiles: response['localFiles'] ?? 0,
      localDirectories: response['localDirectories'] ?? 0,
      localBytes: response['localBytes'] ?? 0,
      needFiles: response['needFiles'] ?? 0,
      needBytes: response['needBytes'] ?? 0,
      state: response['state'] ?? 'idle',
      stateChanged: response['stateChanged'] != null
          ? DateTime.parse(response['stateChanged'])
          : DateTime.now(),
    );
  }
  
  /// Override changes for a folder (accept remote changes)
  Future<bool> overrideChanges(String folderId) async {
    final response = await _apiRequest(
      'POST',
      '/rest/db/override',
      body: {'folder': folderId},
    );
    return response != null;
  }
  
  /// Revert local changes for a folder
  Future<bool> revertChanges(String folderId) async {
    final response = await _apiRequest(
      'POST',
      '/rest/db/revert',
      body: {'folder': folderId},
    );
    return response != null;
  }
  
  /// Get recent changes for a folder
  Future<List<FileChange>> getRecentChanges(String folderId, {int limit = 100}) async {
    final response = await _apiRequest(
      'GET',
      '/rest/events?events=LocalChangeDetected,RemoteChangeDetected&limit=$limit',
    );
    
    if (response == null) return [];
    
    final changes = <FileChange>[];
    if (response is List<dynamic>) {
      for (final event in response) {
        if (event is Map<String, dynamic> && event['data']?['folder'] == folderId) {
          changes.add(FileChange(
            path: event['data']['path'] ?? '',
            action: event['data']['action'] ?? '',
            modifiedBy: event['data']['modifiedBy'] ?? '',
            timestamp: DateTime.parse(event['time']),
          ));
        }
      }
    }
    
    return changes;
  }
  
  /// Get conflicts for a folder
  Future<List<String>> getConflicts(String folderId) async {
    final response = await _apiRequest('GET', '/rest/db/need?folder=$folderId');
    if (response == null) return [];
    
    final conflicts = <String>[];
    for (final file in response['files'] ?? []) {
      if (file['name'].contains('.sync-conflict-')) {
        conflicts.add(file['name']);
      }
    }
    
    return conflicts;
  }
  
  /// Resolve a conflict by choosing local or remote version
  Future<bool> resolveConflict(
    String folderId,
    String filePath,
    ConflictResolution resolution,
  ) async {
    // Implementation would depend on the specific conflict resolution strategy
    // This could involve renaming files, deleting conflicts, or merging changes
    
    switch (resolution) {
      case ConflictResolution.useLocal:
        // Keep local version, delete conflict file
        break;
      case ConflictResolution.useRemote:
        // Replace local with remote version
        break;
      case ConflictResolution.keepBoth:
        // Rename conflict file to preserve both versions
        break;
    }
    
    return true;
  }
  
  void dispose() {
    stopMonitoring();
    _syncStatusController.close();
    _deviceDiscoveryController.close();
    _syncProgressController.close();
  }
}

/// Syncthing folder configuration
class SyncthingFolder {
  final String id;
  final String label;
  final String path;
  final List<SyncthingDeviceRef> devices;
  final bool paused;
  final String type;
  final int rescanIntervalS;
  
  SyncthingFolder({
    required this.id,
    required this.label,
    required this.path,
    required this.devices,
    this.paused = false,
    this.type = 'sendreceive',
    this.rescanIntervalS = 3600,
  });
  
  factory SyncthingFolder.fromJson(Map<String, dynamic> json) {
    return SyncthingFolder(
      id: json['id'],
      label: json['label'] ?? '',
      path: json['path'],
      devices: (json['devices'] as List?)
              ?.map((d) => SyncthingDeviceRef.fromJson(d))
              .toList() ??
          [],
      paused: json['paused'] ?? false,
      type: json['type'] ?? 'sendreceive',
      rescanIntervalS: json['rescanIntervalS'] ?? 3600,
    );
  }
}

/// Reference to a device in a folder configuration
class SyncthingDeviceRef {
  final String deviceId;
  final String introducedBy;
  
  SyncthingDeviceRef({
    required this.deviceId,
    this.introducedBy = '',
  });
  
  factory SyncthingDeviceRef.fromJson(Map<String, dynamic> json) {
    return SyncthingDeviceRef(
      deviceId: json['deviceID'],
      introducedBy: json['introducedBy'] ?? '',
    );
  }
}

/// Syncthing device information
class SyncthingDevice {
  final String deviceId;
  final String name;
  final List<String> addresses;
  final bool connected;
  final bool paused;
  final double syncCompletion;
  final DateTime? lastSeen;
  
  SyncthingDevice({
    required this.deviceId,
    required this.name,
    required this.addresses,
    required this.connected,
    required this.paused,
    required this.syncCompletion,
    this.lastSeen,
  });

  String? get address => addresses.isNotEmpty ? addresses.first : null;
}

/// Syncthing sync status
class SyncthingStatus {
  final bool isRunning;
  final bool isSyncing;
  final int totalFiles;
  final int syncedFiles;
  final int totalBytes;
  final int syncedBytes;
  final int connectedDevices;
  final DateTime lastSync;
  final String globalState;
  final String myId;
  final int? inSyncBytes;
  final int? needBytes;
  
  SyncthingStatus({
    required this.isRunning,
    required this.isSyncing,
    required this.totalFiles,
    required this.syncedFiles,
    required this.totalBytes,
    required this.syncedBytes,
    required this.connectedDevices,
    required this.lastSync,
    required this.globalState,
    required this.myId,
    this.inSyncBytes,
    this.needBytes,
  });
  
  double get syncProgress {
    if (totalFiles == 0) return 1.0;
    return syncedFiles / totalFiles;
  }
  
  String get formattedProgress {
    return '${(syncProgress * 100).toStringAsFixed(1)}%';
  }
}

/// Sync progress information
class SyncProgress {
  final String currentFile;
  final int totalFiles;
  final int syncedFiles;
  final double progress;
  
  SyncProgress({
    required this.currentFile,
    required this.totalFiles,
    required this.syncedFiles,
    required this.progress,
  });
}

/// Folder statistics
class FolderStats {
  final int globalFiles;
  final int globalDirectories;
  final int globalBytes;
  final int localFiles;
  final int localDirectories;
  final int localBytes;
  final int needFiles;
  final int needBytes;
  final String state;
  final DateTime stateChanged;
  
  FolderStats({
    required this.globalFiles,
    required this.globalDirectories,
    required this.globalBytes,
    required this.localFiles,
    required this.localDirectories,
    required this.localBytes,
    required this.needFiles,
    required this.needBytes,
    required this.state,
    required this.stateChanged,
  });
  
  bool get isIdle => state == 'idle';
  bool get isSyncing => state == 'syncing';
  bool get hasConflicts => state == 'error';
  
  double get completion {
    if (globalBytes == 0) return 1.0;
    return localBytes / globalBytes;
  }
}

/// File change information
class FileChange {
  final String path;
  final String action;
  final String modifiedBy;
  final DateTime timestamp;
  
  FileChange({
    required this.path,
    required this.action,
    required this.modifiedBy,
    required this.timestamp,
  });
}

/// Conflict resolution strategies
enum ConflictResolution {
  useLocal,
  useRemote,
  keepBoth,
}