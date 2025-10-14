import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../database/media_database.dart';
import '../database/location_database.dart';
import '../services/calendar_service.dart';
import '../providers/data_activity_tracker.dart';
import 'ai_feature_extractor.dart';
import 'activity_validator.dart';
import 'distance_calculator.dart';
import 'location_cluster_namer.dart';
import 'timeline_event_aggregator.dart';
import 'data_rich_narrative_builder.dart';

/// Comprehensive daily context that synthesizes all collected data
class DailyContext {
  final DateTime date;
  final List<PhotoContext> photoContexts;
  final List<CalendarEventData> calendarEvents;
  final List<LocationPoint> locationPoints;
  final List<DataActivity> activities;
  final List<MovementDataData> movementData;
  final List<GeofenceEvent> geofenceEvents;
  final List<LocationNote> locationNotes;
  final EnvironmentSummary environmentSummary;
  final SocialSummary socialSummary;
  final ActivitySummary activitySummary;
  final LocationSummary locationSummary;
  final ProximitySummary proximitySummary;
  final WrittenContentSummary writtenContentSummary;
  final double overallConfidence;
  final Map<String, dynamic> metadata;

  // Timeline integration
  final List<NarrativeEvent> timelineEvents;

  DailyContext({
    required this.date,
    required this.photoContexts,
    required this.calendarEvents,
    required this.locationPoints,
    required this.activities,
    required this.movementData,
    required this.geofenceEvents,
    required this.locationNotes,
    required this.environmentSummary,
    required this.socialSummary,
    required this.activitySummary,
    required this.locationSummary,
    required this.proximitySummary,
    required this.writtenContentSummary,
    required this.overallConfidence,
    required this.metadata,
    required this.timelineEvents,
  });

  /// Generate a human-readable narrative overview (simple version)
  String get narrativeOverview {
    final buffer = StringBuffer();

    // Start with the most significant activities
    if (activitySummary.primaryActivities.isNotEmpty) {
      buffer.write('Primarily spent time ');
      buffer.write(activitySummary.primaryActivities.take(2).join(' and '));
    }

    // Add social context
    if (socialSummary.totalPeopleDetected > 0) {
      if (socialSummary.totalPeopleDetected == 1) {
        buffer.write(buffer.isEmpty ? 'Had' : ', had');
        buffer.write(' solo moments');
      } else {
        buffer.write(buffer.isEmpty ? 'Spent' : ', spent');
        buffer.write(' time with ${socialSummary.totalPeopleDetected} people');
      }
    }

    // Add location context
    if (locationSummary.significantPlaces.isNotEmpty) {
      buffer.write(buffer.isEmpty ? 'Visited' : ', visiting');
      buffer.write(' ${locationSummary.significantPlaces.length} places');
      if (locationSummary.totalDistance > 1000) {
        buffer.write(', traveled ${(locationSummary.totalDistance / 1000).toStringAsFixed(1)}km');
      }
    }

    // Add written content insights
    if (writtenContentSummary.hasSignificantContent) {
      buffer.write(buffer.isEmpty ? 'Captured' : ', captured');
      buffer.write(' thoughts and reflections');
    }

    // Add proximity insights
    if (proximitySummary.hasProximityInteractions) {
      buffer.write(buffer.isEmpty ? 'Connected' : ', connected');
      buffer.write(' with nearby people and places');
    }

    // Add environment context
    if (environmentSummary.dominantEnvironments.isNotEmpty) {
      buffer.write(buffer.isEmpty ? 'Time' : ', time');
      buffer.write(' in ${environmentSummary.dominantEnvironments.first}');
    }

    return buffer.toString().isEmpty
        ? 'A quiet day with collected memories'
        : '${buffer.toString()}.';
  }

  /// Generate rich AI narrative using all timeline and context data
  ///
  /// Creates 150-300 word narrative with:
  /// - Opening with time/location context
  /// - Chronological timeline events (calendar, photos, locations)
  /// - Natural transitions based on time/distance
  /// - Event descriptions with place names, objects, attendees
  /// - Closing with day summary stats
  Future<String> generateRichNarrative() async {
    final builder = DataRichNarrativeBuilder();
    return await builder.buildNarrative(context: this);
  }
}

/// Environmental analysis summary
class EnvironmentSummary {
  final List<String> dominantEnvironments;
  final Map<String, int> environmentCounts;
  final List<String> weatherConditions;
  final TimeOfDayAnalysis timeOfDayAnalysis;

  EnvironmentSummary({
    required this.dominantEnvironments,
    required this.environmentCounts,
    required this.weatherConditions,
    required this.timeOfDayAnalysis,
  });
}

