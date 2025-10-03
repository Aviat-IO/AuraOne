import 'package:flutter/material.dart';
import 'daily_context_synthesizer.dart';
import 'narrative_template_engine.dart';

/// On-device AI journal generator that creates personalized narratives
/// Uses contextual analysis from Phase 1 to generate meaningful journal entries
/// without requiring cloud APIs - complete privacy-first implementation
class AIJournalGenerator {
  static final AIJournalGenerator _instance = AIJournalGenerator._internal();
  factory AIJournalGenerator() => _instance;
  AIJournalGenerator._internal();

  final NarrativeTemplateEngine _templateEngine = NarrativeTemplateEngine();

  /// Generate a comprehensive journal entry from daily context
  Future<JournalEntry> generateJournalEntry(DailyContext context) async {
    try {
      debugPrint('🎯 Generating AI journal entry for ${context.date}');

      // Generate narrative components using advanced template engine
      final narrative = _templateEngine.generateContextualNarrative(context);
      final insights = _generateInsights(context);
      final highlights = _generateHighlights(context);
      final mood = _inferMood(context);
      final tags = _generateTags(context);

      final entry = JournalEntry(
        date: context.date,
        narrative: narrative,
        insights: insights,
        highlights: highlights,
        mood: mood,
        tags: tags,
        confidence: context.overallConfidence,
        metadata: {
          'generated_at': DateTime.now().toIso8601String(),
          'source_photos': context.photoContexts.length,
          'source_events': context.calendarEvents.length,
          'source_locations': context.locationPoints.length,
          'source_activities': context.activities.length,
          'ai_version': '1.0.0',
        },
      );

      debugPrint('✅ Generated journal entry: ${entry.narrative.length} chars');
      return entry;

    } catch (e) {
      debugPrint('❌ Error generating journal entry: $e');
      return _generateFallbackEntry(context);
    }
  }

  /// Generate the main narrative text
  String _generateNarrative(DailyContext context) {
    final buffer = StringBuffer();

    // Opening based on overall day sentiment
    final openings = _getContextualOpenings(context);
    buffer.write(openings.isNotEmpty ? openings : 'Today was a day of quiet moments and simple experiences. ');

    // Social context
    final socialNarrative = _generateSocialNarrative(context);
    if (socialNarrative.isNotEmpty) {
      buffer.write('$socialNarrative ');
    }

    // Activity narrative
    final activityNarrative = _generateActivityNarrative(context);
    if (activityNarrative.isNotEmpty) {
      buffer.write('$activityNarrative ');
    }

    // Location narrative
    final locationNarrative = _generateLocationNarrative(context);
    if (locationNarrative.isNotEmpty) {
      buffer.write('$locationNarrative ');
    }

    // Environment and mood
    final environmentNarrative = _generateEnvironmentNarrative(context);
    if (environmentNarrative.isNotEmpty) {
      buffer.write('$environmentNarrative ');
    }

    // Closing reflection
    final closing = _generateClosingReflection(context);
    buffer.write(closing);

    return buffer.toString().trim();
  }

  /// Generate contextual opening sentences
  String _getContextualOpenings(DailyContext context) {
    final photoCount = context.photoContexts.length;
    final hasCalendarEvents = context.calendarEvents.isNotEmpty;
    final hasMovement = context.movementData.isNotEmpty;

    // Activity-based openings
    if (photoCount > 10) {
      return 'Today was filled with moments worth capturing. ';
    } else if (photoCount > 5) {
      return 'A day of interesting experiences and memorable moments. ';
    } else if (hasCalendarEvents && context.calendarEvents.length > 3) {
      return 'It was a busy day with several planned activities. ';
    } else if (hasMovement) {
      return 'A day of movement and gentle activity. ';
    } else {
      return 'Today offered a peaceful rhythm and quiet reflection. ';
    }
  }

