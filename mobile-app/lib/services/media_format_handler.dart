import 'dart:io';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../utils/logger.dart';
import 'exif_extractor.dart';

/// Supported media format types
enum MediaFormat {
  // Image formats
  jpeg,
  png,
  heic,
  heif,
  tiff,
  webp,
  gif,
  bmp,
  // Video formats
  mp4,
  mov,
  avi,
  mkv,
  webm,
  // Unknown
  unknown,
}

/// Media format information
class MediaFormatInfo {
  final MediaFormat format;
  final String mimeType;
  final String extension;
  final bool supportsMetadata;
  final bool isVideo;
  final bool isImage;

  const MediaFormatInfo({
    required this.format,
    required this.mimeType,
    required this.extension,
    required this.supportsMetadata,
    required this.isVideo,
    required this.isImage,
  });
}

/// Video metadata extracted from video files
class VideoMetadata {
  final int? width;
  final int? height;
  final Duration? duration;
  final double? frameRate;
  final int? bitrate;
  final String? codec;
  final DateTime? creationDate;
  final GpsCoordinates? location;
  final Map<String, dynamic> rawMetadata;

  const VideoMetadata({
    this.width,
    this.height,
    this.duration,
    this.frameRate,
    this.bitrate,
    this.codec,
    this.creationDate,
    this.location,
    required this.rawMetadata,
  });

  Map<String, dynamic> toJson() => {
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (duration != null) 'duration': duration!.inSeconds,
    if (frameRate != null) 'frameRate': frameRate,
    if (bitrate != null) 'bitrate': bitrate,
    if (codec != null) 'codec': codec,
    if (creationDate != null) 'creationDate': creationDate!.toIso8601String(),
    if (location != null) 'location': location!.toJson(),
    'rawMetadata': rawMetadata,
  };
}

/// Thumbnail generation result
class ThumbnailResult {
  final Uint8List thumbnailData;
  final int width;
  final int height;
  final String format; // 'jpeg', 'png'

  const ThumbnailResult({
    required this.thumbnailData,
    required this.width,
    required this.height,
    required this.format,
  });
}

/// Service for handling various media formats and extracting metadata
class MediaFormatHandler {
  static final _logger = AppLogger('MediaFormatHandler');

  /// Media format mappings
  static const Map<String, MediaFormatInfo> _formatMap = {
    // Image formats
    'image/jpeg': MediaFormatInfo(
      format: MediaFormat.jpeg,
      mimeType: 'image/jpeg',
      extension: 'jpg',
      supportsMetadata: true,
      isVideo: false,
      isImage: true,
    ),
    'image/jpg': MediaFormatInfo(
      format: MediaFormat.jpeg,
      mimeType: 'image/jpeg',
      extension: 'jpg',
      supportsMetadata: true,
      isVideo: false,
      isImage: true,
    ),
    'image/png': MediaFormatInfo(
      format: MediaFormat.png,
      mimeType: 'image/png',
      extension: 'png',
      supportsMetadata: true,
      isVideo: false,
      isImage: true,
    ),
    'image/heic': MediaFormatInfo(
      format: MediaFormat.heic,
      mimeType: 'image/heic',
      extension: 'heic',
      supportsMetadata: true,
      isVideo: false,
      isImage: true,
    ),
    'image/heif': MediaFormatInfo(
      format: MediaFormat.heif,
      mimeType: 'image/heif',
      extension: 'heif',
      supportsMetadata: true,
      isVideo: false,
      isImage: true,
    ),
    'image/tiff': MediaFormatInfo(
      format: MediaFormat.tiff,
      mimeType: 'image/tiff',
      extension: 'tiff',
      supportsMetadata: true,
      isVideo: false,
      isImage: true,
    ),
    'image/webp': MediaFormatInfo(
      format: MediaFormat.webp,
      mimeType: 'image/webp',
      extension: 'webp',
      supportsMetadata: false,
      isVideo: false,
      isImage: true,
    ),
    'image/gif': MediaFormatInfo(
      format: MediaFormat.gif,
      mimeType: 'image/gif',
      extension: 'gif',
      supportsMetadata: false,
      isVideo: false,
      isImage: true,
    ),
    'image/bmp': MediaFormatInfo(
      format: MediaFormat.bmp,
      mimeType: 'image/bmp',
      extension: 'bmp',
      supportsMetadata: false,
      isVideo: false,
      isImage: true,
    ),
    // Video formats
    'video/mp4': MediaFormatInfo(
      format: MediaFormat.mp4,
      mimeType: 'video/mp4',
      extension: 'mp4',
      supportsMetadata: true,
      isVideo: true,
      isImage: false,
    ),
    'video/quicktime': MediaFormatInfo(
      format: MediaFormat.mov,
      mimeType: 'video/quicktime',
      extension: 'mov',
      supportsMetadata: true,
      isVideo: true,
      isImage: false,
    ),
    'video/avi': MediaFormatInfo(
      format: MediaFormat.avi,
      mimeType: 'video/avi',
      extension: 'avi',
      supportsMetadata: true,
      isVideo: true,
      isImage: false,
    ),
    'video/x-msvideo': MediaFormatInfo(
      format: MediaFormat.avi,
      mimeType: 'video/x-msvideo',
      extension: 'avi',
      supportsMetadata: true,
      isVideo: true,
      isImage: false,
    ),
    'video/x-matroska': MediaFormatInfo(
      format: MediaFormat.mkv,
      mimeType: 'video/x-matroska',
      extension: 'mkv',
      supportsMetadata: true,
      isVideo: true,
      isImage: false,
    ),
    'video/webm': MediaFormatInfo(
      format: MediaFormat.webm,
      mimeType: 'video/webm',
      extension: 'webm',
      supportsMetadata: true,
      isVideo: true,
      isImage: false,
    ),
  };

