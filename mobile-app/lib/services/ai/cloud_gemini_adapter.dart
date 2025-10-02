import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/logger.dart';
import '../daily_context_synthesizer.dart';
import 'ai_journal_generator.dart';

/// Tier 4 adapter using Google Gemini 2.5 Pro cloud API
///
/// Premium cloud-based AI features with superior quality
/// but requires network connectivity and user consent.
///
/// Privacy Requirements:
/// - Explicit user consent before data leaves device
/// - Clear privacy warnings about cloud usage
/// - API key stored securely using flutter_secure_storage
/// - Network connectivity required
class CloudGeminiAdapter implements AIJournalGenerator {
  static final _logger = AppLogger('CloudGeminiAdapter');
  static const _storage = FlutterSecureStorage();
  static const _apiKeyStorageKey = 'gemini_api_key';

  static const String _adapterName = 'CloudGemini';
  static const int _tierLevel = 4;

  GenerativeModel? _model;
  bool _userConsentGranted = false;

  /// Check if user has granted consent for cloud usage
  Future<bool> hasUserConsent() async {
    // TODO: Implement consent checking via SharedPreferences
    // This should be set by settings UI
    return _userConsentGranted;
  }

  /// Grant user consent for cloud usage
  Future<void> grantConsent() async {
    // TODO: Store consent in SharedPreferences
    _userConsentGranted = true;
    _logger.info('User granted consent for cloud AI usage');
  }

  /// Revoke user consent for cloud usage
  Future<void> revokeConsent() async {
    // TODO: Remove consent from SharedPreferences
    _userConsentGranted = false;
    _logger.info('User revoked consent for cloud AI usage');
  }

