import '../services/timeline_event_aggregator.dart';
import '../services/daily_context_synthesizer.dart';
import '../utils/logger.dart';

/// Analyzes emotional tone of a day using enriched data from all sources
///
/// Uses objects detected, place types, meeting titles, distances, and activities
/// to determine the emotional character and energy level of the day.
class EmotionalToneAnalyzer {
  static final _logger = AppLogger('EmotionalToneAnalyzer');
  static final EmotionalToneAnalyzer _instance = EmotionalToneAnalyzer._internal();

  factory EmotionalToneAnalyzer() => _instance;
  EmotionalToneAnalyzer._internal();

  /// Analyze emotional profile for a day
  EmotionalProfile analyzeDay(DailyContext context) {
    double energy = 0.0;
    double social = 0.0;
    double contemplative = 0.0;
    double adventurous = 0.0;

    // Analyze timeline events for emotional signals
    for (final event in context.timelineEvents) {
      switch (event.type) {
        case NarrativeEventType.photo:
          _analyzePhotoEmotion(event, context);
          energy += _getPhotoEnergyLevel(event);
          contemplative += _getPhotoContemplativeLevel(event);
          break;

        case NarrativeEventType.location:
          social += _getLocationSocialLevel(event);
          adventurous += _getLocationAdventurousLevel(event);
          break;

        case NarrativeEventType.calendar:
          energy += _getCalendarEnergyLevel(event);
          social += _getCalendarSocialLevel(event);
          break;

        case NarrativeEventType.movement:
          adventurous += _getMovementAdventurousLevel(event);
          energy += _getMovementEnergyLevel(event);
          break;

        case NarrativeEventType.activity:
          // Activities provide background energy signals
          break;
      }
    }

    // Analyze distance for adventurousness
    final totalKm = context.locationSummary.totalKilometers;
    if (totalKm > 15) {
      adventurous += 40; // Very adventurous
      energy += 30;
    } else if (totalKm > 5) {
      adventurous += 20; // Moderately adventurous
      energy += 15;
    } else if (totalKm < 0.5) {
      contemplative += 20; // Stayed local, more contemplative
    }

    // Normalize scores (0-100)
    final eventCount = context.timelineEvents.length.clamp(1, 10);
    energy = (energy / eventCount).clamp(0, 100);
    social = (social / eventCount).clamp(0, 100);
    contemplative = (contemplative / eventCount).clamp(0, 100);
    adventurous = (adventurous / eventCount).clamp(0, 100);

    // Determine primary tone
    final tones = <EmotionalTone, double>{
      EmotionalTone.energetic: energy,
      EmotionalTone.social: social,
      EmotionalTone.contemplative: contemplative,
      EmotionalTone.adventurous: adventurous,
    };

    final primaryTone = tones.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    _logger.debug('Emotional profile: energy=$energy, social=$social, '
                 'contemplative=$contemplative, adventurous=$adventurous');

    return EmotionalProfile(
      primaryTone: primaryTone,
      energy: energy,
      social: social,
      contemplative: contemplative,
      adventurous: adventurous,
    );
  }

  void _analyzePhotoEmotion(NarrativeEvent event, DailyContext context) {
    // Additional logging for photo emotional analysis
    final objects = event.objectsSeen ?? [];
    if (objects.isNotEmpty) {
      _logger.debug('Photo objects detected: ${objects.join(", ")}');
    }
  }

  /// Get energy level from photo content
  double _getPhotoEnergyLevel(NarrativeEvent event) {
    final objects = event.objectsSeen ?? [];
    double energy = 0.0;

    // Animals and active objects increase energy
    final energeticObjects = {
      'dog': 30.0,
      'cat': 20.0,
      'bird': 25.0,
      'horse': 35.0,
      'bicycle': 40.0,
      'skateboard': 45.0,
      'sports ball': 50.0,
      'surfboard': 45.0,
      'snowboard': 45.0,
    };

    for (final obj in objects) {
      final lowerObj = obj.toLowerCase();
      for (final entry in energeticObjects.entries) {
        if (lowerObj.contains(entry.key)) {
          energy += entry.value;
        }
      }
    }

    // People in photos suggest activity
    if (event.peopleCount != null && event.peopleCount! > 0) {
      energy += event.peopleCount! * 15;
    }

    return energy.clamp(0, 100);
  }

  /// Get contemplative level from photo content
  double _getPhotoContemplativeLevel(NarrativeEvent event) {
    final objects = event.objectsSeen ?? [];
    final scene = event.sceneDescription?.toLowerCase() ?? '';
    double contemplative = 0.0;

    // Nature and quiet objects increase contemplation
    final contemplativeObjects = {
      'book': 40.0,
      'plant': 30.0,
      'flower': 35.0,
      'tree': 30.0,
      'bench': 25.0,
      'laptop': 20.0,
    };

    for (final obj in objects) {
      final lowerObj = obj.toLowerCase();
      for (final entry in contemplativeObjects.entries) {
        if (lowerObj.contains(entry.key)) {
          contemplative += entry.value;
        }
      }
    }

    // Scene descriptions
    if (scene.contains('nature') || scene.contains('landscape')) {
      contemplative += 30;
    }
    if (scene.contains('sunset') || scene.contains('sunrise')) {
      contemplative += 35;
    }

    return contemplative.clamp(0, 100);
  }

