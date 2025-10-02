import 'dart:math' as math;
import '../services/timeline_event_aggregator.dart';
import '../services/daily_context_synthesizer.dart';
import '../utils/logger.dart';
import 'contextual_phrase_generator.dart';

/// Builds rich contextual narratives from timeline events and daily context
///
/// Weaves together timeline events (calendar, photos, locations) with
/// contextual data (place names, objects, distances) into a coherent
/// chronological narrative with natural transitions.
class DataRichNarrativeBuilder {
  static final _logger = AppLogger('DataRichNarrativeBuilder');
  static final DataRichNarrativeBuilder _instance = DataRichNarrativeBuilder._internal();

  final ContextualPhraseGenerator _phraseGen = ContextualPhraseGenerator();

  factory DataRichNarrativeBuilder() => _instance;
  DataRichNarrativeBuilder._internal();

  /// Build complete narrative from daily context
  ///
  /// Generates 150-300 word narrative with:
  /// - Opening with time/location context
  /// - Chronological event descriptions
  /// - Natural transitions based on time/distance
  /// - Closing with day summary stats
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

      final narrative = StringBuffer();

      // 1. Opening with time/location context
      narrative.write(_buildOpening(significantEvents, context));
      narrative.write(' ');

      // 2. Event descriptions with transitions
      narrative.write(_buildEventSequence(significantEvents, context));

      // 3. Closing with day summary stats
      narrative.write(' ');
      narrative.write(_buildClosing(significantEvents, context));

      final result = narrative.toString();

      _logger.info('Generated narrative: ${result.split(' ').length} words');

      return result;
    } catch (e, stackTrace) {
      _logger.error('Error building narrative: $e', error: e, stackTrace: stackTrace);
      return _buildFallbackNarrative(context);
    }
  }

  /// Build opening sentence
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

    return _phraseGen.generateOpening(
      date: date,
      firstLocation: firstLocation,
    );
  }

  /// Build sequence of events with transitions
  String _buildEventSequence(List<NarrativeEvent> events, DailyContext context) {
    final sentences = <String>[];
    NarrativeEvent? previousEvent;

    for (var i = 0; i < events.length; i++) {
      final event = events[i];

      // Add transition if not first event
      if (previousEvent != null) {
        final transition = _generateTransition(previousEvent, event);
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

  /// Generate transition between events
  String _generateTransition(NarrativeEvent from, NarrativeEvent to) {
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

    final transitionPhrase = _phraseGen.generateTransition(
      timeDiff: timeDiff,
      distanceMeters: distance,
      fromLocation: from.placeName,
      toLocation: to.placeName,
    );

    // Add movement description if significant distance
    if (distance != null && distance > 100) {
      final movement = _phraseGen.generateMovementPhrase(distance);
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

  /// Describe calendar event
  String _describeCalendarEvent(NarrativeEvent event) {
    if (event.meetingTitle == null) return '';

    final phrase = _phraseGen.generateCalendarPhrase(
      title: event.meetingTitle!,
      attendees: event.attendees,
      isAllDay: event.isAllDay,
    );

    // Add location if available
    if (event.placeName != null) {
      return 'I $phrase at ${event.placeName}.';
    } else {
      return 'I $phrase.';
    }
  }

  /// Describe photo event
  String _describePhotoEvent(NarrativeEvent event) {
    final phrase = _phraseGen.generatePhotoPhrase(
      objects: event.objectsSeen ?? [],
      scene: event.sceneDescription,
      peopleCount: event.peopleCount,
    );

    // Add location context if available
    if (event.placeName != null) {
      return 'At ${event.placeName}, I $phrase.';
    } else {
      return 'I $phrase.';
    }
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

    // Get distance from context
    final totalKm = context.locationSummary.totalKilometers;

    return _phraseGen.generateClosing(
      eventCount: events.length,
      totalKilometers: totalKm,
      photoCount: photoCount,
      calendarEventCount: calendarCount,
    );
  }

  /// Build narrative for empty day
  String _buildEmptyDayNarrative(DailyContext context) {
    final date = context.date;
    final dayName = _phraseGen._getDayOfWeek(date);

    return '$dayName was a quiet day of rest and reflection. '
           'Sometimes the most meaningful moments are found in stillness.';
  }

  /// Build narrative for quiet day (events but not significant)
  String _buildQuietDayNarrative(DailyContext context) {
    final date = context.date;
    final dayName = _phraseGen._getDayOfWeek(date);

    if (context.locationSummary.totalKilometers > 0) {
      final km = context.locationSummary.totalKilometers.toStringAsFixed(1);
      return '$dayName unfolded peacefully. I traveled $km km, moving through the day with quiet purpose. '
             'A day of simple presence.';
    } else {
      return '$dayName passed in gentle quietude. I remained close to home, finding contentment in the familiar. '
             'A day of peaceful stillness.';
    }
  }

  /// Build fallback narrative on error
  String _buildFallbackNarrative(DailyContext context) {
    final date = context.date;
    final dayName = _phraseGen._getDayOfWeek(date);

    return '$dayName brought its own unique rhythm. Though the details blur, '
           'the day held its own quiet significance.';
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
