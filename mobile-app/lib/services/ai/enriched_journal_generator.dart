import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../utils/logger.dart';
import '../daily_context_synthesizer.dart';
import '../context_enrichment_service.dart';
import 'ai_journal_generator.dart';
import 'cloud_gemini_adapter.dart';

class EnrichedJournalGenerator {
  static final _logger = AppLogger('EnrichedJournalGenerator');
  
  final ContextEnrichmentService _enrichmentService = ContextEnrichmentService();
  final CloudGeminiAdapter _cloudAdapter = CloudGeminiAdapter();

  Future<AIGenerationResult> generateEnrichedJournal(DailyContext context) async {
    try {
      final enrichedContext = await _enrichmentService.enrichContext(context);
      
      if (!await _cloudAdapter.checkAvailability()) {
        return AIGenerationResult.failure('Cloud adapter not available');
      }

      final prompt = _buildEnrichedPrompt(enrichedContext);
      
      _logger.info('Generating enriched journal with ${enrichedContext.knownPeople.length} people, ${enrichedContext.knownPlaces.length} places');

      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: _getApiKey(),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final narrative = response.text;

      if (narrative == null || narrative.isEmpty) {
        return AIGenerationResult.failure('Empty response from Gemini API');
      }

      return AIGenerationResult.success(
        narrative,
        metadata: {
          'adapter': 'EnrichedJournalGenerator',
          'people_count': enrichedContext.knownPeople.length,
          'places_count': enrichedContext.knownPlaces.length,
          'occasions_count': enrichedContext.occasionsToday.length,
          'privacy_level': enrichedContext.privacyLevel.name,
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error generating enriched journal', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure('Error: $e');
    }
  }

  String _buildEnrichedPrompt(EnrichedDailyContext enrichedContext) {
    final buffer = StringBuffer();
    final context = enrichedContext.originalContext;

    buffer.writeln('You are a skilled personal journal writer creating an entry in first person perspective.');
    buffer.writeln('Generate a natural, fluent narrative (150-200 words) describing what happened this day.');
    buffer.writeln('');

    _addWritingGuidelines(buffer);
    _addToneGuidelines(buffer);
    _addExclusionGuidelines(buffer);
    _addEmphasisGuidelines(buffer);
    _addMeasurementGuidelines(buffer);

    buffer.writeln('Daily Context for ${context.date.toLocal().toString().split(' ')[0]}:');
    buffer.writeln('');

    _addEnrichedPeopleSection(buffer, enrichedContext);
    _addEnrichedPlacesSection(buffer, enrichedContext);
    _addActivitiesSection(buffer, context);
    _addOccasionsSection(buffer, enrichedContext);
    _addTimelineSection(buffer, context);
    _addPhotosSection(buffer, context);

    _addExamples(buffer);
    _addTask(buffer);

    return buffer.toString();
  }

  void _addWritingGuidelines(StringBuffer buffer) {
    buffer.writeln('WRITING STYLE:');
    buffer.writeln('- Write in complete, grammatically correct sentences with proper punctuation');
    buffer.writeln('- Use natural paragraph structure with smooth transitions between events');
    buffer.writeln('- Vary sentence structure - avoid repetitive patterns');
    buffer.writeln('- Present information in chronological order');
    buffer.writeln('- Focus on observable facts: activities, locations, and events');
    buffer.writeln('');
  }

  void _addToneGuidelines(StringBuffer buffer) {
    buffer.writeln('TONE GUIDELINES:');
    buffer.writeln('- Maintain an objective, factual tone based on observable data');
    buffer.writeln('- Describe WHAT happened, WHERE it happened, and WHEN it happened');
    buffer.writeln('- Avoid assumptions about feelings or subjective experiences');
    buffer.writeln('- Do not use emotional adjectives like "amazing", "wonderful", "enjoyed"');
    buffer.writeln('');
  }

  void _addExclusionGuidelines(StringBuffer buffer) {
    buffer.writeln('WHAT TO EXCLUDE (uninteresting details nobody would write):');
    buffer.writeln('- Technical photo details (shadows, angles, camera positions, lighting)');
    buffer.writeln('- Meta-observations about the photo itself ("you can see", "visible in the photo")');
    buffer.writeln('- Trivial visual artifacts (reflections, shadows on pavement, background clutter)');
    buffer.writeln('- Self-referential photo commentary ("from where I was standing", "captured in this image")');
    buffer.writeln('- Focus on the meaningful content and activities, not photographic technicalities');
    buffer.writeln('');
  }

  void _addEmphasisGuidelines(StringBuffer buffer) {
    buffer.writeln('WHAT TO EMPHASIZE (meaningful content people care about):');
    buffer.writeln('- Activities and experiences over static locations');
    buffer.writeln('- People and interactions over demographics and counts');
    buffer.writeln('- Memorable moments and significant events over routine transitions');
    buffer.writeln('- Context and meaning over technical details');
    buffer.writeln('- Natural flow connecting events rather than listing them');
    buffer.writeln('');
  }

  void _addMeasurementGuidelines(StringBuffer buffer) {
    final useImperial = _shouldUseImperialMeasurements();
    if (useImperial) {
      buffer.writeln('MEASUREMENT UNITS:');
      buffer.writeln('- Convert all metric measurements to imperial units');
      buffer.writeln('- Distance: Use miles instead of kilometers (1 km ≈ 0.62 miles)');
      buffer.writeln('- Temperature: Use Fahrenheit instead of Celsius if mentioned');
      buffer.writeln('- Example: "traveled 2.9 miles" instead of "covered 4.7km"');
      buffer.writeln('');
    }
  }

  void _addEnrichedPeopleSection(StringBuffer buffer, EnrichedDailyContext enrichedContext) {
    if (enrichedContext.knownPeople.isEmpty) return;

    buffer.writeln('PEOPLE MENTIONED TODAY:');
    
    for (final person in enrichedContext.knownPeople.take(5)) {
      if (person.photoCount > 1) {
        buffer.write('- ${person.displayName} (appeared in ${person.photoCount} photos');
      } else {
        buffer.write('- ${person.displayName}');
      }
      
      if (person.relationship != null) {
        buffer.write(' - ${person.relationship}');
      }
      
      buffer.writeln(')');
    }
    
    buffer.writeln('');
  }

  void _addEnrichedPlacesSection(StringBuffer buffer, EnrichedDailyContext enrichedContext) {
    if (enrichedContext.knownPlaces.isEmpty) return;

    buffer.writeln('PLACES VISITED TODAY:');
    
    for (final place in enrichedContext.knownPlaces.take(5)) {
      buffer.write('- ${place.name}');
      
      if (place.neighborhood != null && place.city != null) {
        buffer.write(' in ${place.neighborhood}, ${place.city}');
      } else if (place.neighborhood != null) {
        buffer.write(' in ${place.neighborhood}');
      } else if (place.city != null) {
        buffer.write(' in ${place.city}');
      }
      
      if (place.timeSpent != null && place.timeSpent!.inMinutes > 15) {
        buffer.write(' (${_formatDuration(place.timeSpent!)})');
      }
      
      buffer.writeln();
    }
    
    buffer.writeln('');
  }

  void _addActivitiesSection(StringBuffer buffer, DailyContext context) {
    if (context.calendarEvents.isEmpty && 
        context.activitySummary.primaryActivities.isEmpty) {
      return;
    }

    buffer.writeln('ACTIVITIES & EVENTS:');
    
    for (final event in context.calendarEvents.take(3)) {
      final time = '${event.startDate.hour}:${event.startDate.minute.toString().padLeft(2, '0')}';
      buffer.write('- $time: ${event.title}');
      if (event.location != null && event.location!.isNotEmpty) {
        buffer.write(' at ${event.location}');
      }
      buffer.writeln();
    }
    
    if (context.activitySummary.primaryActivities.isNotEmpty) {
      final activities = context.activitySummary.primaryActivities.take(3).join(', ');
      buffer.writeln('- Activities: $activities');
    }
    
    buffer.writeln('');
  }

  void _addOccasionsSection(StringBuffer buffer, EnrichedDailyContext enrichedContext) {
    if (enrichedContext.occasionsToday.isEmpty) return;

    buffer.writeln('SPECIAL OCCASIONS TODAY:');
    
    for (final occasion in enrichedContext.occasionsToday) {
      buffer.writeln('- ${occasion.name} (${occasion.occasionType})');
    }
    
    buffer.writeln('');
  }

  void _addTimelineSection(StringBuffer buffer, DailyContext context) {
    if (context.timelineEvents.isEmpty) return;

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
      
      buffer.writeln();
    }
    
    buffer.writeln('');
  }

  void _addPhotosSection(StringBuffer buffer, DailyContext context) {
    if (context.photoContexts.isEmpty) return;

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
    
    buffer.writeln('');
  }

  void _addExamples(StringBuffer buffer) {
    buffer.writeln('EXAMPLES:');
    buffer.writeln('');
    buffer.writeln('GOOD EXAMPLE (natural, personalized):');
    buffer.writeln('"Started the morning with Charles at Liberty Park in Downtown. We spent about two');
    buffer.writeln('hours there before heading to Sarah\'s Cafe for lunch. Met up with Mom later in the');
    buffer.writeln('afternoon to work on the quarterly report together. Ended the day with a quiet dinner');
    buffer.writeln('at home."');
    buffer.writeln('');
    buffer.writeln('BAD EXAMPLE (generic, robotic - DO NOT WRITE LIKE THIS):');
    buffer.writeln('"Visited 3 locations today. Photographed a child at a park. You can see trees in');
    buffer.writeln('the image. Later visited a coffee shop and took a photo of a beverage. Returned to');
    buffer.writeln('residential location. Total photos: 5."');
    buffer.writeln('');
  }

  void _addTask(StringBuffer buffer) {
    buffer.writeln('TASK:');
    buffer.writeln('Write a cohesive first-person narrative using the people and place names provided above.');
    buffer.writeln('Use proper grammar, complete sentences, and smooth transitions between events.');
    buffer.writeln('Make it read like a well-written personal journal entry.');
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes} minutes';
    }
  }

  bool _shouldUseImperialMeasurements() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final countryCode = locale.countryCode?.toUpperCase();
    const imperialCountries = {'US', 'LR', 'MM'};
    return countryCode != null && imperialCountries.contains(countryCode);
  }

  String _getApiKey() {
    final envApiKey = dotenv.env['GEMINI_API_KEY'];
    if (envApiKey != null && envApiKey.isNotEmpty && envApiKey != 'your_gemini_api_key_here') {
      return envApiKey;
    }
    return '';
  }
}
