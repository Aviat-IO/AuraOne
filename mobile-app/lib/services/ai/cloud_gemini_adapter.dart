import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';
import '../daily_context_synthesizer.dart';
import 'ai_journal_generator.dart';

/// Tier 2 adapter using Google Gemini 2.0 Flash cloud API (BYOK - Bring Your Own Key)
///
/// Premium cloud-based AI features for users who provide their own API key.
/// Offers superior quality but requires network connectivity and user consent.
///
/// Privacy Requirements:
/// - Explicit user consent before data leaves device
/// - Clear privacy warnings about cloud usage
/// - User-provided API key from .env file
/// - Network connectivity required
///
/// Note: This is Tier 2 (BYOK) - Tier 1 is the managed service with backend proxy.
class CloudGeminiAdapter implements AIJournalGenerator {
  static final _logger = AppLogger('CloudGeminiAdapter');
  static const String _consentKey = 'cloud_ai_consent';

  static const String _adapterName = 'CloudGemini';
  static const int _tierLevel = 2; // Tier 2 for BYOK users

  GenerativeModel? _model;

  /// Determine if user should use imperial measurements based on locale
  bool _shouldUseImperialMeasurements() {
    // Get user's locale
    final locale = ui.PlatformDispatcher.instance.locale;
    final countryCode = locale.countryCode?.toUpperCase();
    
    // Countries that primarily use imperial measurements
    const imperialCountries = {
      'US', // United States
      'LR', // Liberia
      'MM', // Myanmar (Burma)
    };
    
    return countryCode != null && imperialCountries.contains(countryCode);
  }