/// Social interaction analysis
class SocialSummary {
  final int totalPeopleDetected;
  final double averageGroupSize;
  final List<String> socialContexts; // solo, small_group, large_group
  final Map<String, int> socialActivityCounts;
  final bool hadSignificantSocialTime;

  SocialSummary({
    required this.totalPeopleDetected,
    required this.averageGroupSize,
    required this.socialContexts,
    required this.socialActivityCounts,
    required this.hadSignificantSocialTime,
  });
}

/// Activity pattern analysis
class ActivitySummary {
  final List<String> primaryActivities;
  final Map<String, Duration> activityDurations;
  final List<String> detectedObjects;
  final List<String> environments;
  final bool hadPhysicalActivity;
  final bool hadCreativeActivity;
  final bool hadWorkActivity;

  ActivitySummary({
    required this.primaryActivities,
    required this.activityDurations,
    required this.detectedObjects,
    required this.environments,
    required this.hadPhysicalActivity,
    required this.hadCreativeActivity,
    required this.hadWorkActivity,
  });
}

/// Location and movement analysis
class LocationSummary {
  final List<String> significantPlaces;
  final double totalDistance; // meters
  final Duration timeMoving;
  final Duration timeStationary;
  final List<String> movementModes; // walking, driving, stationary
  final Map<String, Duration> placeTimeSpent;

  // Enhanced with place names from reverse geocoding
  final Map<String, String> placeNames; // coordinate key -> place name
  final double totalKilometers; // convenience accessor for distance in km
  final String formattedDistance; // human-readable distance like "2.3km"

  LocationSummary({
    required this.significantPlaces,
    required this.totalDistance,
    required this.timeMoving,
    required this.timeStationary,
    required this.movementModes,
    required this.placeTimeSpent,
    this.placeNames = const {},
    double? totalKilometers,
    String? formattedDistance,
  })  : totalKilometers = totalKilometers ?? totalDistance / 1000,
        formattedDistance = formattedDistance ?? _formatDistance(totalDistance);

  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get place name for a coordinate, fallback to coordinate string
  String getPlaceName(double latitude, double longitude) {
    final key = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    return placeNames[key] ?? '$latitude, $longitude';
  }

  /// Check if we have place names available
  bool get hasPlaceNames => placeNames.isNotEmpty;
}

/// Time of day analysis
class TimeOfDayAnalysis {
  final int morningPhotos;
  final int afternoonPhotos;
  final int eveningPhotos;
  final String mostActiveTime;
  final Map<String, int> activityByTimeOfDay;

  TimeOfDayAnalysis({
    required this.morningPhotos,
    required this.afternoonPhotos,
    required this.eveningPhotos,
    required this.mostActiveTime,
    required this.activityByTimeOfDay,
  });
}

/// Proximity and social interaction analysis from BLE/location data
class ProximitySummary {
  final int nearbyDevicesDetected;
  final List<String> frequentProximityLocations;
  final Map<String, Duration> locationDwellTimes;
  final bool hasProximityInteractions;
  final List<String> geofenceTransitions;

  ProximitySummary({
    required this.nearbyDevicesDetected,
    required this.frequentProximityLocations,
    required this.locationDwellTimes,
    required this.hasProximityInteractions,
    required this.geofenceTransitions,
  });
}

/// Written content and thought analysis
class WrittenContentSummary {
  final List<String> locationNoteContent;
  final List<String> significantThemes;
  final int totalWrittenEntries;
  final bool hasSignificantContent;
  final Map<String, int> emotionalTones;
  final List<String> keyTopics;

  WrittenContentSummary({
    required this.locationNoteContent,
    required this.significantThemes,
    required this.totalWrittenEntries,
    required this.hasSignificantContent,
    required this.emotionalTones,
    required this.keyTopics,
  });
}

/// Service to synthesize all daily data into comprehensive context
class DailyContextSynthesizer {
  static final DailyContextSynthesizer _instance = DailyContextSynthesizer._internal();
  factory DailyContextSynthesizer() => _instance;
  DailyContextSynthesizer._internal();

  final AIFeatureExtractor _aiExtractor = AIFeatureExtractor();
  final CalendarService _calendarService = CalendarService();
  final DistanceCalculator _distanceCalculator = DistanceCalculator();
  final LocationClusterNamer _locationClusterNamer = LocationClusterNamer();
  final TimelineEventAggregator _timelineAggregator = TimelineEventAggregator();
  final ActivityValidator _activityValidator = ActivityValidator();

