import 'dart:async';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:photo_manager/photo_manager.dart';

/// Face detection data for a detected face
class DetectedFace {
  final Rect boundingBox;
  final double? confidence;
  final List<FaceLandmark> landmarks;
  final int? trackingId;
  final double? headEulerAngleX;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? smilingProbability;

  const DetectedFace({
    required this.boundingBox,
    this.confidence,
    required this.landmarks,
    this.trackingId,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.smilingProbability,
  });

  factory DetectedFace.fromMlKitFace(Face face) {
    return DetectedFace(
      boundingBox: face.boundingBox,
      confidence: null, // Face confidence is not available in current ML Kit version
      landmarks: face.landmarks.values.whereType<FaceLandmark>().toList(),
      trackingId: face.trackingId,
      headEulerAngleX: face.headEulerAngleX,
      headEulerAngleY: face.headEulerAngleY,
      headEulerAngleZ: face.headEulerAngleZ,
      leftEyeOpenProbability: face.leftEyeOpenProbability,
      rightEyeOpenProbability: face.rightEyeOpenProbability,
      smilingProbability: face.smilingProbability,
    );
  }

  /// Get a quality score for this face (0.0 to 1.0)
  /// Higher scores indicate better quality faces for recognition
  double get qualityScore {
    double score = 0.0;

    // Confidence contributes heavily to quality
    if (confidence != null) {
      score += confidence! * 0.4;
    } else {
      score += 0.2; // Default moderate confidence
    }

    // Face size (larger faces are generally better quality)
    final faceSize = boundingBox.width * boundingBox.height;
    final sizeScore = (faceSize / (400 * 400)).clamp(0.0, 1.0); // Normalize to 400x400 reference
    score += sizeScore * 0.3;

    // Eye openness (open eyes are better for recognition)
    double eyeScore = 0.5; // Default neutral
    if (leftEyeOpenProbability != null && rightEyeOpenProbability != null) {
      eyeScore = (leftEyeOpenProbability! + rightEyeOpenProbability!) / 2.0;
    }
    score += eyeScore * 0.2;

    // Head pose (frontal faces are better)
    double poseScore = 0.5; // Default neutral
    if (headEulerAngleX != null && headEulerAngleY != null && headEulerAngleZ != null) {
      // Calculate how close to frontal the face is (lower angles = more frontal)
      final totalAngleDeviation =
        (headEulerAngleX!.abs() + headEulerAngleY!.abs() + headEulerAngleZ!.abs()) / 3.0;
      poseScore = (1.0 - (totalAngleDeviation / 45.0)).clamp(0.0, 1.0);
    }
    score += poseScore * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Check if this is a high-quality face for recognition
  bool get isHighQuality => qualityScore >= 0.6;
}

/// Result of face detection on an image
class FaceDetectionResult {
  final List<DetectedFace> faces;
  final String assetId;
  final DateTime timestamp;
  final int imageWidth;
  final int imageHeight;

  const FaceDetectionResult({
    required this.faces,
    required this.assetId,
    required this.timestamp,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// Get only high-quality faces from the detection result
  List<DetectedFace> get highQualityFaces =>
    faces.where((face) => face.isHighQuality).toList();

  /// Get the best quality face from the detection result
  DetectedFace? get bestFace {
    if (faces.isEmpty) return null;
    return faces.reduce((a, b) => a.qualityScore > b.qualityScore ? a : b);
  }
}

/// Configuration for face detection
class FaceDetectionConfig {
  final FaceDetectorOptions options;
  final int maxImageSize;
  final double minFaceSize;
  final bool enableTracking;

  FaceDetectionConfig({
    FaceDetectorOptions? options,
    this.maxImageSize = 1024,
    this.minFaceSize = 50.0,
    this.enableTracking = false,
  }) : options = options ?? FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: false,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    );

  /// Configuration optimized for accuracy over speed
  static final FaceDetectionConfig accurate = FaceDetectionConfig(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: false,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    ),
    maxImageSize: 1536,
    minFaceSize: 40.0,
  );

  /// Configuration optimized for speed over accuracy
  static final FaceDetectionConfig fast = FaceDetectionConfig(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      enableTracking: false,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.fast,
    ),
    maxImageSize: 800,
    minFaceSize: 60.0,
  );
}

/// Service for detecting faces in photos using Google ML Kit
class FaceDetectionService {
  final FaceDetectionConfig _config;
  late final FaceDetector _detector;

  FaceDetectionService({FaceDetectionConfig? config})
    : _config = config ?? FaceDetectionConfig() {
    _detector = FaceDetector(options: _config.options);
  }

  /// Detect faces in a photo asset
  Future<FaceDetectionResult> detectFacesInAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) {
      throw Exception('Could not get file for asset ${asset.id}');
    }

    try {
      final inputImage = InputImage.fromFile(file);
      final faces = await _detector.processImage(inputImage);

      final detectedFaces = faces.map(DetectedFace.fromMlKitFace).toList();

      // Filter faces by minimum size
      final filteredFaces = detectedFaces.where((face) {
        final faceSize = (face.boundingBox.width + face.boundingBox.height) / 2;
        return faceSize >= _config.minFaceSize;
      }).toList();

      return FaceDetectionResult(
        faces: filteredFaces,
        assetId: asset.id,
        timestamp: DateTime.now(),
        imageWidth: asset.width,
        imageHeight: asset.height,
      );
    } catch (e) {
      throw Exception('Face detection failed for asset ${asset.id}: $e');
    }
  }

  /// Detect faces in multiple assets efficiently
  Future<Map<String, FaceDetectionResult>> detectFacesBatch(
    List<AssetEntity> assets, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <String, FaceDetectionResult>{};

    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      try {
        final result = await detectFacesInAsset(asset);
        if (result.faces.isNotEmpty) {
          results[asset.id] = result;
        }
        onProgress?.call(i + 1, assets.length);
      } catch (e) {
        // Log error but continue with other assets
        // Use debugPrint for development logging
        onProgress?.call(i + 1, assets.length);
      }
    }

    return results;
  }

  /// Get faces from assets that have at least one high-quality face
  Future<Map<String, FaceDetectionResult>> getAssetsWithHighQualityFaces(
    List<AssetEntity> assets, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final allResults = await detectFacesBatch(assets, onProgress: onProgress);

    return Map.fromEntries(
      allResults.entries.where(
        (entry) => entry.value.highQualityFaces.isNotEmpty,
      ),
    );
  }

  /// Process faces in the background with yield for UI responsiveness
  Stream<MapEntry<String, FaceDetectionResult>> detectFacesStream(
    List<AssetEntity> assets,
  ) async* {
    for (final asset in assets) {
      try {
        final result = await detectFacesInAsset(asset);
        if (result.faces.isNotEmpty) {
          yield MapEntry(asset.id, result);
        }
      } catch (e) {
        // Log error silently during stream processing
      }

      // Yield control to prevent blocking UI
      await Future.delayed(Duration.zero);
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _detector.close();
  }
}

/// Extension to add face detection to AssetEntity
extension AssetEntityFaceDetection on AssetEntity {
  /// Detect faces in this asset using the provided detector
  Future<FaceDetectionResult> detectFaces([FaceDetectionService? detector]) async {
    final faceDetector = detector ?? FaceDetectionService();
    final result = await faceDetector.detectFacesInAsset(this);
    if (detector == null) {
      await faceDetector.dispose(); // Only dispose if we created it
    }
    return result;
  }
}
