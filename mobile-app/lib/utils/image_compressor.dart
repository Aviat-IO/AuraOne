import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'logger.dart';

/// Image compression utility for AI API requests
///
/// Compresses images to reduce bandwidth and API costs while maintaining
/// sufficient quality for AI vision analysis.
class ImageCompressor {
  static final _logger = AppLogger('ImageCompressor');

  /// Target dimensions for compressed images (max width/height)
  /// Gemini recommends 512-1024px for good quality/cost balance
  static const int _targetDimension = 768;

  /// JPEG quality (0-100)
  /// 85% provides good quality with significant size reduction
  static const int _jpegQuality = 85;

  /// Maximum file size in bytes (500KB)
  /// Helps keep requests small and fast
  static const int _maxFileSizeBytes = 512 * 1024;

  /// Compress an image file for AI API requests
  ///
  /// Returns compressed image as Uint8List, or null if compression fails.
  /// The image is:
  /// - Resized to max 768px on longest side (maintains aspect ratio)
  /// - Compressed to JPEG with 85% quality
  /// - Target size: <500KB
  static Future<Uint8List?> compressForAI(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        _logger.error('Image file not found: $imagePath');
        return null;
      }

      final originalSize = await file.length();
      _logger.debug('Compressing image: ${path.basename(imagePath)} (${(originalSize / 1024).toStringAsFixed(1)}KB)');

      // Create temp directory for compressed image
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Compress image
      final compressedBytes = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        tempPath,
        quality: _jpegQuality,
        minWidth: _targetDimension,
        minHeight: _targetDimension,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        _logger.error('Image compression failed');
        return null;
      }

      // Read compressed file
      final compressedFile = File(compressedBytes.path);
      final bytes = await compressedFile.readAsBytes();
      final compressedSize = bytes.length;

      // Clean up temp file
      try {
        await compressedFile.delete();
      } catch (e) {
        _logger.warning('Failed to delete temp file: $e');
      }

      final compressionRatio = (1 - (compressedSize / originalSize)) * 100;
      _logger.info(
        'Compressed: ${(originalSize / 1024).toStringAsFixed(1)}KB → ${(compressedSize / 1024).toStringAsFixed(1)}KB '
        '(${compressionRatio.toStringAsFixed(1)}% reduction)',
      );

      // Warn if still too large
      if (compressedSize > _maxFileSizeBytes) {
        _logger.warning(
          'Compressed image still large: ${(compressedSize / 1024).toStringAsFixed(1)}KB '
          '(target: ${(_maxFileSizeBytes / 1024).toStringAsFixed(0)}KB)',
        );
      }

      return bytes;
    } catch (e, stackTrace) {
      _logger.error('Error compressing image', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Compress multiple images in batch
  ///
  /// Returns a map of original paths to compressed bytes.
  /// Failed compressions are omitted from the result.
  static Future<Map<String, Uint8List>> compressBatch(List<String> imagePaths) async {
    final results = <String, Uint8List>{};

    for (final imagePath in imagePaths) {
      final compressed = await compressForAI(imagePath);
      if (compressed != null) {
        results[imagePath] = compressed;
      }
    }

    _logger.info('Compressed ${results.length}/${imagePaths.length} images successfully');
    return results;
  }

  /// Convert image bytes to base64 string for API transmission
  ///
  /// This is what gets sent in the JSON request to the backend.
  static String toBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }
}
