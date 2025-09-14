import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Advanced photo analysis result combining all ML Kit capabilities
class AdvancedPhotoAnalysis {
  final List<String> labels;
  final List<DetectedObject> objects;
  final String? recognizedText;
  final int faceCount;
  final String sceneDescription;
  final double confidence;
  final Map<String, dynamic> metadata;

  AdvancedPhotoAnalysis({
    required this.labels,
    required this.objects,
    this.recognizedText,
    required this.faceCount,
    required this.sceneDescription,
    required this.confidence,
    required this.metadata,
  });

  /// Generate a natural language description from the analysis
  String generateDescription() {
    final buffer = StringBuffer();

    // Start with scene context
    if (metadata['isOutdoor'] == true) {
      buffer.write('An outdoor ');
    } else if (metadata['isIndoor'] == true) {
      buffer.write('An indoor ');
    } else {
      buffer.write('A ');
    }

    // Add time of day if detected
    if (metadata['isDaytime'] == true) {
      buffer.write('daytime ');
    } else if (metadata['isNighttime'] == true) {
      buffer.write('nighttime ');
    }

    // Add main subject
    if (faceCount > 0) {
      if (faceCount == 1) {
        buffer.write('portrait');
      } else if (faceCount == 2) {
        buffer.write('photo with two people');
      } else {
        buffer.write('group photo with $faceCount people');
      }
    } else if (objects.isNotEmpty) {
      // Use the most prominent object
      final mainObject = objects.first;
      buffer.write('photo featuring ${_articleFor(mainObject.labels.first.text)} ${mainObject.labels.first.text.toLowerCase()}');
    } else if (labels.isNotEmpty) {
      // Use the top labels
      final topLabels = labels.take(2).map((l) => l.toLowerCase()).toList();
      if (topLabels.length == 1) {
        buffer.write('scene with ${topLabels.first}');
      } else {
        buffer.write('scene with ${topLabels.join(' and ')}');
      }
    } else {
      buffer.write('moment');
    }

    // Add text context if present
    if (recognizedText != null && recognizedText!.isNotEmpty) {
      final textPreview = recognizedText!.length > 30
        ? '${recognizedText!.substring(0, 30)}...'
        : recognizedText!;
      buffer.write(' (text visible: "$textPreview")');
    }

    return buffer.toString();
  }

  String _articleFor(String word) {
    final vowels = ['a', 'e', 'i', 'o', 'u'];
    return vowels.contains(word.toLowerCase()[0]) ? 'an' : 'a';
  }
}

/// Advanced photo analyzer using multiple ML Kit models
class AdvancedPhotoAnalyzer {
  ImageLabeler? _imageLabeler;
  ObjectDetector? _objectDetector;
  TextRecognizer? _textRecognizer;
  FaceDetector? _faceDetector;

  bool _isInitialized = false;

