import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service for using Gemini Nano on-device model
/// Note: Gemini Nano requires specific device support (Pixel 8 Pro, Pixel 9, etc.)
/// This service provides a privacy-first approach with on-device processing
class GeminiNanoService {
  GenerativeModel? _model;
  bool _isAvailable = false;
  bool _isInitialized = false;

  /// Check if Gemini Nano is available on this device
  Future<bool> checkAvailability() async {
    try {
      // Check if we're on Android
      if (!Platform.isAndroid) {
        debugPrint('Gemini Nano: Not available - Android only');
        return false;
      }

      // For Gemini Nano on-device, we would need to check device capabilities
      // Currently, Gemini Nano is available on:
      // - Pixel 8 Pro
      // - Pixel 9 series
      // - Samsung Galaxy S24 series (with One UI 6.1)

      // Note: In production, you would check device model and Android version
      // For now, we'll attempt initialization and handle failures gracefully

      debugPrint('Gemini Nano: Checking device compatibility...');

      // Try to initialize with a minimal model
      // Gemini Nano doesn't require an API key as it runs on-device
      // However, the current SDK might still require one for compatibility

      // For true on-device operation, we would use Android's AICore
      // This is a placeholder that shows the intended architecture

      _isAvailable = false; // Set to false until proper on-device support
      debugPrint('Gemini Nano: On-device support pending AICore integration');

      return _isAvailable;
    } catch (e) {
      debugPrint('Gemini Nano: Not available - $e');
      return false;
    }
  }

  /// Initialize Gemini Nano if available
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isAvailable = await checkAvailability();

      if (_isAvailable) {
        // Initialize the on-device model
        // In production, this would connect to Android's AICore
        // for true on-device processing without any API keys

        debugPrint('Gemini Nano: Would initialize on-device model here');

        // Placeholder for future on-device implementation
        // _model = GenerativeModel(
        //   model: 'gemini-nano', // On-device model
        //   apiKey: 'not-needed-for-on-device', // No API key needed
        // );

        _isInitialized = true;
        debugPrint('Gemini Nano: Ready for on-device processing');
      } else {
        debugPrint('Gemini Nano: Not available on this device');
      }
    } catch (e) {
      debugPrint('Gemini Nano: Initialization failed - $e');
      _isAvailable = false;
    }
  }

  /// Generate a photo description using Gemini Nano
  Future<String?> describePhoto(String imagePath) async {
    if (!_isAvailable || _model == null) {
      return null;
    }

    try {
      final imageBytes = await File(imagePath).readAsBytes();

      // Create content with image
      final content = Content.multi([
        TextPart('Describe this photo in a natural, conversational way. Focus on: '
            '1) Main subjects and people, '
            '2) Activities or actions, '
            '3) Location or setting, '
            '4) Mood or atmosphere. '
            'Keep it under 50 words.'),
        DataPart('image/jpeg', imageBytes),
      ]);

      // Generate description
      final response = await _model!.generateContent([content]);

      if (response.text != null) {
        debugPrint('Gemini Nano: Generated description - ${response.text}');
        return response.text;
      }

      return null;
    } catch (e) {
      debugPrint('Gemini Nano: Error describing photo - $e');
      return null;
    }
  }

  /// Generate a richer daily summary using Gemini Nano
  Future<String?> generateEnhancedSummary({
    required List<String> photoDescriptions,
    required List<String> locations,
    required Map<String, dynamic> metadata,
  }) async {
    if (!_isAvailable || _model == null) {
      return null;
    }

    try {
      // Build context for Gemini
      final contextBuffer = StringBuffer();

      contextBuffer.writeln('Generate a personal daily journal entry based on:');

      if (photoDescriptions.isNotEmpty) {
        contextBuffer.writeln('\nPhotos taken:');
        for (final desc in photoDescriptions) {
          contextBuffer.writeln('- $desc');
        }
      }

      if (locations.isNotEmpty) {
        contextBuffer.writeln('\nPlaces visited:');
        for (final loc in locations) {
          contextBuffer.writeln('- $loc');
        }
      }

      if (metadata.isNotEmpty) {
        contextBuffer.writeln('\nAdditional context:');
        metadata.forEach((key, value) {
          contextBuffer.writeln('- $key: $value');
        });
      }

      contextBuffer.writeln('\nWrite a warm, personal narrative (100-150 words) that '
          'captures the essence of the day. Use first person, be conversational, '
          'and focus on emotions and experiences rather than just facts.');

      final content = Content.text(contextBuffer.toString());
      final response = await _model!.generateContent([content]);

      if (response.text != null) {
        debugPrint('Gemini Nano: Generated enhanced summary');
        return response.text;
      }

      return null;
    } catch (e) {
      debugPrint('Gemini Nano: Error generating summary - $e');
      return null;
    }
  }

  /// Check if service is available and initialized
  bool get isAvailable => _isAvailable && _isInitialized;

  /// Dispose resources
  void dispose() {
    // Clean up if needed
    _model = null;
    _isInitialized = false;
  }
}

/// Factory for creating appropriate AI service based on device capabilities
class AIServiceFactory {
  static GeminiNanoService? _geminiService;

  /// Get the best available AI service for this device
  static Future<dynamic> getBestAvailableService() async {
    // First try Gemini Nano for on-device processing
    _geminiService ??= GeminiNanoService();
    await _geminiService!.initialize();

    if (_geminiService!.isAvailable) {
      debugPrint('AIServiceFactory: Using Gemini Nano (on-device)');
      return _geminiService;
    }

    // Fallback to ML Kit based service
    debugPrint('AIServiceFactory: Using ML Kit (on-device)');
    return null; // Caller should use existing ML Kit service
  }

  /// Clean up resources
  static void dispose() {
    _geminiService?.dispose();
    _geminiService = null;
  }
}