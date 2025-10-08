import 'dart:math' as math;
import '../services/timeline_event_aggregator.dart';
import '../services/daily_context_synthesizer.dart';
import '../utils/logger.dart';
import 'contextual_phrase_generator.dart';
import 'emotional_tone_analyzer.dart';
import 'personality_engine.dart';

/// Builds factual, objective narratives from timeline events and daily context
///
/// Weaves together timeline events (calendar, photos, locations) with
/// contextual data (place names, objects, distances) into a coherent
/// chronological narrative with natural transitions.
///
/// Maintains objective tone focusing on observable facts without assumptions
/// about emotions or subjective experiences.
class DataRichNarrativeBuilder {
  static final _logger = AppLogger('DataRichNarrativeBuilder');
  static final DataRichNarrativeBuilder _instance = DataRichNarrativeBuilder._internal();

  final ContextualPhraseGenerator _phraseGen = ContextualPhraseGenerator();
  final EmotionalToneAnalyzer _emotionAnalyzer = EmotionalToneAnalyzer();
  final PersonalityEngine _personality = PersonalityEngine();

  factory DataRichNarrativeBuilder() => _instance;
  DataRichNarrativeBuilder._internal();

  /// Build complete narrative from daily context
  ///
  /// Generates 150-300 word narrative with:
  /// - Opening with time/location context
  /// - Chronological event descriptions
  /// - Natural transitions based on time/distance
  /// - Closing with day summary stats
  /// - Tone-aware language based on emotional analysis
  Future<String> buildNarrative({
    required DailyContext context,
  }) async {
    try {
      final events = context.timelineEvents;

      if (events.isEmpty) {
        return _buildEmptyDayNarrative(context);
      }

      // Filter to significant events only
      final significantEvents = events.where((e) => e.isSignificant).toList();

      if (significantEvents.isEmpty) {
        return _buildQuietDayNarrative(context);
      }

      // Analyze emotional tone of the day
      final emotionalProfile = _emotionAnalyzer.analyzeDay(context);

      final narrative = StringBuffer();

      // 1. Opening with time/location context (tone-adjusted)
      final opening = _buildOpening(significantEvents, context);
      final tonedOpening = _personality.adjustOpening(opening, emotionalProfile);
      narrative.write(tonedOpening);
      narrative.write(' ');

      // 2. Event descriptions with transitions (tone-adjusted)
      narrative.write(_buildEventSequence(significantEvents, context, emotionalProfile));

      // 3. Closing with day summary stats (tone-adjusted)
      narrative.write(' ');
      final closing = _buildClosing(significantEvents, context);
      final tonedClosing = _personality.adjustClosing(closing, emotionalProfile);
      narrative.write(tonedClosing);

      final result = narrative.toString();

      _logger.info('Generated narrative: ${result.split(' ').length} words, '
                  'tone: ${emotionalProfile.primaryTone.name}, '
                  'profile: ${emotionalProfile.summary}');

      return result;
    } catch (e, stackTrace) {
      _logger.error('Error building narrative: $e', error: e, stackTrace: stackTrace);
      return _buildFallbackNarrative(context);
    }
  }

  /// Build opening sentence with enhanced context
  String _buildOpening(List<NarrativeEvent> events, DailyContext context) {
    final firstEvent = events.first;
    final date = firstEvent.timestamp;

    // Try to get first location
    String? firstLocation;
    if (firstEvent.placeName != null) {
      firstLocation = firstEvent.placeName;
    } else {
      // Look for first location event
      final firstLocationEvent = events.firstWhere(
        (e) => e.placeName != null,
        orElse: () => firstEvent,
      );
      firstLocation = firstLocationEvent.placeName;
    }

    // Enhanced opening with weather/mood context
    String opening = _phraseGen.generateOpening(
      date: date,
      firstLocation: firstLocation,
    );

    // Add contextual richness based on time of day and location diversity
    final hour = firstEvent.timestamp.hour;
    if (hour < 6) {
      opening = 'The day began in the quiet hours before dawn. $opening';
    } else if (hour >= 6 && hour < 9) {
      opening = 'Morning light brought a fresh start. $opening';
    } else if (hour >= 18 && hour < 21) {
      opening = 'As evening settled in, $opening';
    }

    // Add activity context if day was notably active
    if (context.locationSummary.totalKilometers > 10) {
      opening = '$opening The day promised movement and exploration.';
    } else if (context.locationSummary.significantPlaces.length > 3) {
      opening = '$opening Multiple destinations awaited.';
    }

    return opening;
  }

  /// Build sequence of events with transitions (tone-adjusted)
  String _buildEventSequence(
    List<NarrativeEvent> events,
    DailyContext context,
    EmotionalProfile emotionalProfile,
  ) {
    final sentences = <String>[];
    NarrativeEvent? previousEvent;

    for (var i = 0; i < events.length; i++) {
      final event = events[i];

      // Add transition if not first event
      if (previousEvent != null) {
        final transition = _generateTransition(previousEvent, event, context, emotionalProfile);
        if (transition.isNotEmpty) {
          sentences.add(transition);
        }
      }

      // Add event description
      final description = _describeEvent(event, context);
      if (description.isNotEmpty) {
        sentences.add(description);
      }

      previousEvent = event;
    }

    return sentences.join(' ');
  }