  /// Check if user has granted consent for cloud usage
  Future<bool> hasUserConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  /// Grant user consent for cloud usage
  Future<void> grantConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
    _logger.info('User granted consent for cloud AI usage');
  }

  /// Revoke user consent for cloud usage
  Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, false);
    _logger.info('User revoked consent for cloud AI usage');
  }

  /// Get API key from .env file
  String? _getApiKey() {
    final envApiKey = dotenv.env['GEMINI_API_KEY'];
    if (envApiKey != null && envApiKey.isNotEmpty && envApiKey != 'your_gemini_api_key_here') {
      return envApiKey;
    }
    return null;
  }

  /// Initialize Gemini model if not already initialized
  bool _initializeModel() {
    if (_model != null) {
      return true;
    }

    final apiKey = _getApiKey();
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
    final apiKey = _getApiKey();
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

    if (!_initializeModel()) {
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

    if (!_initializeModel()) {
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
Describe this image objectively and factually, focusing only on what is clearly visible.
Focus on:
- What you see in the scene (objects, people, activities)
- The setting and environment
- Notable details that are clearly visible

IMPORTANT:
- DO NOT make assumptions about emotions, feelings, or mood
- DO NOT interpret intent or subjective experiences
- Only describe what is clearly visible in the image
- Keep the description conversational and under 100 words
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

    if (!_initializeModel()) {
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

    buffer.writeln('You are a skilled personal journal writer creating an entry in first person perspective.');
    buffer.writeln('Generate a natural, fluent narrative (150-200 words) describing what happened this day.');
    buffer.writeln('');
    buffer.writeln('WRITING STYLE:');
    buffer.writeln('- Write in complete, grammatically correct sentences with proper punctuation');
    buffer.writeln('- Use natural paragraph structure with smooth transitions between events');
    buffer.writeln('- Vary sentence structure - avoid repetitive patterns');
    buffer.writeln('- Present information in chronological order');
    buffer.writeln('- Focus on observable facts: activities, locations, and events');
    buffer.writeln('');
    buffer.writeln('TONE GUIDELINES:');
    buffer.writeln('- Maintain an objective, factual tone based on observable data');
    buffer.writeln('- Describe WHAT happened, WHERE it happened, and WHEN it happened');
    buffer.writeln('- Avoid assumptions about feelings or subjective experiences');
    buffer.writeln('- Do not use emotional adjectives like "amazing", "wonderful", "enjoyed"');
    buffer.writeln('');
    buffer.writeln('WHAT TO EXCLUDE (uninteresting details nobody would write):');
    buffer.writeln('- Technical photo details (shadows, angles, camera positions, lighting)');
    buffer.writeln('- Meta-observations about the photo itself ("you can see", "visible in the photo")');
    buffer.writeln('- Trivial visual artifacts (reflections, shadows on pavement, background clutter)');
    buffer.writeln('- Self-referential photo commentary ("from where I was standing", "captured in this image")');
    buffer.writeln('- Focus on the meaningful content and activities, not photographic technicalities');
    buffer.writeln('');
    buffer.writeln('WHAT TO EMPHASIZE (meaningful content people care about):');
    buffer.writeln('- Activities and experiences over static locations');
    buffer.writeln('- People and interactions over demographics and counts');
    buffer.writeln('- Memorable moments and significant events over routine transitions');
    buffer.writeln('- Context and meaning over technical details');
    buffer.writeln('- Natural flow connecting events rather than listing them');
    buffer.writeln('');
    
    // Add measurement units guidance based on user locale
    final useImperial = _shouldUseImperialMeasurements();
    if (useImperial) {
      buffer.writeln('MEASUREMENT UNITS:');
      buffer.writeln('- Convert all metric measurements to imperial units');
      buffer.writeln('- Distance: Use miles instead of kilometers (1 km ≈ 0.62 miles)');
      buffer.writeln('- Temperature: Use Fahrenheit instead of Celsius if mentioned');
      buffer.writeln('- Height/Length: Use feet/inches instead of meters/centimeters');
      buffer.writeln('- Example: "traveled 2.9 miles" instead of "covered 4.7km"');
      buffer.writeln('');
    } else {
      buffer.writeln('MEASUREMENT UNITS:');
      buffer.writeln('- Use metric measurements (kilometers, meters, Celsius)');
      buffer.writeln('- Format distances clearly: "4.7 km" or "4.7 kilometers"');
      buffer.writeln('');
    }
    
    buffer.writeln('Daily Context for ${context.date.toLocal().toString().split(' ')[0]}:');
    buffer.writeln('');

    final timeline = _formatTimelineContext(context);
    if (timeline.isNotEmpty) {
      buffer.write(timeline);
      buffer.writeln();
    }

    final places = _formatPlacesContext(context);
    if (places.isNotEmpty) {
      buffer.write(places);
      buffer.writeln();
    }

    final activities = _formatActivitiesContext(context);
    if (activities.isNotEmpty) {
      buffer.write(activities);
      buffer.writeln();
    }

    final people = _formatPeopleContext(context);
    if (people.isNotEmpty) {
      buffer.write(people);
      buffer.writeln();
    }

    if (context.photoContexts.isNotEmpty) {
      buffer.writeln('PHOTOS:');
      buffer.writeln('- ${context.photoContexts.length} photos captured');
      final objects = context.photoContexts
          .expand((p) => p.detectedObjects)
          .toSet()
          .take(5)
          .join(', ');
      if (objects.isNotEmpty) {
        buffer.writeln('- Subjects: $objects');
      }
      buffer.writeln();
    }

    buffer.writeln('');
    buffer.writeln('EXAMPLES:');
    buffer.writeln('');
    buffer.writeln('GOOD EXAMPLE (natural, human-like):');
    buffer.writeln('"Started the morning with a long walk through the park. The fall colors were');
    buffer.writeln('particularly vibrant today. Met up with a friend for coffee downtown - we caught');
    buffer.writeln('up on recent projects and made plans for the weekend. Spent the afternoon working');
    buffer.writeln('from home on the quarterly report. Ended the day with a quiet dinner and some reading."');
    buffer.writeln('');
    buffer.writeln('BAD EXAMPLE (robotic, surveillance-like - DO NOT WRITE LIKE THIS):');
    buffer.writeln('"Visited 3 locations today. Photographed a person at a park. The image shows trees');
    buffer.writeln('and you can see my shadow on the pavement. Later visited a coffee shop and took a');
    buffer.writeln('photo of a beverage. Returned to residential location at 14:30. Took 2 photos of');
    buffer.writeln('food items. Total photos: 5."');
    buffer.writeln('');
    buffer.writeln('TASK:');
    buffer.writeln('Write a cohesive first-person narrative that naturally weaves these events into a flowing story.');
    buffer.writeln('Use proper grammar, complete sentences, and smooth transitions between events.');
    buffer.writeln('Ensure the narrative reads like a well-written journal entry with appropriate measurements.');

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

  String _formatPeopleContext(DailyContext context) {
    if (context.socialSummary.totalPeopleDetected == 0) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('PEOPLE:');
    
    if (context.socialSummary.totalPeopleDetected > 0) {
      buffer.writeln('- ${context.socialSummary.totalPeopleDetected} people detected in photos');
      
      if (context.socialSummary.socialContexts.isNotEmpty) {
        final contexts = context.socialSummary.socialContexts.join(', ');
        buffer.writeln('- Social context: $contexts');
      }
    }
    
    return buffer.toString();
  }

  String _formatPlacesContext(DailyContext context) {
    if (context.locationSummary.significantPlaces.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('PLACES & LOCATIONS:');
    
    for (final place in context.locationSummary.significantPlaces.take(5)) {
      final timeSpent = context.locationSummary.placeTimeSpent[place];
      if (timeSpent != null && timeSpent.inMinutes > 15) {
        buffer.writeln('- $place (${_formatDuration(timeSpent)})');
      } else {
        buffer.writeln('- $place');
      }
    }
    
    if (context.locationSummary.totalKilometers > 0.5) {
      final useImperial = _shouldUseImperialMeasurements();
      if (useImperial) {
        final miles = context.locationSummary.totalKilometers * 0.621371;
        buffer.writeln('- Total distance: ${miles.toStringAsFixed(1)} miles');
      } else {
        buffer.writeln('- Total distance: ${context.locationSummary.totalKilometers.toStringAsFixed(1)} km');
      }
    }
    
    return buffer.toString();
  }

  String _formatActivitiesContext(DailyContext context) {
    if (context.activitySummary.primaryActivities.isEmpty &&
        context.calendarEvents.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('ACTIVITIES & EVENTS:');
    
    if (context.calendarEvents.isNotEmpty) {
      for (final event in context.calendarEvents.take(3)) {
        final time = '${event.startDate.hour}:${event.startDate.minute.toString().padLeft(2, '0')}';
        buffer.write('- $time: ${event.title}');
        if (event.location != null && event.location!.isNotEmpty) {
          buffer.write(' at ${event.location}');
        }
        buffer.writeln();
      }
    }
    
    if (context.activitySummary.primaryActivities.isNotEmpty) {
      final activities = context.activitySummary.primaryActivities.take(3).join(', ');
      buffer.writeln('- Activities: $activities');
    }
    
    return buffer.toString();
  }

  String _formatTimelineContext(DailyContext context) {
    if (context.timelineEvents.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('TIMELINE:');
    
    for (final event in context.timelineEvents.take(8)) {
      final time = '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}';
      buffer.write('- $time');
      
      if (event.placeName != null && event.placeName!.isNotEmpty) {
        buffer.write(' at ${event.placeName}');
      }
      
      if (event.description != null && event.description!.isNotEmpty) {
        buffer.write(': ${event.description}');
      }
      
      if (event.objectsSeen != null && event.objectsSeen!.isNotEmpty) {
        final objects = event.objectsSeen!.take(3).join(', ');
        buffer.write(' ($objects)');
      }
      
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes} minutes';
    }
  }
}
