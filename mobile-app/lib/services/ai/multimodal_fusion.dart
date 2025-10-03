import '../../utils/logger.dart';
import 'dbscan_clustering.dart';
import 'activity_recognition.dart';
import 'image_captioning.dart';
import '../calendar_service.dart';
import '../health_service.dart';
import '../daily_context_synthesizer.dart';
// import '../data_attribution_service.dart'; // Simplified version
// import '../../database/media_database.dart'; // Using dynamic types

/// Represents a daily event with all associated data
class DailyEvent {
  final String id;
  final EventType type;
  final DateTime startTime;
  final DateTime endTime;
  final String? locationId;
  final List<ActivityType> activities;
  final List<String> photoCaptions;
  final List<String> photoIds;
  final Map<String, dynamic> metadata;
  final List<dynamic> attributions;

  DailyEvent({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.locationId,
    this.activities = const [],
    this.photoCaptions = const [],
    this.photoIds = const [],
    this.metadata = const {},
    this.attributions = const [],
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'duration': duration.inMinutes,
    'locationId': locationId,
    'activities': activities.map((a) => a.name).toList(),
    'photoCaptions': photoCaptions,
    'photoIds': photoIds,
    'metadata': metadata,
    'attributions': attributions,
  };
}

/// Event type classification
enum EventType {
  stay,      // Stationary at a location
  journey,   // Moving between locations
  unknown,   // Unclassified
}

/// Multi-modal data fusion and event correlation service
class MultiModalFusionService {
  static final _logger = AppLogger('MultiModalFusionService');
  static final _instance = MultiModalFusionService._internal();

  factory MultiModalFusionService() => _instance;
  MultiModalFusionService._internal();

  // Service dependencies
  final DBSCANClustering _clustering = DBSCANClustering();
  final ActivityRecognitionService _activityService = ActivityRecognitionService();
  final ImageCaptioningService _captionService = ImageCaptioningService();
  final CalendarService _calendarService = CalendarService();
  final HealthService _healthService = HealthService();
  // TODO: PhotoService requires Riverpod Ref - needs refactoring
  // final PhotoService _photoService = PhotoService();
  // final DataAttributionService _attributionService = DataAttributionService();