  /// Generate social context narrative
  String _generateSocialNarrative(DailyContext context) {
    final totalPeople = context.photoContexts.fold(0, (sum, photo) => sum + photo.faceCount);
    final groupPhotos = context.photoContexts.where((photo) => photo.socialContext.isGroupPhoto).length;
    final selfies = context.photoContexts.where((photo) => photo.socialContext.isSelfie).length;

    if (totalPeople == 0) {
      return 'I spent time in solitude, enjoying my own company and thoughts.';
    } else if (groupPhotos > selfies) {
      return 'Time with others brought warmth and connection to the day.';
    } else if (selfies > 2) {
      return 'I documented personal moments and reflections throughout the day.';
    } else if (totalPeople > 10) {
      return 'The day was rich with social interactions and shared experiences.';
    } else {
      return 'I shared meaningful moments with the people around me.';
    }
  }

  /// Generate activity-based narrative
  String _generateActivityNarrative(DailyContext context) {
    final activities = <String>[];
    final environments = <String>[];

    // Analyze photo contexts for activities
    for (final photo in context.photoContexts) {
      // Food and dining
      if (photo.sceneLabels.any((label) => ['restaurant', 'cafe', 'food'].contains(label.toLowerCase())) ||
          photo.objectLabels.any((label) => ['food', 'drink', 'coffee'].contains(label.toLowerCase()))) {
        activities.add('dining');
      }

      // Outdoor activities
      if (photo.sceneLabels.any((label) => ['outdoor', 'nature', 'park'].contains(label.toLowerCase()))) {
        activities.add('outdoor exploration');
      }

      // Work
      if (photo.sceneLabels.any((label) => ['office', 'workplace', 'meeting'].contains(label.toLowerCase()))) {
        activities.add('work');
      }

      // Transportation
      if (photo.sceneLabels.any((label) => ['vehicle', 'car', 'transport'].contains(label.toLowerCase()))) {
        activities.add('travel');
      }
    }

    // Generate narrative from activities
    if (activities.isEmpty) {
      return 'The day unfolded with quiet, undocumented activities.';
    }

    final uniqueActivities = activities.toSet().toList();
    if (uniqueActivities.length == 1) {
      return 'The day centered around ${uniqueActivities.first}, creating a focused experience.';
    } else if (uniqueActivities.length <= 3) {
      return 'The day included ${uniqueActivities.join(', ')}, creating a well-rounded experience.';
    } else {
      return 'A varied day with multiple activities including ${uniqueActivities.take(3).join(', ')} and more.';
    }
  }

  /// Generate location-based narrative
  String _generateLocationNarrative(DailyContext context) {
    if (context.locationPoints.isEmpty) {
      return 'I stayed close to familiar spaces.';
    }

    final locationCount = context.locationPoints.length;
    final hasMovement = context.movementData.isNotEmpty;

    if (locationCount > 20 && hasMovement) {
      return 'The day took me through various locations, each offering its own character and energy.';
    } else if (locationCount > 10) {
      return 'I moved through several different places, experiencing the unique atmosphere of each.';
    } else if (locationCount > 5) {
      return 'A few different locations provided the backdrop for today\'s experiences.';
    } else {
      return 'Most of the day was spent in familiar, comfortable surroundings.';
    }
  }

  /// Generate environment-based narrative
  String _generateEnvironmentNarrative(DailyContext context) {
    final environments = context.photoContexts
        .expand((photo) => photo.sceneLabels)
        .map((label) => label.toLowerCase())
        .toSet();

    if (environments.contains('outdoor') || environments.contains('nature')) {
      return 'The natural world provided a beautiful backdrop, offering fresh air and open spaces.';
    } else if (environments.contains('restaurant') || environments.contains('cafe')) {
      return 'Comfortable dining spaces created opportunities for nourishment and conversation.';
    } else if (environments.contains('home') || environments.contains('house')) {
      return 'Home provided a sanctuary of comfort and personal space.';
    } else if (environments.contains('office') || environments.contains('workplace')) {
      return 'Professional environments shaped the day\'s focus and productivity.';
    } else {
      return 'Each space visited today contributed its own unique energy and atmosphere.';
    }
  }

  /// Generate closing reflection
  String _generateClosingReflection(DailyContext context) {
    final confidence = context.overallConfidence;

    if (confidence > 0.8) {
      return 'Looking back, it was a day filled with clear moments and meaningful experiences.';
    } else if (confidence > 0.6) {
      return 'The day held its own quiet significance, with moments that mattered.';
    } else if (confidence > 0.4) {
      return 'While some details may fade, the essence of today remains.';
    } else {
      return 'Sometimes the most important parts of a day are the feelings and impressions that linger.';
    }
  }

