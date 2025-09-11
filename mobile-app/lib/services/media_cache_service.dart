import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../utils/logger.dart';

/// Cache entry for media metadata
class MediaCacheEntry<T> {
  final String key;
  final T value;
  final DateTime timestamp;
  final Duration ttl;

  MediaCacheEntry({
    required this.key,
    required this.value,
    required this.timestamp,
    this.ttl = const Duration(minutes: 30),
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// LRU cache implementation for media
class MediaLRUCache<T> {
  final int maxSize;
  final Map<String, MediaCacheEntry<T>> _cache = {};
  final List<String> _accessOrder = [];

  MediaLRUCache({this.maxSize = 100});

  /// Get value from cache
  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      remove(key);
      return null;
    }

    // Update access order
    _accessOrder.remove(key);
    _accessOrder.add(key);

    return entry.value;
  }

  /// Put value into cache
  void put(String key, T value, {Duration? ttl}) {
    // Remove if exists to update access order
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    }

    // Evict least recently used if at capacity
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      final lruKey = _accessOrder.removeAt(0);
      _cache.remove(lruKey);
    }

    // Add new entry
    _cache[key] = MediaCacheEntry(
      key: key,
      value: value,
      timestamp: DateTime.now(),
      ttl: ttl ?? const Duration(minutes: 30),
    );
    _accessOrder.add(key);
  }

  /// Remove from cache
  void remove(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// Clear cache
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Get cache size
  int get size => _cache.length;

  /// Clean expired entries
  void cleanExpired() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      remove(key);
    }
  }
}

/// Service for caching media data
class MediaCacheService {
  static final _logger = AppLogger('MediaCacheService');

  // Singleton instance
  static final MediaCacheService _instance = MediaCacheService._internal();
  factory MediaCacheService() => _instance;
  MediaCacheService._internal();

  // Different caches for different data types
  final _thumbnailCache = MediaLRUCache<Uint8List>(maxSize: 200);
  final _metadataCache = MediaLRUCache<Map<String, dynamic>>(maxSize: 500);
  final _assetCache = MediaLRUCache<AssetEntity>(maxSize: 1000);
  final _exifCache = MediaLRUCache<Map<String, dynamic>>(maxSize: 300);
  final _faceCache = MediaLRUCache<List<Map<String, dynamic>>>(maxSize: 200);

  // Memory usage tracking
  int _estimatedMemoryUsage = 0;
  static const int _maxMemoryUsage = 100 * 1024 * 1024; // 100MB

  // Cleanup timer
  Timer? _cleanupTimer;