  /// Get media format information from MIME type
  static MediaFormatInfo getFormatInfo(String? mimeType) {
    if (mimeType == null) {
      return const MediaFormatInfo(
        format: MediaFormat.unknown,
        mimeType: 'unknown',
        extension: 'unknown',
        supportsMetadata: false,
        isVideo: false,
        isImage: false,
      );
    }

    return _formatMap[mimeType.toLowerCase()] ?? const MediaFormatInfo(
      format: MediaFormat.unknown,
      mimeType: 'unknown',
      extension: 'unknown',
      supportsMetadata: false,
      isVideo: false,
      isImage: false,
    );
  }

  /// Check if the format is supported for processing
  static bool isSupportedFormat(String? mimeType) {
    if (mimeType == null) return false;
    return _formatMap.containsKey(mimeType.toLowerCase());
  }

  /// Check if format supports metadata extraction
  static bool supportsMetadata(String? mimeType) {
    final format = getFormatInfo(mimeType);
    return format.supportsMetadata;
  }

  /// Extract metadata from image asset
  static Future<ExifData?> extractImageMetadata(AssetEntity asset) async {
    try {
      final formatInfo = getFormatInfo(asset.mimeType);

      if (!formatInfo.isImage || !formatInfo.supportsMetadata) {
        _logger.debug('Format ${asset.mimeType} does not support metadata extraction');
        return null;
      }

      final file = await asset.file;
      if (file == null) {
        _logger.warning('Could not get file for asset ${asset.id}');
        return null;
      }

      // Handle HEIC/HEIF formats differently if needed
      if (formatInfo.format == MediaFormat.heic || formatInfo.format == MediaFormat.heif) {
        return await _extractHeicMetadata(file);
      }

      // Use standard EXIF extraction for other formats
      return await ExifExtractor.extractFromFile(file.path);
    } catch (e, stack) {
      _logger.error('Failed to extract image metadata for ${asset.id}',
                   error: e, stackTrace: stack);
      return null;
    }
  }

  /// Extract metadata from video asset
  static Future<VideoMetadata?> extractVideoMetadata(AssetEntity asset) async {
    try {
      final formatInfo = getFormatInfo(asset.mimeType);

      if (!formatInfo.isVideo) {
        _logger.debug('Asset ${asset.id} is not a video format');
        return null;
      }

      final file = await asset.file;
      if (file == null) {
        _logger.warning('Could not get file for video asset ${asset.id}');
        return null;
      }

      // Extract basic video metadata from AssetEntity
      return VideoMetadata(
        width: asset.width,
        height: asset.height,
        duration: asset.videoDuration,
        creationDate: asset.createDateTime,
        rawMetadata: {
          'mimeType': asset.mimeType,
          'title': asset.title,
          'orientation': asset.orientation,
          'fileSize': await file.length(),
        },
      );

    } catch (e, stack) {
      _logger.error('Failed to extract video metadata for ${asset.id}',
                   error: e, stackTrace: stack);
      return null;
    }
  }

  /// Generate thumbnail for any media type
  static Future<ThumbnailResult?> generateThumbnail(
    AssetEntity asset, {
    int size = 200,
    int quality = 85,
  }) async {
    try {
      final thumbnailData = await asset.thumbnailDataWithSize(
        ThumbnailSize(size, size),
        quality: quality,
      );

      if (thumbnailData == null) {
        _logger.warning('Could not generate thumbnail for asset ${asset.id}');
        return null;
      }

      return ThumbnailResult(
        thumbnailData: thumbnailData,
        width: size,
        height: size,
        format: 'jpeg', // PhotoManager generates JPEG thumbnails
      );

    } catch (e, stack) {
      _logger.error('Failed to generate thumbnail for ${asset.id}',
                   error: e, stackTrace: stack);
      return null;
    }
  }

  /// Extract HEIC metadata (placeholder for future HEIC support)
  static Future<ExifData?> _extractHeicMetadata(File file) async {
    try {
      // For now, try standard extraction as the image package may support HEIC
      // In the future, this could be enhanced with dedicated HEIC libraries
      final bytes = await file.readAsBytes();
      return ExifExtractor.extractFromBytes(bytes);
    } catch (e, stack) {
      _logger.warning('HEIC metadata extraction not fully supported yet for ${file.path}',
                     error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get all supported image formats
  static List<MediaFormat> getSupportedImageFormats() {
    return _formatMap.values
        .where((format) => format.isImage)
        .map((format) => format.format)
        .toList();
  }

  /// Get all supported video formats
  static List<MediaFormat> getSupportedVideoFormats() {
    return _formatMap.values
        .where((format) => format.isVideo)
        .map((format) => format.format)
        .toList();
  }

  /// Check if asset is processable based on its format
  static bool isProcessableAsset(AssetEntity asset) {
    final formatInfo = getFormatInfo(asset.mimeType);
    return formatInfo.format != MediaFormat.unknown;
  }
}
