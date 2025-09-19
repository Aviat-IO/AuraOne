import 'package:flutter/foundation.dart';

/// On-device AI service for journal generation without any backend calls
/// Uses data-driven content generation for factual journal entries
class OnDeviceAIService {

  OnDeviceAIService();

  /// Generate a journal entry based on provided context (completely on-device)
  Future<Map<String, dynamic>> generateJournalEntry(Map<String, dynamic> context) async {
    try {
      // Simulate processing time for realistic UX
      await Future.delayed(const Duration(milliseconds: 800));

      final date = context['date'] ?? DateTime.now().toIso8601String();

      // Extract rich context from provided data with safe casting
      final photos = _safeListCast(context['photos']);
      final locations = _safeListCast(context['locations']);
      final calendarEvents = _safeListCast(context['calendarEvents']);
      final movements = _safeListCast(context['movements']);
      final clusters = _safeListCast(context['locationClusters']);

      // Legacy fallback for backward compatibility
      final photosCount = context['photosCount'] as int? ?? photos.length;
      final locationsCount = context['locationsCount'] as int? ?? locations.length;
      final simpleCalendarEvents = context['calendarEvents'] is List<String>
          ? context['calendarEvents'] as List<String>
          : calendarEvents.map((e) => e['title'] as String? ?? 'Event').toList();

      // Generate rich, compelling narrative with all context
      final content = _generateCompellingNarrative(
        date: date,
        photos: photos,
        locations: locations,
        calendarEvents: calendarEvents,
        movements: movements,
        locationClusters: clusters,
        photosCount: photosCount,
        locationsCount: locationsCount,
      );

      // Create an engaging summary
      final summary = _generateEngagingSummary(
        photos: photos,
        locations: locations,
        calendarEvents: calendarEvents,
        movements: movements,
        clusters: clusters,
      );

      debugPrint('OnDevice AI: Generated compelling journal entry for $date');

      return {
        'content': content,
        'summary': summary,
        'generated_on_device': true,
      };
    } catch (e) {
      debugPrint('OnDevice AI: Error generating journal entry - $e');
      return {
        'content': _getFallbackContent(),
        'summary': 'Daily reflection',
        'generated_on_device': true,
      };
    }
  }

  /// Generate a contextual summary for text content
  Future<String> generateSummary(String content) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final words = content.split(' ');
    if (words.length < 20) {
      return 'Brief daily reflection';
    }

    // Extract key themes from content
    final themes = _extractThemes(content);
    if (themes.isNotEmpty) {
      return 'Reflection on ${themes.join(', ')}';
    }