  /// Synthesize comprehensive daily context from all data sources
  Future<DailyContext> synthesizeDailyContext({
    required DateTime date,
    required MediaDatabase mediaDatabase,
    required LocationDatabase locationDatabase,
    required List<DataActivity> activities,
    Set<String>? enabledCalendarIds,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      // Collect all data in parallel for efficiency
      final results = await Future.wait([
        _getPhotoContexts(mediaDatabase, startOfDay, endOfDay),
        _getCalendarEvents(startOfDay, endOfDay, enabledCalendarIds),
        _getLocationData(locationDatabase, startOfDay, endOfDay),
        _getMovementData(locationDatabase, startOfDay, endOfDay),
        _getGeofenceEvents(locationDatabase, startOfDay, endOfDay),
        _getLocationNotes(locationDatabase, startOfDay, endOfDay),
      ]);

      final photoContexts = results[0] as List<PhotoContext>;
      final calendarEvents = results[1] as List<CalendarEventData>;
      final locationPoints = results[2] as List<LocationPoint>;
      final movementData = results[3] as List<MovementDataData>;
      final geofenceEvents = results[4] as List<GeofenceEvent>;
      final locationNotes = results[5] as List<LocationNote>;

      // Filter activities for the day
      final dayActivities = activities.where((activity) {
        return activity.timestamp.isAfter(startOfDay) &&
               activity.timestamp.isBefore(endOfDay);
      }).toList();

      // Analyze and synthesize insights
      final environmentSummary = _analyzeEnvironment(photoContexts, calendarEvents);
      final socialSummary = _analyzeSocialContext(photoContexts, calendarEvents);
      final activitySummary = _analyzeActivities(photoContexts, calendarEvents, dayActivities);
      final locationSummary = await _analyzeLocation(locationPoints, movementData, calendarEvents);
      final proximitySummary = _analyzeProximity(geofenceEvents, locationPoints, locationNotes);
      final writtenContentSummary = _analyzeWrittenContent(locationNotes);

      // Aggregate timeline events with calendar filtering
      final timelineEvents = await _timelineAggregator.aggregateTimeline(
        date: date,
        calendarEvents: calendarEvents,
        locationPoints: locationPoints,
        photoContexts: photoContexts,
        activities: dayActivities,
        movementData: movementData,
        enabledCalendarIds: enabledCalendarIds,
        locationPlaceNames: locationSummary.placeNames,
      );

      // Calculate overall confidence
      final overallConfidence = _calculateOverallConfidence(
        photoContexts, calendarEvents, locationPoints, dayActivities, geofenceEvents, locationNotes,
      );

      // Generate metadata for additional insights
      final metadata = _generateMetadata(
        photoContexts, calendarEvents, locationPoints, dayActivities, movementData, geofenceEvents, locationNotes,
      );

      return DailyContext(
        date: date,
        photoContexts: photoContexts,
        calendarEvents: calendarEvents,
        locationPoints: locationPoints,
        activities: dayActivities,
        movementData: movementData,
        geofenceEvents: geofenceEvents,
        locationNotes: locationNotes,
        environmentSummary: environmentSummary,
        socialSummary: socialSummary,
        activitySummary: activitySummary,
        locationSummary: locationSummary,
        proximitySummary: proximitySummary,
        writtenContentSummary: writtenContentSummary,
        overallConfidence: overallConfidence,
        metadata: metadata,
        timelineEvents: timelineEvents,
      );
    } catch (e) {
      debugPrint('Error synthesizing daily context: $e');

      // Return minimal context on error
      return DailyContext(
        date: date,
        photoContexts: [],
        calendarEvents: [],
        locationPoints: [],
        activities: [],
        movementData: [],
        geofenceEvents: [],
        locationNotes: [],
        timelineEvents: [],
        environmentSummary: EnvironmentSummary(
          dominantEnvironments: [],
          environmentCounts: {},
          weatherConditions: [],
          timeOfDayAnalysis: TimeOfDayAnalysis(
            morningPhotos: 0,
            afternoonPhotos: 0,
            eveningPhotos: 0,
            mostActiveTime: 'unknown',
            activityByTimeOfDay: {},
          ),
        ),
        socialSummary: SocialSummary(
          totalPeopleDetected: 0,
          averageGroupSize: 0.0,
          socialContexts: [],
          socialActivityCounts: {},
          hadSignificantSocialTime: false,
        ),
        activitySummary: ActivitySummary(
          primaryActivities: [],
          activityDurations: {},
          detectedObjects: [],
          environments: [],
          hadPhysicalActivity: false,
          hadCreativeActivity: false,
          hadWorkActivity: false,
        ),
        locationSummary: LocationSummary(
          significantPlaces: [],
          totalDistance: 0.0,
          timeMoving: Duration.zero,
          timeStationary: Duration.zero,
          movementModes: [],
          placeTimeSpent: {},
        ),
        proximitySummary: ProximitySummary(
          nearbyDevicesDetected: 0,
          frequentProximityLocations: [],
          locationDwellTimes: {},
          hasProximityInteractions: false,
          geofenceTransitions: [],
        ),
        writtenContentSummary: WrittenContentSummary(
          locationNoteContent: [],
          significantThemes: [],
          totalWrittenEntries: 0,
          hasSignificantContent: false,
          emotionalTones: {},
          keyTopics: [],
        ),
        overallConfidence: 0.0,
        metadata: {},
      );
    }
  }

