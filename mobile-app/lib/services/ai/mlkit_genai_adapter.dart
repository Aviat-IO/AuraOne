import 'dart:io';
import 'package:flutter/services.dart';
import '../../utils/logger.dart';
import '../daily_context_synthesizer.dart';
import 'ai_journal_generator.dart';

/// Tier 1 adapter using ML Kit GenAI APIs for on-device AI
///
/// Requires:
/// - Android API 26+ (Android 8.0 Oreo)
/// - AICore support (Pixel 8+, Galaxy S24+)
/// - ML Kit GenAI features downloaded
///
/// iOS Support:
/// - Will use similar on-device AI APIs when available
/// - Currently returns unavailable on iOS
class MLKitGenAIAdapter implements AIJournalGenerator {
  static final _logger = AppLogger('MLKitGenAIAdapter');
  static const _channel = MethodChannel('com.auraone.mlkit_genai');

  bool _isInitialized = false;
  bool _isAvailable = false;

  static const String _adapterName = 'MLKitGenAI';
  static const int _tierLevel = 1;

  /// Supported tones for rewriting
  static const Set<String> _supportedTones = {
    'elaborate',
    'emojify',
    'shorten',
    'friendly',
    'professional',
    'rephrase',
  };

  /// Supported languages (ML Kit GenAI supports many languages)
  static const Set<String> _supportedLanguages = {
    'en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh',
    'nl', 'pl', 'ru', 'tr', 'vi', 'ar', 'hi', 'th', 'id',
  };

  @override
  Future<bool> checkAvailability() async {
    if (_isInitialized) {
      return _isAvailable;
    }

    try {
      // iOS not yet supported - return false
      if (Platform.isIOS) {
        _logger.info('iOS not yet supported for ML Kit GenAI');
        _isAvailable = false;
        _isInitialized = true;
        return false;
      }

      // Check if platform supports ML Kit GenAI
      final result = await _channel.invokeMethod<bool>('checkAvailability');
      _isAvailable = result ?? false;
      _isInitialized = true;

      _logger.info('ML Kit GenAI availability: $_isAvailable');
      return _isAvailable;
    } catch (e, stackTrace) {
      _logger.error('Error checking ML Kit GenAI availability', error: e, stackTrace: stackTrace);
      _isAvailable = false;
      _isInitialized = true;
      return false;
    }
  }

  @override
  AICapabilities getCapabilities() {
    return AICapabilities(
      canGenerateSummary: true,
      canDescribeImage: true,
      canRewriteText: true,
      isOnDevice: true,
      requiresNetwork: false, // Fully on-device
      supportedLanguages: _supportedLanguages,
      supportedTones: _supportedTones,
      adapterName: _adapterName,
      tierLevel: _tierLevel,
    );
  }

