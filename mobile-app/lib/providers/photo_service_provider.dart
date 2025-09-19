// Stub implementation for APK size optimization
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/photo_service.dart';
import '../services/face_detector.dart';

// Photo Service Provider - with stub implementations
final photoServiceProvider = Provider<PhotoService>((ref) {
  return PhotoService();
});

// Face Detector Provider - with stub implementation
final faceDetectorProvider = Provider<FaceDetector>((ref) {
  return FaceDetector();
});