  /// Generate transition between events (tone-adjusted)
  String _generateTransition(
    NarrativeEvent from,
    NarrativeEvent to,
    DailyContext context,
    EmotionalProfile emotionalProfile,
  ) {
    final timeDiff = to.timestamp.difference(from.timestamp);

    // Calculate distance if both have locations
    double? distance;
    if (from.latitude != null && from.longitude != null &&
        to.latitude != null && to.longitude != null) {
      distance = _calculateDistance(
        from.latitude!, from.longitude!,
        to.latitude!, to.longitude!,
      );
    }

    final baseTransition = _phraseGen.generateTransition(
      timeDiff: timeDiff,
      distanceMeters: distance,
      fromLocation: from.placeName,
      toLocation: to.placeName,
    );

    // Adjust transition based on emotional tone
    final transitionPhrase = _personality.adjustTransition(baseTransition, emotionalProfile);

    // Add movement description if significant distance
    if (distance != null && distance > 100) {
      final movement = _phraseGen.generateMovementPhrase(
        distance,
        movementModes: context.locationSummary.movementModes,
      );
      return '$transitionPhrase, I $movement';
    }

    return transitionPhrase;
  }

  /// Describe individual event
  String _describeEvent(NarrativeEvent event, DailyContext context) {
    switch (event.type) {
      case NarrativeEventType.calendar:
        return _describeCalendarEvent(event);

      case NarrativeEventType.photo:
        return _describePhotoEvent(event);

      case NarrativeEventType.location:
        return _describeLocationEvent(event);

      case NarrativeEventType.activity:
        return ''; // Skip activity events (background noise)

      case NarrativeEventType.movement:
        return ''; // Movement handled in transitions
    }
  }

  /// Describe calendar event with enhanced details
  String _describeCalendarEvent(NarrativeEvent event) {
    if (event.meetingTitle == null) return '';

    final phrase = _phraseGen.generateCalendarPhrase(
      title: event.meetingTitle!,
      attendees: event.attendees,
      isAllDay: event.isAllDay,
    );

    // Build richer description with attendee context
    final buffer = StringBuffer();
    buffer.write('I $phrase');

    // Add attendee details for social context
    if (event.attendees != null && event.attendees!.isNotEmpty) {
      final attendeeCount = event.attendees!.length;
      if (attendeeCount == 1) {
        buffer.write(' with ${event.attendees!.first}');
      } else if (attendeeCount <= 3) {
        buffer.write(' with ${event.attendees!.join(', ')}');
      } else {
        buffer.write(' with $attendeeCount people');
      }
    }

    // Add location if available
    if (event.placeName != null) {
      buffer.write(' at ${event.placeName}');
    }

    // Add duration context for longer meetings
    if (event.duration != null && event.duration!.inMinutes > 30) {
      final hours = event.duration!.inHours;
      final minutes = event.duration!.inMinutes % 60;
      if (hours > 0) {
        buffer.write(', spanning ${hours}h ${minutes}m');
      }
    }

    buffer.write('.');
    return buffer.toString();
  }

  /// Describe photo event with richer context
  String _describePhotoEvent(NarrativeEvent event) {
    final phrase = _phraseGen.generatePhotoPhrase(
      objects: event.objectsSeen ?? [],
      scene: event.sceneDescription,
      peopleCount: event.peopleCount,
    );

    // Build vivid description with sensory details
    final buffer = StringBuffer();

    // Add location context with vivid phrasing
    if (event.placeName != null) {
      // Vary the location introduction for naturalness
      final locationIntros = [
        'At ${event.placeName}',
        'While at ${event.placeName}',
        'Finding myself at ${event.placeName}',
      ];
      final intro = locationIntros[event.timestamp.minute % locationIntros.length];
      buffer.write('$intro, ');
    }

    buffer.write('I $phrase');

    // Add vivid scene description if available
    if (event.sceneDescription != null && event.sceneDescription!.isNotEmpty) {
      if (!phrase.toLowerCase().contains(event.sceneDescription!.toLowerCase())) {
        buffer.write('. ${event.sceneDescription} filled the scene');
      }
    }

    // Add object context
    if (event.objectsSeen != null && event.objectsSeen!.isNotEmpty) {
      final objects = event.objectsSeen!.take(3).toList();
      if (!phrase.contains(objects.join(', '))) {
        if (objects.length == 1) {
          buffer.write(', with ${objects[0]} visible');
        } else if (objects.length == 2) {
          buffer.write(', with ${objects[0]} and ${objects[1]} in view');
        } else {
          buffer.write(', showing ${objects[0]}, ${objects[1]}, and ${objects[2]}');
        }
      }
    }

    // Add people context
    if (event.peopleCount != null && event.peopleCount! > 0) {
      if (event.peopleCount == 1) {
        buffer.write('. One person was present');
      } else if (event.peopleCount! <= 3) {
        buffer.write('. ${event.peopleCount} people were present');
      } else {
        buffer.write('. ${event.peopleCount} people were in the area');
      }
    }

    buffer.write('.');
    return buffer.toString();
  }

