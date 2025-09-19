// Stub implementation for APK size optimization
// Original image captioning temporarily disabled to reduce APK size

class ImageCaptioningService {
  Future<String> generateCaption(String imagePath) async {
    return 'Image captioning temporarily disabled for optimized build';
  }

  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    return {
      'caption': 'Image analysis temporarily disabled for optimized build',
      'disabled': true,
    };
  }

  Future<String> captionImage(dynamic imageData) async {
    return 'Image captioning temporarily disabled for optimized build';
  }
}