import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Cache manager for media thumbnails
class ThumbnailCache {
  static const int maxCacheSize = 100; // Maximum number of cached thumbnails
  static const Duration cacheExpiry = Duration(hours: 24);

  final Map<String, CachedThumbnail> _cache = {};
  final Map<String, DateTime> _lastAccessed = {};

  /// Get a thumbnail from cache
  Uint8List? get(String key) {
    final cached = _cache[key];
    if (cached != null) {
      if (DateTime.now().difference(cached.timestamp) < cacheExpiry) {
        _lastAccessed[key] = DateTime.now();
        return cached.data;
      } else {
        // Expired, remove from cache
        _cache.remove(key);
        _lastAccessed.remove(key);
      }
    }
    return null;
  }

  /// Add a thumbnail to cache
  void put(String key, Uint8List data) {
    // Check cache size limit
    if (_cache.length >= maxCacheSize) {
      _evictOldest();
    }

    _cache[key] = CachedThumbnail(data: data, timestamp: DateTime.now());
    _lastAccessed[key] = DateTime.now();
  }

  /// Evict oldest accessed item from cache
  void _evictOldest() {
    if (_lastAccessed.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _lastAccessed.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
      _lastAccessed.remove(oldestKey);
    }
  }

  /// Clear all cached thumbnails
  void clear() {
    _cache.clear();
    _lastAccessed.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'items': _cache.length,
      'maxItems': maxCacheSize,
      'totalSize': _cache.values.fold<int>(0, (sum, item) => sum + item.data.length),
    };
  }
}

/// Cached thumbnail data
class CachedThumbnail {
  final Uint8List data;
  final DateTime timestamp;

  CachedThumbnail({required this.data, required this.timestamp});
}

/// Provider for thumbnail cache
final thumbnailCacheProvider = Provider<ThumbnailCache>((ref) {
  final cache = ThumbnailCache();

  // Clear cache when provider is disposed
  ref.onDispose(() {
    cache.clear();
  });

  return cache;
});

/// Provider for generating and caching thumbnails
final thumbnailProvider = FutureProvider.family<Uint8List?, String>((ref, filePath) async {
  final cache = ref.watch(thumbnailCacheProvider);

  // Generate cache key from file path
  final cacheKey = _generateCacheKey(filePath);

  // Check memory cache first
  final cachedData = cache.get(cacheKey);
  if (cachedData != null) {
    return cachedData;
  }

  // Check if file exists
  final file = File(filePath);
  if (!await file.exists()) {
    return null;
  }

  // For now, just read the file directly
  // In a production app, you might want to generate actual thumbnails
  // using image processing libraries
  try {
    final bytes = await file.readAsBytes();

    // Cache the thumbnail
    cache.put(cacheKey, bytes);

    return bytes;
  } catch (e) {
    debugPrint('Error loading thumbnail for $filePath: $e');
    return null;
  }
});

/// Generate a stable cache key from file path
String _generateCacheKey(String filePath) {
  final bytes = utf8.encode(filePath);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

/// Provider for batch loading thumbnails
final batchThumbnailProvider = FutureProvider.family<Map<String, Uint8List?>, List<String>>((ref, filePaths) async {
  final cache = ref.watch(thumbnailCacheProvider);
  final results = <String, Uint8List?>{};
  final toLoad = <String>[];

  // First pass: check cache
  for (final filePath in filePaths) {
    final cacheKey = _generateCacheKey(filePath);
    final cached = cache.get(cacheKey);

    if (cached != null) {
      results[filePath] = cached;
    } else {
      toLoad.add(filePath);
    }
  }

  // Second pass: load missing thumbnails in parallel
  if (toLoad.isNotEmpty) {
    final futures = toLoad.map((filePath) async {
      final file = File(filePath);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          cache.put(_generateCacheKey(filePath), bytes);
          return MapEntry(filePath, bytes);
        } catch (e) {
          debugPrint('Error loading thumbnail for $filePath: $e');
          return MapEntry(filePath, null);
        }
      }
      return MapEntry(filePath, null);
    });

    final loadedEntries = await Future.wait(futures);
    results.addEntries(loadedEntries);
  }

  return results;
});

/// Widget to display a cached thumbnail
class CachedThumbnailWidget extends ConsumerWidget {
  final String filePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedThumbnailWidget({
    super.key,
    required this.filePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(thumbnailProvider(filePath));

    return thumbnailAsync.when(
      data: (bytes) {
        if (bytes == null) {
          return errorWidget ?? _buildDefaultError(context);
        }

        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          cacheWidth: width != null ? (width! * 2).toInt() : null,
          cacheHeight: height != null ? (height! * 2).toInt() : null,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _buildDefaultError(context),
        );
      },
      loading: () => placeholder ?? _buildDefaultPlaceholder(context),
      error: (error, stack) => errorWidget ?? _buildDefaultError(context),
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildDefaultError(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        size: 24,
      ),
    );
  }
}