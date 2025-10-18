import '../services/calendar_service.dart';
import '../providers/data_activity_tracker.dart';
import '../database/location_database.dart';
import '../services/ai_feature_extractor.dart';
import '../utils/logger.dart';

/// Narrative event type for timeline
enum NarrativeEventType {
  calendar,
  location,
  photo,
  activity,
  movement,
}

/// Unified narrative event structure for building journal timelines
class NarrativeEvent {
  final NarrativeEventType type;
  final DateTime timestamp;
  final Duration? duration;

  // Calendar-specific fields
  final String? meetingTitle;
  final String? meetingDescription;
  final List<String>? attendees;
  final bool? isAllDay;

  // Location-specific fields
  final String? placeName;
  final double? latitude;
  final double? longitude;
  final String? placeType;

  // Photo-specific fields
  final List<String>? objectsSeen;
  final String? sceneDescription;
  final int? peopleCount;
  final PhotoContext? photoContext;

  // Activity-specific fields
  final String? activityType;
  final String? activityAction;
  final Map<String, dynamic>? activityMetadata;

  // Movement-specific fields
  final String? movementMode; // walking, driving, still
  final double? distanceTraveled;

  // General fields
  final String? description;
  final Map<String, dynamic>? metadata;

  NarrativeEvent({
    required this.type,
    required this.timestamp,
    this.duration,
    // Calendar fields
    this.meetingTitle,
    this.meetingDescription,
    this.attendees,
    this.isAllDay,
    // Location fields
    this.placeName,
    this.latitude,
    this.longitude,
    this.placeType,
    // Photo fields
    this.objectsSeen,
    this.sceneDescription,
    this.peopleCount,
    this.photoContext,
    // Activity fields
    this.activityType,
    this.activityAction,
    this.activityMetadata,
    // Movement fields
    this.movementMode,
    this.distanceTraveled,
    // General
    this.description,
    this.metadata,
  });

  /// Create event from calendar data
  factory NarrativeEvent.fromCalendar(CalendarEventData event) {
    return NarrativeEvent(
      type: NarrativeEventType.calendar,
      timestamp: event.startDate,
      duration: event.endDate?.difference(event.startDate),
      meetingTitle: event.title,
      meetingDescription: event.description,
      attendees: event.attendees,
      isAllDay: event.isAllDay,
      placeName: event.location,
      metadata: event.metadata,
    );
  }

  /// Create event from location data
  factory NarrativeEvent.fromLocation(
    LocationPoint location, {
    String? placeName,
    String? placeType,
    Duration? duration,
  }) {
    return NarrativeEvent(
      type: NarrativeEventType.location,
      timestamp: location.timestamp,
      duration: duration,
      latitude: location.latitude,
      longitude: location.longitude,
      placeName: placeName,
      placeType: placeType,
      description: placeName ?? 'Location update',
    );
  }

  /// Create event from photo context
  factory NarrativeEvent.fromPhoto(PhotoContext photo) {
    return NarrativeEvent(
      type: NarrativeEventType.photo,
      timestamp: photo.timestamp,
      objectsSeen: photo.detectedObjects.isNotEmpty
          ? photo.detectedObjects
          : photo.objectLabels,
      sceneDescription: photo.sceneLabels.isNotEmpty
          ? photo.sceneLabels.join(', ')
          : null,
      peopleCount: photo.faceCount,
      photoContext: photo,
      placeName: photo.placeName,
      latitude: photo.latitude,
      longitude: photo.longitude,
      description: 'Photo captured',
    );
  }

  /// Create event from activity data
  factory NarrativeEvent.fromActivity(DataActivity activity) {
    return NarrativeEvent(
      type: NarrativeEventType.activity,
      timestamp: activity.timestamp,
      activityType: activity.type.toString(),
      activityAction: activity.action,
      activityMetadata: activity.metadata,
      description: '${activity.type.name}: ${activity.action}',
    );
  }

  /// Create event from movement data
  factory NarrativeEvent.fromMovement(
    MovementDataData movement, {
    double? distanceTraveled,
  }) {
    return NarrativeEvent(
      type: NarrativeEventType.movement,
      timestamp: movement.timestamp,
      movementMode: movement.state,
      distanceTraveled: distanceTraveled,
      description: 'Movement: ${movement.state}',
    );
  }

  /// Get a human-readable summary of this event
  String get summary {
    switch (type) {
      case NarrativeEventType.calendar:
        if (isAllDay == true) {
          return '$meetingTitle (all day)';
        }
        final timeStr = _formatTime(timestamp);
        return '$meetingTitle at $timeStr';

      case NarrativeEventType.location:
        return 'At ${placeName ?? "location"}';

      case NarrativeEventType.photo:
        final parts = <String>[];
        if (objectsSeen != null && objectsSeen!.isNotEmpty) {
          parts.add(objectsSeen!.take(2).join(', '));
        }
        if (sceneDescription != null) {
          parts.add(sceneDescription!);
        }
        if (peopleCount != null && peopleCount! > 0) {
          parts.add('$peopleCount ${peopleCount == 1 ? "person" : "people"}');
        }
        return 'Photo: ${parts.isEmpty ? "captured" : parts.join(", ")}';

      case NarrativeEventType.activity:
        return activityAction ?? 'Activity';

      case NarrativeEventType.movement:
        return movementMode ?? 'Movement';
    }
  }

