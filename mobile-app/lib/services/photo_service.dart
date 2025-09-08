import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../utils/logger.dart';

/// Service for managing photo library access and scanning
class PhotoService {
  static final _logger = AppLogger('PhotoService');
  
  /// Current permission state
  PermissionState? _permissionState;
  
  /// Stream controller for photo discovery events
  final _photoDiscoveryController = StreamController<PhotoDiscoveryEvent>.broadcast();
  
  /// Stream of photo discovery events
  Stream<PhotoDiscoveryEvent> get photoDiscoveryStream => _photoDiscoveryController.stream;
  
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
  
  /// Clean up resources
  void dispose() {
    PhotoManager.removeChangeCallback(_onPhotoLibraryChanged);
    PhotoManager.stopChangeNotify();
    _photoDiscoveryController.close();
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