    return 'Personal insights and reflections';
  }

  /// Enhanced text processing for contextual understanding
  Future<String> processText(String text) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // On-device text enhancement without external calls
    if (text.trim().isEmpty) return text;

    // Basic enhancement: proper capitalization and punctuation
    final sentences = text.split(RegExp(r'[.!?]+'));
    final enhanced = sentences.map((sentence) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) return '';

      // Capitalize first letter
      final capitalized = trimmed[0].toUpperCase() + trimmed.substring(1);
      return capitalized;
    }).where((s) => s.isNotEmpty).join('. ');

    return enhanced.endsWith('.') ? enhanced : '$enhanced.';
  }

  String _generateCompellingNarrative({
    required String date,
    required List<Map<String, dynamic>> photos,
    required List<Map<String, dynamic>> locations,
    required List<Map<String, dynamic>> calendarEvents,
    required List<Map<String, dynamic>> movements,
    required List<Map<String, dynamic>> locationClusters,
    required int photosCount,
    required int locationsCount,
  }) {
    final List<String> narrativeParts = [];
    final dateObj = DateTime.tryParse(date) ?? DateTime.now();
    final dateStr = _formatDate(dateObj);

    // Start with an engaging opening
    narrativeParts.add('# $dateStr\n');

    // Create time-based narrative structure
    final morning = <String>[];
    final afternoon = <String>[];
    final evening = <String>[];

    // Process calendar events with rich context
    if (calendarEvents.isNotEmpty) {
      narrativeParts.add('## Your Day\'s Journey\n');

      for (final event in calendarEvents) {
        final title = event['title'] ?? 'Event';
        final startTime = event['startTime'] != null
            ? DateTime.tryParse(event['startTime'].toString())
            : null;
        final location = event['location'];
        final attendees = event['attendees'] as List<String>? ?? [];

        String eventNarrative = '';
        if (startTime != null) {
          final hour = startTime.hour;
          if (hour < 12) {
            eventNarrative = 'Your morning began with $title';
          } else if (hour < 17) {
            eventNarrative = 'The afternoon brought $title';
          } else {
            eventNarrative = 'Your evening included $title';
          }

          if (location != null && location.toString().isNotEmpty) {
            eventNarrative += ' at $location';
          }

          if (attendees.isNotEmpty) {
            if (attendees.length == 1) {
              eventNarrative += ', connecting with ${attendees.first}';
            } else if (attendees.length == 2) {
              eventNarrative += ', bringing together ${attendees.join(' and ')}';
            } else {
              eventNarrative += ', gathering with ${attendees.length} people';
            }
          }

          eventNarrative += '.';

          // Add to appropriate time section
          if (hour < 12) {
            morning.add(eventNarrative);
          } else if (hour < 17) {
            afternoon.add(eventNarrative);
          } else {
            evening.add(eventNarrative);
          }
        } else {
          narrativeParts.add('• $title occurred during your day.');
        }
      }
    }

    // Process location clusters for meaningful place narratives
    if (locationClusters.isNotEmpty) {
      narrativeParts.add('\n## Places That Shaped Your Day\n');

      for (final cluster in locationClusters) {
        final placeName = cluster['name'] ?? cluster['address'] ?? 'A familiar place';
        final duration = cluster['duration'] as int? ?? 0;
        final visitCount = cluster['visitCount'] as int? ?? 1;
        final timeOfDay = cluster['timeOfDay'] as String?;

        String placeNarrative = '';

        if (duration > 60) {
          final hours = duration ~/ 60;
          placeNarrative = 'You spent ${hours} hour${hours > 1 ? 's' : ''} at $placeName';
        } else if (duration > 30) {
          placeNarrative = 'You had a meaningful visit to $placeName';
        } else if (duration > 5) {
          placeNarrative = 'You stopped by $placeName';
        } else {
          placeNarrative = 'You passed through $placeName';
        }

        if (visitCount > 1) {
          placeNarrative += ', returning $visitCount times throughout the day';
        }

        if (timeOfDay != null) {
          placeNarrative += ' during the $timeOfDay';
        }

        narrativeParts.add('$placeNarrative.');
      }
    }

    // Process photos with rich metadata
    if (photos.isNotEmpty) {
      narrativeParts.add('\n## Moments Captured\n');

      final photosByLocation = <String, List<Map<String, dynamic>>>{};
      final photosByTime = <String, List<Map<String, dynamic>>>{};

      for (final photo in photos) {
        final location = photo['location'] as String? ?? 'Unknown location';
        final timestamp = photo['timestamp'] != null
            ? DateTime.tryParse(photo['timestamp'].toString())
            : null;

        photosByLocation.putIfAbsent(location, () => []).add(photo);

        if (timestamp != null) {
          final timeKey = timestamp.hour < 12 ? 'morning'
              : timestamp.hour < 17 ? 'afternoon'
              : 'evening';
          photosByTime.putIfAbsent(timeKey, () => []).add(photo);
        }
      }

      // Create photo narrative
      if (photos.length == 1) {
        narrativeParts.add('You captured a single moment today, preserving a memory that stood out.');
      } else if (photos.length < 5) {
        narrativeParts.add('You documented ${photos.length} special moments, each telling part of your story.');
      } else if (photos.length < 20) {
        narrativeParts.add('Your camera was active today, capturing ${photos.length} moments across your journey.');
      } else {
        narrativeParts.add('You extensively documented today with ${photos.length} photos, creating a rich visual diary.');
      }

      // Add location-based photo insights
      if (photosByLocation.length > 1) {
        final topLocation = photosByLocation.entries
            .reduce((a, b) => a.value.length > b.value.length ? a : b);
        if (topLocation.value.length > 3) {
          narrativeParts.add('${topLocation.key} was particularly photogenic, inspiring ${topLocation.value.length} captures.');
        }
      }
    }

    // Process movement patterns
    if (movements.isNotEmpty) {
      narrativeParts.add('\n## Your Movement Story\n');

      int totalSteps = 0;
      double totalDistance = 0;
      int activeMinutes = 0;

      for (final movement in movements) {
        totalSteps += (movement['steps'] as int? ?? 0);
        totalDistance += (movement['distance'] as double? ?? 0.0);
        activeMinutes += (movement['activeMinutes'] as int? ?? 0);
      }

      if (totalSteps > 10000) {
        narrativeParts.add('An impressively active day with ${totalSteps.toStringAsFixed(0)} steps covering ${(totalDistance / 1000).toStringAsFixed(1)} kilometers.');
      } else if (totalSteps > 5000) {
        narrativeParts.add('You stayed moderately active with ${totalSteps.toStringAsFixed(0)} steps throughout the day.');
      } else if (totalSteps > 0) {
        narrativeParts.add('A quieter day physically, with ${totalSteps.toStringAsFixed(0)} steps taken.');
      }

      if (activeMinutes > 30) {
        narrativeParts.add('You achieved ${activeMinutes} minutes of active movement, contributing to your wellness.');
      }
    }

    // Compile time-based sections if they exist
    if (morning.isNotEmpty || afternoon.isNotEmpty || evening.isNotEmpty) {
      narrativeParts.add('\n## The Flow of Your Day\n');

      if (morning.isNotEmpty) {
        narrativeParts.add('### Morning');
        narrativeParts.addAll(morning);
      }

      if (afternoon.isNotEmpty) {
        narrativeParts.add('\n### Afternoon');
        narrativeParts.addAll(afternoon);
      }

      if (evening.isNotEmpty) {
        narrativeParts.add('\n### Evening');
        narrativeParts.addAll(evening);
      }
    }

    // Add a reflective closing if we have enough content
    if (narrativeParts.length > 3) {
      narrativeParts.add('\n---\n');
      narrativeParts.add(_generateReflectiveClosing(
        photosCount: photos.length,
        placesCount: locationClusters.length,
        eventsCount: calendarEvents.length,
        wasActive: movements.isNotEmpty,
      ));
    }

    // If still minimal content, use legacy generation as fallback
    if (narrativeParts.length <= 2) {
      return _generateDataDrivenContent(photosCount, locationsCount,
          calendarEvents.map((e) => e['title']?.toString() ?? 'Event').toList(), date);
    }

    return narrativeParts.join('\n').trim();
  }

  String _generateEngagingSummary({
    required List<Map<String, dynamic>> photos,
    required List<Map<String, dynamic>> locations,
    required List<Map<String, dynamic>> calendarEvents,
    required List<Map<String, dynamic>> movements,
    required List<Map<String, dynamic>> clusters,
  }) {
    final highlights = <String>[];

    // Key events
    if (calendarEvents.isNotEmpty) {
      final keyEvent = calendarEvents.first['title'] ?? 'Key events';
      highlights.add(keyEvent.toString());
    }

    // Notable places
    if (clusters.isNotEmpty) {
      final significantPlaces = clusters
          .where((c) => (c['duration'] as int? ?? 0) > 30)
          .length;
      if (significantPlaces > 0) {
        highlights.add('$significantPlaces meaningful place${significantPlaces > 1 ? 's' : ''}');
      }
    }

    // Photo moments
    if (photos.length > 5) {
      highlights.add('${photos.length} captured moments');
    }

    // Activity level
    if (movements.isNotEmpty) {
      final totalSteps = movements.fold(0, (sum, m) => sum + (m['steps'] as int? ?? 0));
      if (totalSteps > 5000) {
        highlights.add('active day');
      }
    }

    if (highlights.isEmpty) {
      return 'A day in your journey';
    } else if (highlights.length == 1) {
      return 'A day marked by ${highlights.first}';
    } else {
      final lastHighlight = highlights.removeLast();
      return 'A day of ${highlights.join(', ')} and $lastHighlight';
    }
  }

  String _generateReflectiveClosing({
    required int photosCount,
    required int placesCount,
    required int eventsCount,
    required bool wasActive,
  }) {
    final reflections = <String>[];

    if (photosCount > 10 && placesCount > 3) {
      reflections.add('Today was rich with experiences and exploration.');
    } else if (eventsCount > 3) {
      reflections.add('A full day of meaningful engagements.');
    } else if (wasActive) {
      reflections.add('You balanced activity and purpose today.');
    } else if (placesCount == 1) {
      reflections.add('A focused day in familiar surroundings.');
    } else {
      reflections.add('Another chapter in your ongoing story.');
    }

    // Add time-aware reflection
    final now = DateTime.now();
    if (now.weekday == DateTime.friday) {
      reflections.add('The week draws to a close with today\'s experiences.');
    } else if (now.weekday == DateTime.sunday) {
      reflections.add('A day of rest and reflection before the week ahead.');
    }

    return reflections.join(' ');
  }

  String _generateDataDrivenContent(int photosCount, int locationsCount, List<String> calendarEvents, String date) {
    final List<String> contentParts = [];

    // Add date header
    final dateObj = DateTime.tryParse(date) ?? DateTime.now();
    final dateStr = _formatDate(dateObj);
    contentParts.add('$dateStr\n');

    // Only add factual information about what actually happened
    if (calendarEvents.isNotEmpty) {
      contentParts.add('Events today:');
      for (final event in calendarEvents.take(3)) {
        contentParts.add('• $event');
      }
      contentParts.add('');
    }

    if (photosCount > 0) {
      if (photosCount == 1) {
        contentParts.add('Captured 1 photo today.');
      } else if (photosCount < 5) {
        contentParts.add('Captured $photosCount photos today.');
      } else if (photosCount < 10) {
        contentParts.add('Documented the day with $photosCount photos.');
      } else {
        contentParts.add('Extensively documented today with $photosCount photos.');
      }
    }

    if (locationsCount > 0) {
      if (locationsCount == 1) {
        contentParts.add('Stayed in one area today.');
      } else if (locationsCount == 2) {
        contentParts.add('Visited 2 different locations.');
      } else if (locationsCount <= 5) {
        contentParts.add('Visited $locationsCount different places.');
      } else {
        contentParts.add('Had an active day visiting $locationsCount locations.');
      }
    }

    // If no data, add minimal entry
    if (contentParts.length <= 1) {
      contentParts.add('A quiet day.');
    }

    return contentParts.join('\n').trim();
  }

  // Helper method to safely cast dynamic lists to List<Map<String, dynamic>>
  List<Map<String, dynamic>> _safeListCast(dynamic value) {
    if (value == null) return [];
    if (value is List<Map<String, dynamic>>) return value;
    if (value is List) {
      try {
        return value.map((item) {
          if (item is Map<String, dynamic>) return item;
          if (item is Map) return Map<String, dynamic>.from(item);
          // Handle string items (e.g., simple calendar events)
          if (item is String) {
            return <String, dynamic>{'title': item};
          }
          return <String, dynamic>{};
        }).toList();
      } catch (e) {
        debugPrint('OnDevice AI: Failed to cast list: $e');
        return [];
      }
    }
    return [];
  }

  String _generateFactualSummary(int photosCount, int locationsCount, List<String> calendarEvents) {
    final List<String> summaryParts = [];

    if (calendarEvents.isNotEmpty) {
      summaryParts.add('${calendarEvents.length} event${calendarEvents.length > 1 ? 's' : ''}');
    }

    if (photosCount > 0) {
      summaryParts.add('$photosCount photo${photosCount > 1 ? 's' : ''}');
    }

    if (locationsCount > 0) {
      summaryParts.add('$locationsCount location${locationsCount > 1 ? 's' : ''}');
    }

    if (summaryParts.isEmpty) {
      return 'Daily journal entry';
    }

    return 'Day with ${summaryParts.join(', ')}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getFallbackContent() {
    return "Today's journal entry.";
  }

  List<String> _extractThemes(String content) {
    final themes = <String>[];
    final lowerContent = content.toLowerCase();

    if (lowerContent.contains('grateful') || lowerContent.contains('thankful')) {
      themes.add('gratitude');
    }
    if (lowerContent.contains('learn') || lowerContent.contains('understand')) {
      themes.add('learning');
    }
    if (lowerContent.contains('peace') || lowerContent.contains('calm')) {
      themes.add('mindfulness');
    }
    if (lowerContent.contains('growth') || lowerContent.contains('change')) {
      themes.add('personal growth');
    }

    return themes;
  }

  /// Check if service is available (always true for on-device service)
  bool get isAvailable => true;
  bool get isInitialized => true;

  /// Initialize service (no-op for on-device service)
  Future<void> initialize() async {
    debugPrint('OnDevice AI: Service initialized successfully');
  }
}