  /// Get social level from location
  double _getLocationSocialLevel(NarrativeEvent event) {
    final placeType = event.placeType?.toLowerCase() ?? '';
    final placeName = event.placeName?.toLowerCase() ?? '';

    // Social place types
    if (placeType.contains('cafe') || placeName.contains('coffee')) {
      return 60.0;
    }
    if (placeType.contains('restaurant') || placeType.contains('dining')) {
      return 70.0;
    }
    if (placeType.contains('bar') || placeType.contains('club')) {
      return 80.0;
    }
    if (placeType.contains('shopping') || placeName.contains('mall')) {
      return 50.0;
    }
    if (placeType.contains('park') && (event.peopleCount ?? 0) > 0) {
      return 60.0;
    }

    return 10.0;
  }

  /// Get adventurous level from location
  double _getLocationAdventurousLevel(NarrativeEvent event) {
    final placeType = event.placeType?.toLowerCase() ?? '';
    final placeName = event.placeName?.toLowerCase() ?? '';

    // Adventurous place types
    if (placeType.contains('park')) {
      return 40.0;
    }
    if (placeType.contains('trail') || placeName.contains('trail')) {
      return 60.0;
    }
    if (placeName.contains('beach') || placeName.contains('mountain')) {
      return 70.0;
    }
    if (placeType.contains('gym') || placeType.contains('fitness')) {
      return 50.0;
    }

    // Novelty - new places are more adventurous
    // (In a full implementation, this would check against historical locations)
    return 20.0;
  }

  /// Get energy level from calendar event
  double _getCalendarEnergyLevel(NarrativeEvent event) {
    final title = event.meetingTitle?.toLowerCase() ?? '';

    // Stressful/high-energy meeting types
    if (title.contains('review') || title.contains('deadline')) {
      return 80.0;
    }
    if (title.contains('presentation') || title.contains('demo')) {
      return 70.0;
    }
    if (title.contains('brainstorm') || title.contains('planning')) {
      return 60.0;
    }
    if (title.contains('standup') || title.contains('sync')) {
      return 40.0;
    }
    if (title.contains('1:1') || title.contains('one-on-one')) {
      return 30.0;
    }

    return 20.0; // Default meeting energy
  }

  /// Get social level from calendar event
  double _getCalendarSocialLevel(NarrativeEvent event) {
    final attendeeCount = event.attendees?.length ?? 0;

    if (attendeeCount == 0) {
      return 10.0; // Solo event
    } else if (attendeeCount == 1) {
      return 40.0; // 1:1 meeting
    } else if (attendeeCount <= 4) {
      return 60.0; // Small group
    } else if (attendeeCount <= 10) {
      return 75.0; // Medium group
    } else {
      return 90.0; // Large group
    }
  }

  /// Get adventurous level from movement
  double _getMovementAdventurousLevel(NarrativeEvent event) {
    final mode = event.movementMode?.toLowerCase() ?? '';

    if (mode.contains('running')) {
      return 60.0;
    }
    if (mode.contains('walking')) {
      return 30.0;
    }
    if (mode.contains('cycling')) {
      return 70.0;
    }
    if (mode.contains('driving')) {
      return 20.0;
    }

    return 10.0;
  }

  /// Get energy level from movement
  double _getMovementEnergyLevel(NarrativeEvent event) {
    final distance = event.distanceTraveled ?? 0.0;
    final distanceKm = distance / 1000;

    if (distanceKm > 10) {
      return 70.0;
    } else if (distanceKm > 5) {
      return 50.0;
    } else if (distanceKm > 1) {
      return 30.0;
    }

    return 10.0;
  }
}

/// Emotional tone categories
enum EmotionalTone {
  energetic,     // High activity, fast pace
  social,        // Interactions, meetings, groups
  contemplative, // Quiet, reflective, peaceful
  adventurous,   // Exploration, novelty, movement
}

extension EmotionalToneExtension on EmotionalTone {
  String get name {
    switch (this) {
      case EmotionalTone.energetic:
        return 'Energetic';
      case EmotionalTone.social:
        return 'Social';
      case EmotionalTone.contemplative:
        return 'Contemplative';
      case EmotionalTone.adventurous:
        return 'Adventurous';
    }
  }

  String get description {
    switch (this) {
      case EmotionalTone.energetic:
        return 'A day full of activity and dynamic energy';
      case EmotionalTone.social:
        return 'A day of connections and shared moments';
      case EmotionalTone.contemplative:
        return 'A day of reflection and quiet presence';
      case EmotionalTone.adventurous:
        return 'A day of exploration and new experiences';
    }
  }
}

/// Emotional profile with dimensional scores
class EmotionalProfile {
  final EmotionalTone primaryTone;
  final double energy;        // 0-100: Low energy to high energy
  final double social;        // 0-100: Solitary to highly social
  final double contemplative; // 0-100: Active to contemplative
  final double adventurous;   // 0-100: Routine to adventurous

  EmotionalProfile({
    required this.primaryTone,
    required this.energy,
    required this.social,
    required this.contemplative,
    required this.adventurous,
  });

  /// Get a human-readable emotional summary
  String get summary {
    final parts = <String>[];

    if (energy > 70) {
      parts.add('high-energy');
    } else if (energy < 30) {
      parts.add('calm');
    }

    if (social > 70) {
      parts.add('socially active');
    } else if (social < 30) {
      parts.add('solitary');
    }

    if (contemplative > 70) {
      parts.add('reflective');
    }

    if (adventurous > 70) {
      parts.add('exploratory');
    } else if (adventurous < 30) {
      parts.add('routine-focused');
    }

    if (parts.isEmpty) {
      return 'balanced';
    }

    return parts.join(', ');
  }

  /// Get emotional intensity (how strong the emotions are)
  double get intensity {
    final scores = [energy, social, contemplative, adventurous];
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;

    // Intensity is high when there's a clear dominant emotion
    return (maxScore - avgScore) / 50;
  }
}
