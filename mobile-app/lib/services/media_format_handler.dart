import 'dart:io';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'package:exif/exif.dart' as exif_lib;
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

  /// Extract HEIC metadata using native exif package for better HEIC/HEIF support
  static Future<ExifData?> _extractHeicMetadata(File file) async {
    try {
      final bytes = await file.readAsBytes();

      // Use exif package for direct binary parsing of HEIC/HEIF files
      final exifMap = await exif_lib.readExifFromBytes(bytes);

      if (exifMap.isEmpty) {
        _logger.info('No EXIF data found in HEIC file: ${file.path}');
        return null;
      }

      // Convert exif package data to our ExifData structure
      return _convertExifMapToExifData(exifMap);

    } catch (e, stack) {
      _logger.warning('Failed to extract HEIC metadata from ${file.path}',
                     error: e, stackTrace: stack);

      // Fallback to standard extraction for compatibility
      try {
        final bytes = await file.readAsBytes();
        return ExifExtractor.extractFromBytes(bytes);
      } catch (fallbackError, fallbackStack) {
        _logger.error('Fallback HEIC metadata extraction also failed for ${file.path}',
                     error: fallbackError, stackTrace: fallbackStack);
        return null;
      }
    }
  }

  /// Convert exif package Map to our ExifData structure
  static ExifData _convertExifMapToExifData(Map<String, exif_lib.IfdTag> exifMap) {
    // Extract basic device info
    final make = _getExifStringValue(exifMap['Image Make']);
    final model = _getExifStringValue(exifMap['Image Model']);
    final software = _getExifStringValue(exifMap['Image Software']);

    // Extract timestamps
    final dateTime = _getExifStringValue(exifMap['Image DateTime']);
    final dateTimeOriginal = _getExifStringValue(exifMap['EXIF DateTimeOriginal']);
    final dateTimeDigitized = _getExifStringValue(exifMap['EXIF DateTimeDigitized']);

    // Extract image dimensions
    final imageWidth = _getExifIntValue(exifMap['EXIF ExifImageWidth']) ??
                      _getExifIntValue(exifMap['Image ImageWidth']);
    final imageHeight = _getExifIntValue(exifMap['EXIF ExifImageLength']) ??
                       _getExifIntValue(exifMap['Image ImageLength']);
    final orientation = _getExifIntValue(exifMap['Image Orientation']);

    // Extract GPS coordinates using exif package GPS data
    final gpsCoordinates = _extractGpsFromExifMap(exifMap);

    // Extract camera settings
    final cameraSettings = CameraSettings(
      aperture: _getExifRationalValue(exifMap['EXIF FNumber']),
      shutterSpeed: _getExifRationalValue(exifMap['EXIF ExposureTime']),
      iso: _getExifIntValue(exifMap['EXIF ISOSpeedRatings']),
      focalLength: _getExifRationalValue(exifMap['EXIF FocalLength']),
      flash: _getExifIntValue(exifMap['EXIF Flash']),
      exposureMode: _getExifIntValue(exifMap['EXIF ExposureMode']),
      meteringMode: _getExifIntValue(exifMap['EXIF MeteringMode']),
      whiteBalance: _getExifIntValue(exifMap['EXIF WhiteBalance']),
    );

    // Convert all EXIF data to a serializable format
    final allExifData = <String, dynamic>{};
    for (final entry in exifMap.entries) {
      try {
        allExifData[entry.key] = _convertIfdTagToValue(entry.value);
      } catch (e) {
        // Skip problematic tags but don't fail the entire extraction
        _logger.debug('Failed to convert EXIF tag ${entry.key}: $e');
      }
    }

    return ExifData(
      make: make,
      model: model,
      software: software,
      dateTime: dateTime,
      dateTimeOriginal: dateTimeOriginal,
      dateTimeDigitized: dateTimeDigitized,
      gpsCoordinates: gpsCoordinates,
      cameraSettings: cameraSettings,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      orientation: orientation,
      allExifData: allExifData,
    );
  }

  /// Extract GPS coordinates from exif package Map
  static GpsCoordinates? _extractGpsFromExifMap(Map<String, exif_lib.IfdTag> exifMap) {
    try {
      final latRef = _getExifStringValue(exifMap['GPS GPSLatitudeRef']);
      final lngRef = _getExifStringValue(exifMap['GPS GPSLongitudeRef']);
      final latData = exifMap['GPS GPSLatitude'];
      final lngData = exifMap['GPS GPSLongitude'];

      if (latData == null || lngData == null) return null;

      // Convert GPS coordinates from DMS to decimal
      final lat = _convertDmsToDecimal(latData.values, latRef);
      final lng = _convertDmsToDecimal(lngData.values, lngRef);

      if (lat == null || lng == null) return null;

      // Extract altitude if available
      double? altitude;
      final altData = exifMap['GPS GPSAltitude'];
      if (altData != null) {
        altitude = _getExifRationalValue(altData);

        // Check altitude reference (0 = above sea level, 1 = below sea level)
        final altRef = _getExifIntValue(exifMap['GPS GPSAltitudeRef']);
        if (altRef == 1 && altitude != null) {
          altitude = -altitude;
        }
      }

      return GpsCoordinates(
        latitude: lat,
        longitude: lng,
        altitude: altitude,
      );
    } catch (e) {
      _logger.debug('Failed to extract GPS coordinates from HEIC: $e');
      return null;
    }
  }

  /// Convert DMS (degrees, minutes, seconds) to decimal degrees
  static double? _convertDmsToDecimal(dynamic values, String? ref) {
    if (values is! Iterable || values.length < 3) return null;

    try {
      final valuesList = values.toList();
      final degrees = _parseRationalValue(valuesList[0]);
      final minutes = _parseRationalValue(valuesList[1]);
      final seconds = _parseRationalValue(valuesList[2]);

      if (degrees == null || minutes == null || seconds == null) return null;

      double decimal = degrees + (minutes / 60) + (seconds / 3600);

      // Apply hemisphere reference (S and W are negative)
      if (ref == 'S' || ref == 'W') {
        decimal = -decimal;
      }

      return decimal;
    } catch (e) {
      return null;
    }
  }

  /// Parse rational value (fraction) from various formats
  static double? _parseRationalValue(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    if (value is exif_lib.Ratio) {
      return value.numerator / value.denominator;
    }

    // Handle string representations like "24/1"
    if (value is String && value.contains('/')) {
      final parts = value.split('/');
      if (parts.length == 2) {
        final numerator = double.tryParse(parts[0]);
        final denominator = double.tryParse(parts[1]);
        if (numerator != null && denominator != null && denominator != 0) {
          return numerator / denominator;
        }
      }
    }

    return null;
  }

  /// Get string value from IfdTag
  static String? _getExifStringValue(exif_lib.IfdTag? tag) {
    if (tag == null) return null;

    try {
      final value = tag.printable;
      if (value.isEmpty) return null;

      // Clean up string (remove null terminators and trim)
      return value.replaceAll('\x00', '').trim();
    } catch (e) {
      return null;
    }
  }

  /// Get integer value from IfdTag
  static int? _getExifIntValue(exif_lib.IfdTag? tag) {
    if (tag == null) return null;

    try {
      final values = tag.values.toList();
      if (values.isNotEmpty) {
        final value = values.first;
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
        if (value is num) return value.round();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get rational (fraction) value from IfdTag as double
  static double? _getExifRationalValue(exif_lib.IfdTag? tag) {
    if (tag == null) return null;

    try {
      final values = tag.values.toList();
      if (values.isNotEmpty) {
        return _parseRationalValue(values.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert IfdTag to a serializable value for JSON storage
  static dynamic _convertIfdTagToValue(exif_lib.IfdTag tag) {
    try {
      final values = tag.values.toList();
      if (values.isEmpty) {
        return tag.printable;
      }

      if (values.length == 1) {
        final value = values.first;
        if (value is exif_lib.Ratio) {
          return [value.numerator, value.denominator];
        }
        return value;
      }

      // Multiple values - convert to list
      return values.map((value) {
        if (value is exif_lib.Ratio) {
          return [value.numerator, value.denominator];
        }
        return value;
      }).toList();
    } catch (e) {
      // Fallback to printable representation
      return tag.printable;
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
