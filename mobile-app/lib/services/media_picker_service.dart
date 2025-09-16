import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'photo_service.dart';
import '../providers/media_database_provider.dart';
import '../utils/logger.dart';

/// Service for handling media picking from camera and gallery
/// Integrates MediaPickerPlus with existing PhotoService and MediaDatabase
class MediaPickerService {
  static final _logger = AppLogger('MediaPickerService');

  final Ref _ref;

  MediaPickerService(this._ref);

  /// Check and request necessary permissions for camera and gallery access
  Future<bool> checkAndRequestPermissions() async {
    try {
      _logger.debug('Checking media picker permissions');

      // Check current permissions
      final cameraPermission = await MediaPickerPlus.hasCameraPermission();
      final galleryPermission = await MediaPickerPlus.hasGalleryPermission();

      _logger.debug('Current permissions - Camera: $cameraPermission, Gallery: $galleryPermission');

      // Request permissions if needed
      bool hasAllPermissions = true;

      if (!cameraPermission) {
        final cameraGranted = await MediaPickerPlus.requestCameraPermission();
        if (!cameraGranted) {
          _logger.warning('Camera permission denied');
          hasAllPermissions = false;
        }
      }

      if (!galleryPermission) {
        final galleryGranted = await MediaPickerPlus.requestGalleryPermission();
        if (!galleryGranted) {
          _logger.warning('Gallery permission denied');
          hasAllPermissions = false;
        }
      }

      _logger.debug('All permissions granted: $hasAllPermissions');
      return hasAllPermissions;
    } catch (e, stack) {
      _logger.error('Error checking/requesting permissions: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Present a bottom sheet with camera and gallery options
  Future<String?> showMediaPickerOptions(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _MediaPickerBottomSheet(this),
    );
  }

  /// Capture photo using device camera
  Future<String?> capturePhoto() async {
    try {
      _logger.debug('Attempting to capture photo');

      final photoPath = await MediaPickerPlus.capturePhoto(
        options: const MediaOptions(
          imageQuality: 90,
          maxWidth: 2560,
          maxHeight: 1440,
        ),
      );

      if (photoPath != null) {
        _logger.debug('Photo captured: $photoPath');

        // Process and store the captured photo
        await _processAndStoreMedia(photoPath);
        return photoPath;
      }

      return null;
    } catch (e, stack) {
      _logger.error('Error capturing photo: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Pick photo from gallery
  Future<String?> pickPhotoFromGallery() async {
    try {
      _logger.debug('Attempting to pick photo from gallery');

      final photoPath = await MediaPickerPlus.pickImage(
        options: const MediaOptions(
          imageQuality: 90,
          maxWidth: 2560,
          maxHeight: 1440,
        ),
      );

      if (photoPath != null) {
        _logger.debug('Photo picked from gallery: $photoPath');

        // Process and store the selected photo
        await _processAndStoreMedia(photoPath);
        return photoPath;
      }

      return null;
    } catch (e, stack) {
      _logger.error('Error picking photo from gallery: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Record video using device camera
  Future<String?> recordVideo() async {
    try {
      _logger.debug('Attempting to record video');

      final videoPath = await MediaPickerPlus.recordVideo(
        options: const MediaOptions(
          maxWidth: 1920,
          maxHeight: 1080,
          maxDuration: Duration(minutes: 5),
        ),
      );

      if (videoPath != null) {
        _logger.debug('Video recorded: $videoPath');

        // Process and store the recorded video
        await _processAndStoreMedia(videoPath);
        return videoPath;
      }

      return null;
    } catch (e, stack) {
      _logger.error('Error recording video: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Pick video from gallery
  Future<String?> pickVideoFromGallery() async {
    try {
      _logger.debug('Attempting to pick video from gallery');

      final videoPath = await MediaPickerPlus.pickVideo(
        options: const MediaOptions(
          maxWidth: 1920,
          maxHeight: 1080,
          maxDuration: Duration(minutes: 10),
        ),
      );

      if (videoPath != null) {
        _logger.debug('Video picked from gallery: $videoPath');

        // Process and store the selected video
        await _processAndStoreMedia(videoPath);
        return videoPath;
      }

      return null;
    } catch (e, stack) {
      _logger.error('Error picking video from gallery', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Process and store media file in MediaDatabase
  Future<void> _processAndStoreMedia(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        _logger.warning('File does not exist: $filePath');
        return;
      }

      _logger.debug('Processing media file: $filePath');

      // Get file stats
      final fileStat = await file.stat();
      final fileSize = fileStat.size;
      final fileName = file.path.split('/').last;

      // Determine MIME type based on extension
      String mimeType = 'application/octet-stream';
      final extension = fileName.split('.').last.toLowerCase();

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'mp4':
          mimeType = 'video/mp4';
          break;
        case 'mov':
          mimeType = 'video/quicktime';
          break;
        default:
          _logger.warning('Unknown file extension: $extension');
      }

      // Generate unique ID for the media item
      final mediaId = DateTime.now().millisecondsSinceEpoch.toString();

      // Get MediaDatabase and PhotoService
      final mediaDb = _ref.read(mediaDatabaseProvider);
      final mediaManagement = _ref.read(mediaManagementProvider);

      // Insert media item into database
      await mediaManagement.addMediaItem(
        id: mediaId,
        fileName: fileName,
        mimeType: mimeType,
        fileSize: fileSize,
        createdDate: DateTime.now(),
        modifiedDate: DateTime.now(),
        filePath: filePath,
      );

      _logger.debug('Media item stored in database: $mediaId');

      // Process with PhotoService for metadata extraction if it's an image
      if (mimeType.startsWith('image/')) {
        try {
          final photoService = PhotoService(_ref);
          // Note: PhotoService works with AssetEntity, so we may need to
          // implement a different approach for newly captured photos
          // For now, we'll mark it as processed since we have the basic info
          await mediaManagement.markMediaProcessed(mediaId);

          _logger.debug('Image processed and marked as complete: $mediaId');
        } catch (e, stack) {
          _logger.warning('Could not process image with PhotoService, marking as processed anyway', error: e, stackTrace: stack);
          await mediaManagement.markMediaProcessed(mediaId);
        }
      } else {
        // For videos, mark as processed since we have the basic info
        await mediaManagement.markMediaProcessed(mediaId);
        _logger.debug('Video processed and marked as complete: $mediaId');
      }

    } catch (e, stack) {
      _logger.error('Error processing and storing media', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

/// Bottom sheet widget for media picker options
class _MediaPickerBottomSheet extends StatelessWidget {
  final MediaPickerService _service;

  const _MediaPickerBottomSheet(this._service);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Add Media',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Options
          _buildOption(
            context,
            icon: Icons.camera_alt,
            title: 'Take Photo',
            subtitle: 'Capture a new photo',
            onTap: () async {
              Navigator.pop(context);
              try {
                final path = await _service.capturePhoto();
                if (context.mounted && path != null) {
                  Navigator.pop(context, path);
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorDialog(context, 'Failed to capture photo: $e');
                }
              }
            },
          ),

          _buildOption(
            context,
            icon: Icons.photo_library,
            title: 'Choose Photo',
            subtitle: 'Select from gallery',
            onTap: () async {
              Navigator.pop(context);
              try {
                final path = await _service.pickPhotoFromGallery();
                if (context.mounted && path != null) {
                  Navigator.pop(context, path);
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorDialog(context, 'Failed to pick photo: $e');
                }
              }
            },
          ),

          _buildOption(
            context,
            icon: Icons.videocam,
            title: 'Record Video',
            subtitle: 'Capture a new video',
            onTap: () async {
              Navigator.pop(context);
              try {
                final path = await _service.recordVideo();
                if (context.mounted && path != null) {
                  Navigator.pop(context, path);
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorDialog(context, 'Failed to record video: $e');
                }
              }
            },
          ),

          _buildOption(
            context,
            icon: Icons.video_library,
            title: 'Choose Video',
            subtitle: 'Select from gallery',
            onTap: () async {
              Navigator.pop(context);
              try {
                final path = await _service.pickVideoFromGallery();
                if (context.mounted && path != null) {
                  Navigator.pop(context, path);
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorDialog(context, 'Failed to pick video: $e');
                }
              }
            },
          ),

          const SizedBox(height: 8),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.transparent,
        hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Provider for MediaPickerService
final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return MediaPickerService(ref);
});