import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:drift/drift.dart' show Value;
import '../utils/logger.dart';
import '../database/media_database.dart';
import '../providers/media_database_provider.dart';
import 'exif_extractor.dart';
import 'media_format_handler.dart';
import 'person_service.dart';
import 'media_processing_isolate.dart';
import 'media_cache_service.dart';

/// Service for managing photo library access and automated scanning
class PhotoService {
  static final _logger = AppLogger('PhotoService');

  /// Reference to Riverpod container for database access
  final Ref? _ref;

  /// Media database for storing photo metadata
  MediaDatabase? _mediaDatabase;

  /// Media management service
  MediaManagementService? _mediaManagement;

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

  /// Pagination configuration
  static const int defaultPageSize = 50;
  static const int maxConcurrentProcessing = 3;

  /// Background processing pool
  MediaProcessingPool? _processingPool;
  bool _isPoolInitialized = false;

  /// Cache service
  final _cacheService = MediaCacheService();

  /// Stream controller for new photo events
  final _newPhotoController = StreamController<List<AssetEntity>>.broadcast();

  /// Stream of newly discovered photos
  Stream<List<AssetEntity>> get newPhotoStream => _newPhotoController.stream;

  /// Check if we have photo library access
  bool get hasAccess => _permissionState?.hasAccess ?? false;

  /// Check if we have full photo library access
  bool get hasFullAccess => _permissionState?.isAuth ?? false;

  /// Constructor that optionally accepts a Riverpod ref for database access
  PhotoService([this._ref]);

  /// Get media database instance
  MediaDatabase get mediaDatabase {
    if (_mediaDatabase == null) {
      if (_ref != null) {
        _mediaDatabase = _ref!.read(mediaDatabaseProvider);
      } else {
        _mediaDatabase = MediaDatabase();
      }
    }
    return _mediaDatabase!;
  }

  /// Get media management service
  MediaManagementService get mediaManagement {
    if (_mediaManagement == null) {
      if (_ref != null) {
        _mediaManagement = _ref!.read(mediaManagementProvider);
      } else {
        _mediaManagement = MediaManagementService(_ref!);
      }
    }
    return _mediaManagement!;
  }

