import '../utils/logger.dart';

/// Generates contextual transition phrases based on time, distance, and activity
///
/// Creates natural narrative flow by selecting appropriate phrases for transitions
/// between timeline events considering temporal and spatial relationships.
class ContextualPhraseGenerator {
  static final _logger = AppLogger('ContextualPhraseGenerator');
  static final ContextualPhraseGenerator _instance = ContextualPhraseGenerator._internal();

  factory ContextualPhraseGenerator() => _instance;
  ContextualPhraseGenerator._internal();

  /// Generate opening phrase based on time of day
  String generateOpening({
    required DateTime date,
    String? firstLocation,
  }) {
    final hour = date.hour;
    final dayOfWeek = getDayOfWeek(date);

    if (firstLocation != null) {
      return _openingWithLocation(hour, dayOfWeek, firstLocation);
    } else {
      return _openingWithoutLocation(hour, dayOfWeek);
    }
  }

  String _openingWithLocation(int hour, String dayOfWeek, String location) {
    if (hour >= 5 && hour < 8) {
      return 'Early $dayOfWeek morning began at $location.';
    } else if (hour >= 8 && hour < 12) {
      return '$dayOfWeek started at $location.';
    } else if (hour >= 12 && hour < 17) {
      return 'This $dayOfWeek afternoon found me at $location.';
    } else if (hour >= 17 && hour < 21) {
      return 'The $dayOfWeek evening began at $location.';
    } else {
      return '$dayOfWeek started quietly at $location.';
    }
  }

  String _openingWithoutLocation(int hour, String dayOfWeek) {
    if (hour >= 5 && hour < 8) {
      return 'Early $dayOfWeek morning began with quiet reflection.';
    } else if (hour >= 8 && hour < 12) {
      return '$dayOfWeek started with a calm beginning.';
    } else if (hour >= 12 && hour < 17) {
      return 'This $dayOfWeek afternoon unfolded peacefully.';
    } else if (hour >= 17 && hour < 21) {
      return 'The $dayOfWeek evening arrived gently.';
    } else {
      return '$dayOfWeek began in stillness.';
    }
  }

  /// Generate transition phrase based on distance and time
  String generateTransition({
    required Duration timeDiff,
    double? distanceMeters,
    String? fromLocation,
    String? toLocation,
  }) {
    final minutes = timeDiff.inMinutes;
    final hours = timeDiff.inHours;

    // Time-based transitions
    if (minutes < 5) {
      return 'Moments later';
    } else if (minutes < 15) {
      return 'Shortly after';
    } else if (minutes < 30) {
      return 'A little while later';
    } else if (minutes < 60) {
      return 'Some time later';
    } else if (hours < 2) {
      return 'An hour later';
    } else if (hours < 4) {
      return 'A few hours later';
    } else {
      return 'Later that day';
    }
  }

  /// Generate movement phrase based on distance traveled
  String generateMovementPhrase(double meters, {List<String>? movementModes}) {
    final km = meters / 1000;

    // Determine primary transportation mode from flutter_background_geolocation activity types
    // Activity types: still, stationary, on_foot, walking, running, in_vehicle, on_bicycle
    String? mode;
    if (movementModes != null && movementModes.isNotEmpty) {
      // Prioritize: in_vehicle > running > walking/on_foot > on_bicycle > stationary/still
      if (movementModes.contains('in_vehicle')) {
        mode = 'driving';
      } else if (movementModes.contains('running')) {
        mode = 'running';
      } else if (movementModes.contains('walking') || movementModes.contains('on_foot')) {
        mode = 'walking';
      } else if (movementModes.contains('on_bicycle')) {
        mode = 'cycling';
      }
    }

    if (km < 0.1) {
      return 'stayed nearby';
    } else if (km < 0.5) {
      return mode == 'running' ? 'ran a short distance' : 'walked a short distance';
    } else if (km < 2) {
      if (mode == 'driving') {
        return 'drove ${km.toStringAsFixed(1)}km';
      } else if (mode == 'running') {
        return 'ran ${km.toStringAsFixed(1)}km';
      } else if (mode == 'cycling') {
        return 'cycled ${km.toStringAsFixed(1)}km';
      } else {
        return 'walked ${km.toStringAsFixed(1)}km';
      }
    } else if (km < 10) {
      if (mode == 'driving') {
        return 'drove ${km.toStringAsFixed(1)}km';
      } else if (mode == 'running') {
        return 'ran ${km.toStringAsFixed(0)}km';
      } else if (mode == 'cycling') {
        return 'cycled ${km.toStringAsFixed(1)}km';
      } else {
        return 'journeyed ${km.toStringAsFixed(1)}km';
      }
    } else {
      if (mode == 'driving') {
        return 'drove ${km.toStringAsFixed(0)}km';
      } else {
        return 'covered ${km.toStringAsFixed(0)}km';
      }
    }
  }