  /// Get photo contexts for the day using AI analysis
  Future<List<PhotoContext>> _getPhotoContexts(
    MediaDatabase mediaDatabase,
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    final mediaItems = await mediaDatabase.getMediaByDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
      includeDeleted: false,
      processedOnly: false,
    );

    if (mediaItems.isEmpty) return [];

    try {
      // Analyze photos with AI feature extraction
      return await _aiExtractor.analyzePhotos(mediaItems);
    } catch (e) {
      debugPrint('Error analyzing photos: $e');
      return [];
    }
  }

  /// Get calendar events for the day
  Future<List<CalendarEventData>> _getCalendarEvents(
    DateTime startOfDay,
    DateTime endOfDay,
    Set<String>? enabledCalendarIds,
  ) async {
    try {
      return await _calendarService.getEventsInRange(
        startOfDay,
        endOfDay,
        enabledCalendarIds: enabledCalendarIds,
      );
    } catch (e) {
      debugPrint('Error getting calendar events: $e');
      return [];
    }
  }

  /// Get location data for the day
  Future<List<LocationPoint>> _getLocationData(
    LocationDatabase locationDatabase,
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      return await locationDatabase.getLocationPointsBetween(startOfDay, endOfDay);
    } catch (e) {
      debugPrint('Error getting location data: $e');
      return [];
    }
  }

  /// Get movement data for the day
  Future<List<MovementDataData>> _getMovementData(
    LocationDatabase locationDatabase,
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      // Query movement data directly using the database interface
      return await (locationDatabase.select(locationDatabase.movementData)
            ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(startOfDay) &
                           tbl.timestamp.isSmallerOrEqualValue(endOfDay))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]))
          .get();
    } catch (e) {
      debugPrint('Error getting movement data: $e');
      return [];
    }
  }

  /// Get geofence events for the day
  Future<List<GeofenceEvent>> _getGeofenceEvents(
    LocationDatabase locationDatabase,
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      return await (locationDatabase.select(locationDatabase.geofenceEvents)
            ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(startOfDay) &
                           tbl.timestamp.isSmallerOrEqualValue(endOfDay))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]))
          .get();
    } catch (e) {
      debugPrint('Error getting geofence events: $e');
      return [];
    }
  }

  /// Get location notes for the day
  Future<List<LocationNote>> _getLocationNotes(
    LocationDatabase locationDatabase,
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      return await (locationDatabase.select(locationDatabase.locationNotes)
            ..where((tbl) => tbl.timestamp.isBiggerOrEqualValue(startOfDay) &
                           tbl.timestamp.isSmallerOrEqualValue(endOfDay))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]))
          .get();
    } catch (e) {
      debugPrint('Error getting location notes: $e');
      return [];
    }
  }

  /// Analyze environmental context from photos and calendar
  EnvironmentSummary _analyzeEnvironment(
    List<PhotoContext> photoContexts,
    List<CalendarEventData> calendarEvents,
  ) {
    final environmentCounts = <String, int>{};
    final weatherConditions = <String>{};

    // Analyze photo environments
    for (final photo in photoContexts) {
      for (final label in photo.sceneLabels) {
        environmentCounts[label] = (environmentCounts[label] ?? 0) + 1;
      }
    }

    // Infer environments from calendar events
    for (final event in calendarEvents) {
      if (event.location != null && event.location!.isNotEmpty) {
        final location = event.location!.toLowerCase();
        if (location.contains('outdoor') ||
            location.contains('park') ||
            location.contains('beach')) {
          environmentCounts['outdoor'] = (environmentCounts['outdoor'] ?? 0) + 1;
        } else if (location.contains('office') ||
                   location.contains('work')) {
          environmentCounts['workplace'] = (environmentCounts['workplace'] ?? 0) + 1;
        } else if (location.contains('restaurant') ||
                   location.contains('cafe')) {
          environmentCounts['dining'] = (environmentCounts['dining'] ?? 0) + 1;
        }
      }
    }

    // Get dominant environments
    final sortedEnvironments = environmentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dominantEnvironments = sortedEnvironments
        .take(3)
        .map((e) => e.key)
        .toList();

    // Analyze time of day patterns
    final timeOfDayAnalysis = _analyzeTimeOfDay(photoContexts, calendarEvents);

    return EnvironmentSummary(
      dominantEnvironments: dominantEnvironments,
      environmentCounts: environmentCounts,
      weatherConditions: weatherConditions.toList(),
      timeOfDayAnalysis: timeOfDayAnalysis,
    );
  }

  /// Analyze social context from photos and calendar
  SocialSummary _analyzeSocialContext(
    List<PhotoContext> photoContexts,
    List<CalendarEventData> calendarEvents,
  ) {
    int totalPeopleDetected = 0;
    final groupSizes = <int>[];
    final socialContexts = <String>{};
    final socialActivityCounts = <String, int>{};

    // Analyze photo social context
    for (final photo in photoContexts) {
      totalPeopleDetected += photo.faceCount;

      if (photo.faceCount > 0) {
        groupSizes.add(photo.faceCount);

        if (photo.socialContext.isSelfie) {
          socialContexts.add('selfie');
          socialActivityCounts['selfie'] = (socialActivityCounts['selfie'] ?? 0) + 1;
        } else if (photo.socialContext.isGroupPhoto) {
          if (photo.faceCount <= 3) {
            socialContexts.add('small_group');
            socialActivityCounts['small_group'] = (socialActivityCounts['small_group'] ?? 0) + 1;
          } else {
            socialContexts.add('large_group');
            socialActivityCounts['large_group'] = (socialActivityCounts['large_group'] ?? 0) + 1;
          }
        } else {
          socialContexts.add('solo');
          socialActivityCounts['solo'] = (socialActivityCounts['solo'] ?? 0) + 1;
        }
      }
    }

    // Analyze calendar social context
    for (final event in calendarEvents) {
      if (event.attendees.isNotEmpty) {
        final attendeeCount = event.attendees.length + 1; // +1 for user
        groupSizes.add(attendeeCount);
        totalPeopleDetected += event.attendees.length;

        if (attendeeCount <= 3) {
          socialContexts.add('meeting_small');
          socialActivityCounts['meeting_small'] = (socialActivityCounts['meeting_small'] ?? 0) + 1;
        } else {
          socialContexts.add('meeting_large');
          socialActivityCounts['meeting_large'] = (socialActivityCounts['meeting_large'] ?? 0) + 1;
        }
      }
    }

    final averageGroupSize = groupSizes.isNotEmpty
        ? groupSizes.reduce((a, b) => a + b) / groupSizes.length
        : 0.0;

    final hadSignificantSocialTime = totalPeopleDetected > 2 ||
                                    socialActivityCounts.values.any((count) => count >= 3);

    return SocialSummary(
      totalPeopleDetected: totalPeopleDetected,
      averageGroupSize: averageGroupSize,
      socialContexts: socialContexts.toList(),
      socialActivityCounts: socialActivityCounts,
      hadSignificantSocialTime: hadSignificantSocialTime,
    );
  }

  /// Analyze activities from all data sources
  ActivitySummary _analyzeActivities(
    List<PhotoContext> photoContexts,
    List<CalendarEventData> calendarEvents,
    List<DataActivity> activities,
  ) {
    final activitySet = <String>{};
    final activityDurations = <String, Duration>{};
    final detectedObjects = <String>{};
    final environments = <String>{};

    // Analyze photo activities
    for (final photo in photoContexts) {
      activitySet.add(photo.activityDescription);
      detectedObjects.addAll(photo.objectLabels);
      environments.addAll(photo.sceneLabels);
    }

    // Analyze calendar activities
    for (final event in calendarEvents) {
      final eventType = _categorizeCalendarEvent(event);
      activitySet.add(eventType);

      final duration = event.endDate?.difference(event.startDate) ?? Duration(hours: 1);
      activityDurations[eventType] = (activityDurations[eventType] ?? Duration.zero) + duration;
    }

    // Analyze system activities
    for (final activity in activities) {
      activitySet.add(activity.action);
    }

    // Categorize activities
    final physicalActivities = {'outdoor activity', 'sports', 'exercise', 'walking', 'running'};
    final creativeActivities = {'creative', 'art', 'music', 'writing', 'design'};
    final workActivities = {'work-related', 'meeting', 'office', 'professional'};

    final hadPhysicalActivity = activitySet.any((activity) =>
        physicalActivities.any((physical) => activity.toLowerCase().contains(physical)));
    final hadCreativeActivity = activitySet.any((activity) =>
        creativeActivities.any((creative) => activity.toLowerCase().contains(creative)));
    final hadWorkActivity = activitySet.any((activity) =>
        workActivities.any((work) => activity.toLowerCase().contains(work)));

    // Get primary activities (most frequent/longest duration)
    final primaryActivities = activitySet.take(3).toList();

    return ActivitySummary(
      primaryActivities: primaryActivities,
      activityDurations: activityDurations,
      detectedObjects: detectedObjects.toList(),
      environments: environments.toList(),
      hadPhysicalActivity: hadPhysicalActivity,
      hadCreativeActivity: hadCreativeActivity,
      hadWorkActivity: hadWorkActivity,
    );
  }

  /// Analyze location and movement patterns
  Future<LocationSummary> _analyzeLocation(
    List<LocationPoint> locationPoints,
    List<MovementDataData> movementData,
    List<CalendarEventData> calendarEvents,
  ) async {
    final significantPlaces = <String>{};
    Duration timeMoving = Duration.zero;
    Duration timeStationary = Duration.zero;
    final movementModes = <String>{};
    final placeTimeSpent = <String, Duration>{};

    // Calculate total distance using DistanceCalculator
    final totalDistance = _distanceCalculator.calculateTotalDistance(locationPoints);

    // Get place names using LocationClusterNamer (with reverse geocoding if enabled)
    final placeNames = await _locationClusterNamer.getPlaceNames(locationPoints);

    // Analyze location clusters for significant places
    if (locationPoints.isNotEmpty) {
      final clusterCenters = _clusterLocations(locationPoints);

      // Add place names from reverse geocoding or coordinate-based names
      for (final centerPoint in clusterCenters) {
        final key = '${centerPoint.latitude.toStringAsFixed(4)},${centerPoint.longitude.toStringAsFixed(4)}';
        final placeName = placeNames[key] ?? _locationToPlaceName(centerPoint);
        significantPlaces.add(placeName);
      }
    }

    // Validate and correct activity types using speed-based analysis
    final validatedLocationPoints = _activityValidator.validateSequence(locationPoints);

    // Analyze movement data from validated location points
    for (final location in validatedLocationPoints) {
      if (location.activityType != null) {
        movementModes.add(location.activityType!);

        // Determine if moving or stationary based on activity type
        if (location.activityType == 'still' || location.activityType == 'stationary') {
          timeStationary += Duration(minutes: 1); // Approximate
        } else {
          timeMoving += Duration(minutes: 1);
        }
      }
    }

    // Add calendar locations
    for (final event in calendarEvents) {
      if (event.location != null && event.location!.isNotEmpty) {
        significantPlaces.add(event.location!);
        final duration = event.endDate?.difference(event.startDate) ?? Duration(hours: 1);
        placeTimeSpent[event.location!] =
            (placeTimeSpent[event.location!] ?? Duration.zero) + duration;
      }
    }

    return LocationSummary(
      significantPlaces: significantPlaces.toList(),
      totalDistance: totalDistance,
      timeMoving: timeMoving,
      timeStationary: timeStationary,
      movementModes: movementModes.toList(),
      placeTimeSpent: placeTimeSpent,
      placeNames: placeNames,
    );
  }

  /// Calculate center point of a location cluster
  // Unused: Future feature for cluster analysis
  /* LocationPoint _calculateClusterCenter(List<LocationPoint> cluster) {
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
  } */

  /// Analyze time of day patterns
  TimeOfDayAnalysis _analyzeTimeOfDay(
    List<PhotoContext> photoContexts,
    List<CalendarEventData> calendarEvents,
  ) {
    int morningPhotos = 0;
    int afternoonPhotos = 0;
    int eveningPhotos = 0;
    final activityByTimeOfDay = <String, int>{};

    for (final photo in photoContexts) {
      final hour = photo.timestamp.hour;
      if (hour >= 6 && hour < 12) {
        morningPhotos++;
        activityByTimeOfDay['morning'] = (activityByTimeOfDay['morning'] ?? 0) + 1;
      } else if (hour >= 12 && hour < 18) {
        afternoonPhotos++;
        activityByTimeOfDay['afternoon'] = (activityByTimeOfDay['afternoon'] ?? 0) + 1;
      } else {
        eveningPhotos++;
        activityByTimeOfDay['evening'] = (activityByTimeOfDay['evening'] ?? 0) + 1;
      }
    }

    // Determine most active time
    String mostActiveTime = 'morning';
    int maxActivity = morningPhotos;
    if (afternoonPhotos > maxActivity) {
      mostActiveTime = 'afternoon';
      maxActivity = afternoonPhotos;
    }
    if (eveningPhotos > maxActivity) {
      mostActiveTime = 'evening';
    }

    return TimeOfDayAnalysis(
      morningPhotos: morningPhotos,
      afternoonPhotos: afternoonPhotos,
      eveningPhotos: eveningPhotos,
      mostActiveTime: mostActiveTime,
      activityByTimeOfDay: activityByTimeOfDay,
    );
  }

  /// Calculate overall confidence score
  double _calculateOverallConfidence(
    List<PhotoContext> photoContexts,
    List<CalendarEventData> calendarEvents,
    List<LocationPoint> locationPoints,
    List<DataActivity> activities,
    List<GeofenceEvent> geofenceEvents,
    List<LocationNote> locationNotes,
  ) {
    double confidence = 0.0;

    // Photo analysis confidence
    if (photoContexts.isNotEmpty) {
      final avgPhotoConfidence = photoContexts
          .map((p) => p.confidenceScore)
          .reduce((a, b) => a + b) / photoContexts.length;
      confidence += avgPhotoConfidence * 0.4;
    }

    // Calendar data adds structure
    confidence += (calendarEvents.length * 0.1).clamp(0.0, 0.3);

    // Location data adds context
    confidence += (locationPoints.length * 0.001).clamp(0.0, 0.2);

    // Activity tracking adds detail
    confidence += (activities.length * 0.02).clamp(0.0, 0.1);

    // Written content adds narrative depth
    confidence += (locationNotes.length * 0.05).clamp(0.0, 0.15);

    // Geofence events add location context
    confidence += (geofenceEvents.length * 0.03).clamp(0.0, 0.1);

    return confidence.clamp(0.0, 1.0);
  }

  /// Generate additional metadata
  Map<String, dynamic> _generateMetadata(
    List<PhotoContext> photoContexts,
    List<CalendarEventData> calendarEvents,
    List<LocationPoint> locationPoints,
    List<DataActivity> activities,
    List<MovementDataData> movementData,
    List<GeofenceEvent> geofenceEvents,
    List<LocationNote> locationNotes,
  ) {
    return {
      'photo_count': photoContexts.length,
      'calendar_events_count': calendarEvents.length,
      'location_points_count': locationPoints.length,
      'activities_count': activities.length,
      'movement_samples_count': movementData.length,
      'geofence_events_count': geofenceEvents.length,
      'location_notes_count': locationNotes.length,
      'synthesis_timestamp': DateTime.now().toIso8601String(),
      'data_completeness': _calculateDataCompleteness(
        photoContexts, calendarEvents, locationPoints, activities, geofenceEvents, locationNotes,
      ),
    };
  }

  /// Helper methods for data processing

  String _categorizeCalendarEvent(CalendarEventData event) {
    final title = event.title.toLowerCase();

    if (title.contains('meeting') || title.contains('call') ||
        title.contains('interview') || title.contains('conference')) {
      return 'meeting';
    } else if (title.contains('workout') || title.contains('gym') ||
               title.contains('run') || title.contains('sport')) {
      return 'exercise';
    } else if (title.contains('meal') || title.contains('lunch') ||
               title.contains('dinner') || title.contains('breakfast')) {
      return 'dining';
    } else if (title.contains('travel') || title.contains('flight') ||
               title.contains('trip')) {
      return 'travel';
    } else if (title.contains('doctor') || title.contains('appointment') ||
               title.contains('medical')) {
      return 'health';
    } else {
      return 'general';
    }
  }

  List<LocationPoint> _clusterLocations(List<LocationPoint> points) {
    // Simple clustering algorithm - group nearby points
    final clusters = <LocationPoint>[];
    const double clusterRadius = 100.0; // 100 meters

    for (final point in points) {
      bool addedToCluster = false;

      for (final cluster in clusters) {
        final distance = _calculateDistance(
          point.latitude, point.longitude,
          cluster.latitude, cluster.longitude,
        );

        if (distance <= clusterRadius) {
          addedToCluster = true;
          break;
        }
      }

      if (!addedToCluster) {
        clusters.add(point);
      }
    }

    return clusters;
  }

  String _locationToPlaceName(LocationPoint point) {
    // In a real implementation, this would use reverse geocoding
    // For now, return a generic description
    return 'Location ${point.latitude.toStringAsFixed(3)},${point.longitude.toStringAsFixed(3)}';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _calculateDataCompleteness(
    List<PhotoContext> photoContexts,
    List<CalendarEventData> calendarEvents,
    List<LocationPoint> locationPoints,
    List<DataActivity> activities,
    List<GeofenceEvent> geofenceEvents,
    List<LocationNote> locationNotes,
  ) {
    double completeness = 0.0;

    // Weight different data types
    if (photoContexts.isNotEmpty) completeness += 0.3;
    if (calendarEvents.isNotEmpty) completeness += 0.25;
    if (locationPoints.isNotEmpty) completeness += 0.15;
    if (activities.isNotEmpty) completeness += 0.1;
    if (geofenceEvents.isNotEmpty) completeness += 0.1;
    if (locationNotes.isNotEmpty) completeness += 0.1;

    return completeness;
  }

  /// Analyze proximity and geofence interactions
  ProximitySummary _analyzeProximity(
    List<GeofenceEvent> geofenceEvents,
    List<LocationPoint> locationPoints,
    List<LocationNote> locationNotes,
  ) {
    final geofenceTransitions = <String>[];
    final locationDwellTimes = <String, Duration>{};
    final frequentProximityLocations = <String>{};

    // Analyze geofence transitions
    for (final event in geofenceEvents) {
      geofenceTransitions.add('${event.eventType} at ${event.geofenceId}');

      if (event.eventType == 'dwell' && event.dwellTime != null) {
        final duration = Duration(seconds: event.dwellTime!);
        locationDwellTimes[event.geofenceId] =
            (locationDwellTimes[event.geofenceId] ?? Duration.zero) + duration;
      }
    }

    // Identify frequent proximity locations from location notes
    for (final note in locationNotes) {
      if (note.placeName != null && note.placeName!.isNotEmpty) {
        frequentProximityLocations.add(note.placeName!);
      }
    }

    final hasProximityInteractions = geofenceEvents.isNotEmpty ||
                                   locationNotes.isNotEmpty ||
                                   locationDwellTimes.values.any((d) => d.inMinutes > 10);

    return ProximitySummary(
      nearbyDevicesDetected: 0, // TODO: Implement BLE device detection
      frequentProximityLocations: frequentProximityLocations.toList(),
      locationDwellTimes: locationDwellTimes,
      hasProximityInteractions: hasProximityInteractions,
      geofenceTransitions: geofenceTransitions,
    );
  }

  /// Analyze written content and extract insights
  WrittenContentSummary _analyzeWrittenContent(
    List<LocationNote> locationNotes,
  ) {
    final locationNoteContent = <String>[];
    final significantThemes = <String>{};
    final emotionalTones = <String, int>{};
    final keyTopics = <String>{};

    for (final note in locationNotes) {
      locationNoteContent.add(note.content);

      // Simple keyword-based theme detection
      final content = note.content.toLowerCase();

      // Emotional tone detection
      if (content.contains('happy') || content.contains('joy') ||
          content.contains('excited') || content.contains('great')) {
        emotionalTones['positive'] = (emotionalTones['positive'] ?? 0) + 1;
      }
      if (content.contains('sad') || content.contains('frustrated') ||
          content.contains('tired') || content.contains('difficult')) {
        emotionalTones['negative'] = (emotionalTones['negative'] ?? 0) + 1;
      }
      if (content.contains('calm') || content.contains('peaceful') ||
          content.contains('reflective') || content.contains('thinking')) {
        emotionalTones['reflective'] = (emotionalTones['reflective'] ?? 0) + 1;
      }

      // Theme detection
      if (content.contains('work') || content.contains('meeting') ||
          content.contains('project') || content.contains('task')) {
        significantThemes.add('work');
      }
      if (content.contains('family') || content.contains('friend') ||
          content.contains('people') || content.contains('social')) {
        significantThemes.add('relationships');
      }
      if (content.contains('nature') || content.contains('outdoor') ||
          content.contains('walk') || content.contains('park')) {
        significantThemes.add('nature');
      }
      if (content.contains('food') || content.contains('meal') ||
          content.contains('restaurant') || content.contains('cooking')) {
        significantThemes.add('food');
      }
      if (content.contains('travel') || content.contains('trip') ||
          content.contains('journey') || content.contains('explore')) {
        significantThemes.add('travel');
      }

      // Extract key topics (simple word frequency)
      final words = content.split(RegExp(r'\W+'))
          .where((w) => w.length > 3)
          .where((w) => !['this', 'that', 'with', 'from', 'they', 'have', 'been', 'were'].contains(w));
      keyTopics.addAll(words);
    }

    final hasSignificantContent = locationNotes.length > 2 ||
                                 locationNoteContent.any((c) => c.length > 50) ||
                                 significantThemes.length > 2;

    return WrittenContentSummary(
      locationNoteContent: locationNoteContent,
      significantThemes: significantThemes.toList(),
      totalWrittenEntries: locationNotes.length,
      hasSignificantContent: hasSignificantContent,
      emotionalTones: emotionalTones,
      keyTopics: keyTopics.take(10).toList(), // Top 10 key topics
    );
  }
}

