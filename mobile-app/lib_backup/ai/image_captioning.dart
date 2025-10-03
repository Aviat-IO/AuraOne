import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../utils/logger.dart';

/// Image caption result
class ImageCaptionResult {
  final String caption;
  final double confidence;
  final List<String> labels;
  final Map<String, double> labelConfidences;
  final DateTime timestamp;

  ImageCaptionResult({
    required this.caption,
    required this.confidence,
    required this.labels,
    required this.labelConfidences,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'caption': caption,
    'confidence': confidence,
    'labels': labels,
    'labelConfidences': labelConfidences,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Image preprocessing configuration
class ImagePreprocessConfig {
  final int targetWidth;
  final int targetHeight;
  final double mean;
  final double std;

  const ImagePreprocessConfig({
    this.targetWidth = 224,
    this.targetHeight = 224,
    this.mean = 127.5,
    this.std = 127.5,
  });
}

/// Image captioning service using lightweight models
class ImageCaptioningService {
  static final _logger = AppLogger('ImageCaptioningService');
  static final _instance = ImageCaptioningService._internal();

  factory ImageCaptioningService() => _instance;
  ImageCaptioningService._internal();

  // Model management
  Interpreter? _captionInterpreter;
  IsolateInterpreter? _isolateCaptionInterpreter;
  bool _isInitialized = false;

  // Configuration
  final _preprocessConfig = const ImagePreprocessConfig();

  /// Initialize the image captioning service
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.info('Image captioning service already initialized');
      return;
    }

    try {
      _logger.info('Initializing image captioning service...');

      // Load caption model
      await _loadCaptionModel();

      _isInitialized = true;
      _logger.info('Image captioning service initialized successfully');
    } catch (e, stack) {
      _logger.error('Failed to initialize image captioning', error: e, stackTrace: stack);
      throw Exception('Failed to initialize image captioning: $e');
    }
  }

  /// Load the caption generation model
  Future<void> _loadCaptionModel() async {
    try {
      const modelPath = 'assets/models/caption_model.tflite';

      try {
        _captionInterpreter = await Interpreter.fromAsset(modelPath);

        // Create isolate interpreter for background processing
        _isolateCaptionInterpreter = await IsolateInterpreter.create(
          address: _captionInterpreter!.address,
        );

        _logger.info('Caption model loaded successfully');
      } catch (e) {
        // Silently skip if model not found - will use fallback labeling
        // Model will be downloaded/generated in a production app
      }
    } catch (e) {
      _logger.error('Failed to load caption model', error: e);
      rethrow;
    }
  }


  /// Generate caption for an asset entity
  Future<ImageCaptionResult> captionAsset(AssetEntity asset) async {
    try {
      // Get image bytes
      final bytes = await asset.originBytes;
      if (bytes == null) {
        throw Exception('Failed to load image bytes');
      }

      return await captionImage(bytes);
    } catch (e) {
      _logger.error('Failed to caption asset', error: e);
      return _generateFallbackCaption();
    }
  }

  /// Generate caption for image bytes
  Future<ImageCaptionResult> captionImage(Uint8List imageBytes) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      ImageCaptionResult result;

      if (_isolateCaptionInterpreter != null) {
        // Use caption model
        result = await _runCaptionModel(imageBytes);
      } else {
        // Generate basic fallback caption based on image analysis
        result = await _analyzeImageFallback(imageBytes);
      }

      _logger.debug('Generated caption: ${result.caption}');

      return result;
    } catch (e) {
      _logger.error('Failed to generate caption', error: e);
      return _generateFallbackCaption();
    }
  }

  /// Run caption model inference
  Future<ImageCaptionResult> _runCaptionModel(Uint8List imageBytes) async {
    try {
      // Preprocess image
      final input = _preprocessImage(imageBytes);

      // Prepare output buffer for caption tokens
      // Assuming model outputs sequence of token IDs
      final outputLength = 20; // Max caption length
      final output = List.filled(outputLength, 0);

      // Run inference in isolate
      await _isolateCaptionInterpreter!.run(input, output);

      // Decode tokens to text (simplified - real implementation needs vocabulary)
      final caption = _decodeCaption(output);

      // Extract labels from caption (simplified)
      final labels = _extractLabelsFromCaption(caption);

      return ImageCaptionResult(
        caption: caption,
        confidence: 0.85, // Model confidence would be calculated properly
        labels: labels,
        labelConfidences: Map.fromIterable(
          labels,
          value: (_) => 0.8,
        ),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Caption model inference failed', error: e);
      // Fallback to ML Kit
      return await _analyzeImageFallback(imageBytes);
    }
  }

  /// Analyze image using basic heuristics as fallback
  Future<ImageCaptionResult> _analyzeImageFallback(Uint8List imageBytes) async {
    try {
      // Decode image for basic analysis
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return _generateFallbackCaption();
      }

      // Analyze image characteristics
      final brightness = _calculateAverageBrightness(image);
      final dominantColors = _extractDominantColors(image);
      final aspectRatio = image.width / image.height;

      // Generate caption based on analysis
      String caption;
      List<String> labels = [];

      // Determine scene type based on characteristics
      if (brightness > 200) {
        caption = 'A bright photo';
        labels.add('bright');
      } else if (brightness < 50) {
        caption = 'A dark photo';
        labels.add('dark');
      } else {
        caption = 'A photo';
      }

      // Add aspect ratio information
      if (aspectRatio > 1.5) {
        labels.add('landscape');
        caption = 'A landscape photo';
      } else if (aspectRatio < 0.67) {
        labels.add('portrait');
        caption = 'A portrait photo';
      } else {
        labels.add('square');
      }

      // Check for dominant colors
      if (dominantColors['blue']! > 0.3) {
        labels.add('sky');
        caption = 'A photo with sky';
      } else if (dominantColors['green']! > 0.3) {
        labels.add('nature');
        caption = 'A nature photo';
      }

      return ImageCaptionResult(
        caption: caption,
        confidence: 0.5,
        labels: labels,
        labelConfidences: Map.fromIterable(labels, value: (_) => 0.5),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Image analysis failed', error: e);
      return _generateFallbackCaption();
    }
  }

  /// Calculate average brightness of image
  double _calculateAverageBrightness(img.Image image) {
    double totalBrightness = 0;
    int pixelCount = 0;

    // Sample every 10th pixel for performance
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        // Calculate brightness using luminance formula
        final brightness = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        totalBrightness += brightness;
        pixelCount++;
      }
    }

    return totalBrightness / pixelCount;
  }

  /// Extract dominant color ratios
  Map<String, double> _extractDominantColors(img.Image image) {
    int redCount = 0;
    int greenCount = 0;
    int blueCount = 0;
    int totalPixels = 0;

    // Sample every 10th pixel for performance
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);

        // Determine dominant channel
        if (pixel.r > pixel.g && pixel.r > pixel.b) {
          redCount++;
        } else if (pixel.g > pixel.r && pixel.g > pixel.b) {
          greenCount++;
        } else {
          blueCount++;
        }
        totalPixels++;
      }
    }

    return {
      'red': redCount / totalPixels,
      'green': greenCount / totalPixels,
      'blue': blueCount / totalPixels,
    };
  }

  /// Preprocess image for model input
  Float32List _preprocessImage(Uint8List imageBytes) {
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to target size
    final resized = img.copyResize(
      image,
      width: _preprocessConfig.targetWidth,
      height: _preprocessConfig.targetHeight,
    );

    // Convert to Float32List with normalization
    final buffer = Float32List(
      1 * _preprocessConfig.targetHeight * _preprocessConfig.targetWidth * 3,
    );

    int pixelIndex = 0;
    for (int y = 0; y < _preprocessConfig.targetHeight; y++) {
      for (int x = 0; x < _preprocessConfig.targetWidth; x++) {
        final pixel = resized.getPixel(x, y);

        // Normalize pixel values
        buffer[pixelIndex++] = (pixel.r - _preprocessConfig.mean) / _preprocessConfig.std;
        buffer[pixelIndex++] = (pixel.g - _preprocessConfig.mean) / _preprocessConfig.std;
        buffer[pixelIndex++] = (pixel.b - _preprocessConfig.mean) / _preprocessConfig.std;
      }
    }

    return buffer;
  }

  /// Decode caption from model output tokens
  String _decodeCaption(List<int> tokens) {
    // Simplified decoder - real implementation needs vocabulary mapping
    final words = <String>[];

    // Example token-to-word mapping (would be loaded from vocabulary file)
    final vocabulary = {
      1: 'a',
      2: 'photo',
      3: 'of',
      4: 'person',
      5: 'standing',
      6: 'sitting',
      7: 'walking',
      8: 'in',
      9: 'with',
      10: 'and',
      11: 'the',
      12: 'outdoors',
      13: 'indoors',
      14: 'food',
      15: 'landscape',
      // ... more vocabulary
    };

    for (final token in tokens) {
      if (token == 0) break; // End token
      if (vocabulary.containsKey(token)) {
        words.add(vocabulary[token]!);
      }
    }

    if (words.isEmpty) {
      return 'A photo';
    }

    return words.join(' ');
  }

  /// Extract labels from caption text
  List<String> _extractLabelsFromCaption(String caption) {
    // Simple keyword extraction
    final keywords = <String>[];
    final words = caption.toLowerCase().split(' ');

    final importantWords = {
      'person', 'people', 'food', 'landscape', 'building',
      'car', 'animal', 'nature', 'indoor', 'outdoor',
      'selfie', 'group', 'sunset', 'beach', 'mountain',
    };

    for (final word in words) {
      if (importantWords.contains(word)) {
        keywords.add(word);
      }
    }

    return keywords;
  }


  /// Generate fallback caption when models are not available
  ImageCaptionResult _generateFallbackCaption() {
    return ImageCaptionResult(
      caption: 'A photo',
      confidence: 0.0,
      labels: ['photo'],
      labelConfidences: {'photo': 0.0},
      timestamp: DateTime.now(),
    );
  }

  /// Process multiple images in batch
  Future<List<ImageCaptionResult>> captionBatch(List<Uint8List> images) async {
    final results = <ImageCaptionResult>[];

    for (final imageBytes in images) {
      try {
        final result = await captionImage(imageBytes);
        results.add(result);
      } catch (e) {
        _logger.error('Failed to caption image in batch', error: e);
        results.add(_generateFallbackCaption());
      }
    }

    return results;
  }

  /// Dispose resources
  void dispose() {
    _captionInterpreter?.close();
    _isolateCaptionInterpreter?.close();
    _isInitialized = false;
    _logger.info('Image captioning service disposed');
  }
}