  /// Initialize the photo service
  Future<void> initialize() async {
    try {
      _logger.info('Initializing PhotoService...');

      // Initialize cache service
      _cacheService.initialize();

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

      // Store new media items in database if we have database access
      if (_ref != null) {
        await _storeMediaItemsInDatabase(assets);
      }

      return assets;
    } catch (e, stack) {
      _logger.error('Failed to scan for new photos', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get recent photos
  Future<List<AssetEntity>> getRecentPhotos({
    int limit = 100,
    DateTime? since,
  }) async {
    if (!hasAccess) {
      _logger.warning('Cannot get recent photos without library access');
      return [];
    }

    try {
      // Get all photos album
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isEmpty) {
        _logger.warning('No photo albums found');
        return [];
      }

      final allPhotos = albums.first;

      // Get photos from the album
      final photos = await allPhotos.getAssetListRange(
        start: 0,
        end: limit,
      );

      // Filter by date if provided
      if (since != null) {
        return photos.where((photo) {
          final createTime = photo.createDateTime;
          return createTime.isAfter(since);
        }).toList();
      }

      return photos;
    } catch (e, stack) {
      _logger.error('Failed to get recent photos', error: e, stackTrace: stack);
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

  /// Generate enhanced thumbnail using MediaFormatHandler
  Future<ThumbnailResult?> generateThumbnail(
    AssetEntity asset, {
    int size = 200,
    int quality = 85,
  }) async {
    try {
      // Check if format is supported for processing
      if (!MediaFormatHandler.isProcessableAsset(asset)) {
        _logger.warning('Asset format ${asset.mimeType} is not supported for processing: ${asset.id}');
        return null;
      }

      // Use enhanced format handler for thumbnail generation
      final thumbnailResult = await MediaFormatHandler.generateThumbnail(
        asset,
        size: size,
        quality: quality,
      );

      if (thumbnailResult != null) {
        final formatInfo = MediaFormatHandler.getFormatInfo(asset.mimeType);
        _logger.debug('Generated ${thumbnailResult.format} thumbnail for ${formatInfo.format.name} asset: ${asset.id}');
      }

      return thumbnailResult;
    } catch (e, stack) {
      _logger.error('Failed to generate enhanced thumbnail for asset: ${asset.id}', error: e, stackTrace: stack);
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

  /// Extract EXIF metadata from a photo asset using enhanced format handler
  Future<ExifData?> extractExifData(AssetEntity asset) async {
    if (asset.type != AssetType.image) {
      _logger.warning('Cannot extract EXIF from non-image asset: ${asset.id}');
      return null;
    }

    try {
      // Check cache first
      final cachedData = _cacheService.getCachedExifData(asset.id);
      if (cachedData != null) {
        _logger.debug('EXIF cache hit for asset: ${asset.id}');
        return ExifData.fromJson(cachedData);
      }

      // Check if the format supports metadata extraction
      if (!MediaFormatHandler.supportsMetadata(asset.mimeType)) {
        _logger.debug('Format ${asset.mimeType} does not support metadata extraction');
        return null;
      }

      // Use enhanced format handler for metadata extraction
      final exifData = await MediaFormatHandler.extractImageMetadata(asset);

      if (exifData != null) {
        // Cache the result
        _cacheService.cacheExifData(asset.id, exifData.toJson());

        final formatInfo = MediaFormatHandler.getFormatInfo(asset.mimeType);
        _logger.info('Successfully extracted EXIF data from ${formatInfo.format.name} asset: ${asset.id}');
        _logger.debug('GPS: ${exifData.gpsCoordinates}, Camera: ${exifData.make} ${exifData.model}');
      } else {
        _logger.info('No EXIF data found in asset: ${asset.id}');
      }

      return exifData;
    } catch (e, stack) {
      _logger.error('Failed to extract EXIF data from asset: ${asset.id}',
                   error: e, stackTrace: stack);
      return null;
    }
  }

  /// Extract EXIF data from multiple photo assets
  Future<Map<String, ExifData>> extractExifDataBatch(List<AssetEntity> assets) async {
    final results = <String, ExifData>{};

    for (final asset in assets) {
      if (asset.type == AssetType.image) {
        final exifData = await extractExifData(asset);
        if (exifData != null) {
          results[asset.id] = exifData;
        }
      }
    }

    _logger.info('Extracted EXIF data from ${results.length}/${assets.length} assets');
    return results;
  }

  /// Extract video metadata from a video asset
  Future<VideoMetadata?> extractVideoMetadata(AssetEntity asset) async {
    if (asset.type != AssetType.video) {
      _logger.warning('Cannot extract video metadata from non-video asset: ${asset.id}');
      return null;
    }

    try {
      // Use enhanced format handler for video metadata extraction
      final videoMetadata = await MediaFormatHandler.extractVideoMetadata(asset);

      if (videoMetadata != null) {
        final formatInfo = MediaFormatHandler.getFormatInfo(asset.mimeType);
        _logger.info('Successfully extracted video metadata from ${formatInfo.format.name} asset: ${asset.id}');
        _logger.debug('Duration: ${videoMetadata.duration}, Resolution: ${videoMetadata.width}x${videoMetadata.height}');
      } else {
        _logger.info('No video metadata found in asset: ${asset.id}');
      }

      return videoMetadata;
    } catch (e, stack) {
      _logger.error('Failed to extract video metadata from asset: ${asset.id}',
                   error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get photos with GPS coordinates from a list of assets
  Future<List<PhotoWithLocation>> getPhotosWithLocation(List<AssetEntity> assets) async {
    final photosWithLocation = <PhotoWithLocation>[];

    for (final asset in assets) {
      if (asset.type == AssetType.image) {
        final exifData = await extractExifData(asset);
        if (exifData?.gpsCoordinates != null) {
          photosWithLocation.add(PhotoWithLocation(
            asset: asset,
            coordinates: exifData!.gpsCoordinates!,
            timestamp: ExifExtractor.parseExifDateTime(exifData.dateTimeOriginal) ??
                      asset.createDateTime,
          ));
        }
      }
    }

    _logger.info('Found ${photosWithLocation.length} photos with GPS coordinates');
    return photosWithLocation;
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

  /// Scan and index today's photos into the database
  Future<void> scanAndIndexTodayPhotos() async {
    try {
      // Check permission first
      final permission = await PhotoManager.requestPermissionExtend();
      if (permission != PermissionState.authorized && permission != PermissionState.limited) {
        _logger.warning('No photo library access');
        return;
      }

      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Fetch photos from today
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );

      if (albums.isEmpty) return;

      // Get the "Recent" or "All" album
      final recentAlbum = albums.firstWhere(
        (album) => album.isAll,
        orElse: () => albums.first,
      );

      // Get photos from today
      final photos = await recentAlbum.getAssetListRange(
        start: 0,
        end: 1000, // Get up to 1000 photos
      );

      // Filter to today's photos and index them
      for (final photo in photos) {
        final createDate = photo.createDateTime;
        if (createDate.isAfter(todayStart) && createDate.isBefore(todayEnd)) {
          try {
            // Index this photo using upsert to handle duplicates gracefully
            final file = await photo.file;
            if (file != null) {
              final fileName = file.path.split('/').last;
              await mediaDatabase.insertOrReplaceMediaItem(
                MediaItemsCompanion.insert(
                  id: photo.id,
                  filePath: Value(file.path),
                  fileName: fileName,
                  mimeType: photo.mimeType ?? 'image/jpeg',
                  createdDate: createDate,
                  modifiedDate: createDate,
                  fileSize: await file.length(),
                  width: Value(photo.width),
                  height: Value(photo.height),
                ),
              );
            }
          } catch (e) {
            // Log individual photo indexing errors but continue with others
            _logger.warning('Failed to index photo ${photo.id}: $e');
          }
        }
      }

      _logger.info('Indexed photos for today');
    } catch (e, stack) {
      _logger.error('Failed to scan and index today\'s photos', error: e, stackTrace: stack);
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






  // MARK: - Face Clustering and Person Identification

  /// Initialize face clustering and person identification services
  FaceClusteringService? _clusteringService;
  PersonService? _personService;

  /// Get or initialize clustering service
  FaceClusteringService get clusteringService {
    _clusteringService ??= FaceClusteringService();
    return _clusteringService!;
  }

  /// Get or initialize person service
  PersonService get personService {
    _personService ??= PersonService(clusteringService: clusteringService);
    return _personService!;
  }

  /// Initialize person identification service
  Future<void> initializePersonService() async {
    if (_personService == null) {
      _personService = PersonService(clusteringService: clusteringService);
      await _personService!.initialize();
      _logger.info('Person service initialized');
    }
  }

  /// Process photos to identify persons through face clustering
  Future<List<Person>> identifyPersonsInPhotos(List<AssetEntity> photos) async {
    try {
      await initializePersonService();

      _logger.info('Starting person identification for ${photos.length} photos');

      final persons = await personService.processPhotos(photos);

      _logger.info('Person identification complete: found ${persons.length} persons');

      // Store person identification results for each photo
      for (final photo in photos) {
        final personsInPhoto = persons.where((person) =>
          person.cluster.photoIds.contains(photo.id)
        ).toList();

        if (personsInPhoto.isNotEmpty) {
          await storePersonTags(photo.id, personsInPhoto);
        }
      }

      return persons;
    } catch (e, stack) {
      _logger.error('Failed to identify persons in photos', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get all identified persons
  Future<List<Person>> getAllPersons() async {
    try {
      await initializePersonService();
      return personService.persons;
    } catch (e, stack) {
      _logger.error('Failed to get all persons', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Find persons in a specific photo
  Future<List<Person>> getPersonsInPhoto(String photoId) async {
    try {
      await initializePersonService();
      return personService.getPersonsInPhoto(photoId);
    } catch (e, stack) {
      _logger.error('Failed to get persons in photo', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Name a person identified through face clustering
  Future<Person?> namePerson(String personId, String name) async {
    try {
      await initializePersonService();
      return await personService.namePerson(personId, name);
    } catch (e, stack) {
      _logger.error('Failed to name person', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Merge two persons into one
  Future<Person?> mergePersons(String person1Id, String person2Id, {String? newName}) async {
    try {
      await initializePersonService();
      return await personService.mergePersons(person1Id, person2Id, newName: newName);
    } catch (e, stack) {
      _logger.error('Failed to merge persons', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get person identification statistics
  Future<Map<String, dynamic>> getPersonStatistics() async {
    try {
      await initializePersonService();
      return personService.getStatistics();
    } catch (e, stack) {
      _logger.error('Failed to get person statistics', error: e, stackTrace: stack);
      return {};
    }
  }

  /// Search for persons by name
  Future<List<Person>> searchPersonsByName(String query) async {
    try {
      await initializePersonService();
      return personService.searchPersonsByName(query);
    } catch (e, stack) {
      _logger.error('Failed to search persons by name', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Process today's photos to identify new persons
  Future<List<Person>> identifyPersonsInTodayPhotos() async {
    try {
      // Get today's photos
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final todayPhotos = await scanNewPhotos(since: startOfDay);

      if (todayPhotos.isEmpty) {
        _logger.info('No photos found from today for person identification');
        return [];
      }

      _logger.info('Processing ${todayPhotos.length} photos from today for person identification');

      return await identifyPersonsInPhotos(todayPhotos);
    } catch (e, stack) {
      _logger.error('Failed to identify persons in today\'s photos', error: e, stackTrace: stack);
      return [];
    }
  }

  // MARK: - Database Integration Methods

  /// Store media items in the database
  Future<void> _storeMediaItemsInDatabase(List<AssetEntity> assets) async {
    if (_ref == null) return;

    try {
      _logger.info('Storing ${assets.length} media items in database');

      for (final asset in assets) {
        await _storeMediaItem(asset);
      }

      _logger.info('Successfully stored ${assets.length} media items in database');
    } catch (e, stack) {
      _logger.error('Failed to store media items in database', error: e, stackTrace: stack);
    }
  }

  /// Store a single media item in the database
  Future<void> _storeMediaItem(AssetEntity asset) async {
    try {
      // Check if media item already exists
      final existingItem = await mediaDatabase.getMediaItem(asset.id);
      if (existingItem != null) {
        _logger.debug('Media item already exists in database: ${asset.id}');
        return;
      }

      // Get file info
      final file = await asset.file;
      final fileSize = file != null ? await file.length() : 0;

      // Store basic media item
      await mediaManagement.addMediaItem(
        id: asset.id,
        fileName: asset.title ?? 'Unknown',
        mimeType: asset.mimeType ?? 'unknown',
        fileSize: fileSize,
        createdDate: asset.createDateTime,
        modifiedDate: asset.modifiedDateTime,
        filePath: file?.path,
        width: asset.width,
        height: asset.height,
        duration: asset.videoDuration?.inSeconds,
      );

      _logger.debug('Stored media item: ${asset.id}');

      // Store metadata asynchronously
      _storeMediaMetadata(asset);
    } catch (e, stack) {
      _logger.error('Failed to store media item ${asset.id}', error: e, stackTrace: stack);
    }
  }

  /// Store metadata for a media item (runs asynchronously)
  Future<void> _storeMediaMetadata(AssetEntity asset) async {
    try {
      // Store basic metadata
      await mediaManagement.addMetadata(
        mediaId: asset.id,
        metadataType: 'asset_info',
        key: 'type',
        value: asset.type.name,
      );

      if (asset.orientation != null) {
        await mediaManagement.addMetadata(
          mediaId: asset.id,
          metadataType: 'asset_info',
          key: 'orientation',
          value: asset.orientation.toString(),
        );
      }

      // Extract and store metadata based on media type
      if (asset.type == AssetType.image) {
        final exifData = await extractExifData(asset);
        if (exifData != null) {
          await _storeExifMetadata(asset.id, exifData);
        }
      } else if (asset.type == AssetType.video) {
        final videoMetadata = await extractVideoMetadata(asset);
        if (videoMetadata != null) {
          await _storeVideoMetadata(asset.id, videoMetadata);
        }
      }

      // Mark as processed
      await mediaManagement.markMediaProcessed(asset.id);
    } catch (e, stack) {
      _logger.error('Failed to store metadata for ${asset.id}', error: e, stackTrace: stack);
    }
  }

  /// Store EXIF metadata in database
  Future<void> _storeExifMetadata(String mediaId, ExifData exifData) async {
    try {
      // Store camera information
      if (exifData.make != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'exif',
          key: 'camera_make',
          value: exifData.make!,
        );
      }

      if (exifData.model != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'exif',
          key: 'camera_model',
          value: exifData.model!,
        );
      }

      // Store GPS coordinates
      if (exifData.gpsCoordinates != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'exif',
          key: 'gps_latitude',
          value: exifData.gpsCoordinates!.latitude.toString(),
        );

        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'exif',
          key: 'gps_longitude',
          value: exifData.gpsCoordinates!.longitude.toString(),
        );
      }

      // Store technical details from camera settings
      if (exifData.cameraSettings.aperture != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'exif',
          key: 'aperture',
          value: exifData.cameraSettings.aperture.toString(),
        );
      }

      if (exifData.cameraSettings.shutterSpeed != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'exif',
          key: 'shutter_speed',
          value: exifData.cameraSettings.shutterSpeed.toString(),
        );
      }

      if (exifData.cameraSettings.iso != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'exif',
          key: 'iso',
          value: exifData.cameraSettings.iso.toString(),
        );
      }

      _logger.debug('Stored EXIF metadata for media: $mediaId');
    } catch (e, stack) {
      _logger.error('Failed to store EXIF metadata for $mediaId', error: e, stackTrace: stack);
    }
  }

  /// Store video metadata in database
  Future<void> _storeVideoMetadata(String mediaId, VideoMetadata videoMetadata) async {
    try {
      // Store video dimensions
      if (videoMetadata.width != null && videoMetadata.height != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'video',
          key: 'resolution',
          value: '${videoMetadata.width}x${videoMetadata.height}',
        );
      }

      // Store duration
      if (videoMetadata.duration != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'video',
          key: 'duration_seconds',
          value: videoMetadata.duration!.inSeconds.toString(),
        );
      }

      // Store frame rate
      if (videoMetadata.frameRate != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'video',
          key: 'frame_rate',
          value: videoMetadata.frameRate.toString(),
        );
      }

      // Store bitrate
      if (videoMetadata.bitrate != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'video',
          key: 'bitrate',
          value: videoMetadata.bitrate.toString(),
        );
      }

      // Store codec
      if (videoMetadata.codec != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'video',
          key: 'codec',
          value: videoMetadata.codec!,
        );
      }

      // Store GPS coordinates if available
      if (videoMetadata.location != null) {
        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'video',
          key: 'gps_latitude',
          value: videoMetadata.location!.latitude.toString(),
        );

        await mediaManagement.addMetadata(
          mediaId: mediaId,
          metadataType: 'video',
          key: 'gps_longitude',
          value: videoMetadata.location!.longitude.toString(),
        );

        if (videoMetadata.location!.altitude != null) {
          await mediaManagement.addMetadata(
            mediaId: mediaId,
            metadataType: 'video',
            key: 'gps_altitude',
            value: videoMetadata.location!.altitude.toString(),
          );
        }
      }

      _logger.debug('Stored video metadata for media: $mediaId');
    } catch (e, stack) {
      _logger.error('Failed to store video metadata for $mediaId', error: e, stackTrace: stack);
    }
  }


  /// Store person identification results in database
  Future<void> storePersonTags(String mediaId, List<Person> persons) async {
    if (_ref == null) return;

    try {
      for (final person in persons) {
        // Get the representative face for this person in this photo
        final facesInPhoto = person.cluster.faces.where((face) => face.photoId == mediaId).toList();

        for (final face in facesInPhoto) {
          await mediaManagement.addPersonTag(
            personId: person.personId,
            mediaId: mediaId,
            boundingBoxX: face.boundingBox.left,
            boundingBoxY: face.boundingBox.top,
            boundingBoxWidth: face.boundingBox.width,
            boundingBoxHeight: face.boundingBox.height,
            confidence: face.confidence,
            personName: person.name,
            personNickname: person.nickname,
            similarity: null, // similarity is not a direct property of FaceEmbedding
          );
        }
      }

      _logger.info('Stored person tags for media: $mediaId (${persons.length} persons)');
    } catch (e, stack) {
      _logger.error('Failed to store person tags for $mediaId', error: e, stackTrace: stack);
    }
  }

  /// Get media items from database
  Future<List<MediaItem>> getStoredMediaItems({
    bool includeDeleted = false,
    bool processedOnly = false,
  }) async {
    if (_ref == null) return [];

    try {
      final items = await _ref!.read(mediaItemsProvider(
        (includeDeleted: includeDeleted, processedOnly: processedOnly)
      ).future);
      return items;
    } catch (e, stack) {
      _logger.error('Failed to get stored media items', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get media statistics from database
  Future<Map<String, int>> getStoredMediaStatistics() async {
    if (_ref == null) return {};

    try {
      return await _ref!.read(mediaStatisticsProvider.future);
    } catch (e, stack) {
      _logger.error('Failed to get media statistics', error: e, stackTrace: stack);
      return {};
    }
  }

  /// Scan media library with pagination and progress tracking
  Future<void> scanMediaLibraryWithPagination({
    DateTime? since,
    DateTime? until,
    RequestType type = RequestType.common,
    int pageSize = defaultPageSize,
    void Function(int processed, int total)? onProgress,
    void Function(List<AssetEntity> batch)? onBatchProcessed,
    bool processInBackground = false,
  }) async {
    if (!hasAccess) {
      _logger.warning('Cannot scan media library without access');
      return;
    }

    try {
      _logger.info('Starting paginated media library scan');

      final filterOption = FilterOptionGroup(
        createTimeCond: since != null || until != null
            ? DateTimeCond(
                min: since ?? DateTime(1970),
                max: until ?? DateTime.now(),
              )
            : null,
        orders: [
          OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      );

      // Get all photo paths
      final paths = await PhotoManager.getAssetPathList(
        type: type,
        onlyAll: true,
        filterOption: filterOption,
      );

      if (paths.isEmpty) {
        _logger.info('No media collections found');
        return;
      }

      final allPhotos = paths.first;
      final totalAssets = await allPhotos.assetCountAsync;

      _logger.info('Found $totalAssets assets to process');

      if (totalAssets == 0) {
        return;
      }

      // Calculate number of pages
      final pageCount = (totalAssets / pageSize).ceil();
      int processedCount = 0;

      // Process pages in batches for better performance
      for (int page = 0; page < pageCount; page++) {
        // Fetch current page of assets
        final pageAssets = await allPhotos.getAssetListPaged(
          page: page,
          size: pageSize,
        );

        if (pageAssets.isEmpty) {
          continue;
        }

        // Process batch
        if (processInBackground) {
          // Queue for background processing (will be implemented with isolates)
          await _queueForBackgroundProcessing(pageAssets);
        } else {
          // Process immediately
          await _processBatch(pageAssets);
        }

        processedCount += pageAssets.length;

        // Report progress
        onProgress?.call(processedCount, totalAssets);
        onBatchProcessed?.call(pageAssets);

        _logger.debug('Processed batch ${page + 1}/$pageCount (${processedCount}/$totalAssets assets)');

        // Add small delay between batches to prevent overwhelming the system
        if (page < pageCount - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      _logger.info('Completed paginated scan: processed $processedCount assets');
    } catch (e, stack) {
      _logger.error('Paginated scan failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Process a batch of assets
  Future<void> _processBatch(List<AssetEntity> assets) async {
    try {
      for (final asset in assets) {
        // Check if already in database
        final existing = await mediaDatabase.getMediaItem(asset.id);
        if (existing != null && existing.isProcessed) {
          continue;
        }

        // Add to database if new
        if (existing == null) {
          await mediaManagement.addMediaItem(
            id: asset.id,
            fileName: asset.title ?? 'Untitled',
            mimeType: asset.mimeType ?? 'application/octet-stream',
            fileSize: 0, // Will be updated when file is accessed
            createdDate: asset.createDateTime,
            modifiedDate: asset.modifiedDateTime,
            width: asset.width,
            height: asset.height,
            duration: asset.duration,
          );
        }

        // Extract metadata based on type
        if (asset.type == AssetType.image) {
          final exifData = await extractExifData(asset);
          if (exifData != null) {
            await _storeExifMetadata(asset.id, exifData);
          }
        } else if (asset.type == AssetType.video) {
          final videoMetadata = await extractVideoMetadata(asset);
          if (videoMetadata != null) {
            await _storeVideoMetadata(asset.id, videoMetadata);
          }
        }

        // Mark as processed
        await mediaManagement.markMediaProcessed(asset.id);

        // Add to known IDs cache
        _knownPhotoIds.add(asset.id);
      }
    } catch (e, stack) {
      _logger.error('Failed to process batch', error: e, stackTrace: stack);
    }
  }

  /// Queue assets for background processing
  Future<void> _queueForBackgroundProcessing(List<AssetEntity> assets) async {
    try {
      // Initialize pool if needed
      if (!_isPoolInitialized) {
        await _initializeProcessingPool();
      }

      if (_processingPool == null) {
        // Fallback to inline processing if pool initialization failed
        await _processBatch(assets);
        return;
      }

      // Get database path
      final databasePath = 'media_database';

      // Convert AssetEntity list to ID list for isolate
      final assetIds = assets.map((asset) => asset.id).toList();

      // Process in isolate pool
      final results = await _processingPool!.processAssetsInParallel(
        assetIds,
        databasePath,
        onProgress: (processed, total) {
          _logger.debug('Background processing: $processed/$total assets');
        },
      );

      // Store results in database
      for (final result in results) {
        if (result.success && result.metadata != null) {
          final metadata = result.metadata!;

          if (metadata['type'] == 'exif') {
            // Store EXIF metadata
            await mediaManagement.addMetadata(
              mediaId: result.assetId,
              metadataType: 'exif',
              key: 'data',
              value: jsonEncode(metadata['data']),
            );
          } else if (metadata['type'] == 'video') {
            // Store video metadata
            await mediaManagement.addMetadata(
              mediaId: result.assetId,
              metadataType: 'video',
              key: 'data',
              value: jsonEncode(metadata['data']),
            );
          }
        }

        // Mark as processed
        await mediaManagement.markMediaProcessed(result.assetId);
        _knownPhotoIds.add(result.assetId);
      }

      _logger.info('Background processing completed for ${results.length} assets');
    } catch (e, stack) {
      _logger.error('Background processing failed', error: e, stackTrace: stack);
      // Fallback to inline processing
      await _processBatch(assets);
    }
  }

  /// Initialize background processing pool
  Future<void> _initializeProcessingPool() async {
    try {
      _logger.info('Initializing background processing pool');
      _processingPool = MediaProcessingPool(poolSize: maxConcurrentProcessing);
      await _processingPool!.initialize();
      _isPoolInitialized = true;
      _logger.info('Background processing pool initialized successfully');
    } catch (e, stack) {
      _logger.error('Failed to initialize processing pool', error: e, stackTrace: stack);
      _processingPool = null;
      _isPoolInitialized = false;
    }
  }

  /// Get unprocessed media count
  Future<int> getUnprocessedMediaCount() async {
    try {
      final unprocessed = await mediaDatabase.getUnprocessedMedia();
      return unprocessed.length;
    } catch (e, stack) {
      _logger.error('Failed to get unprocessed media count', error: e, stackTrace: stack);
      return 0;
    }
  }

  /// Process unprocessed media in batches
  Future<void> processUnprocessedMedia({
    int batchSize = defaultPageSize,
    void Function(int processed, int total)? onProgress,
  }) async {
    try {
      final unprocessed = await mediaDatabase.getUnprocessedMedia();
      final total = unprocessed.length;

      if (total == 0) {
        _logger.info('No unprocessed media found');
        return;
      }

      _logger.info('Processing $total unprocessed media items');

      int processed = 0;
      for (int i = 0; i < total; i += batchSize) {
        final end = (i + batchSize < total) ? i + batchSize : total;
        final batch = unprocessed.sublist(i, end);

        // Process each item in the batch
        for (final mediaItem in batch) {
          try {
            // Get the corresponding AssetEntity
            final asset = await AssetEntity.fromId(mediaItem.id);
            if (asset != null) {
              // Extract metadata
              if (asset.type == AssetType.image) {
                final exifData = await extractExifData(asset);
                if (exifData != null) {
                  await _storeExifMetadata(asset.id, exifData);
                }
              } else if (asset.type == AssetType.video) {
                final videoMetadata = await extractVideoMetadata(asset);
                if (videoMetadata != null) {
                  await _storeVideoMetadata(asset.id, videoMetadata);
                }
              }
            }

            // Mark as processed
            await mediaManagement.markMediaProcessed(mediaItem.id);
            processed++;

          } catch (e) {
            _logger.error('Failed to process media item ${mediaItem.id}', error: e);
          }
        }

        onProgress?.call(processed, total);

        // Small delay between batches
        if (i + batchSize < total) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      _logger.info('Completed processing unprocessed media: $processed/$total items');
    } catch (e, stack) {
      _logger.error('Failed to process unprocessed media', error: e, stackTrace: stack);
    }
  }

  /// Clean up resources
  void dispose() async {
    stopAutomaticScanning();
    PhotoManager.removeChangeCallback(_onPhotoLibraryChanged);
    PhotoManager.stopChangeNotify();
    _photoDiscoveryController.close();
    _newPhotoController.close();
    _mediaDatabase?.close();

    // Shutdown isolate pool
    if (_processingPool != null) {
      await _processingPool!.shutdown();
      _processingPool = null;
      _isPoolInitialized = false;
    }

    // Dispose cache service
    _cacheService.dispose();

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

/// Photo with location information
class PhotoWithLocation {
  final AssetEntity asset;
  final GpsCoordinates coordinates;
  final DateTime timestamp;

  PhotoWithLocation({
    required this.asset,
    required this.coordinates,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'assetId': asset.id,
    'coordinates': coordinates.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };
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