  /// Initialize cache service
  void initialize() {
    _logger.info('Initializing media cache service');

    // Start periodic cleanup
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      performCleanup();
    });
  }

  /// Get thumbnail from cache or load it
  Future<Uint8List?> getThumbnail(
    String assetId,
    int width,
    int height, {
    Future<Uint8List?> Function()? loader,
  }) async {
    final key = '${assetId}_${width}x$height';

    // Check cache
    var thumbnail = _thumbnailCache.get(key);
    if (thumbnail != null) {
      _logger.debug('Thumbnail cache hit: $key');
      return thumbnail;
    }

    // Load if loader provided
    if (loader != null) {
      _logger.debug('Loading thumbnail: $key');
      thumbnail = await loader();

      if (thumbnail != null) {
        // Estimate memory usage (approximate)
        final size = thumbnail.length;
        if (_estimatedMemoryUsage + size < _maxMemoryUsage) {
          _thumbnailCache.put(key, thumbnail);
          _estimatedMemoryUsage += size;
          _logger.debug('Cached thumbnail: $key (${size ~/ 1024}KB)');
        } else {
          _logger.warning('Memory limit reached, not caching thumbnail');
        }
      }
    }

    return thumbnail;
  }

  /// Cache metadata
  void cacheMetadata(String assetId, Map<String, dynamic> metadata) {
    _metadataCache.put(assetId, metadata, ttl: const Duration(hours: 1));
    _logger.debug('Cached metadata for asset: $assetId');
  }

  /// Get cached metadata
  Map<String, dynamic>? getCachedMetadata(String assetId) {
    return _metadataCache.get(assetId);
  }

  /// Cache EXIF data
  void cacheExifData(String assetId, Map<String, dynamic> exifData) {
    _exifCache.put(assetId, exifData, ttl: const Duration(hours: 2));
    _logger.debug('Cached EXIF data for asset: $assetId');
  }

  /// Get cached EXIF data
  Map<String, dynamic>? getCachedExifData(String assetId) {
    return _exifCache.get(assetId);
  }

  /// Cache face detection results
  void cacheFaceData(String assetId, List<Map<String, dynamic>> faces) {
    _faceCache.put(assetId, faces, ttl: const Duration(hours: 4));
    _logger.debug('Cached ${faces.length} faces for asset: $assetId');
  }

  /// Get cached face data
  List<Map<String, dynamic>>? getCachedFaceData(String assetId) {
    return _faceCache.get(assetId);
  }

  /// Cache AssetEntity
  void cacheAsset(AssetEntity asset) {
    _assetCache.put(asset.id, asset, ttl: const Duration(minutes: 15));
  }

  /// Get cached AssetEntity
  AssetEntity? getCachedAsset(String assetId) {
    return _assetCache.get(assetId);
  }

  /// Perform cleanup
  void performCleanup() {
    _logger.info('Performing cache cleanup');

    final beforeSize = getTotalCacheSize();

    // Clean expired entries
    _thumbnailCache.cleanExpired();
    _metadataCache.cleanExpired();
    _assetCache.cleanExpired();
    _exifCache.cleanExpired();
    _faceCache.cleanExpired();

    final afterSize = getTotalCacheSize();

    if (beforeSize != afterSize) {
      _logger.info('Cache cleanup: $beforeSize -> $afterSize entries');
    }

    // Clear if memory usage too high
    if (_estimatedMemoryUsage > _maxMemoryUsage * 0.9) {
      _logger.warning('Memory usage high, clearing thumbnail cache');
      _thumbnailCache.clear();
      _estimatedMemoryUsage = 0;
    }
  }

  /// Get total cache size
  int getTotalCacheSize() {
    return _thumbnailCache.size +
           _metadataCache.size +
           _assetCache.size +
           _exifCache.size +
           _faceCache.size;
  }

  /// Get cache statistics
  Map<String, dynamic> getStatistics() {
    return {
      'thumbnails': _thumbnailCache.size,
      'metadata': _metadataCache.size,
      'assets': _assetCache.size,
      'exif': _exifCache.size,
      'faces': _faceCache.size,
      'total': getTotalCacheSize(),
      'estimatedMemoryMB': _estimatedMemoryUsage ~/ (1024 * 1024),
    };
  }

  /// Clear all caches
  void clearAll() {
    _logger.info('Clearing all caches');

    _thumbnailCache.clear();
    _metadataCache.clear();
    _assetCache.clear();
    _exifCache.clear();
    _faceCache.clear();
    _estimatedMemoryUsage = 0;
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    clearAll();
    _logger.info('Media cache service disposed');
  }
}

/// Widget for displaying cached thumbnails
class CachedThumbnail extends StatefulWidget {
  final String assetId;
  final int width;
  final int height;
  final Future<Uint8List?> Function() loader;
  final BoxFit fit;

  const CachedThumbnail({
    Key? key,
    required this.assetId,
    required this.width,
    required this.height,
    required this.loader,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<CachedThumbnail> createState() => _CachedThumbnailState();
}

class _CachedThumbnailState extends State<CachedThumbnail> {
  final _cacheService = MediaCacheService();
  Uint8List? _thumbnailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(CachedThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    setState(() {
      _isLoading = true;
    });

    final thumbnail = await _cacheService.getThumbnail(
      widget.assetId,
      widget.width,
      widget.height,
      loader: widget.loader,
    );

    if (mounted) {
      setState(() {
        _thumbnailData = thumbnail;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width.toDouble(),
        height: widget.height.toDouble(),
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_thumbnailData == null) {
      return Container(
        width: widget.width.toDouble(),
        height: widget.height.toDouble(),
        color: Colors.grey[400],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    return Image.memory(
      _thumbnailData!,
      width: widget.width.toDouble(),
      height: widget.height.toDouble(),
      fit: widget.fit,
    );
  }
}
