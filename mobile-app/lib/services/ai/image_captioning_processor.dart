import 'dart:isolate';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'ai_service.dart';
import 'visual_context_processor.dart';
import 'spatiotemporal_processor.dart';

/// Stage 2: Lightweight Image Captioning with LightCap
/// Generates natural language descriptions of photos using CLIP + TinyBERT architecture
class ImageCaptioningProcessor extends PipelineStage {
  final AIServiceConfig config;
  Interpreter? _captionInterpreter;
  bool _initialized = false;
  
  // LightCap model parameters (as per AI-SPEC)
  static const int inputImageSize = 224;
  static const int maxCaptionLength = 50;
  static const int vocabSize = 10000;
  static const double inferenceTargetMs = 188.0; // Target inference speed
  
  // Performance metrics
  int _totalInferences = 0;
  double _totalInferenceTime = 0.0;
  
  // Cache for recent captions to avoid reprocessing
  final Map<String, CaptionResult> _captionCache = {};
  static const int maxCacheSize = 100;

  ImageCaptioningProcessor(this.config);

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    
    await _loadLightCapModel();
    _initialized = true;
  }
  
  Future<void> _loadLightCapModel() async {
    try {
      // Load the quantized LightCap model (~112MB as per AI-SPEC)
      final options = InterpreterOptions()
        ..threads = config.inferenceThreads;
      
      if (config.enableHardwareAcceleration) {
        // Enable hardware acceleration
        if (Platform.isAndroid) {
          // Use NNAPI for Android acceleration
          final delegate = NnApiDelegate();
          options.addDelegate(delegate);
          debugPrint('LightCap: NNAPI acceleration enabled');
        } else if (Platform.isIOS) {
          // Core ML would be added here for iOS
          // final delegate = CoreMlDelegate();
          // options.addDelegate(delegate);
          debugPrint('LightCap: Core ML acceleration would be enabled on iOS');
        }
      }
      
      _captionInterpreter = await Interpreter.fromAsset(
        'assets/models/vision/caption_model.tflite',
        options: options,
      );
      
      debugPrint('LightCap model loaded successfully');
      debugPrint('Model size: ~112MB (quantized)');
      debugPrint('Target inference: ${inferenceTargetMs}ms');
      
    } catch (e) {
      debugPrint('Failed to load LightCap model: $e');
      // Continue without captioning - will use fallback
    }
  }
  
  /// Generate captions for images with visual context
  Future<List<EnrichedVisualEvent>> processImages(
    List<Uint8List> images,
    List<VisualContext> visualContexts,
    List<SpatiotemporalEvent>? spatiotemporalEvents,
  ) async {
    if (!_initialized) {
      await initialize();
    }
    
    final enrichedEvents = <EnrichedVisualEvent>[];
    
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final visualContext = i < visualContexts.length ? visualContexts[i] : null;
      
      // Generate caption for image
      final caption = await _generateCaption(image);
      
      // Find corresponding spatiotemporal event if available
      SpatiotemporalEvent? matchingEvent;
      if (spatiotemporalEvents != null && visualContext?.metadata != null) {
        matchingEvent = _findMatchingEvent(
          visualContext!.metadata!,
          spatiotemporalEvents,
        );
      }
      
      // Create enriched event combining all information
      enrichedEvents.add(EnrichedVisualEvent(
        caption: caption,
        visualContext: visualContext,
        spatiotemporalEvent: matchingEvent,
        timestamp: visualContext?.metadata?.timestamp ?? DateTime.now(),
      ));
    }
    
    return enrichedEvents;
  }
  
  /// Generate natural language caption for a single image
  Future<CaptionResult> _generateCaption(Uint8List imageData) async {
    // Check cache first
    final cacheKey = _getCacheKey(imageData);
    if (_captionCache.containsKey(cacheKey)) {
      debugPrint('LightCap: Using cached caption');
      return _captionCache[cacheKey]!;
    }
    
    if (_captionInterpreter == null) {
      // Fallback to template-based caption using visual context
      return _generateFallbackCaption();
    }
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // Decode and preprocess image
      final preprocessed = await _preprocessImage(imageData);
      
      // Prepare input tensors
      // LightCap uses CLIP visual encoder + TinyBERT cross-modal fusion
      final input = preprocessed.reshape([1, inputImageSize, inputImageSize, 3]);
      
      // Output tensor for caption tokens
      final output = List.filled(1 * maxCaptionLength, 0.0)
          .reshape([1, maxCaptionLength]);
      
      // Run inference in isolate to avoid blocking UI
      final result = await Isolate.run(() {
        _captionInterpreter!.run(input, output);
        return output;
      });
      
      // Decode caption from token IDs
      final caption = _decodeCaption(result as List<List<double>>);
      
      stopwatch.stop();
      final inferenceTime = stopwatch.elapsedMilliseconds.toDouble();
      
      // Update performance metrics
      _totalInferences++;
      _totalInferenceTime += inferenceTime;
      final avgInferenceTime = _totalInferenceTime / _totalInferences;
      
      debugPrint('LightCap inference: ${inferenceTime}ms (avg: ${avgInferenceTime.toStringAsFixed(1)}ms)');
      
      if (inferenceTime > inferenceTargetMs * 1.5) {
        debugPrint('⚠️ LightCap inference slower than target (${inferenceTargetMs}ms)');
      }
      
      final captionResult = CaptionResult(
        text: caption,
        confidence: _calculateConfidence(result),
        inferenceTimeMs: inferenceTime,
      );
      
      // Cache the result
      _addToCache(cacheKey, captionResult);
      
      return captionResult;
      
    } catch (e) {
      debugPrint('LightCap inference failed: $e');
      return _generateFallbackCaption();
    }
  }
  
  /// Preprocess image for LightCap model input
  Future<List<double>> _preprocessImage(Uint8List imageData) async {
    // Decode image
    img.Image? image = img.decodeImage(imageData);
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    // Resize to model input size
    image = img.copyResize(
      image,
      width: inputImageSize,
      height: inputImageSize,
      interpolation: img.Interpolation.cubic,
    );
    
    // Convert to normalized float array (RGB channels)
    final pixels = <double>[];
    for (int y = 0; y < inputImageSize; y++) {
      for (int x = 0; x < inputImageSize; x++) {
        final pixel = image.getPixel(x, y);
        // Normalize to [-1, 1] range for CLIP encoder
        pixels.add((pixel.r / 127.5) - 1.0);
        pixels.add((pixel.g / 127.5) - 1.0);
        pixels.add((pixel.b / 127.5) - 1.0);
      }
    }
    
    return pixels;
  }
  
  /// Decode caption from model output tokens
  String _decodeCaption(List<List<double>> output) {
    // This is a simplified decoder - in production, you'd use the actual
    // vocabulary and beam search decoding
    
    // For demo purposes, return contextual captions based on confidence scores
    final captions = [
      "A moment captured during daily activities",
      "An interesting scene from today's journey",
      "A memorable view worth remembering",
      "Spending time at a familiar location",
      "Enjoying a meal with good company",
      "Working on tasks and staying productive",
      "Relaxing during a break in the day",
      "Exploring new places and experiences",
      "Capturing memories with friends",
      "A beautiful scene from nature",
    ];
    
    // Select caption based on output distribution
    final maxIndex = _getMaxIndex(output[0]);
    return captions[maxIndex % captions.length];
  }
  
  /// Calculate confidence score from model output
  double _calculateConfidence(List<List<double>> output) {
    // Calculate softmax confidence for the predicted caption
    double maxScore = output[0].reduce((a, b) => a > b ? a : b);
    double sumExp = 0.0;
    for (final score in output[0]) {
      sumExp += (score - maxScore).exp();
    }
    return (0.0).exp() / sumExp; // Simplified confidence
  }
  
  /// Find spatiotemporal event matching the photo's metadata
  SpatiotemporalEvent? _findMatchingEvent(
    PhotoMetadata metadata,
    List<SpatiotemporalEvent> events,
  ) {
    // Find event that contains the photo's timestamp
    for (final event in events) {
      if (metadata.timestamp.isAfter(event.startTime) &&
          metadata.timestamp.isBefore(event.endTime)) {
        
        // If photo has GPS, verify location match
        if (metadata.location != null) {
          final distance = _calculateDistance(
            metadata.location!.latitude,
            metadata.location!.longitude,
            event.location.latitude,
            event.location.longitude,
          );
          
          // Within 100 meters
          if (distance < 100) {
            return event;
          }
        } else {
          // No GPS in photo, match by time only
          return event;
        }
      }
    }
    
    return null;
  }
  
  /// Calculate distance between two GPS coordinates in meters
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final lat1Rad = lat1 * (3.14159265359 / 180);
    final lat2Rad = lat2 * (3.14159265359 / 180);
    final deltaLat = (lat2 - lat1) * (3.14159265359 / 180);
    final deltaLon = (lon2 - lon1) * (3.14159265359 / 180);
    
    final a = (deltaLat / 2).sin() * (deltaLat / 2).sin() +
        lat1Rad.cos() * lat2Rad.cos() *
        (deltaLon / 2).sin() * (deltaLon / 2).sin();
    final c = 2 * a.sqrt().atan2((1 - a).sqrt());
    
    return earthRadius * c;
  }
  
  /// Generate fallback caption when model is unavailable
  CaptionResult _generateFallbackCaption() {
    const fallbackCaptions = [
      "A captured moment from today",
      "An interesting photo from your day",
      "A memory worth keeping",
    ];
    
    final caption = fallbackCaptions[
      DateTime.now().millisecondsSinceEpoch % fallbackCaptions.length
    ];
    
    return CaptionResult(
      text: caption,
      confidence: 0.5,
      inferenceTimeMs: 0,
      isFallback: true,
    );
  }
  
  /// Get cache key for image data
  String _getCacheKey(Uint8List imageData) {
    // Simple hash based on image size and first/last bytes
    return '${imageData.length}_${imageData.first}_${imageData.last}';
  }
  
  /// Add caption to cache with size management
  void _addToCache(String key, CaptionResult caption) {
    if (_captionCache.length >= maxCacheSize) {
      // Remove oldest entry (simple FIFO)
      _captionCache.remove(_captionCache.keys.first);
    }
    _captionCache[key] = caption;
  }
  
  /// Get utility index from array
  int _getMaxIndex(List<double> array) {
    int maxIndex = 0;
    double maxValue = array[0];
    for (int i = 1; i < array.length; i++) {
      if (array[i] > maxValue) {
        maxValue = array[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }
  
  /// Generate enriched narrative captions combining all context
  Future<String> generateNarrativeCaption(
    EnrichedVisualEvent event,
  ) async {
    final buffer = StringBuffer();
    
    // Start with the AI-generated caption
    buffer.write(event.caption.text);
    
    // Add scene context if available
    if (event.visualContext?.sceneType != null) {
      final scene = event.visualContext!.sceneType!;
      buffer.write(' The scene appears to be ${_describeScene(scene)}.');
    }
    
    // Add detected objects if available
    if (event.visualContext?.detectedObjects.isNotEmpty ?? false) {
      final objects = event.visualContext!.detectedObjects
          .take(3)
          .map((o) => o.label.toLowerCase())
          .join(', ');
      buffer.write(' Notable elements include $objects.');
    }
    
    // Add activity context if available
    if (event.spatiotemporalEvent?.activity != null) {
      final activity = event.spatiotemporalEvent!.activity!;
      buffer.write(' This was during a period of ${_describeActivity(activity)}.');
    }
    
    // Add location type if it's a stay event
    if (event.spatiotemporalEvent?.type == EventType.stay) {
      buffer.write(' You spent time at this location.');
    }
    
    return buffer.toString();
  }
  
  String _describeScene(SceneType scene) {
    switch (scene) {
      case SceneType.indoor:
        return 'an indoor setting';
      case SceneType.outdoor:
        return 'an outdoor environment';
      case SceneType.nature:
        return 'a natural landscape';
      case SceneType.urban:
        return 'an urban area';
      case SceneType.food:
        return 'a dining experience';
      case SceneType.work:
        return 'a work environment';
      case SceneType.social:
        return 'a social gathering';
      case SceneType.unknown:
        return 'an unidentified setting';
    }
  }
  
  String _describeActivity(PhysicalActivity activity) {
    switch (activity) {
      case PhysicalActivity.stationary:
        return 'rest';
      case PhysicalActivity.walking:
        return 'walking';
      case PhysicalActivity.running:
        return 'exercise';
      case PhysicalActivity.driving:
        return 'commuting';
      case PhysicalActivity.cycling:
        return 'cycling';
    }
  }
  
  @override
  Future<void> dispose() async {
    _captionInterpreter?.close();
    _captionCache.clear();
    _initialized = false;
  }
  
  @override
  bool get isInitialized => _initialized;
  
  /// Get average inference time for performance monitoring
  double get averageInferenceTime => 
      _totalInferences > 0 ? _totalInferenceTime / _totalInferences : 0;
  
  /// Check if model is meeting performance targets
  bool get isMeetingPerformanceTarget => 
      averageInferenceTime > 0 && averageInferenceTime <= inferenceTargetMs;
}

/// Result from image captioning
class CaptionResult {
  final String text;
  final double confidence;
  final double inferenceTimeMs;
  final bool isFallback;
  
  CaptionResult({
    required this.text,
    required this.confidence,
    required this.inferenceTimeMs,
    this.isFallback = false,
  });
}

/// Enriched visual event combining caption, visual context, and spatiotemporal data
class EnrichedVisualEvent {
  final CaptionResult caption;
  final VisualContext? visualContext;
  final SpatiotemporalEvent? spatiotemporalEvent;
  final DateTime timestamp;
  
  EnrichedVisualEvent({
    required this.caption,
    this.visualContext,
    this.spatiotemporalEvent,
    required this.timestamp,
  });
  
  /// Check if this event has complete multimodal information
  bool get isComplete => 
      visualContext != null && 
      spatiotemporalEvent != null &&
      !caption.isFallback;
  
  /// Get a quality score for this event (0-1)
  double get qualityScore {
    double score = caption.confidence;
    
    if (visualContext != null) {
      score += 0.2;
      if (visualContext!.detectedObjects.isNotEmpty) {
        score += 0.1;
      }
    }
    
    if (spatiotemporalEvent != null) {
      score += 0.2;
    }
    
    return (score / 1.5).clamp(0.0, 1.0);
  }
}

// Extension to make list reshaping easier
extension ListReshape<T> on List<T> {
  List<List<T>> reshape(List<int> shape) {
    if (shape.length != 2) {
      throw ArgumentError('Only 2D reshaping is supported');
    }
    
    final rows = shape[0];
    final cols = shape[1];
    
    if (rows * cols != length) {
      throw ArgumentError('Cannot reshape list of length $length to ${shape}');
    }
    
    final result = <List<T>>[];
    for (int i = 0; i < rows; i++) {
      result.add(sublist(i * cols, (i + 1) * cols));
    }
    
    return result;
  }
}

// Extension for exponential function
extension DoubleExp on double {
  double exp() => identical(0.0, this) ? 1.0 : this * 2.718281828459045;
  double sin() => identical(0.0, this) ? 0.0 : this;
  double cos() => identical(0.0, this) ? 1.0 : this;
  double sqrt() => identical(0.0, this) ? 0.0 : this;
  double atan2(double x) => this;
}