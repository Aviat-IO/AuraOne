import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../utils/logger.dart';

/// Service for managing photo library access and automated scanning
class PhotoService {
  static final _logger = AppLogger('PhotoService');
  
  /// Current permission state
  PermissionState? _permissionState;
  
  /// Stream controller for photo discovery events
  final _photoDiscoveryController = StreamController<PhotoDiscoveryEvent>.broadcast();
  
  /// Stream of photo discovery events
  Stream<PhotoDiscoveryEvent> get photoDiscoveryStream => _photoDiscoveryController.stream;
  
  /// Timer for automated scanning
  Timer? _scanTimer;
  
  /// Last scan timestamp
  DateTime? _lastScanTime;
  
  /// Cached photo IDs to detect new items
  final Set<String> _knownPhotoIds = {};
  
  /// Scanning configuration
  Duration _scanInterval = const Duration(minutes: 30);
  bool _isAutomaticScanningEnabled = false;
  
  /// Stream controller for new photo events
  final _newPhotoController = StreamController<List<AssetEntity>>.broadcast();
  
  /// Stream of newly discovered photos
  Stream<List<AssetEntity>> get newPhotoStream => _newPhotoController.stream;
  
  /// Check if we have photo library access
  bool get hasAccess => _permissionState?.hasAccess ?? false;
  
  /// Check if we have full photo library access
  bool get hasFullAccess => _permissionState?.isAuth ?? false;
  
  /// Initialize the photo service
  Future<void> initialize() async {
    try {
      _logger.info('Initializing PhotoService...');
      
      // Check current permission state
      _permissionState = await PhotoManager.requestPermissionExtend();
      final isAuth = _permissionState?.isAuth ?? false;
      _logger.info('Photo library permission state: ${isAuth ? "Authorized" : "Limited/Denied"}');
      
      if (_permissionState?.hasAccess ?? false) {
        // Register for photo library changes
        PhotoManager.addChangeCallback(_onPhotoLibraryChanged);
        PhotoManager.startChangeNotify();
        _logger.info('Photo library change notifications enabled');
      }
    } catch (e, stack) {
      _logger.error('Failed to initialize PhotoService', error: e, stackTrace: stack);
    }
  }
  
  /// Request photo library permissions
  Future<PermissionState> requestPermissions() async {
    try {
      _logger.info('Requesting photo library permissions...');
      _permissionState = await PhotoManager.requestPermissionExtend();
      
      if (_permissionState!.isAuth) {
        _logger.info('Full photo library access granted');
      } else if (_permissionState!.hasAccess) {
        _logger.info('Limited photo library access granted');
      } else {
        _logger.warning('Photo library access denied');
      }
      
      return _permissionState!;
    } catch (e, stack) {
      _logger.error('Failed to request photo permissions', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  /// Open system settings for photo permissions
  Future<void> openSettings() async {
    try {
      await PhotoManager.openSetting();
    } catch (e, stack) {
      _logger.error('Failed to open photo settings', error: e, stackTrace: stack);
    }
  }
  
  /// Present limited photo selection UI (iOS 14+)
  Future<void> presentLimitedSelection() async {
    // Check if we have limited access (hasAccess but not isAuth)
    final hasLimitedAccess = (_permissionState?.hasAccess ?? false) && 
                             !(_permissionState?.isAuth ?? false);
    
    if (Platform.isIOS && hasLimitedAccess) {
      try {
        await PhotoManager.presentLimited();
      } catch (e, stack) {
        _logger.error('Failed to present limited selection', error: e, stackTrace: stack);
      }
    }
  }
  
  /// Get all photo albums/collections
  Future<List<AssetPathEntity>> getAlbums({
    RequestType type = RequestType.common,
    bool onlyAll = false,
  }) async {
    if (!hasAccess) {
      _logger.warning('Cannot get albums without photo library access');
      return [];
    }
    
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: type,
        onlyAll: onlyAll,
        filterOption: FilterOptionGroup(
          orders: [
            OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            ),
          ],
        ),
      );
      
      _logger.info('Found ${albums.length} photo albums');
      return albums;
    } catch (e, stack) {
      _logger.error('Failed to get photo albums', error: e, stackTrace: stack);
      return [];
    }
  }
  
