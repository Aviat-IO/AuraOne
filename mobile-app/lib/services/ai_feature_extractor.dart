import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../database/media_database.dart';
import 'ai/photo_object_detector.dart';
import 'photo_geocoder.dart';

/// Represents the context extracted from a photo using AI analysis
class PhotoContext {
  final String photoId;
  final DateTime timestamp;
  final List<String> sceneLabels;      // "outdoor", "restaurant", "nature"
  final List<String> objectLabels;     // "food", "car", "building"
  final int faceCount;                 // Number of people detected
  final List<String> textContent;     // Text found in image
  final SocialContext socialContext;
  final double confidenceScore;       // Overall confidence in analysis

  // NEW: Enhanced metadata from object detection and geocoding
  final List<String> detectedObjects;  // Specific objects from ML Kit Object Detection
  final Map<String, double> objectConfidence; // Object -> confidence score
  final double? latitude;              // GPS coordinates from EXIF
  final double? longitude;
  final String? placeName;             // Reverse-geocoded place name ("Golden Gate Park")
  final String? placeType;             // Inferred place type ("park", "restaurant", etc.)
  final String? street;                // Street address component
  final String? locality;              // City/locality component

  PhotoContext({
    required this.photoId,
    required this.timestamp,
    required this.sceneLabels,
    required this.objectLabels,
    required this.faceCount,
    required this.textContent,
    required this.socialContext,
    required this.confidenceScore,
    this.detectedObjects = const [],
    this.objectConfidence = const {},
    this.latitude,
    this.longitude,
    this.placeName,
    this.placeType,
    this.street,
    this.locality,
  });

  /// Check if photo has GPS coordinates
  bool get hasLocation => latitude != null && longitude != null;

  /// Check if photo has a place name
  bool get hasPlaceName => placeName != null && placeName!.isNotEmpty;

  /// Get location description (place name if available, otherwise coordinates)
  String get locationDescription {
    if (hasPlaceName) return placeName!;
    if (hasLocation) return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    return 'Unknown location';
  }

  /// Generate a human-readable description of what was happening in the photo
  String get activityDescription {
    final activities = <String>[];

    // Social context
    if (faceCount > 0) {
      if (faceCount == 1) {
        activities.add('Solo activity');
      } else if (faceCount <= 3) {
        activities.add('Small group activity');
      } else {
        activities.add('Group activity');
      }
    }

    // Scene context
    if (sceneLabels.contains('restaurant') || sceneLabels.contains('food')) {
      activities.add('dining/eating');
    }
    if (sceneLabels.contains('outdoor') || sceneLabels.contains('nature')) {
      activities.add('outdoor activity');
    }
    if (sceneLabels.contains('vehicle') || sceneLabels.contains('car')) {
      activities.add('transportation');
    }
    if (sceneLabels.contains('sports') || sceneLabels.contains('exercise')) {
      activities.add('physical activity');
    }
    if (sceneLabels.contains('work') || sceneLabels.contains('meeting')) {
      activities.add('work-related');
    }

    return activities.isEmpty ? 'General activity' : activities.join(', ');
  }

  /// Generate environment description
  String get environmentDescription {
    final environments = <String>[];

    for (final label in sceneLabels) {
      switch (label.toLowerCase()) {
        case 'outdoor':
        case 'nature':
        case 'park':
          environments.add('outdoors');
          break;
        case 'restaurant':
        case 'cafe':
        case 'bar':
          environments.add('dining establishment');
          break;
        case 'home':
        case 'house':
        case 'room':
          environments.add('home');
          break;
        case 'office':
        case 'workplace':
          environments.add('workplace');
          break;
        case 'vehicle':
        case 'car':
        case 'transport':
          environments.add('in transit');
          break;
      }
    }

    return environments.isEmpty ? 'indoor setting' : environments.first;
  }
}

class SocialContext {
  final int peopleCount;
  final bool isGroupPhoto;
  final bool isSelfie;

  SocialContext({
    required this.peopleCount,
    required this.isGroupPhoto,
    required this.isSelfie,
  });
}

/// On-device AI service for extracting rich context from photos
class AIFeatureExtractor {
  static final AIFeatureExtractor _instance = AIFeatureExtractor._internal();
  factory AIFeatureExtractor() => _instance;
  AIFeatureExtractor._internal();

  // ML Kit detectors - lazy initialization for performance
  late final ImageLabeler _imageLabeler;
  late final FaceDetector _faceDetector;
  late final TextRecognizer _textRecognizer;
  late final ObjectDetector _objectDetector;