  /// Generate insights based on patterns and context
  List<String> _generateInsights(DailyContext context) {
    final insights = <String>[];

    // Social insights
    final totalPeople = context.photoContexts.fold(0, (sum, photo) => sum + photo.faceCount);
    if (totalPeople > 0) {
      insights.add('Social connection was an important part of today');
    }

    // Activity insights
    final photoCount = context.photoContexts.length;
    if (photoCount > 10) {
      insights.add('A particularly photo-worthy day with many memorable moments');
    }

    // Environment insights
    final outdoorPhotos = context.photoContexts.where((photo) =>
        photo.sceneLabels.any((label) => label.toLowerCase().contains('outdoor')));
    if (outdoorPhotos.length > photoCount * 0.5 && photoCount > 0) {
      insights.add('Spent significant time in outdoor environments');
    }

    // Movement insights
    if (context.movementData.isNotEmpty) {
      final totalMovement = context.movementData.fold(0.0, (sum, data) => sum + (100 - data.stillPercentage));
      if (totalMovement > context.movementData.length * 50) {
        insights.add('An active day with notable movement and energy');
      }
    }

    // Calendar insights
    if (context.calendarEvents.length > 3) {
      insights.add('A well-scheduled day with multiple planned activities');
    }

    return insights;
  }

  /// Generate key highlights from the day
  List<String> _generateHighlights(DailyContext context) {
    final highlights = <String>[];

    // Photo highlights
    if (context.photoContexts.isNotEmpty) {
      final bestPhotos = context.photoContexts
          .where((photo) => photo.confidenceScore > 0.8)
          .take(3);

      for (final photo in bestPhotos) {
        highlights.add('${photo.activityDescription} - ${photo.environmentDescription}');
      }
    }

    // Calendar highlights
    for (final event in context.calendarEvents.take(2)) {
      highlights.add('${event.title} ${event.description != null ? "- ${event.description}" : ""}');
    }

    // If no specific highlights, create general ones
    if (highlights.isEmpty) {
      if (context.photoContexts.isNotEmpty) {
        highlights.add('${context.photoContexts.length} moments captured');
      }
      if (context.locationPoints.isNotEmpty) {
        highlights.add('Visited ${context.locationPoints.length} different locations');
      }
      if (highlights.isEmpty) {
        highlights.add('A day of quiet reflection and personal time');
      }
    }

    return highlights;
  }

  /// Infer mood based on context including movement data
  String _inferMood(DailyContext context) {
    final score = context.overallConfidence;
    final socialScore = context.photoContexts.fold(0, (sum, photo) => sum + photo.faceCount);
    final activityScore = context.photoContexts.length + context.calendarEvents.length;

    // Calculate movement-based mood factors
    double movementScore = 0;
    if (context.movementData.isNotEmpty) {
      double avgWalking = 0;
      double avgRunning = 0;
      double avgActivity = 0;
      for (final data in context.movementData) {
        avgWalking += data.walkingPercentage;
        avgRunning += data.runningPercentage;
        avgActivity += data.averageMagnitude;
      }
      avgWalking /= context.movementData.length;
      avgRunning /= context.movementData.length;
      avgActivity /= context.movementData.length;

      // High physical activity correlates with energetic mood
      if (avgRunning > 0.1 || avgWalking > 0.4) {
        movementScore = 0.8;
      } else if (avgWalking > 0.2) {
        movementScore = 0.6;
      } else if (avgActivity > 0.5) {
        movementScore = 0.4;
      }
    }

    // Combine all factors for mood inference
    if (movementScore > 0.6 && (score > 0.7 || socialScore > 3)) {
      return 'energetic';
    } else if (score > 0.8 && socialScore > 5) {
      return 'joyful';
    } else if (score > 0.7 && activityScore > 10) {
      return 'accomplished';
    } else if (movementScore > 0.4) {
      return 'active';
    } else if (socialScore > 0) {
      return 'connected';
    } else if (activityScore > 5) {
      return 'engaged';
    } else if (score > 0.5) {
      return 'peaceful';
    } else {
      return 'reflective';
    }
  }