  /// Build a unified timeline for a specific date
  Future<List<DailyEvent>> buildDailyTimeline({
    required DateTime date,
    List<LocationPoint>? locationPoints,
    List<ActivityRecognitionResult>? activityResults,
    List<dynamic>? photos,
  }) async {
    try {
      _logger.info('Building daily timeline for ${date.toIso8601String()}');

      // Set date boundaries
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Collect data if not provided
      locationPoints ??= await _getLocationData(startOfDay, endOfDay);
      activityResults ??= await _getActivityData(startOfDay, endOfDay);
      photos ??= await _getPhotoData(startOfDay, endOfDay);

      // Get calendar events
      final calendarEvents = []; // TODO: Implement calendar integration

      // Get health data
      final healthData = {}; // TODO: Implement health data integration

      // Perform location clustering
      final locationClusters = _clustering.cluster(locationPoints);
      final journeySegments = _clustering.identifyJourneys(locationPoints);

      // Build timeline events
      final events = <DailyEvent>[];

      // Add stay events from clusters
      for (final cluster in locationClusters) {
        final event = await _buildStayEvent(
          cluster: cluster,
          activities: activityResults,
          photos: photos,
          calendarEvents: calendarEvents,
          healthData: Map<String, dynamic>.from(healthData),
        );
        events.add(event);
      }

      // Add journey events
      for (final journey in journeySegments) {
        final event = await _buildJourneyEvent(
          journey: journey,
          activities: activityResults,
          photos: photos,
        );
        events.add(event);
      }

      // Add orphan events (calendar events without location)
      for (final calEvent in calendarEvents) {
        if (!_isEventCovered(calEvent, events)) {
          final event = _buildOrphanCalendarEvent(calEvent);
          events.add(event);
        }
      }

      // Sort events by start time
      events.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Merge adjacent similar events
      final mergedEvents = _mergeAdjacentEvents(events);

      _logger.info('Built timeline with ${mergedEvents.length} events');

      return mergedEvents;
    } catch (e, stack) {
      _logger.error('Failed to build daily timeline', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Build a stay event from cluster data
  Future<DailyEvent> _buildStayEvent({
    required LocationCluster cluster,
    required List<ActivityRecognitionResult> activities,
    required List<dynamic> photos,
    required List<dynamic> calendarEvents,
    required Map<String, dynamic> healthData,
  }) async {
    // Filter activities within time range
    final eventActivities = activities
        .where((a) =>
            a.timestamp.isAfter(cluster.startTime) &&
            a.timestamp.isBefore(cluster.endTime))
        .map((a) => a.activity)
        .toSet()
        .toList();

    // Filter photos within time range
    final eventPhotos = photos.where((p) {
      final photoTime = DateTime.now(); // TODO: Get actual photo time
      return photoTime.isAfter(cluster.startTime) &&
             photoTime.isBefore(cluster.endTime);
    }).toList();

    // Generate captions for photos
    final photoCaptions = <String>[];
    final photoIds = <String>[];

    for (final photo in eventPhotos) {
      photoIds.add('photo_${photoIds.length}'); // TODO: Get actual photo ID

      // Try to get caption
      try {
        // TODO: Get actual photo bytes
        final bytes = null;
        if (bytes != null) {
          final caption = await _captionService.captionImage(bytes);
          photoCaptions.add('Photo'); // TODO: Use actual caption
        }
      } catch (e) {
        _logger.debug('Failed to caption photo: $e');
        photoCaptions.add('A photo');
      }
    }

    // Find matching calendar events
    final matchingCalendarEvents = calendarEvents.where((e) {
      final eventTime = cluster.startTime; // TODO: Get actual calendar event time
      return eventTime.isAfter(cluster.startTime.subtract(const Duration(minutes: 30))) &&
             eventTime.isBefore(cluster.endTime.add(const Duration(minutes: 30)));
    }).toList();

    // Build metadata
    final metadata = <String, dynamic>{
      'location': {
        'latitude': cluster.centerLatitude,
        'longitude': cluster.centerLongitude,
      },
      'calendarEvents': matchingCalendarEvents,
      'healthData': healthData,
      'photoCount': eventPhotos.length,
    };

    // Build attributions
    final attributions = [];

    return DailyEvent(
      id: 'stay_${cluster.id}_${cluster.startTime.millisecondsSinceEpoch}',
      type: EventType.stay,
      startTime: cluster.startTime,
      endTime: cluster.endTime,
      locationId: 'cluster_${cluster.id}',
      activities: eventActivities,
      photoCaptions: photoCaptions,
      photoIds: photoIds,
      metadata: metadata,
      attributions: attributions,
    );
  }

  /// Build a journey event from movement data
  Future<DailyEvent> _buildJourneyEvent({
    required JourneySegment journey,
    required List<ActivityRecognitionResult> activities,
    required List<dynamic> photos,
  }) async {
    // Filter activities during journey
    final journeyActivities = activities
        .where((a) =>
            a.timestamp.isAfter(journey.startTime) &&
            a.timestamp.isBefore(journey.endTime))
        .map((a) => a.activity)
        .toSet()
        .toList();

    // If no activities detected, infer from journey characteristics
    if (journeyActivities.isEmpty) {
      if (journey.totalDistance < 500) {
        journeyActivities.add(ActivityType.walking);
      } else if (journey.totalDistance < 5000) {
        journeyActivities.add(ActivityType.cycling);
      } else {
        journeyActivities.add(ActivityType.driving);
      }
    }

    // Filter photos during journey
    final journeyPhotos = photos.where((p) {
      final photoTime = DateTime.now(); // TODO: Get actual photo time
      return photoTime.isAfter(journey.startTime) &&
             photoTime.isBefore(journey.endTime);
    }).toList();

    // Generate captions for photos
    final photoCaptions = <String>[];
    final photoIds = <String>[];

    for (final photo in journeyPhotos) {
      photoIds.add('photo_${photoIds.length}'); // TODO: Get actual photo ID
      photoCaptions.add('Photo during journey');
    }

    // Build metadata
    final metadata = <String, dynamic>{
      'distance': journey.totalDistance,
      'points': journey.points.length,
      'photoCount': journeyPhotos.length,
    };

    return DailyEvent(
      id: 'journey_${journey.startTime.millisecondsSinceEpoch}',
      type: EventType.journey,
      startTime: journey.startTime,
      endTime: journey.endTime,
      activities: journeyActivities,
      photoCaptions: photoCaptions,
      photoIds: photoIds,
      metadata: metadata,
      attributions: [],
    );
  }

  /// Build event for calendar entry without location
  DailyEvent _buildOrphanCalendarEvent(dynamic calEvent) {
    return DailyEvent(
      id: 'calendar_event',
      type: EventType.stay,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      metadata: {
        'title': 'Event',
        'description': '',
        'location': '',
      },
      attributions: [],
    );
  }

  /// Check if calendar event is covered by existing events
  bool _isEventCovered(dynamic calEvent, List<DailyEvent> events) {
    // TODO: Check if calendar event is already covered
    return false;

    for (final event in events) {
      if (event.metadata['calendarEvents'] != null) {
        final calEvents = event.metadata['calendarEvents'] as List;
        if (calEvents.isNotEmpty) { // TODO: Check actual event ID
          return true;
        }
      }
    }

    return false;
  }

  /// Merge adjacent events with similar characteristics
  List<DailyEvent> _mergeAdjacentEvents(List<DailyEvent> events) {
    if (events.isEmpty) return events;

    final merged = <DailyEvent>[];
    DailyEvent current = events.first;

    for (int i = 1; i < events.length; i++) {
      final next = events[i];

      // Check if events can be merged
      if (_canMergeEvents(current, next)) {
        // Merge events
        current = _mergeEvents(current, next);
      } else {
        merged.add(current);
        current = next;
      }
    }

    merged.add(current);
    return merged;
  }

  /// Check if two events can be merged
  bool _canMergeEvents(DailyEvent first, DailyEvent second) {
    // Don't merge different types
    if (first.type != second.type) return false;

    // Check time proximity (within 5 minutes)
    final gap = second.startTime.difference(first.endTime);
    if (gap.inMinutes > 5) return false;

    // Check if same location for stay events
    if (first.type == EventType.stay &&
        first.locationId != second.locationId) {
      return false;
    }

    return true;
  }

  /// Merge two events into one
  DailyEvent _mergeEvents(DailyEvent first, DailyEvent second) {
    // Combine activities
    final activities = <ActivityType>{
      ...first.activities,
      ...second.activities,
    }.toList();

    // Combine photos
    final photoCaptions = [...first.photoCaptions, ...second.photoCaptions];
    final photoIds = [...first.photoIds, ...second.photoIds];

    // Merge metadata
    final metadata = {...first.metadata};
    second.metadata.forEach((key, value) {
      if (metadata.containsKey(key) && value is List && metadata[key] is List) {
        metadata[key] = [...metadata[key], ...value];
      } else {
        metadata[key] = value;
      }
    });

    // Combine attributions
    final attributions = {...first.attributions, ...second.attributions}.toList();

    return DailyEvent(
      id: first.id,
      type: first.type,
      startTime: first.startTime,
      endTime: second.endTime,
      locationId: first.locationId,
      activities: activities,
      photoCaptions: photoCaptions,
      photoIds: photoIds,
      metadata: metadata,
      attributions: attributions,
    );
  }

  /// Get location data for date range
  Future<List<LocationPoint>> _getLocationData(
    DateTime start,
    DateTime end,
  ) async {
    // This would be implemented to fetch from database
    // For now, return empty list
    return [];
  }

  /// Get activity data for date range
  Future<List<ActivityRecognitionResult>> _getActivityData(
    DateTime start,
    DateTime end,
  ) async {
    // This would be implemented to fetch from database
    // For now, return empty list
    return [];
  }

  /// Get photo data for date range
  Future<List<dynamic>> _getPhotoData(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final photos = []; // TODO: Implement photo fetching
      return photos;
    } catch (e) {
      _logger.error('Failed to get photo data', error: e);
      return [];
    }
  }

  /// Generate structured context for AI processing
  Map<String, dynamic> generateStructuredContext(List<DailyEvent> events) {
    final context = <String, dynamic>{
      'date': events.isNotEmpty
          ? events.first.startTime.toIso8601String().split('T')[0]
          : DateTime.now().toIso8601String().split('T')[0],
      'eventCount': events.length,
      'events': [],
      'summary': {},
    };

    // Process each event
    for (final event in events) {
      final eventData = {
        'type': event.type.name,
        'time': '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
        'duration': event.duration.inMinutes,
        'activities': event.activities.map((a) => a.name).toList(),
        'photos': event.photoCaptions,
        'metadata': event.metadata,
      };

      context['events'].add(eventData);
    }

    // Generate summary statistics
    context['summary'] = {
      'totalDuration': events.fold<int>(
        0,
        (sum, e) => sum + e.duration.inMinutes,
      ),
      'stayEvents': events.where((e) => e.type == EventType.stay).length,
      'journeyEvents': events.where((e) => e.type == EventType.journey).length,
      'totalPhotos': events.fold<int>(
        0,
        (sum, e) => sum + e.photoIds.length,
      ),
      'uniqueActivities': events
          .expand((e) => e.activities)
          .toSet()
          .map((a) => a.name)
          .toList(),
    };

    return context;
  }

  /// Generate enhanced structured context from comprehensive DailyContext
  Map<String, dynamic> generateEnhancedStructuredContext(DailyContext dailyContext) {
    final context = <String, dynamic>{
      'date': dailyContext.date.toIso8601String().split('T')[0],
      'eventCount': dailyContext.photoContexts.length + dailyContext.calendarEvents.length,
      'events': [],
      'summary': {},
      'writtenContent': {},
      'proximityContext': {},
      'confidenceScore': dailyContext.overallConfidence,
    };

    // Process photo contexts
    for (final photo in dailyContext.photoContexts) {
      final eventData = {
        'type': 'photo_context',
        'time': _formatTime(photo.timestamp),
        'description': photo.activityDescription,
        'social': {
          'faceCount': photo.faceCount,
          'isSelfie': photo.socialContext.isSelfie,
          'isGroupPhoto': photo.socialContext.isGroupPhoto,
        },
        'environment': {
          'sceneLabels': photo.sceneLabels,
          'objectLabels': photo.objectLabels,
        },
        'confidence': photo.confidenceScore,
      };
      context['events'].add(eventData);
    }

    // Process calendar events
    for (final calEvent in dailyContext.calendarEvents) {
      final eventData = {
        'type': 'calendar_event',
        'time': _formatTime(calEvent.startDate),
        'title': calEvent.title,
        'duration': calEvent.endDate?.difference(calEvent.startDate).inMinutes ?? 60,
        'location': calEvent.location,
        'attendeeCount': calEvent.attendees.length,
      };
      context['events'].add(eventData);
    }

    // Process written content summary
    context['writtenContent'] = {
      'totalEntries': dailyContext.writtenContentSummary.totalWrittenEntries,
      'hasSignificantContent': dailyContext.writtenContentSummary.hasSignificantContent,
      'themes': dailyContext.writtenContentSummary.significantThemes,
      'emotionalTones': dailyContext.writtenContentSummary.emotionalTones,
      'keyTopics': dailyContext.writtenContentSummary.keyTopics,
    };

    // Process proximity context
    context['proximityContext'] = {
      'hasProximityInteractions': dailyContext.proximitySummary.hasProximityInteractions,
      'geofenceTransitions': dailyContext.proximitySummary.geofenceTransitions,
      'frequentLocations': dailyContext.proximitySummary.frequentProximityLocations,
      'dwellTimes': dailyContext.proximitySummary.locationDwellTimes.map(
        (key, value) => MapEntry(key, value.inMinutes),
      ),
    };

    // Generate enhanced summary statistics
    context['summary'] = {
      'totalPhotos': dailyContext.photoContexts.length,
      'totalCalendarEvents': dailyContext.calendarEvents.length,
      'totalLocationPoints': dailyContext.locationPoints.length,
      'totalMovementSamples': dailyContext.movementData.length,
      'totalActivities': dailyContext.activities.length,
      'totalWrittenContent': dailyContext.writtenContentSummary.totalWrittenEntries,
      'socialInteractions': dailyContext.socialSummary.totalPeopleDetected,
      'primaryActivities': dailyContext.activitySummary.primaryActivities,
      'dominantEnvironments': dailyContext.environmentSummary.dominantEnvironments,
      'significantPlaces': dailyContext.locationSummary.significantPlaces,
      'totalDistance': dailyContext.locationSummary.totalDistance,
      'movementModes': dailyContext.locationSummary.movementModes,
      'mostActiveTime': dailyContext.environmentSummary.timeOfDayAnalysis.mostActiveTime,
      'hadPhysicalActivity': dailyContext.activitySummary.hadPhysicalActivity,
      'hadCreativeActivity': dailyContext.activitySummary.hadCreativeActivity,
      'hadWorkActivity': dailyContext.activitySummary.hadWorkActivity,
      'dataCompleteness': _calculateEnhancedDataCompleteness(dailyContext),
    };

    return context;
  }

  /// Calculate enhanced data completeness score for DailyContext
  double _calculateEnhancedDataCompleteness(DailyContext dailyContext) {
    double completeness = 0.0;

    // Weight different data types based on their narrative value
    if (dailyContext.photoContexts.isNotEmpty) completeness += 0.25;
    if (dailyContext.calendarEvents.isNotEmpty) completeness += 0.20;
    if (dailyContext.locationPoints.isNotEmpty) completeness += 0.15;
    if (dailyContext.movementData.isNotEmpty) completeness += 0.10;
    if (dailyContext.activities.isNotEmpty) completeness += 0.10;
    if (dailyContext.writtenContentSummary.hasSignificantContent) completeness += 0.10;
    if (dailyContext.proximitySummary.hasProximityInteractions) completeness += 0.10;

    return completeness.clamp(0.0, 1.0);
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}';
  }
}