  /// Format time as "9:00am" or "5:30pm"
  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute$period';
  }

  /// Check if this event has location data
  bool get hasLocation => latitude != null && longitude != null;

  /// Check if this is a significant event (for narrative purposes)
  bool get isSignificant {
    switch (type) {
      case NarrativeEventType.calendar:
        return true; // All calendar events are significant
      case NarrativeEventType.photo:
        return true; // All photos are significant
      case NarrativeEventType.location:
        return placeName != null; // Only named places are significant
      case NarrativeEventType.movement:
        return movementMode != 'still'; // Only actual movement is significant
      case NarrativeEventType.activity:
        return false; // Activities are usually background noise
    }
  }
}

/// Service to aggregate timeline events from multiple sources
class TimelineEventAggregator {
  static final _logger = AppLogger('TimelineEventAggregator');
  static final TimelineEventAggregator _instance = TimelineEventAggregator._internal();

  factory TimelineEventAggregator() => _instance;
  TimelineEventAggregator._internal();

  /// Aggregate all events for a day into a chronological timeline
  Future<List<NarrativeEvent>> aggregateTimeline({
    required DateTime date,
    required List<CalendarEventData> calendarEvents,
    required List<LocationPoint> locationPoints,
    required List<PhotoContext> photoContexts,
    required List<DataActivity> activities,
    required List<MovementDataData> movementData,
    Set<String>? enabledCalendarIds,
    Map<String, String>? locationPlaceNames,
  }) async {
    final events = <NarrativeEvent>[];

    // Filter and add calendar events (only from enabled calendars)
    final filteredCalendarEvents = _filterCalendarEvents(
      calendarEvents,
      enabledCalendarIds,
    );

    for (final calendarEvent in filteredCalendarEvents) {
      events.add(NarrativeEvent.fromCalendar(calendarEvent));
    }

    _logger.debug(
      'Added ${events.length} calendar events (filtered from ${calendarEvents.length} total, '
      'enabled calendars: ${enabledCalendarIds?.length ?? "all"})',
    );

    // Add photo events
    for (final photo in photoContexts) {
      events.add(NarrativeEvent.fromPhoto(photo));
    }

    _logger.debug('Added ${photoContexts.length} photo events');

    // Add significant location events (cluster nearby locations)
    final locationClusters = _clusterLocationsByTime(locationPoints);
    for (final cluster in locationClusters) {
      final centerPoint = _calculateClusterCenter(cluster);
      final key = '${centerPoint.latitude.toStringAsFixed(4)},${centerPoint.longitude.toStringAsFixed(4)}';
      final placeName = locationPlaceNames?[key];

      // Only add if we have a place name
      if (placeName != null) {
        final duration = _calculateClusterDuration(cluster);
        events.add(NarrativeEvent.fromLocation(
          centerPoint,
          placeName: placeName,
          duration: duration,
        ));
      }
    }

    _logger.debug('Added ${locationClusters.where((c) {
      final centerPoint = _calculateClusterCenter(c);
      final key = '${centerPoint.latitude.toStringAsFixed(4)},${centerPoint.longitude.toStringAsFixed(4)}';
      return locationPlaceNames?[key] != null;
    }).length} location events from ${locationClusters.length} clusters');

    // Sort chronologically
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _logger.info('Aggregated ${events.length} total narrative events for $date');

    // Filter to only significant events and group related activities
    final filteredEvents = _filterAndGroupEvents(events);
    
    _logger.info('Filtered to ${filteredEvents.length} significant events after grouping');

    return filteredEvents;
  }

  /// Filter calendar events by enabled calendar IDs
  List<CalendarEventData> _filterCalendarEvents(
    List<CalendarEventData> events,
    Set<String>? enabledCalendarIds,
  ) {
    if (enabledCalendarIds == null || enabledCalendarIds.isEmpty) {
      // If no filter specified, include all events
      return events;
    }

    return events.where((event) {
      if (event.calendarId == null) return false;
      return enabledCalendarIds.contains(event.calendarId);
    }).toList();
  }

  /// Cluster location points by time proximity
  List<List<LocationPoint>> _clusterLocationsByTime(
    List<LocationPoint> points, {
    Duration maxTimeBetweenPoints = const Duration(minutes: 30),
  }) {
    if (points.isEmpty) {
      return [];
    }

    final sortedPoints = List<LocationPoint>.from(points)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final clusters = <List<LocationPoint>>[];
    List<LocationPoint> currentCluster = [sortedPoints.first];

    for (int i = 1; i < sortedPoints.length; i++) {
      final timeDiff = sortedPoints[i].timestamp.difference(
        sortedPoints[i - 1].timestamp,
      );

      if (timeDiff <= maxTimeBetweenPoints) {
        currentCluster.add(sortedPoints[i]);
      } else {
        if (currentCluster.isNotEmpty) {
          clusters.add(currentCluster);
        }
        currentCluster = [sortedPoints[i]];
      }
    }

    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    return clusters;
  }

  /// Calculate center point of a location cluster
  LocationPoint _calculateClusterCenter(List<LocationPoint> cluster) {
    if (cluster.length == 1) {
      return cluster.first;
    }

    double sumLat = 0;
    double sumLon = 0;

    for (final point in cluster) {
      sumLat += point.latitude;
      sumLon += point.longitude;
    }

    final centerLat = sumLat / cluster.length;
    final centerLon = sumLon / cluster.length;

    return LocationPoint(
      id: cluster.first.id,
      timestamp: cluster.first.timestamp,
      latitude: centerLat,
      longitude: centerLon,
      accuracy: cluster.first.accuracy,
      altitude: cluster.first.altitude,
      speed: cluster.first.speed,
      heading: cluster.first.heading,
      activityType: cluster.first.activityType,
      isSignificant: cluster.first.isSignificant,
      createdAt: cluster.first.createdAt,
    );
  }

  /// Calculate duration spent at a location cluster
  Duration _calculateClusterDuration(List<LocationPoint> cluster) {
    if (cluster.length < 2) {
      return Duration.zero;
    }

    final sortedPoints = List<LocationPoint>.from(cluster)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return sortedPoints.last.timestamp.difference(sortedPoints.first.timestamp);
  }

  /// Get only significant events for narrative
  List<NarrativeEvent> getSignificantEvents(List<NarrativeEvent> events) {
    return events.where((event) => event.isSignificant).toList();
  }

  /// Group events by time of day
  Map<String, List<NarrativeEvent>> groupByTimeOfDay(
    List<NarrativeEvent> events,
  ) {
    final groups = <String, List<NarrativeEvent>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
      'night': [],
    };

    for (final event in events) {
      final hour = event.timestamp.hour;
      if (hour >= 5 && hour < 12) {
        groups['morning']!.add(event);
      } else if (hour >= 12 && hour < 17) {
        groups['afternoon']!.add(event);
      } else if (hour >= 17 && hour < 21) {
        groups['evening']!.add(event);
      } else {
        groups['night']!.add(event);
      }
    }

    return groups;
  }

  List<NarrativeEvent> _filterAndGroupEvents(List<NarrativeEvent> events) {
    final filtered = <NarrativeEvent>[];
    
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      
      if (!event.isSignificant) {
        continue;
      }
      
      if (event.type == NarrativeEventType.location) {
        final isDuplicate = _isNearDuplicate(event, filtered);
        if (isDuplicate) continue;
      }
      
      if (event.type == NarrativeEventType.photo) {
        final shouldMerge = _shouldMergeWithPreviousPhoto(event, filtered);
        if (shouldMerge) {
          _mergePhotoEvents(filtered.last, event);
          continue;
        }
      }
      
      filtered.add(event);
    }
    
    return filtered;
  }

  bool _isNearDuplicate(NarrativeEvent newEvent, List<NarrativeEvent> existing) {
    if (newEvent.latitude == null || newEvent.longitude == null) {
      return false;
    }
    
    for (final event in existing.reversed.take(3)) {
      if (event.type != NarrativeEventType.location) continue;
      if (event.latitude == null || event.longitude == null) continue;
      
      final timeDiff = newEvent.timestamp.difference(event.timestamp).abs();
      if (timeDiff.inMinutes < 30 && event.placeName == newEvent.placeName) {
        return true;
      }
    }
    
    return false;
  }

  bool _shouldMergeWithPreviousPhoto(NarrativeEvent newPhoto, List<NarrativeEvent> existing) {
    if (existing.isEmpty) return false;
    
    final lastEvent = existing.last;
    if (lastEvent.type != NarrativeEventType.photo) return false;
    
    final timeDiff = newPhoto.timestamp.difference(lastEvent.timestamp);
    if (timeDiff.inMinutes > 10) return false;
    
    final sameLocation = lastEvent.latitude == newPhoto.latitude && 
                        lastEvent.longitude == newPhoto.longitude;
    
    return sameLocation || timeDiff.inMinutes < 2;
  }

  void _mergePhotoEvents(NarrativeEvent existing, NarrativeEvent newPhoto) {
    if (existing.metadata != null && newPhoto.metadata != null) {
      existing.metadata!['merged_count'] = 
          (existing.metadata!['merged_count'] as int? ?? 1) + 1;
      
      if (newPhoto.objectsSeen != null && existing.objectsSeen != null) {
        final combined = {...existing.objectsSeen!, ...newPhoto.objectsSeen!};
        existing.metadata!['all_objects'] = combined.toList();
      }
    }
  }
}
