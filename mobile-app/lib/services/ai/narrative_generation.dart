import 'dart:convert';
import 'dart:typed_data';
// import 'package:tflite_flutter/tflite_flutter.dart'; // Temporarily disabled for APK size optimization
import '../../utils/logger.dart';
import 'multimodal_fusion.dart';
import '../narrative_template_engine.dart';
import '../daily_context_synthesizer.dart';

// Stub types for TFLite functionality
class Interpreter {
  final String address = 'stub_address';

  static Future<Interpreter> fromAsset(String assetPath) async {
    return Interpreter();
  }

  void run(dynamic input, dynamic output) {
    // Stub - no actual inference
  }

  void close() {
    // Stub - no cleanup needed
  }

  void dispose() {}
}

class IsolateInterpreter {
  static Future<IsolateInterpreter> create({required String address}) async {
    return IsolateInterpreter();
  }

  Future<void> run(dynamic input, dynamic output) async {
    // Stub - no actual inference
  }

  void close() {
    // Stub - no cleanup needed
  }

  void dispose() {}
}

/// Narrative style options
enum NarrativeStyle {
  professional,
  casual,
  reflective,
  detailed,
  brief,
  poetic,
}

/// Generated narrative result
class NarrativeResult {
  final String narrative;
  final String summary;
  final NarrativeStyle style;
  final double confidence;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  NarrativeResult({
    required this.narrative,
    required this.summary,
    required this.style,
    required this.confidence,
    required this.generatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'narrative': narrative,
    'summary': summary,
    'style': style.name,
    'confidence': confidence,
    'generatedAt': generatedAt.toIso8601String(),
    'metadata': metadata,
  };
}

/// Prompt template for narrative generation
class PromptTemplate {
  final String template;
  final NarrativeStyle style;
  final Map<String, String> placeholders;

  const PromptTemplate({
    required this.template,
    required this.style,
    this.placeholders = const {},
  });

  String format(Map<String, dynamic> context) {
    var result = template;

    // Replace placeholders with context values
    context.forEach((key, value) {
      final placeholder = '{$key}';
      if (result.contains(placeholder)) {
        final valueStr = value is String ? value : jsonEncode(value);
        result = result.replaceAll(placeholder, valueStr);
      }
    });

    return result;
  }
}

/// Narrative generation service using Small Language Models
class NarrativeGenerationService {
  static final _logger = AppLogger('NarrativeGenerationService');
  static final _instance = NarrativeGenerationService._internal();

  factory NarrativeGenerationService() => _instance;
  NarrativeGenerationService._internal();

  // Model management
  Interpreter? _slmInterpreter;
  IsolateInterpreter? _isolateSlmInterpreter;
  bool _isInitialized = false;

  // Token vocabulary (simplified - would be loaded from file)
  Map<String, int> _vocabulary = {};
  Map<int, String> _reverseVocabulary = {};

  // Prompt templates for different styles
  final Map<NarrativeStyle, PromptTemplate> _templates = {
    NarrativeStyle.professional: const PromptTemplate(
      template: '''Based on the following events, write a professional daily summary:
{events}

Professional Summary:''',
      style: NarrativeStyle.professional,
    ),
    NarrativeStyle.casual: const PromptTemplate(
      template: '''Here's what happened today:
{events}

Casual recap:''',
      style: NarrativeStyle.casual,
    ),
    NarrativeStyle.reflective: const PromptTemplate(
      template: '''Reflecting on today's experiences:
{events}

Thoughtful reflection:''',
      style: NarrativeStyle.reflective,
    ),
    NarrativeStyle.detailed: const PromptTemplate(
      template: '''Comprehensive account of the day:
{events}

Detailed narrative:''',
      style: NarrativeStyle.detailed,
    ),
    NarrativeStyle.brief: const PromptTemplate(
      template: '''Quick summary of today:
{events}

Brief overview:''',
      style: NarrativeStyle.brief,
    ),
    NarrativeStyle.poetic: const PromptTemplate(
      template: '''Today's journey in verse:
{events}

Poetic interpretation:''',
      style: NarrativeStyle.poetic,
    ),
  };

