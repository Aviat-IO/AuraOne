// Stub implementation for APK size optimization
// Original TFLite manager temporarily disabled to reduce APK size

class TFLiteManager {
  bool get isInitialized => false;

  Future<void> initialize() async {
    // Stub - no initialization in optimized build
  }

  Future<void> loadModelFromAsset(String assetPath, {String? modelId}) async {
    // Stub - no model loading in optimized build
  }

  List<int> getInputShape(String modelId) {
    return [1, 224, 224, 3]; // Default stub shape
  }

  List<int> getOutputShape(String modelId) {
    return [1, 10]; // Default stub shape
  }

  Future<List<List<double>>> runInference(String modelId, List<List<double>> input) async {
    return [[0.0]]; // Stub result
  }

  Map<String, dynamic> getAccelerationStatus() {
    return {'enabled': false, 'type': 'none'};
  }

  void releaseModel(String modelId) {
    // Stub - no model to release
  }

  Future<void> dispose() async {
    // Stub - no cleanup needed
  }
}