  /// Generate relevant tags including movement-based tags
  List<String> _generateTags(DailyContext context) {
    final tags = <String>[];

    // Movement-based tags
    if (context.movementData.isNotEmpty) {
      double avgWalking = 0;
      double avgRunning = 0;
      double avgDriving = 0;
      double avgStill = 0;

      for (final data in context.movementData) {
        avgWalking += data.walkingPercentage;
        avgRunning += data.runningPercentage;
        avgDriving += data.drivingPercentage;
        avgStill += data.stillPercentage;
      }

      final count = context.movementData.length;
      avgWalking /= count;
      avgRunning /= count;
      avgDriving /= count;
      avgStill /= count;

      if (avgRunning > 0.1) {
        tags.add('exercise');
        tags.add('running');
      }
      if (avgWalking > 0.3) {
        tags.add('active');
        tags.add('walking');
      }
      if (avgDriving > 0.3) {
        tags.add('travel');
        tags.add('driving');
      }
      if (avgStill > 0.7) {
        tags.add('focused');
      }
    }

    // Environment tags
    final environments = context.photoContexts
        .expand((photo) => photo.sceneLabels)
        .toSet();

    if (environments.any((env) => ['outdoor', 'nature', 'park'].contains(env.toLowerCase()))) {
      tags.add('outdoor');
    }
    if (environments.any((env) => ['restaurant', 'cafe', 'food'].contains(env.toLowerCase()))) {
      tags.add('dining');
    }
    if (environments.any((env) => ['work', 'office', 'meeting'].contains(env.toLowerCase()))) {
      tags.add('work');
    }

    // Social tags
    final totalPeople = context.photoContexts.fold(0, (sum, photo) => sum + photo.faceCount);
    if (totalPeople > 5) {
      tags.add('social');
    } else if (totalPeople > 0) {
      tags.add('friends');
    } else {
      tags.add('solo');
    }

    // Activity tags
    if (context.photoContexts.length > 10) {
      tags.add('active');
    }
    if (context.calendarEvents.length > 3) {
      tags.add('busy');
    }

    return tags.take(5).toList();
  }

  /// Generate fallback entry when processing fails
  JournalEntry _generateFallbackEntry(DailyContext context) {
    return JournalEntry(
      date: context.date,
      narrative: 'Today was a day of simple moments and quiet experiences. '
          'While the details may be soft, the essence of the day remains meaningful.',
      insights: ['Sometimes the most important experiences are felt rather than documented'],
      highlights: ['A day of personal reflection'],
      mood: 'peaceful',
      tags: ['reflection', 'personal'],
      confidence: 0.5,
      metadata: {
        'generated_at': DateTime.now().toIso8601String(),
        'fallback': true,
        'ai_version': '1.0.0',
      },
    );
  }

}

/// Represents a generated journal entry with AI insights
class JournalEntry {
  final DateTime date;
  final String narrative;
  final List<String> insights;
  final List<String> highlights;
  final String mood;
  final List<String> tags;
  final double confidence;
  final Map<String, dynamic> metadata;

  JournalEntry({
    required this.date,
    required this.narrative,
    required this.insights,
    required this.highlights,
    required this.mood,
    required this.tags,
    required this.confidence,
    required this.metadata,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'narrative': narrative,
      'insights': insights,
      'highlights': highlights,
      'mood': mood,
      'tags': tags,
      'confidence': confidence,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      date: DateTime.parse(json['date']),
      narrative: json['narrative'] ?? '',
      insights: List<String>.from(json['insights'] ?? []),
      highlights: List<String>.from(json['highlights'] ?? []),
      mood: json['mood'] ?? 'neutral',
      tags: List<String>.from(json['tags'] ?? []),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Generate a brief summary of the entry
  String get summary {
    final words = narrative.split(' ');
    if (words.length <= 20) return narrative;
    return '${words.take(20).join(' ')}...';
  }

  /// Get the primary theme of the day
  String get primaryTheme {
    if (tags.isEmpty) return 'reflection';
    return tags.first;
  }
}