  /// Initialize the narrative generation service
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.info('Narrative generation service already initialized');
      return;
    }

    try {
      _logger.info('Initializing narrative generation service...');

      // Load SLM model
      await _loadSLMModel();

      // Load vocabulary
      await _loadVocabulary();

      _isInitialized = true;
      _logger.info('Narrative generation service initialized successfully');
    } catch (e, stack) {
      _logger.error('Failed to initialize narrative generation', error: e, stackTrace: stack);
      throw Exception('Failed to initialize narrative generation: $e');
    }
  }

  /// Load the Small Language Model
  Future<void> _loadSLMModel() async {
    try {
      // Try different model paths
      const modelPaths = [
        'assets/models/tinyllama.tflite',
        'assets/models/phi3_mini.tflite',
        'assets/models/gemma_2b.tflite',
        'assets/models/slm_model.tflite',
      ];

      bool modelLoaded = false;

      for (final modelPath in modelPaths) {
        try {
          _slmInterpreter = await Interpreter.fromAsset(modelPath);

          // Create isolate interpreter for background processing
          _isolateSlmInterpreter = await IsolateInterpreter.create(
            address: _slmInterpreter!.address,
          );

          _logger.info('SLM model loaded successfully from $modelPath');
          modelLoaded = true;
          break;
        } catch (e) {
          _logger.debug('Model not found at $modelPath');
        }
      }

      if (!modelLoaded) {
        _logger.warning('No SLM model found, using fallback generation');
      }
    } catch (e) {
      _logger.error('Failed to load SLM model', error: e);
      rethrow;
    }
  }

  /// Load vocabulary for tokenization
  Future<void> _loadVocabulary() async {
    try {
      // In production, this would load from a vocabulary file
      // For now, create a simple vocabulary
      _vocabulary = _createSimpleVocabulary();
      _reverseVocabulary = Map.fromEntries(
        _vocabulary.entries.map((e) => MapEntry(e.value, e.key)),
      );

      _logger.info('Vocabulary loaded with ${_vocabulary.length} tokens');
    } catch (e) {
      _logger.error('Failed to load vocabulary', error: e);
    }
  }

  /// Create a simple vocabulary for demonstration
  Map<String, int> _createSimpleVocabulary() {
    final words = [
      // Special tokens
      '<PAD>', '<START>', '<END>', '<UNK>',
      // Common words
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were',
      // Time words
      'morning', 'afternoon', 'evening', 'night', 'today', 'day',
      'hour', 'minute', 'time', 'early', 'late',
      // Activity words
      'went', 'visited', 'stayed', 'traveled', 'walked', 'drove', 'stopped',
      'spent', 'enjoyed', 'experienced', 'completed', 'started', 'finished',
      // Location words
      'home', 'work', 'office', 'place', 'location', 'area', 'city',
      // Emotion words
      'productive', 'relaxing', 'busy', 'quiet', 'active', 'peaceful',
      // Common nouns
      'photo', 'photos', 'activity', 'activities', 'event', 'events',
      'journey', 'trip', 'meeting', 'meal', 'exercise', 'rest',
    ];

    final vocabulary = <String, int>{};
    for (int i = 0; i < words.length; i++) {
      vocabulary[words[i]] = i;
    }

    return vocabulary;
  }

  /// Generate narrative from daily events
  Future<NarrativeResult> generateNarrative({
    required List<DailyEvent> events,
    NarrativeStyle style = NarrativeStyle.casual,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Generate structured context
      final fusionService = MultiModalFusionService();
      final context = fusionService.generateStructuredContext(events);

      // Add additional context if provided
      if (additionalContext != null) {
        context.addAll(additionalContext);
      }

      // Generate narrative
      NarrativeResult result;

      if (_isolateSlmInterpreter != null) {
        // Use SLM model
        result = await _generateWithSLM(context, style);
      } else {
        // Use fallback template-based generation
        result = _generateWithTemplates(context, style);
      }

      _logger.info('Generated narrative with style: ${style.name}');

      return result;
    } catch (e, stack) {
      _logger.error('Failed to generate narrative', error: e, stackTrace: stack);
      return _generateFallbackNarrative(events, style);
    }
  }

  /// Generate narrative using SLM
  Future<NarrativeResult> _generateWithSLM(
    Map<String, dynamic> context,
    NarrativeStyle style,
  ) async {
    try {
      // Get prompt template
      final template = _templates[style]!;
      final prompt = template.format(context);

      // Tokenize prompt
      final inputTokens = _tokenize(prompt);

      // Prepare input tensor
      const maxInputLength = 512;
      final input = Float32List(maxInputLength);
      for (int i = 0; i < inputTokens.length && i < maxInputLength; i++) {
        input[i] = inputTokens[i].toDouble();
      }

      // Prepare output buffer
      const maxOutputLength = 256;
      final output = Float32List(maxOutputLength);

      // Run inference in isolate
      await _isolateSlmInterpreter!.run(input, output);

      // Decode output tokens
      final narrative = _decodeTokens(output);

      // Generate summary
      final summary = _generateSummaryFromNarrative(narrative);

      return NarrativeResult(
        narrative: narrative,
        summary: summary,
        style: style,
        confidence: 0.85,
        generatedAt: DateTime.now(),
        metadata: {
          'model': 'slm',
          'tokenCount': output.length,
        },
      );
    } catch (e) {
      _logger.error('SLM generation failed', error: e);
      return _generateWithTemplates(context, style);
    }
  }

  /// Generate narrative using templates
  NarrativeResult _generateWithTemplates(
    Map<String, dynamic> context,
    NarrativeStyle style,
  ) {
    final buffer = StringBuffer();
    final events = context['events'] as List;

    // Build narrative based on style
    switch (style) {
      case NarrativeStyle.professional:
        buffer.writeln(_generateProfessionalNarrative(events, context));
        break;
      case NarrativeStyle.casual:
        buffer.writeln(_generateCasualNarrative(events, context));
        break;
      case NarrativeStyle.reflective:
        buffer.writeln(_generateReflectiveNarrative(events, context));
        break;
      case NarrativeStyle.detailed:
        buffer.writeln(_generateDetailedNarrative(events, context));
        break;
      case NarrativeStyle.brief:
        buffer.writeln(_generateBriefNarrative(events, context));
        break;
      case NarrativeStyle.poetic:
        buffer.writeln(_generatePoeticNarrative(events, context));
        break;
    }

    final narrative = buffer.toString();
    final summary = _generateSummaryFromNarrative(narrative);

    return NarrativeResult(
      narrative: narrative,
      summary: summary,
      style: style,
      confidence: 0.7,
      generatedAt: DateTime.now(),
      metadata: {
        'model': 'template',
      },
    );
  }

  /// Generate professional narrative
  String _generateProfessionalNarrative(List events, Map<String, dynamic> context) {
    final buffer = StringBuffer();

    buffer.writeln('Daily Activity Report');
    buffer.writeln('Date: ${context['date']}');
    buffer.writeln();

    for (final event in events) {
      final eventMap = event as Map<String, dynamic>;
      buffer.writeln('${eventMap['time']}: ${eventMap['type'].toString().toUpperCase()}');

      if (eventMap['activities'] != null && (eventMap['activities'] as List).isNotEmpty) {
        buffer.writeln('Activities: ${(eventMap['activities'] as List).join(', ')}');
      }

      if (eventMap['photos'] != null && (eventMap['photos'] as List).isNotEmpty) {
        buffer.writeln('Documentation: ${(eventMap['photos'] as List).length} photos captured');
      }

      buffer.writeln();
    }

    final summary = context['summary'] as Map<String, dynamic>;
    buffer.writeln('Summary Statistics:');
    buffer.writeln('- Total Events: ${events.length}');
    buffer.writeln('- Active Time: ${summary['totalDuration']} minutes');
    buffer.writeln('- Photos Taken: ${summary['totalPhotos']}');

    return buffer.toString();
  }

  /// Generate casual narrative
  String _generateCasualNarrative(List events, Map<String, dynamic> context) {
    final buffer = StringBuffer();

    if (events.isEmpty) {
      return 'Pretty quiet day today. Not much to report!';
    }

    buffer.write('Today was ');

    final summary = context['summary'] as Map<String, dynamic>;
    final activities = summary['uniqueActivities'] as List;

    if (activities.contains('running') || activities.contains('cycling')) {
      buffer.write('an active day! ');
    } else if (events.length > 5) {
      buffer.write('quite busy! ');
    } else {
      buffer.write('pretty relaxed. ');
    }

    // Describe main events
    int stayCount = 0;
    int journeyCount = 0;

    for (final event in events) {
      final eventMap = event as Map<String, dynamic>;
      if (eventMap['type'] == 'stay') {
        stayCount++;
      } else if (eventMap['type'] == 'journey') {
        journeyCount++;
      }
    }

    if (stayCount > 0) {
      buffer.write('Spent time at $stayCount ${stayCount == 1 ? "place" : "places"}. ');
    }

    if (journeyCount > 0) {
      buffer.write('Had $journeyCount ${journeyCount == 1 ? "trip" : "trips"} around. ');
    }

    if (summary['totalPhotos'] > 0) {
      buffer.write('Took ${summary['totalPhotos']} photos to remember the day. ');
    }

    return buffer.toString();
  }

  /// Generate reflective narrative
  String _generateReflectiveNarrative(List events, Map<String, dynamic> context) {
    final buffer = StringBuffer();

    buffer.writeln('Looking back on today, it\'s interesting to observe the rhythm of daily life.');
    buffer.writeln();

    for (final event in events) {
      final eventMap = event as Map<String, dynamic>;

      if (eventMap['type'] == 'stay') {
        buffer.write('The time spent at this location ');

        if (eventMap['duration'] > 120) {
          buffer.write('was substantial, suggesting it was an important part of the day. ');
        } else {
          buffer.write('was brief, perhaps just a quick stop. ');
        }
      } else if (eventMap['type'] == 'journey') {
        buffer.write('The journey ');

        final activities = eventMap['activities'] as List?;
        if (activities != null && activities.contains('walking')) {
          buffer.write('on foot provided time for contemplation. ');
        } else {
          buffer.write('between places marked transitions in the day. ');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('Each moment captured contributes to the larger tapestry of life.');

    return buffer.toString();
  }

  /// Generate detailed narrative
  String _generateDetailedNarrative(List events, Map<String, dynamic> context) {
    final buffer = StringBuffer();

    buffer.writeln('Comprehensive Daily Chronicle');
    buffer.writeln('=' * 40);
    buffer.writeln();

    for (int i = 0; i < events.length; i++) {
      final event = events[i] as Map<String, dynamic>;

      buffer.writeln('Event ${i + 1}: ${event['type'].toString().toUpperCase()}');
      buffer.writeln('Time: ${event['time']}');
      buffer.writeln('Duration: ${event['duration']} minutes');

      if (event['activities'] != null && (event['activities'] as List).isNotEmpty) {
        buffer.writeln('Activities Detected:');
        for (final activity in event['activities']) {
          buffer.writeln('  - $activity');
        }
      }

      if (event['photos'] != null && (event['photos'] as List).isNotEmpty) {
        buffer.writeln('Visual Documentation:');
        for (final caption in event['photos']) {
          buffer.writeln('  - $caption');
        }
      }

      if (event['metadata'] != null) {
        final metadata = event['metadata'] as Map<String, dynamic>;

        if (metadata['distance'] != null) {
          buffer.writeln('Distance Traveled: ${metadata['distance']} meters');
        }

        if (metadata['calendarEvents'] != null &&
            (metadata['calendarEvents'] as List).isNotEmpty) {
          buffer.writeln('Scheduled Events:');
          for (final calEvent in metadata['calendarEvents']) {
            buffer.writeln('  - ${calEvent['title']}');
          }
        }
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate brief narrative
  String _generateBriefNarrative(List events, Map<String, dynamic> context) {
    final summary = context['summary'] as Map<String, dynamic>;

    return '${events.length} events today. '
           '${summary['totalDuration']} minutes of activity. '
           '${summary['totalPhotos']} photos taken.';
  }

  /// Generate poetic narrative
  String _generatePoeticNarrative(List events, Map<String, dynamic> context) {
    final buffer = StringBuffer();

    buffer.writeln('Dawn broke upon a canvas new,');
    buffer.writeln('As footsteps traced their daily due.');

    if (events.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Through places known and paths between,');
      buffer.writeln('Life\'s moments captured, felt, and seen.');
    }

    final summary = context['summary'] as Map<String, dynamic>;
    if (summary['totalPhotos'] > 0) {
      buffer.writeln();
      buffer.writeln('In pixels caught, memories stay,');
      buffer.writeln('To light tomorrow\'s distant day.');
    }

    buffer.writeln();
    buffer.writeln('And as the sun sets on this page,');
    buffer.writeln('Another day joins history\'s stage.');

    return buffer.toString();
  }

  /// Generate summary from narrative
  String _generateSummaryFromNarrative(String narrative) {
    // Extract first meaningful sentence or generate basic summary
    final sentences = narrative.split(RegExp(r'[.!?]'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (sentences.isEmpty) {
      return 'A day in the life.';
    }

    // Take first 2-3 sentences for summary
    final summaryLength = sentences.length.clamp(1, 3);
    final summary = sentences.take(summaryLength).join('. ');

    return summary.length > 200
        ? '${summary.substring(0, 197)}...'
        : summary;
  }

  /// Tokenize text into token IDs
  List<int> _tokenize(String text) {
    final tokens = <int>[];
    final words = text.toLowerCase().split(RegExp(r'\s+'));

    for (final word in words) {
      if (_vocabulary.containsKey(word)) {
        tokens.add(_vocabulary[word]!);
      } else {
        tokens.add(_vocabulary['<UNK>'] ?? 3);
      }
    }

    return tokens;
  }

  /// Decode token IDs back to text
  String _decodeTokens(Float32List tokenIds) {
    final words = <String>[];

    for (final tokenId in tokenIds) {
      final id = tokenId.round();
      if (id == 0 || id == 2) break; // PAD or END token

      if (_reverseVocabulary.containsKey(id)) {
        words.add(_reverseVocabulary[id]!);
      }
    }

    return words.join(' ');
  }

  /// Generate enhanced narrative from comprehensive daily context
  Future<NarrativeResult> generateEnhancedNarrative({
    required DailyContext dailyContext,
    NarrativeStyle style = NarrativeStyle.casual,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Use the enhanced narrative template engine for better results
      final templateEngine = NarrativeTemplateEngine();
      final narrative = templateEngine.generateContextualNarrative(dailyContext);

      // Generate structured context for metadata
      final fusionService = MultiModalFusionService();
      final context = fusionService.generateEnhancedStructuredContext(dailyContext);

      // Add additional context if provided
      if (additionalContext != null) {
        context.addAll(additionalContext);
      }

      // Calculate confidence based on enhanced data completeness
      final confidence = _calculateEnhancedConfidence(dailyContext, context);

      // Generate summary from narrative
      final summary = _generateSummaryFromNarrative(narrative);

      _logger.info('Generated enhanced narrative with style: ${style.name}, confidence: ${confidence.toStringAsFixed(2)}');

      return NarrativeResult(
        narrative: narrative,
        summary: summary,
        style: style,
        confidence: confidence,
        generatedAt: DateTime.now(),
        metadata: {
          'model': 'enhanced_template',
          'dataCompleteness': context['summary']['dataCompleteness'],
          'totalDataSources': _countActiveDatasources(dailyContext),
          'hasWrittenContent': dailyContext.writtenContentSummary.hasSignificantContent,
          'hasProximityData': dailyContext.proximitySummary.hasProximityInteractions,
        },
      );
    } catch (e, stack) {
      _logger.error('Failed to generate enhanced narrative', error: e, stackTrace: stack);
      return _generateFallbackNarrativeFromContext(dailyContext, style);
    }
  }

  /// Calculate enhanced confidence based on data richness
  double _calculateEnhancedConfidence(DailyContext dailyContext, Map<String, dynamic> context) {
    double confidence = dailyContext.overallConfidence;

    // Bonus for written content richness
    if (dailyContext.writtenContentSummary.hasSignificantContent) {
      confidence += 0.15;
      if (dailyContext.writtenContentSummary.totalWrittenEntries > 3) {
        confidence += 0.1;
      }
    }

    // Bonus for proximity interactions
    if (dailyContext.proximitySummary.hasProximityInteractions) {
      confidence += 0.1;
    }

    // Bonus for movement data richness
    if (dailyContext.movementData.length > 50) {
      confidence += 0.1;
    }

    // Bonus for diverse data sources
    final activeSources = _countActiveDatasources(dailyContext);
    confidence += (activeSources * 0.05).clamp(0.0, 0.2);

    return confidence.clamp(0.0, 1.0);
  }

  /// Count active data sources for confidence calculation
  int _countActiveDatasources(DailyContext dailyContext) {
    int count = 0;
    if (dailyContext.photoContexts.isNotEmpty) count++;
    if (dailyContext.calendarEvents.isNotEmpty) count++;
    if (dailyContext.locationPoints.isNotEmpty) count++;
    if (dailyContext.movementData.isNotEmpty) count++;
    if (dailyContext.activities.isNotEmpty) count++;
    if (dailyContext.writtenContentSummary.hasSignificantContent) count++;
    if (dailyContext.proximitySummary.hasProximityInteractions) count++;
    if (dailyContext.geofenceEvents.isNotEmpty) count++;
    return count;
  }

  /// Generate fallback narrative when service fails
  NarrativeResult _generateFallbackNarrative(
    List<DailyEvent> events,
    NarrativeStyle style,
  ) {
    final narrative = events.isEmpty
        ? 'No events recorded for today.'
        : 'Recorded ${events.length} events today.';

    return NarrativeResult(
      narrative: narrative,
      summary: narrative,
      style: style,
      confidence: 0.0,
      generatedAt: DateTime.now(),
      metadata: {'fallback': true},
    );
  }

  /// Generate fallback narrative from DailyContext when service fails
  NarrativeResult _generateFallbackNarrativeFromContext(
    DailyContext dailyContext,
    NarrativeStyle style,
  ) {
    final buffer = StringBuffer();

    if (dailyContext.photoContexts.isNotEmpty) {
      buffer.write('${dailyContext.photoContexts.length} photos captured. ');
    }
    if (dailyContext.calendarEvents.isNotEmpty) {
      buffer.write('${dailyContext.calendarEvents.length} calendar events. ');
    }
    if (dailyContext.writtenContentSummary.hasSignificantContent) {
      buffer.write('Written reflections recorded. ');
    }
    if (dailyContext.proximitySummary.hasProximityInteractions) {
      buffer.write('Location interactions noted. ');
    }

    final narrative = buffer.isEmpty
        ? 'A day with collected memories and experiences.'
        : buffer.toString();

    return NarrativeResult(
      narrative: narrative,
      summary: narrative,
      style: style,
      confidence: dailyContext.overallConfidence * 0.5, // Reduced confidence for fallback
      generatedAt: DateTime.now(),
      metadata: {
        'fallback': true,
        'contextFallback': true,
        'dataCompleteness': _countActiveDatasources(dailyContext) / 8.0,
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _slmInterpreter?.close();
    _isolateSlmInterpreter?.close();
    _isInitialized = false;
    _logger.info('Narrative generation service disposed');
  }
}
