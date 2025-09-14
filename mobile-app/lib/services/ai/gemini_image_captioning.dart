import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../../database/media_database.dart';
import '../../utils/logger.dart';

/// High-quality image captioning using Gemini
class GeminiImageCaptioning {
  static final _instance = GeminiImageCaptioning._internal();
  factory GeminiImageCaptioning() => _instance;
  GeminiImageCaptioning._internal();

  final _logger = AppLogger();
  GenerativeModel? _model;
  ImageLabeler? _imageLabeler;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize with API key
  Future<void> initialize({String? apiKey}) async {
    if (_isInitialized) return;

    try {
      // Use provided API key or try to get from environment
      final key = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY');

      if (key.isEmpty) {
        _logger.info('Gemini API key not found, falling back to ML Kit only');
        // Just initialize ML Kit as fallback
        _imageLabeler = ImageLabeler(
          options: ImageLabelerOptions(
            confidenceThreshold: 0.75,
          ),
        );
        _isInitialized = true;
        return;
      }

      // Initialize Gemini Flash model for fast, efficient captioning
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 150,
        ),
      );

      // Also initialize ML Kit for quick fallback
      _imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(
          confidenceThreshold: 0.75,
        ),
      );

      _isInitialized = true;
      _logger.info('Gemini image captioning initialized');
    } catch (e) {
      _logger.error('Failed to initialize Gemini', error: e);
      // Still mark as initialized to use fallback
      _isInitialized = true;
    }
  }

  /// Generate high-quality caption for image
  Future<PhotoDescription> generateCaption(MediaItem photo) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (photo.filePath == null) {
      return PhotoDescription(
        photoId: photo.id,
        caption: 'A photo',
        confidence: 0.0,
        timestamp: photo.createdDate,
      );
    }

    try {
      final file = File(photo.filePath!);
      if (!await file.exists()) {
        return PhotoDescription(
          photoId: photo.id,
          caption: 'A photo',
          confidence: 0.0,
          timestamp: photo.createdDate,
        );
      }

      // Try Gemini first for high-quality captions
      if (_model != null) {
        try {
          final bytes = await file.readAsBytes();
          final image = await _decodeImage(bytes);

          if (image != null) {
            final caption = await _generateGeminiCaption(image, photo);
            if (caption != null) {
              return PhotoDescription(
                photoId: photo.id,
                caption: caption,
                confidence: 0.95,
                timestamp: photo.createdDate,
                source: 'gemini',
              );
            }
          }
        } catch (e) {
          debugPrint('Gemini caption failed, falling back: $e');
        }
      }

      // Fallback to ML Kit
      return await _generateMLKitCaption(file, photo);
    } catch (e) {
      _logger.error('Error generating caption', error: e);
      return PhotoDescription(
        photoId: photo.id,
        caption: 'A captured moment',
        confidence: 0.5,
        timestamp: photo.createdDate,
      );
    }
  }

  /// Generate caption using Gemini
  Future<String?> _generateGeminiCaption(Uint8List imageBytes, MediaItem photo) async {
    if (_model == null) return null;

    try {
      final prompt = '''
You are an expert at describing photos for personal journaling.
Generate a natural, descriptive caption for this photo that captures its essence.
Focus on: the main subject, mood/atmosphere, notable details, and any text visible.
Keep it concise (max 2 sentences) and write as if describing a memory.
Make it personal and warm, not clinical.
If you see a location or landmark, mention it.
''';

      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);

      final response = await _model!.generateContent([content]);
      final caption = response.text?.trim();

      if (caption != null && caption.isNotEmpty) {
        return caption;
      }
    } catch (e) {
      debugPrint('Gemini generation error: $e');
    }

    return null;
  }

  /// Fallback ML Kit caption generation
  Future<PhotoDescription> _generateMLKitCaption(File file, MediaItem photo) async {
    try {
      if (_imageLabeler == null) {
        return PhotoDescription(
          photoId: photo.id,
          caption: 'A photo',
          confidence: 0.5,
          timestamp: photo.createdDate,
        );
      }

      final inputImage = InputImage.fromFile(file);
      final labels = await _imageLabeler!.processImage(inputImage);

      // Filter high-confidence labels
      final topLabels = labels
          .where((l) => l.confidence >= 0.75)
          .take(5)
          .map((l) => l.label.toLowerCase())
          .toList();

      if (topLabels.isEmpty) {
        return PhotoDescription(
          photoId: photo.id,
          caption: _getTimeBasedCaption(photo.createdDate),
          confidence: 0.6,
          timestamp: photo.createdDate,
          source: 'time',
        );
      }

      // Generate ML Kit-based caption
      final caption = _buildMLKitCaption(topLabels, photo.createdDate);

      return PhotoDescription(
        photoId: photo.id,
        caption: caption,
        confidence: labels.first.confidence,
        timestamp: photo.createdDate,
        labels: topLabels,
        source: 'mlkit',
      );
    } catch (e) {
      debugPrint('ML Kit caption error: $e');
      return PhotoDescription(
        photoId: photo.id,
        caption: _getTimeBasedCaption(photo.createdDate),
        confidence: 0.5,
        timestamp: photo.createdDate,
      );
    }
  }

  /// Build caption from ML Kit labels
  String _buildMLKitCaption(List<String> labels, DateTime timestamp) {
    if (labels.isEmpty) {
      return _getTimeBasedCaption(timestamp);
    }

    // Sophisticated pattern matching
    if (_containsAny(labels, ['sunset', 'sunrise', 'dawn', 'dusk'])) {
      final skyType = labels.firstWhere((l) =>
        ['sunset', 'sunrise', 'dawn', 'dusk'].contains(l));
      return "A breathtaking $skyType";
    }

    if (_containsAny(labels, ['beach', 'ocean', 'sea', 'coast'])) {
      if (_containsAny(labels, ['sunset', 'sunrise'])) {
        return "Sunset at the beach";
      }
      return "A beautiful day by the ocean";
    }

    if (_containsAny(labels, ['mountain', 'peak', 'summit'])) {
      if (_containsAny(labels, ['snow', 'winter'])) {
        return "Snow-covered mountain peaks";
      }
      return "Majestic mountain views";
    }

    if (_containsAny(labels, ['food', 'meal', 'dish', 'cuisine'])) {
      if (_containsAny(labels, ['restaurant', 'dining'])) {
        return "Dining out experience";
      }
      return "A delicious meal";
    }

    if (_containsAny(labels, ['person', 'people', 'face', 'smile'])) {
      if (_containsAny(labels, ['group', 'crowd', 'friends'])) {
        return "Good times with friends";
      }
      if (_containsAny(labels, ['smile', 'happy', 'laughing'])) {
        return "A happy moment captured";
      }
      return "A portrait moment";
    }

    if (_containsAny(labels, ['city', 'building', 'street', 'urban'])) {
      if (_containsAny(labels, ['night', 'lights'])) {
        return "City lights after dark";
      }
      return "Urban exploration";
    }

    if (_containsAny(labels, ['nature', 'forest', 'tree', 'park'])) {
      if (_containsAny(labels, ['flower', 'bloom'])) {
        return "Beautiful flowers in nature";
      }
      return "A peaceful moment in nature";
    }

    // Default to the most confident label
    return "A photo of ${labels.first}";
  }

  /// Get time-based caption as last resort
  String _getTimeBasedCaption(DateTime timestamp) {
    final hour = timestamp.hour;
    if (hour < 6 || hour > 20) {
      return "An evening capture";
    } else if (hour < 10) {
      return "A morning moment";
    } else if (hour < 14) {
      return "A midday photo";
    } else {
      return "An afternoon shot";
    }
  }

  bool _containsAny(List<String> labels, List<String> keywords) {
    return labels.any((label) => keywords.contains(label));
  }

  /// Decode image bytes
  Future<Uint8List?> _decodeImage(Uint8List bytes) async {
    try {
      // For now, just return the raw bytes
      // Could add image processing here if needed
      return bytes;
    } catch (e) {
      debugPrint('Image decode error: $e');
      return null;
    }
  }

  void dispose() {
    _imageLabeler?.close();
    _isInitialized = false;
  }
}

/// Enhanced photo description with source tracking
class PhotoDescription {
  final String photoId;
  final String caption;
  final double confidence;
  final DateTime timestamp;
  final List<String>? labels;
  final String? detectedText;
  final String? source; // 'gemini', 'mlkit', 'time'

  PhotoDescription({
    required this.photoId,
    required this.caption,
    required this.confidence,
    required this.timestamp,
    this.labels,
    this.detectedText,
    this.source,
  });
}