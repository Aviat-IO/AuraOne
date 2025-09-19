// Stub types for APK size optimization
// Original face detection types temporarily disabled to reduce APK size

class FaceDetectionResult {
  final List<DetectedFace> faces;
  final String photoId;
  final List<DetectedFace> highQualityFaces;

  FaceDetectionResult({
    required this.faces,
    required this.photoId,
  }) : highQualityFaces = faces;
}

class FaceDetectionConfig {
  final double confidence;
  final bool enableLandmarks;

  FaceDetectionConfig({
    this.confidence = 0.5,
    this.enableLandmarks = false,
  });
}

class DetectedFace {
  final String faceId;
  final double confidence;
  final List<FaceLandmark> landmarks;
  final Rect boundingBox;
  final double? headEulerAngleX;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? smilingProbability;
  final double qualityScore;

  DetectedFace({
    required this.faceId,
    required this.confidence,
    required this.landmarks,
    required this.boundingBox,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.smilingProbability,
    required this.qualityScore,
  });
}

class Rect {
  final double left;
  final double top;
  final double width;
  final double height;

  Rect(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;

  static Rect fromLTRB(double left, double top, double right, double bottom) {
    return Rect(left, top, right - left, bottom - top);
  }
}

class FaceLandmark {
  final FaceLandmarkType type;
  final Point position;

  FaceLandmark({
    required this.type,
    required this.position,
  });
}

enum FaceLandmarkType {
  leftEye,
  rightEye,
  noseBase,
  bottomMouth,
  leftCheek,
  rightCheek,
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}

class FaceDetectionService {
  FaceDetectionService({FaceDetectionConfig? config});

  Future<FaceDetectionResult> detectFaces(String imagePath) async {
    return FaceDetectionResult(
      faces: [],
      photoId: imagePath,
    );
  }

  Future<FaceDetectionResult> detectFacesInAsset(dynamic asset) async {
    return FaceDetectionResult(
      faces: [],
      photoId: 'asset',
    );
  }

  Future<Map<String, FaceDetectionResult>> detectFacesBatch(
    List<dynamic> assets, {
    FaceDetectionConfig? config,
  }) async {
    return {};
  }

  Stream<MapEntry<String, FaceDetectionResult>> detectFacesStream(
    List<dynamic> assets,
  ) async* {
    // Empty stream
  }

  Future<void> dispose() async {
    // Stub - no cleanup needed
  }

  Future<String> captionImage(dynamic imageData) async {
    return 'Image captioning temporarily disabled for optimized build';
  }
}