  /// Scan for new photos created within a time range
  Future<List<AssetEntity>> scanNewPhotos({
    required DateTime since,
    DateTime? until,
    RequestType type = RequestType.common,
  }) async {
    if (!hasAccess) {
      _logger.warning('Cannot scan photos without library access');
      return [];
    }
    
    try {
      _logger.info('Scanning for photos since $since');
      
      final filterOption = FilterOptionGroup(
        createTimeCond: DateTimeCond(
          min: since,
          max: until ?? DateTime.now(),
        ),
        orders: [
          OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      );
      
      // Get all photos from the specified time range
      final paths = await PhotoManager.getAssetPathList(
        type: type,
        onlyAll: true,
        filterOption: filterOption,
      );
      
      if (paths.isEmpty) {
        _logger.info('No photo collections found');
        return [];
      }
      
      // Get the "All" album which contains all photos
      final allPhotos = paths.first;
      final assetCount = await allPhotos.assetCountAsync;
      
      _logger.info('Found $assetCount photos/videos in time range');
      
      // Fetch all assets (paginated if needed)
      final assets = <AssetEntity>[];
      const pageSize = 100;
      final pageCount = (assetCount / pageSize).ceil();
      
      for (int page = 0; page < pageCount; page++) {
        final pageAssets = await allPhotos.getAssetListPaged(
          page: page,
          size: pageSize,
        );
        assets.addAll(pageAssets);
      }
      
      // Notify about discovered photos
      _photoDiscoveryController.add(PhotoDiscoveryEvent(
        assets: assets,
        timestamp: DateTime.now(),
      ));
      
      return assets;
    } catch (e, stack) {
      _logger.error('Failed to scan for new photos', error: e, stackTrace: stack);
      return [];
    }
  }
  
  /// Get a specific photo by ID
  Future<AssetEntity?> getPhotoById(String id) async {
    if (!hasAccess) {
      _logger.warning('Cannot get photo without library access');
      return null;
    }
    
    try {
      return await AssetEntity.fromId(id);
    } catch (e, stack) {
      _logger.error('Failed to get photo by ID: $id', error: e, stackTrace: stack);
      return null;
    }
  }
  
  /// Get thumbnail data for an asset
  Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    ThumbnailSize size = const ThumbnailSize.square(200),
    ThumbnailFormat format = ThumbnailFormat.jpeg,
  }) async {
    try {
      return await asset.thumbnailDataWithSize(
        size,
        format: format,
      );
    } catch (e, stack) {
      _logger.error('Failed to get thumbnail for asset: ${asset.id}', error: e, stackTrace: stack);
      return null;
    }
  }
  
  /// Get the full file for an asset
  Future<File?> getFile(AssetEntity asset, {bool isOrigin = false}) async {
    try {
      if (isOrigin) {
        return await asset.originFile;
      } else {
        return await asset.file;
      }
    } catch (e, stack) {
      _logger.error('Failed to get file for asset: ${asset.id}', error: e, stackTrace: stack);
      return null;
    }
  }
  
  /// Handle photo library changes
  void _onPhotoLibraryChanged(MethodCall call) {
    _logger.info('Photo library changed: ${call.method}');
    // Trigger a rescan or update UI as needed
  }
  
  /// Start automated scanning for new photos
  void startAutomaticScanning({Duration? interval}) {
    if (!hasAccess) {
      _logger.warning('Cannot start automatic scanning without photo library access');
      return;
    }
    
    if (interval != null) {
      _scanInterval = interval;
    }
    
    _isAutomaticScanningEnabled = true;
    _logger.info('Starting automatic photo scanning with interval: $_scanInterval');
    
    // Perform initial scan
    _performAutomaticScan();
    
    // Schedule periodic scans
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(_scanInterval, (_) => _performAutomaticScan());
  }
  
  /// Stop automated scanning
  void stopAutomaticScanning() {
    _isAutomaticScanningEnabled = false;
    _scanTimer?.cancel();
    _scanTimer = null;
    _logger.info('Stopped automatic photo scanning');
  }
  
  /// Perform an automatic scan for new photos
  Future<void> _performAutomaticScan() async {
    if (!_isAutomaticScanningEnabled || !hasAccess) {
      return;
    }
    
    try {
      _logger.info('Performing automatic photo scan...');
      
      // Determine scan time range
      final now = DateTime.now();
      final scanSince = _lastScanTime ?? now.subtract(const Duration(days: 1));
      
      // Scan for new photos
      final allPhotos = await scanNewPhotos(
        since: scanSince,
        until: now,
      );
      
      // Filter out known photos to find only new ones
      final newPhotos = <AssetEntity>[];
      for (final photo in allPhotos) {
        if (!_knownPhotoIds.contains(photo.id)) {
          _knownPhotoIds.add(photo.id);
          newPhotos.add(photo);
        }
      }
      
      if (newPhotos.isNotEmpty) {
        _logger.info('Found ${newPhotos.length} new photos');
        _newPhotoController.add(newPhotos);
      }
      
      _lastScanTime = now;
    } catch (e, stack) {
      _logger.error('Automatic scan failed', error: e, stackTrace: stack);
    }
  }
  
  /// Manually trigger a scan for new photos
  Future<List<AssetEntity>> performManualScan({
    DateTime? since,
    Duration lookback = const Duration(hours: 24),
  }) async {
    if (!hasAccess) {
      _logger.warning('Cannot perform manual scan without photo library access');
      return [];
    }
    
    try {
      final scanSince = since ?? DateTime.now().subtract(lookback);
      _logger.info('Performing manual scan since $scanSince');
      
      final photos = await scanNewPhotos(since: scanSince);
      
      // Update known photos cache
      for (final photo in photos) {
        _knownPhotoIds.add(photo.id);
      }
      
      return photos;
    } catch (e, stack) {
      _logger.error('Manual scan failed', error: e, stackTrace: stack);
      return [];
    }
  }
  
  /// Clear the photo cache (useful for fresh rescans)
  void clearPhotoCache() {
    _knownPhotoIds.clear();
    _lastScanTime = null;
    _logger.info('Cleared photo cache');
  }
  
  /// Get scan statistics
  Map<String, dynamic> getScanStatistics() {
    return {
      'isScanning': _isAutomaticScanningEnabled,
      'scanInterval': _scanInterval.inMinutes,
      'lastScanTime': _lastScanTime?.toIso8601String(),
      'knownPhotosCount': _knownPhotoIds.length,
      'hasAccess': hasAccess,
    };
  }
  
  /// Clean up resources
  void dispose() {
    stopAutomaticScanning();
    PhotoManager.removeChangeCallback(_onPhotoLibraryChanged);
    PhotoManager.stopChangeNotify();
    _photoDiscoveryController.close();
    _newPhotoController.close();
    _logger.info('PhotoService disposed');
  }
}