  @override
  Future<bool> downloadRequiredAssets({
    void Function(double progress)? onProgress,
  }) async {
    try {
      _logger.info('Requesting ML Kit GenAI feature download');

      // Set up progress listener if callback provided
      if (onProgress != null) {
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'onDownloadProgress') {
            final progress = call.arguments as double;
            onProgress(progress);
          }
        });
      }

      final result = await _channel.invokeMethod<bool>('downloadFeatures');

      // Clear method call handler
      if (onProgress != null) {
        _channel.setMethodCallHandler(null);
      }

      _logger.info('ML Kit GenAI download result: $result');
      return result ?? false;
    } catch (e, stackTrace) {
      _logger.error('Error downloading ML Kit GenAI features', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<AIGenerationResult> generateSummary(DailyContext context) async {
    if (!_isAvailable) {
      return AIGenerationResult.failure('ML Kit GenAI not available');
    }

    try {
      _logger.info('Generating summary with ML Kit GenAI');

      // Convert DailyContext to structured text for summarization
      final structuredInput = _buildStructuredInput(context);

      final result = await _channel.invokeMethod<String>(
        'generateSummary',
        {'input': structuredInput},
      );

      if (result != null && result.isNotEmpty) {
        _logger.info('Generated summary: ${result.length} characters');
        return AIGenerationResult.success(
          result,
          metadata: {
            'adapter': _adapterName,
            'tier': _tierLevel,
            'input_length': structuredInput.length,
          },
        );
      }

      return AIGenerationResult.failure('Empty response from ML Kit GenAI');
    } catch (e, stackTrace) {
      _logger.error('Error generating summary', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure('Error: $e');
    }
  }

  @override
  Future<AIGenerationResult> describeImage(String imagePath) async {
    if (!_isAvailable) {
      return AIGenerationResult.failure('ML Kit GenAI not available');
    }

    try {
      _logger.info('Describing image with ML Kit GenAI: $imagePath');

      final result = await _channel.invokeMethod<String>(
        'describeImage',
        {'imagePath': imagePath},
      );

      if (result != null && result.isNotEmpty) {
        _logger.info('Generated image description: ${result.length} characters');
        return AIGenerationResult.success(
          result,
          metadata: {
            'adapter': _adapterName,
            'tier': _tierLevel,
            'image_path': imagePath,
          },
        );
      }

      return AIGenerationResult.failure('Empty response from ML Kit GenAI');
    } catch (e, stackTrace) {
      _logger.error('Error describing image', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure('Error: $e');
    }
  }

  @override
  Future<AIGenerationResult> rewriteText(
    String text, {
    String? tone,
    String? language,
  }) async {
    if (!_isAvailable) {
      return AIGenerationResult.failure('ML Kit GenAI not available');
    }

    // Validate tone if provided
    if (tone != null && !_supportedTones.contains(tone.toLowerCase())) {
      return AIGenerationResult.failure('Unsupported tone: $tone');
    }

    // Validate language if provided
    if (language != null && !_supportedLanguages.contains(language.toLowerCase())) {
      return AIGenerationResult.failure('Unsupported language: $language');
    }

    try {
      _logger.info('Rewriting text with ML Kit GenAI (tone: $tone, language: $language)');

      final result = await _channel.invokeMethod<String>(
        'rewriteText',
        {
          'text': text,
          'tone': tone?.toLowerCase(),
          'language': language?.toLowerCase(),
        },
      );

      if (result != null && result.isNotEmpty) {
        _logger.info('Rewritten text: ${result.length} characters');
        return AIGenerationResult.success(
          result,
          metadata: {
            'adapter': _adapterName,
            'tier': _tierLevel,
            'original_length': text.length,
            'tone': tone,
            'language': language,
          },
        );
      }

      return AIGenerationResult.failure('Empty response from ML Kit GenAI');
    } catch (e, stackTrace) {
      _logger.error('Error rewriting text', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure('Error: $e');
    }
  }

  /// Build structured input from DailyContext for summarization
  String _buildStructuredInput(DailyContext context) {
    final buffer = StringBuffer();

    buffer.writeln('Daily Context for ${context.date.toLocal().toString().split(' ')[0]}:');
    buffer.writeln();

    // Timeline events
    if (context.timelineEvents.isNotEmpty) {
      buffer.writeln('Timeline Events:');
      for (final event in context.timelineEvents) {
        buffer.write('- ${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}');
        if (event.placeName != null) {
          buffer.write(' at ${event.placeName}');
        }
        if (event.description != null) {
          buffer.write(': ${event.description}');
        }
        if (event.objectsSeen != null && event.objectsSeen!.isNotEmpty) {
          buffer.write(' (${event.objectsSeen!.take(3).join(', ')})');
        }
        buffer.writeln();
      }
      buffer.writeln();
    }

    // Location summary
    if (context.locationSummary.significantPlaces.isNotEmpty) {
      buffer.writeln('Places visited:');
      for (final place in context.locationSummary.significantPlaces) {
        final timeSpent = context.locationSummary.placeTimeSpent[place];
        if (timeSpent != null) {
          buffer.writeln('- $place (${timeSpent.inMinutes} minutes)');
        } else {
          buffer.writeln('- $place');
        }
      }
      buffer.writeln();
    }

    // Activity summary
    if (context.activitySummary.primaryActivities.isNotEmpty) {
      buffer.writeln('Activities:');
      buffer.writeln('- ${context.activitySummary.primaryActivities.join(', ')}');
      buffer.writeln();
    }

    // Social summary
    if (context.socialSummary.totalPeopleDetected > 0) {
      buffer.writeln('Social:');
      buffer.writeln('- ${context.socialSummary.totalPeopleDetected} people detected');
      if (context.socialSummary.socialContexts.isNotEmpty) {
        buffer.writeln('- Context: ${context.socialSummary.socialContexts.join(', ')}');
      }
      buffer.writeln();
    }

    // Photo contexts
    if (context.photoContexts.isNotEmpty) {
      buffer.writeln('Photos:');
      buffer.writeln('- ${context.photoContexts.length} photos taken');
      final objects = context.photoContexts
          .expand((p) => p.detectedObjects)
          .toSet()
          .take(5)
          .join(', ');
      if (objects.isNotEmpty) {
        buffer.writeln('- Common subjects: $objects');
      }
      buffer.writeln();
    }

    buffer.writeln('Generate a natural, conversational 150-200 word narrative that captures the essence of this day.');

    return buffer.toString();
  }
}
