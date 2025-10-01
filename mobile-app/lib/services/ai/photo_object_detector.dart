import 'dart:io';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../../utils/logger.dart';

/// Detected object information
class DetectedObjectInfo {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final int? trackingId;

  DetectedObjectInfo({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.trackingId,
  });

  @override
  String toString() => '$label (${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Service for detecting objects in photos using ML Kit
class PhotoObjectDetector {
  static final _logger = AppLogger('PhotoObjectDetector');
  static final PhotoObjectDetector _instance = PhotoObjectDetector._internal();

  factory PhotoObjectDetector() => _instance;
  PhotoObjectDetector._internal();

  ObjectDetector? _detector;
  bool _isInitialized = false;

  /// Initialize the object detector
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.debug('Object detector already initialized');
      return;
    }

    try {
      _logger.info('Initializing object detector...');

      // Configure object detector options
      final options = ObjectDetectorOptions(
        mode: DetectionMode.single, // Process one image at a time
        classifyObjects: true,       // Enable classification
        multipleObjects: true,       // Detect multiple objects
      );

      _detector = ObjectDetector(options: options);
      _isInitialized = true;

      _logger.info('Object detector initialized successfully');
    } catch (e, stack) {
      _logger.error('Failed to initialize object detector', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Detect objects in a photo
  Future<List<DetectedObjectInfo>> detectObjects(String photoPath) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_detector == null) {
      _logger.warning('Object detector not available');
      return [];
    }

    try {
      // Verify file exists
      final file = File(photoPath);
      if (!await file.exists()) {
        _logger.warning('Photo file not found: $photoPath');
        return [];
      }

      _logger.debug('Detecting objects in: $photoPath');

      // Create input image from file path
      final inputImage = InputImage.fromFilePath(photoPath);

      // Process image
      final objects = await _detector!.processImage(inputImage);

      _logger.debug('Detected ${objects.length} objects in photo');

      // Convert to our format
      final results = <DetectedObjectInfo>[];
      for (final obj in objects) {
        // Get the best label (highest confidence)
        if (obj.labels.isNotEmpty) {
          final bestLabel = obj.labels.first;
          results.add(DetectedObjectInfo(
            label: bestLabel.text,
            confidence: bestLabel.confidence,
            boundingBox: obj.boundingBox,
            trackingId: obj.trackingId,
          ));
        }
      }

      return results;
    } catch (e, stack) {
      _logger.error('Error detecting objects in photo', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Detect objects in multiple photos
  Future<Map<String, List<DetectedObjectInfo>>> detectObjectsInPhotos(
    List<String> photoPaths,
  ) async {
    final results = <String, List<DetectedObjectInfo>>{};

    for (final photoPath in photoPaths) {
      final objects = await detectObjects(photoPath);
      results[photoPath] = objects;
    }

    return results;
  }

  /// Get unique object labels from detection results
  List<String> getUniqueLabels(List<DetectedObjectInfo> objects) {
    final labels = objects.map((obj) => obj.label).toSet();
    return labels.toList()..sort();
  }

  /// Filter objects by minimum confidence threshold
  List<DetectedObjectInfo> filterByConfidence(
    List<DetectedObjectInfo> objects,
    double minConfidence,
  ) {
    return objects.where((obj) => obj.confidence >= minConfidence).toList();
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_detector != null) {
      await _detector!.close();
      _detector = null;
      _isInitialized = false;
      _logger.info('Object detector disposed');
    }
  }
}