  /// Set API key for Gemini access
  Future<void> setApiKey(String apiKey) async {
    try {
      await _storage.write(key: _apiKeyStorageKey, value: apiKey);
      _model = null; // Force re-initialization
      _logger.info('API key stored securely');
    } catch (e, stackTrace) {
      _logger.error('Error storing API key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get stored API key
  Future<String?> _getApiKey() async {
    try {
      return await _storage.read(key: _apiKeyStorageKey);
    } catch (e, stackTrace) {
      _logger.error('Error reading API key', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Initialize Gemini model if not already initialized
  Future<bool> _initializeModel() async {
    if (_model != null) {
      return true;
    }

    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      _logger.warning('No API key configured');
      return false;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );
      _logger.info('Gemini model initialized successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error initializing Gemini model', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check network connectivity
  Future<bool> _hasNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('generativelanguage.googleapis.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _logger.warning('No network connectivity: $e');
      return false;
    }
  }

  @override
  Future<bool> checkAvailability() async {
    // Check user consent
    if (!await hasUserConsent()) {
      _logger.info('Cloud adapter unavailable: user consent not granted');
      return false;
    }

    // Check API key
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      _logger.info('Cloud adapter unavailable: no API key');
      return false;
    }

    // Check network connectivity
    if (!await _hasNetworkConnectivity()) {
      _logger.info('Cloud adapter unavailable: no network connectivity');
      return false;
    }

    return true;
  }

  @override
  AICapabilities getCapabilities() {
    return AICapabilities(
      canGenerateSummary: true,
      canDescribeImage: true,
      canRewriteText: true,
      isOnDevice: false,
      requiresNetwork: true,
      supportedLanguages: {
        'en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh',
        'nl', 'pl', 'ru', 'tr', 'vi', 'ar', 'hi', 'th', 'id',
        // Gemini supports 100+ languages
      },
      supportedTones: {
        'friendly',
        'professional',
        'elaborate',
        'concise',
        'casual',
        'formal',
        'empathetic',
        'enthusiastic',
      },
      adapterName: _adapterName,
      tierLevel: _tierLevel,
    );
  }

  @override
  Future<bool> downloadRequiredAssets({
    void Function(double progress)? onProgress,
  }) async {
    // Cloud adapter has no assets to download
    // Model runs on Google's servers
    return true;
  }

  @override
  Future<AIGenerationResult> generateSummary(DailyContext context) async {
    if (!await checkAvailability()) {
      return AIGenerationResult.failure('Cloud adapter not available');
    }

    if (!await _initializeModel()) {
      return AIGenerationResult.failure('Failed to initialize Gemini model');
    }

    try {
      _logger.info('Generating cloud-based narrative summary');

      final prompt = _buildNarrativePrompt(context);

      final response = await _model!.generateContent([Content.text(prompt)]);
      final narrative = response.text;

      if (narrative == null || narrative.isEmpty) {
        return AIGenerationResult.failure('Empty response from Gemini API');
      }

      _logger.info('Generated narrative: ${narrative.split(' ').length} words');

      return AIGenerationResult.success(
        narrative,
        metadata: {
          'adapter': _adapterName,
          'tier': _tierLevel,
          'model': 'gemini-2.0-flash-exp',
          'word_count': narrative.split(' ').length,
          'event_count': context.timelineEvents.length,
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error generating narrative', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure('Gemini API error: $e');
    }
  }

  @override
  Future<AIGenerationResult> describeImage(String imagePath) async {
    if (!await checkAvailability()) {
      return AIGenerationResult.failure('Cloud adapter not available');
    }

    if (!await _initializeModel()) {
      return AIGenerationResult.failure('Failed to initialize Gemini model');
    }

    try {
      _logger.info('Describing image using Gemini multimodal: $imagePath');

      // Read image file
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return AIGenerationResult.failure('Image file not found: $imagePath');
      }

      final imageBytes = await imageFile.readAsBytes();

      // Create multimodal prompt
      final prompt = '''
Describe this image in natural, engaging language as if you're recalling a memory.
Focus on:
- What you see in the scene
- The mood and atmosphere
- Notable objects, people, or activities
- The setting and environment

Keep the description conversational and under 100 words.
''';

      final response = await _model!.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      final description = response.text;

      if (description == null || description.isEmpty) {
        return AIGenerationResult.failure('Empty response from Gemini API');
      }

      _logger.info('Generated image description: ${description.length} characters');

      return AIGenerationResult.success(
        description,
        metadata: {
          'adapter': _adapterName,
          'tier': _tierLevel,
          'model': 'gemini-2.0-flash-exp',
          'image_path': imagePath,
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error describing image', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure('Gemini API error: $e');
    }
  }

  @override
  Future<AIGenerationResult> rewriteText(
    String text, {
    String? tone,
    String? language,
  }) async {
    if (!await checkAvailability()) {
      return AIGenerationResult.failure('Cloud adapter not available');
    }

    if (!await _initializeModel()) {
      return AIGenerationResult.failure('Failed to initialize Gemini model');
    }

    try {
      _logger.info('Rewriting text with tone: $tone, language: $language');

      final prompt = _buildRewritePrompt(text, tone, language);

      final response = await _model!.generateContent([Content.text(prompt)]);
      final rewritten = response.text;

      if (rewritten == null || rewritten.isEmpty) {
        return AIGenerationResult.failure('Empty response from Gemini API');
      }

      _logger.info('Rewritten text: ${rewritten.length} characters');

      return AIGenerationResult.success(
        rewritten,
        metadata: {
          'adapter': _adapterName,
          'tier': _tierLevel,
          'model': 'gemini-2.0-flash-exp',
          'tone': tone,
          'language': language,
          'original_length': text.length,
          'rewritten_length': rewritten.length,
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error rewriting text', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure('Gemini API error: $e');
    }
  }

  /// Build prompt for narrative generation
  String _buildNarrativePrompt(DailyContext context) {
    final buffer = StringBuffer();

    buffer.writeln('You are writing a personal journal entry in first person.');
    buffer.writeln('Generate a natural, conversational 150-200 word narrative that captures the essence of this day.');
    buffer.writeln('');
    buffer.writeln('Daily Context for ${context.date.toLocal().toString().split(' ')[0]}:');
    buffer.writeln('');

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

    buffer.writeln('Write a reflective, engaging narrative in first person that weaves these elements together.');

    return buffer.toString();
  }

  /// Build prompt for text rewriting
  String _buildRewritePrompt(String text, String? tone, String? language) {
    final buffer = StringBuffer();

    buffer.writeln('Rewrite the following text');

    if (tone != null && tone.isNotEmpty) {
      buffer.writeln('with a $tone tone');
    }

    if (language != null && language.isNotEmpty && language != 'en') {
      buffer.writeln('in $language language');
    } else {
      buffer.writeln('in English');
    }

    buffer.writeln('');
    buffer.writeln('Original text:');
    buffer.writeln(text);
    buffer.writeln('');
    buffer.writeln('Rewritten version:');

    return buffer.toString();
  }
}