  bool _initialized = false;

  /// Initialize all ML Kit detectors
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configure image labeler for scene recognition
      final imageLabelerOptions = ImageLabelerOptions(
        confidenceThreshold: 0.6, // Only confident labels
      );
      _imageLabeler = ImageLabeler(options: imageLabelerOptions);

      // Configure face detector for people counting
      final faceDetectorOptions = FaceDetectorOptions(
        enableLandmarks: false,     // Don't need facial landmarks
        enableClassification: false, // Don't need emotion classification for privacy
        enableTracking: false,      // Don't need tracking
        enableContours: false,      // Don't need contours
        minFaceSize: 0.1,          // Detect smaller faces
      );
      _faceDetector = FaceDetector(options: faceDetectorOptions);

      // Configure text recognizer
      _textRecognizer = TextRecognizer();

      // Configure object detector for activity recognition
      final objectDetectorOptions = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: objectDetectorOptions);

      _initialized = true;
      debugPrint('AIFeatureExtractor initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AIFeatureExtractor: $e');
      rethrow;
    }
  }

  /// Extract comprehensive context from a photo
  Future<PhotoContext> analyzePhoto(MediaItem mediaItem) async {
    if (!_initialized) {
      await initialize();
    }

    if (mediaItem.filePath == null) {
      throw Exception('Media item has no file path');
    }

    final file = File(mediaItem.filePath!);
    if (!await file.exists()) {
      throw Exception('Photo file does not exist: ${mediaItem.filePath}');
    }

    try {
      // Load and prepare image
      final inputImage = InputImage.fromFilePath(file.path);

      // Initialize new services
      final photoObjectDetector = PhotoObjectDetector();
      final photoGeocoder = PhotoGeocoder();

      // Run all ML analyses in parallel for performance
      final results = await Future.wait([
        _extractImageLabels(inputImage),
        _detectFaces(inputImage),
        _recognizeText(inputImage),
        _detectObjects(inputImage),
        photoObjectDetector.detectObjects(file.path),
        photoGeocoder.extractLocationData(mediaItem),
      ]);

      final imageLabels = results[0] as List<String>;
      final faces = results[1] as List<Face>;
      final textBlocks = results[2] as List<TextBlock>;
      final objects = results[3] as List<DetectedObject>;
      final detectedObjectsInfo = results[4] as List<DetectedObjectInfo>;
      final photoLocation = results[5] as PhotoLocation;

      // Process results
      final sceneLabels = imageLabels.where(_isSceneLabel).toList();
      final objectLabels = [
        ...imageLabels.where(_isObjectLabel),
        ...objects.map((obj) => obj.labels.isNotEmpty ? obj.labels.first.text : 'object')
      ].toList();

      final textContent = textBlocks.map((block) => block.text.trim()).where((text) => text.isNotEmpty).toList();

      final socialContext = SocialContext(
        peopleCount: faces.length,
        isGroupPhoto: faces.length > 1,
        isSelfie: _isSelfie(faces, inputImage),
      );

      // Extract detected objects and confidence scores
      final detectedObjects = detectedObjectsInfo.map((obj) => obj.label).toList();
      final objectConfidence = Map<String, double>.fromEntries(
        detectedObjectsInfo.map((obj) => MapEntry(obj.label, obj.confidence)),
      );

      // Calculate confidence based on number of detected features
      final confidenceScore = _calculateConfidence(imageLabels.map((label) => ImageLabel(label: label, confidence: 0.8, index: 0)).toList(), faces, textBlocks, objects);

      return PhotoContext(
        photoId: mediaItem.id,
        timestamp: mediaItem.createdDate,
        sceneLabels: sceneLabels,
        objectLabels: objectLabels,
        faceCount: faces.length,
        textContent: textContent,
        socialContext: socialContext,
        confidenceScore: confidenceScore,
        // Enhanced metadata
        detectedObjects: detectedObjects,
        objectConfidence: objectConfidence,
        latitude: photoLocation.latitude,
        longitude: photoLocation.longitude,
        placeName: photoLocation.placeName,
        placeType: photoLocation.placeType,
        street: photoLocation.street,
        locality: photoLocation.locality,
      );

    } catch (e) {
      debugPrint('Error analyzing photo ${mediaItem.id}: $e');

      // Return minimal context on error
      return PhotoContext(
        photoId: mediaItem.id,
        timestamp: mediaItem.createdDate,
        sceneLabels: [],
        objectLabels: [],
        faceCount: 0,
        textContent: [],
        socialContext: SocialContext(peopleCount: 0, isGroupPhoto: false, isSelfie: false),
        confidenceScore: 0.0,
      );
    }
  }

  /// Analyze multiple photos efficiently
  Future<List<PhotoContext>> analyzePhotos(List<MediaItem> mediaItems) async {
    const batchSize = 5; // Process in small batches to avoid memory issues
    final results = <PhotoContext>[];

    for (int i = 0; i < mediaItems.length; i += batchSize) {
      final batch = mediaItems.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((item) => analyzePhoto(item)),
      );
      results.addAll(batchResults);

      // Small delay between batches to prevent overwhelming the device
      if (i + batchSize < mediaItems.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// Extract image labels (scenes and objects)
  Future<List<String>> _extractImageLabels(InputImage inputImage) async {
    try {
      final labels = await _imageLabeler.processImage(inputImage);
      return labels.map((label) => label.label.toLowerCase()).toList();
    } catch (e) {
      debugPrint('Error extracting image labels: $e');
      return [];
    }
  }

  /// Detect faces in image
  Future<List<Face>> _detectFaces(InputImage inputImage) async {
    try {
      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      debugPrint('Error detecting faces: $e');
      return [];
    }
  }

  /// Recognize text in image
  Future<List<TextBlock>> _recognizeText(InputImage inputImage) async {
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.blocks;
    } catch (e) {
      debugPrint('Error recognizing text: $e');
      return [];
    }
  }

  /// Detect objects in image
  Future<List<DetectedObject>> _detectObjects(InputImage inputImage) async {
    try {
      return await _objectDetector.processImage(inputImage);
    } catch (e) {
      debugPrint('Error detecting objects: $e');
      return [];
    }
  }

  /// Determine if a label represents a scene/environment
  bool _isSceneLabel(String label) {
    const sceneKeywords = {
      'outdoor', 'indoor', 'restaurant', 'cafe', 'home', 'office', 'park',
      'nature', 'beach', 'mountain', 'city', 'street', 'building', 'room',
      'kitchen', 'living room', 'bedroom', 'vehicle', 'car', 'airplane',
      'train', 'sports', 'gym', 'workplace', 'school', 'hospital',
    };

    return sceneKeywords.any((keyword) => label.contains(keyword));
  }

  /// Determine if a label represents an object/activity
  bool _isObjectLabel(String label) {
    const objectKeywords = {
      'food', 'drink', 'coffee', 'meal', 'pizza', 'sandwich', 'fruit',
      'book', 'computer', 'phone', 'camera', 'bicycle', 'flower',
      'animal', 'dog', 'cat', 'bird', 'tree', 'plant', 'toy',
      'instrument', 'guitar', 'piano', 'ball', 'equipment',
    };

    return objectKeywords.any((keyword) => label.contains(keyword));
  }

  /// Determine if photo is likely a selfie based on face positions
  bool _isSelfie(List<Face> faces, InputImage inputImage) {
    if (faces.isEmpty) return false;

    // Simple heuristic: if there's one face that takes up a significant portion
    // of the image and is centered, it's likely a selfie
    if (faces.length == 1) {
      final face = faces.first;
      final imageArea = (inputImage.metadata?.size.width ?? 1) * (inputImage.metadata?.size.height ?? 1);
      final faceArea = face.boundingBox.width * face.boundingBox.height;
      final faceRatio = faceArea / imageArea;

      // If face takes up more than 15% of image, likely a selfie
      return faceRatio > 0.15;
    }

    return false;
  }

  /// Calculate confidence score based on extracted features
  double _calculateConfidence(List<ImageLabel> labels, List<Face> faces, List<TextBlock> textBlocks, List<DetectedObject> objects) {
    double confidence = 0.0;

    // More detected labels = higher confidence
    confidence += (labels.length * 0.1).clamp(0.0, 0.4);

    // Face detection adds confidence
    confidence += (faces.length * 0.15).clamp(0.0, 0.3);

    // Text detection adds confidence
    confidence += (textBlocks.length * 0.05).clamp(0.0, 0.2);

    // Object detection adds confidence
    confidence += (objects.length * 0.05).clamp(0.0, 0.1);

    return confidence.clamp(0.0, 1.0);
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (!_initialized) return;

    await Future.wait([
      _imageLabeler.close(),
      _faceDetector.close(),
      _textRecognizer.close(),
      _objectDetector.close(),
    ]);

    _initialized = false;
    debugPrint('AIFeatureExtractor disposed');
  }
}