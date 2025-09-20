import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../database/media_database.dart';
import '../database/location_database.dart';
import '../services/calendar_service.dart';
import '../providers/data_activity_tracker.dart';
import 'ai_feature_extractor.dart';

/// Comprehensive daily context that synthesizes all collected data
class DailyContext {
  final DateTime date;
  final List<PhotoContext> photoContexts;
  final List<CalendarEventData> calendarEvents;
  final List<LocationPoint> locationPoints;
  final List<DataActivity> activities;
  final List<MovementDataData> movementData;
  final EnvironmentSummary environmentSummary;
  final SocialSummary socialSummary;
  final ActivitySummary activitySummary;
  final LocationSummary locationSummary;
  final double overallConfidence;
  final Map<String, dynamic> metadata;

  DailyContext({
    required this.date,
    required this.photoContexts,
    required this.calendarEvents,
    required this.locationPoints,
    required this.activities,
    required this.movementData,
    required this.environmentSummary,
    required this.socialSummary,
    required this.activitySummary,
    required this.locationSummary,
    required this.overallConfidence,
    required this.metadata,
  });

  /// Generate a human-readable narrative overview
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

    // Add environment context
    if (environmentSummary.dominantEnvironments.isNotEmpty) {
      buffer.write(buffer.isEmpty ? 'Time' : ', time');
      buffer.write(' in ${environmentSummary.dominantEnvironments.first}');
    }

    return buffer.toString().isEmpty
        ? 'A quiet day with collected memories'
        : '${buffer.toString()}.';
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
  final double totalDistance;
  final Duration timeMoving;
  final Duration timeStationary;
  final List<String> movementModes; // walking, driving, stationary
  final Map<String, Duration> placeTimeSpent;

  LocationSummary({
    required this.significantPlaces,
    required this.totalDistance,
    required this.timeMoving,
    required this.timeStationary,
    required this.movementModes,
    required this.placeTimeSpent,
  });
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

/// Service to synthesize all daily data into comprehensive context
class DailyContextSynthesizer {
  static final DailyContextSynthesizer _instance = DailyContextSynthesizer._internal();
  factory DailyContextSynthesizer() => _instance;
  DailyContextSynthesizer._internal();

  final AIFeatureExtractor _aiExtractor = AIFeatureExtractor();
  final CalendarService _calendarService = CalendarService();

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
      ]);

      final photoContexts = results[0] as List<PhotoContext>;
      final calendarEvents = results[1] as List<CalendarEventData>;
      final locationPoints = results[2] as List<LocationPoint>;
      final movementData = results[3] as List<MovementDataData>;

      // Filter activities for the day
      final dayActivities = activities.where((activity) {
        return activity.timestamp.isAfter(startOfDay) &&
               activity.timestamp.isBefore(endOfDay);
      }).toList();

      // Analyze and synthesize insights
      final environmentSummary = _analyzeEnvironment(photoContexts, calendarEvents);
      final socialSummary = _analyzeSocialContext(photoContexts, calendarEvents);
      final activitySummary = _analyzeActivities(photoContexts, calendarEvents, dayActivities);
      final locationSummary = _analyzeLocation(locationPoints, movementData, calendarEvents);

      // Calculate overall confidence
      final overallConfidence = _calculateOverallConfidence(
        photoContexts, calendarEvents, locationPoints, dayActivities,
      );

      // Generate metadata for additional insights
      final metadata = _generateMetadata(
        photoContexts, calendarEvents, locationPoints, dayActivities, movementData,
      );

      return DailyContext(
        date: date,
        photoContexts: photoContexts,
        calendarEvents: calendarEvents,
        locationPoints: locationPoints,
        activities: dayActivities,
        movementData: movementData,
        environmentSummary: environmentSummary,
        socialSummary: socialSummary,
        activitySummary: activitySummary,
        locationSummary: locationSummary,
        overallConfidence: overallConfidence,
        metadata: metadata,
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
  LocationSummary _analyzeLocation(
    List<LocationPoint> locationPoints,
    List<MovementDataData> movementData,
    List<CalendarEventData> calendarEvents,
  ) {
    final significantPlaces = <String>{};
    double totalDistance = 0.0;
    Duration timeMoving = Duration.zero;
    Duration timeStationary = Duration.zero;
    final movementModes = <String>{};
    final placeTimeSpent = <String, Duration>{};

    // Analyze location clusters for significant places
    if (locationPoints.isNotEmpty) {
      final clusters = _clusterLocations(locationPoints);
      significantPlaces.addAll(clusters.map((c) => _locationToPlaceName(c)));

      // Calculate total distance
      for (int i = 1; i < locationPoints.length; i++) {
        final prev = locationPoints[i - 1];
        final curr = locationPoints[i];
        totalDistance += _calculateDistance(
          prev.latitude, prev.longitude,
          curr.latitude, curr.longitude,
        );
      }
    }

    // Analyze movement data
    for (final movement in movementData) {
      final movementState = movement.state;
      movementModes.add(movementState);

      if (movementState == 'still') {
        timeStationary += Duration(minutes: 1); // Approximate
      } else {
        timeMoving += Duration(minutes: 1);
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
    );
  }

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

    return confidence.clamp(0.0, 1.0);
  }

  /// Generate additional metadata
  Map<String, dynamic> _generateMetadata(
    List<PhotoContext> photoContexts,
    List<CalendarEventData> calendarEvents,
    List<LocationPoint> locationPoints,
    List<DataActivity> activities,
    List<MovementDataData> movementData,
  ) {
    return {
      'photo_count': photoContexts.length,
      'calendar_events_count': calendarEvents.length,
      'location_points_count': locationPoints.length,
      'activities_count': activities.length,
      'movement_samples_count': movementData.length,
      'synthesis_timestamp': DateTime.now().toIso8601String(),
      'data_completeness': _calculateDataCompleteness(
        photoContexts, calendarEvents, locationPoints, activities,
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
  ) {
    double completeness = 0.0;

    // Weight different data types
    if (photoContexts.isNotEmpty) completeness += 0.4;
    if (calendarEvents.isNotEmpty) completeness += 0.3;
    if (locationPoints.isNotEmpty) completeness += 0.2;
    if (activities.isNotEmpty) completeness += 0.1;

    return completeness;
  }
}