  /// Initialize all ML Kit components
  Future<void> initialize() async {
    try {
      // Initialize Image Labeler with higher confidence
      _imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(
          confidenceThreshold: 0.6,
        ),
      );

      // Initialize Object Detector for multiple objects
      _objectDetector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.single,
          classifyObjects: true,
          multipleObjects: true,
        ),
      );

      // Initialize Text Recognizer
      _textRecognizer = TextRecognizer();

      // Initialize Face Detector with landmarks and contours
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableContours: false, // Keep false for performance
          enableTracking: false,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      _isInitialized = true;
      debugPrint('Advanced Photo Analyzer initialized with all ML Kit models');
    } catch (e) {
      debugPrint('Error initializing Advanced Photo Analyzer: $e');
      // Still mark as initialized to allow partial functionality
      _isInitialized = true;
    }
  }

  /// Analyze a photo using all available ML Kit models
  Future<AdvancedPhotoAnalysis?> analyzePhoto(String filePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final inputImage = InputImage.fromFile(file);

      // Run all analyses in parallel for performance
      final results = await Future.wait([
        _analyzeLabels(inputImage),
        _detectObjects(inputImage),
        _recognizeText(inputImage),
        _detectFaces(inputImage),
      ]);

      final labels = results[0] as List<String>;
      final objects = results[1] as List<DetectedObject>;
      final text = results[2] as String?;
      final faceCount = results[3] as int;

      // Analyze scene characteristics
      final metadata = _analyzeSceneMetadata(labels, objects);

      // Generate scene description
      final sceneDescription = _generateSceneDescription(
        labels: labels,
        objects: objects,
        faceCount: faceCount,
        metadata: metadata,
      );

      // Calculate overall confidence
      final confidence = _calculateConfidence(
        labels: labels,
        objects: objects,
        hasText: text != null,
        faceCount: faceCount,
      );

      return AdvancedPhotoAnalysis(
        labels: labels,
        objects: objects,
        recognizedText: text,
        faceCount: faceCount,
        sceneDescription: sceneDescription,
        confidence: confidence,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Error analyzing photo: $e');
      return null;
    }
  }

  /// Analyze image labels
  Future<List<String>> _analyzeLabels(InputImage inputImage) async {
    try {
      if (_imageLabeler == null) return [];

      final labels = await _imageLabeler!.processImage(inputImage);

      // Filter and sort by confidence
      return labels
        .where((l) => l.confidence >= 0.65)
        .map((l) => l.label)
        .toList();
    } catch (e) {
      debugPrint('Error analyzing labels: $e');
      return [];
    }
  }

  /// Detect objects in the image
  Future<List<DetectedObject>> _detectObjects(InputImage inputImage) async {
    try {
      if (_objectDetector == null) return [];

      final objects = await _objectDetector!.processImage(inputImage);

      // Sort by confidence and size
      objects.sort((a, b) {
        final aConfidence = a.labels.isNotEmpty ? a.labels.first.confidence : 0;
        final bConfidence = b.labels.isNotEmpty ? b.labels.first.confidence : 0;
        return bConfidence.compareTo(aConfidence);
      });

      return objects;
    } catch (e) {
      debugPrint('Error detecting objects: $e');
      return [];
    }
  }

  /// Recognize text in the image
  Future<String?> _recognizeText(InputImage inputImage) async {
    try {
      if (_textRecognizer == null) return null;

      final recognizedText = await _textRecognizer!.processImage(inputImage);

      if (recognizedText.text.isEmpty) return null;

      // Clean up the text
      final cleanedText = recognizedText.text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

      return cleanedText.isNotEmpty ? cleanedText : null;
    } catch (e) {
      debugPrint('Error recognizing text: $e');
      return null;
    }
  }

  /// Detect faces in the image
  Future<int> _detectFaces(InputImage inputImage) async {
    try {
      if (_faceDetector == null) return 0;

      final faces = await _faceDetector!.processImage(inputImage);
      return faces.length;
    } catch (e) {
      debugPrint('Error detecting faces: $e');
      return 0;
    }
  }

  /// Analyze scene metadata from labels and objects
  Map<String, dynamic> _analyzeSceneMetadata(
    List<String> labels,
    List<DetectedObject> objects,
  ) {
    final metadata = <String, dynamic>{};

    // Outdoor indicators
    final outdoorKeywords = [
      'sky', 'cloud', 'tree', 'grass', 'mountain', 'beach', 'ocean',
      'sunset', 'sunrise', 'landscape', 'nature', 'outdoor', 'street',
      'building', 'architecture', 'city'
    ];

    // Indoor indicators
    final indoorKeywords = [
      'room', 'indoor', 'furniture', 'wall', 'ceiling', 'floor',
      'table', 'chair', 'couch', 'bed', 'kitchen', 'office'
    ];

    // Time indicators
    final daytimeKeywords = ['sunlight', 'daylight', 'sunny', 'bright', 'blue sky'];
    final nighttimeKeywords = ['night', 'dark', 'lights', 'neon', 'stars', 'moon'];

    // Food indicators
    final foodKeywords = ['food', 'meal', 'dish', 'restaurant', 'coffee', 'drink', 'cuisine'];

    // Activity indicators
    final workKeywords = ['computer', 'desk', 'office', 'laptop', 'keyboard', 'meeting'];
    final exerciseKeywords = ['gym', 'exercise', 'sport', 'fitness', 'running'];

    // Check labels
    final lowerLabels = labels.map((l) => l.toLowerCase()).toList();

    metadata['isOutdoor'] = outdoorKeywords.any((k) => lowerLabels.any((l) => l.contains(k)));
    metadata['isIndoor'] = indoorKeywords.any((k) => lowerLabels.any((l) => l.contains(k)));
    metadata['isDaytime'] = daytimeKeywords.any((k) => lowerLabels.any((l) => l.contains(k)));
    metadata['isNighttime'] = nighttimeKeywords.any((k) => lowerLabels.any((l) => l.contains(k)));
    metadata['hasFood'] = foodKeywords.any((k) => lowerLabels.any((l) => l.contains(k)));
    metadata['isWork'] = workKeywords.any((k) => lowerLabels.any((l) => l.contains(k)));
    metadata['isExercise'] = exerciseKeywords.any((k) => lowerLabels.any((l) => l.contains(k)));

    return metadata;
  }

  /// Generate a scene description from all available data
  String _generateSceneDescription({
    required List<String> labels,
    required List<DetectedObject> objects,
    required int faceCount,
    required Map<String, dynamic> metadata,
  }) {
    final elements = <String>[];

    // Add people context
    if (faceCount > 0) {
      if (faceCount == 1) {
        elements.add('a person');
      } else if (faceCount == 2) {
        elements.add('two people');
      } else {
        elements.add('$faceCount people');
      }
    }

    // Add main objects
    if (objects.isNotEmpty) {
      final topObjects = objects
        .where((o) => o.labels.isNotEmpty)
        .take(2)
        .map((o) => o.labels.first.text.toLowerCase())
        .toList();

      if (topObjects.isNotEmpty) {
        elements.addAll(topObjects);
      }
    }

    // Add scene context
    if (metadata['isOutdoor'] == true) {
      elements.add('outdoors');
    } else if (metadata['isIndoor'] == true) {
      elements.add('indoors');
    }

    // Add activity context
    if (metadata['hasFood'] == true) {
      elements.add('food');
    }
    if (metadata['isWork'] == true) {
      elements.add('work');
    }
    if (metadata['isExercise'] == true) {
      elements.add('exercise');
    }

    // Build the description
    if (elements.isEmpty) {
      return 'a captured moment';
    } else if (elements.length == 1) {
      return elements.first;
    } else {
      return elements.join(', ');
    }
  }

  /// Calculate overall confidence score
  double _calculateConfidence({
    required List<String> labels,
    required List<DetectedObject> objects,
    required bool hasText,
    required int faceCount,
  }) {
    double confidence = 0.5; // Base confidence

    // More detected features = higher confidence
    if (labels.isNotEmpty) confidence += 0.2;
    if (objects.isNotEmpty) confidence += 0.15;
    if (hasText) confidence += 0.1;
    if (faceCount > 0) confidence += 0.15;

    // Cap at 1.0
    return confidence.clamp(0.0, 1.0);
  }

  /// Cleanup resources
  void dispose() {
    _imageLabeler?.close();
    _objectDetector?.close();
    _textRecognizer?.close();
    _faceDetector?.close();
  }
}