  /// Generate location arrival phrase
  String generateArrivalPhrase(String placeName) {
    final phrases = [
      'arrived at $placeName',
      'reached $placeName',
      'found myself at $placeName',
      'made my way to $placeName',
      'visited $placeName',
    ];

    // Deterministic selection based on place name hash
    final index = placeName.hashCode.abs() % phrases.length;
    return phrases[index];
  }

  /// Generate activity phrase based on dwell time
  String generateDwellPhrase(Duration duration, String? activity) {
    final minutes = duration.inMinutes;
    final hours = duration.inHours;

    String timePhrase;
    if (minutes < 15) {
      timePhrase = 'briefly';
    } else if (minutes < 30) {
      timePhrase = 'for a while';
    } else if (minutes < 60) {
      timePhrase = 'for some time';
    } else if (hours < 2) {
      timePhrase = 'for about an hour';
    } else {
      timePhrase = 'for $hours hours';
    }

    if (activity != null) {
      return 'spent $timePhrase $activity';
    } else {
      return 'stayed $timePhrase';
    }
  }

  /// Generate photo observation phrase
  String generatePhotoPhrase({
    required List<String> objects,
    String? scene,
    int? peopleCount,
  }) {
    final parts = <String>[];

    if (peopleCount != null && peopleCount > 0) {
      if (peopleCount == 1) {
        parts.add('captured a moment with someone special');
      } else {
        parts.add('captured a moment with $peopleCount people');
      }
    }

    if (objects.isNotEmpty) {
      final topObjects = objects.take(2).toList();
      if (topObjects.length == 1) {
        parts.add('photographed ${_articleFor(topObjects[0])} ${topObjects[0]}');
      } else {
        parts.add('photographed ${topObjects.join(" and ")}');
      }
    }

    if (scene != null && parts.isEmpty) {
      parts.add('captured the $scene');
    }

    if (parts.isEmpty) {
      return 'took a photo';
    }

    return parts.first;
  }

  /// Generate calendar event phrase
  String generateCalendarPhrase({
    required String title,
    List<String>? attendees,
    bool? isAllDay,
  }) {
    if (isAllDay == true) {
      return 'observed $title all day';
    }

    if (attendees != null && attendees.isNotEmpty) {
      if (attendees.length == 1) {
        return 'met for $title with ${attendees.first}';
      } else if (attendees.length <= 3) {
        return 'met for $title with ${attendees.join(", ")}';
      } else {
        return 'met for $title with ${attendees.length} others';
      }
    }

    return 'attended $title';
  }

  /// Generate closing summary phrase
  String generateClosing({
    required int eventCount,
    required double totalKilometers,
    required int photoCount,
    required int calendarEventCount,
  }) {
    final parts = <String>[];

    // Distance summary
    if (totalKilometers > 0) {
      if (totalKilometers < 1) {
        parts.add('stayed local');
      } else if (totalKilometers < 5) {
        parts.add('traveled ${totalKilometers.toStringAsFixed(1)}km');
      } else {
        parts.add('covered ${totalKilometers.toStringAsFixed(0)}km');
      }
    }

    // Photo summary
    if (photoCount > 0) {
      if (photoCount == 1) {
        parts.add('captured 1 memory');
      } else {
        parts.add('captured $photoCount memories');
      }
    }

    // Calendar summary
    if (calendarEventCount > 0) {
      if (calendarEventCount == 1) {
        parts.add('attended 1 event');
      } else {
        parts.add('attended $calendarEventCount events');
      }
    }

    if (parts.isEmpty) {
      return 'A quiet day of rest and reflection.';
    } else if (parts.length == 1) {
      return 'A day where I ${parts[0]}.';
    } else {
      final last = parts.removeLast();
      return 'A day where I ${parts.join(", ")} and $last.';
    }
  }

  /// Get day of week name
  String getDayOfWeek(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  /// Get appropriate article for a noun
  String _articleFor(String noun) {
    final lower = noun.toLowerCase();
    final vowels = {'a', 'e', 'i', 'o', 'u'};

    if (vowels.contains(lower[0])) {
      return 'an';
    } else {
      return 'a';
    }
  }

  /// Generate time-of-day phrase
  String getTimeOfDayPhrase(DateTime time) {
    final hour = time.hour;

    if (hour >= 5 && hour < 8) {
      return 'early morning';
    } else if (hour >= 8 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 14) {
      return 'midday';
    } else if (hour >= 14 && hour < 17) {
      return 'afternoon';
    } else if (hour >= 17 && hour < 20) {
      return 'evening';
    } else if (hour >= 20 && hour < 22) {
      return 'late evening';
    } else {
      return 'night';
    }
  }

  /// Format time for narrative (e.g., "9:30am")
  String formatTimeForNarrative(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute$period';
  }
}