/// Event emitted when new photos are discovered
class PhotoDiscoveryEvent {
  final List<AssetEntity> assets;
  final DateTime timestamp;
  
  PhotoDiscoveryEvent({
    required this.assets,
    required this.timestamp,
  });
}

/// Provider for PhotoService
final photoServiceProvider = Provider<PhotoService>((ref) {
  final service = PhotoService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for photo library permission state
final photoPermissionStateProvider = FutureProvider<PermissionState>((ref) async {
  final service = ref.watch(photoServiceProvider);
  await service.initialize();
  
  if (!service.hasAccess) {
    return await service.requestPermissions();
  }
  
  return await PhotoManager.requestPermissionExtend();
});

/// Provider for photo discovery stream
final photoDiscoveryStreamProvider = StreamProvider<PhotoDiscoveryEvent>((ref) {
  final service = ref.watch(photoServiceProvider);
  return service.photoDiscoveryStream;
});

/// Provider for scanning today's photos
final todayPhotosProvider = FutureProvider<List<AssetEntity>>((ref) async {
  final service = ref.watch(photoServiceProvider);
  
  // Ensure permissions are granted
  final permissionState = await ref.watch(photoPermissionStateProvider.future);
  if (!permissionState.hasAccess) {
    return [];
  }
  
  // Scan for photos from today
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  
  return await service.scanNewPhotos(since: startOfDay);
});

/// Provider for new photo stream
final newPhotoStreamProvider = StreamProvider<List<AssetEntity>>((ref) {
  final service = ref.watch(photoServiceProvider);
  return service.newPhotoStream;
});

/// Provider for automatic scanning state
final automaticScanningProvider = StateNotifierProvider<AutomaticScanningNotifier, AutomaticScanningState>((ref) {
  final service = ref.watch(photoServiceProvider);
  return AutomaticScanningNotifier(service);
});

/// State for automatic scanning
class AutomaticScanningState {
  final bool isEnabled;
  final Duration interval;
  final DateTime? lastScanTime;
  final int knownPhotosCount;
  
  AutomaticScanningState({
    this.isEnabled = false,
    this.interval = const Duration(minutes: 30),
    this.lastScanTime,
    this.knownPhotosCount = 0,
  });
  
  AutomaticScanningState copyWith({
    bool? isEnabled,
    Duration? interval,
    DateTime? lastScanTime,
    int? knownPhotosCount,
  }) {
    return AutomaticScanningState(
      isEnabled: isEnabled ?? this.isEnabled,
      interval: interval ?? this.interval,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      knownPhotosCount: knownPhotosCount ?? this.knownPhotosCount,
    );
  }
}

/// Notifier for automatic scanning state
class AutomaticScanningNotifier extends StateNotifier<AutomaticScanningState> {
  final PhotoService _service;
  
  AutomaticScanningNotifier(this._service) : super(AutomaticScanningState());
  
  void startScanning({Duration? interval}) {
    _service.startAutomaticScanning(interval: interval);
    state = state.copyWith(
      isEnabled: true,
      interval: interval ?? state.interval,
    );
    updateStatistics();
  }
  
  void stopScanning() {
    _service.stopAutomaticScanning();
    state = state.copyWith(isEnabled: false);
  }
  
  void updateInterval(Duration interval) {
    if (state.isEnabled) {
      _service.stopAutomaticScanning();
      _service.startAutomaticScanning(interval: interval);
    }
    state = state.copyWith(interval: interval);
  }
  
  void updateStatistics() {
    final stats = _service.getScanStatistics();
    state = state.copyWith(
      isEnabled: stats['isScanning'] as bool,
      lastScanTime: stats['lastScanTime'] != null 
        ? DateTime.parse(stats['lastScanTime'] as String)
        : null,
      knownPhotosCount: stats['knownPhotosCount'] as int,
    );
  }
  
  Future<List<AssetEntity>> performManualScan({Duration lookback = const Duration(hours: 24)}) async {
    final photos = await _service.performManualScan(lookback: lookback);
    updateStatistics();
    return photos;
  }
  
  void clearCache() {
    _service.clearPhotoCache();
    updateStatistics();
  }
}