  /// Describe location event
  String _describeLocationEvent(NarrativeEvent event) {
    if (event.placeName == null) return '';

    final arrival = _phraseGen.generateArrivalPhrase(event.placeName!);

    // Add dwell time if available
    if (event.duration != null && event.duration!.inMinutes > 5) {
      final dwell = _phraseGen.generateDwellPhrase(event.duration!, null);
      return 'I $arrival and $dwell.';
    } else {
      return 'I $arrival.';
    }
  }

  /// Build closing summary
  String _buildClosing(List<NarrativeEvent> events, DailyContext context) {
    // Count event types
    final photoCount = events.where((e) => e.type == NarrativeEventType.photo).length;
    final calendarCount = events.where((e) => e.type == NarrativeEventType.calendar).length;
    final locationCount = context.locationSummary.significantPlaces.length;

    // Get distance from context
    final totalKm = context.locationSummary.totalKilometers;

    // Build factual closing summary
    final buffer = StringBuffer();

    // Add summary transition
    buffer.write('Throughout the day, ');

    // Start with base closing
    final baseClosing = _phraseGen.generateClosing(
      eventCount: events.length,
      totalKilometers: totalKm,
      photoCount: photoCount,
      calendarEventCount: calendarCount,
    );
    buffer.write(baseClosing.toLowerCase()); // lowercase since we added "Throughout the day, "

    // Add location context
    if (locationCount > 3) {
      buffer.write(' The route covered $locationCount distinct locations.');
    } else if (locationCount == 3) {
      final places = context.locationSummary.significantPlaces.take(3).toList();
      buffer.write(' The route included ${places[0]}, ${places[1]}, and ${places[2]}.');
    } else if (locationCount == 2) {
      final places = context.locationSummary.significantPlaces.toList();
      buffer.write(' Time was split between ${places[0]} and ${places[1]}.');
    } else if (locationCount == 1) {
      buffer.write(' All activities occurred at ${context.locationSummary.significantPlaces.first}.');
    }

    // Add activity summary
    if (context.activitySummary.primaryActivities.isNotEmpty) {
      final activities = context.activitySummary.primaryActivities.take(2).toList();
      if (activities.length == 1) {
        buffer.write(' The main activity was ${activities[0]}.');
      } else {
        buffer.write(' Activities included ${activities.join(' and ')}.');
      }
    }

    // Add social context
    if (context.socialSummary.totalPeopleDetected > 0) {
      if (context.socialSummary.totalPeopleDetected == 1) {
        buffer.write(' One other person was detected.');
      } else if (context.socialSummary.totalPeopleDetected <= 5) {
        buffer.write(' ${context.socialSummary.totalPeopleDetected} people were detected.');
      } else {
        buffer.write(' ${context.socialSummary.totalPeopleDetected} people were present at various times.');
      }
    }

    // Add distance summary if notable
    if (totalKm > 20) {
      buffer.write(' Total distance traveled was ${ totalKm.toStringAsFixed(1)} kilometers.');
    } else if (totalKm > 5) {
      buffer.write(' Distance covered: ${ totalKm.toStringAsFixed(1)} kilometers.');
    }

    return buffer.toString();
  }

  /// Build narrative for empty day
  String _buildEmptyDayNarrative(DailyContext context) {
    final date = context.date;
    final dayName = _phraseGen.getDayOfWeek(date);

    return '$dayName had minimal recorded activity. '
           'No significant events or locations were captured.';
  }

  /// Build narrative for quiet day (events but not significant)
  String _buildQuietDayNarrative(DailyContext context) {
    final date = context.date;
    final dayName = _phraseGen.getDayOfWeek(date);

    if (context.locationSummary.totalKilometers > 0) {
      final km = context.locationSummary.totalKilometers.toStringAsFixed(1);
      return '$dayName had limited recorded activity. I traveled $km km, '
             'staying mostly in familiar areas.';
    } else {
      return '$dayName was spent primarily in one location. '
             'No significant travel or movement was recorded.';
    }
  }

  /// Build fallback narrative on error
  String _buildFallbackNarrative(DailyContext context) {
    final date = context.date;
    final dayName = _phraseGen.getDayOfWeek(date);

    return '$dayName occurred but detailed data could not be processed. '
           'Limited information is available for this date.';
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.cos(_degreesToRadians(lat1)) *
              math.cos(_degreesToRadians(lat2)) *
              math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
