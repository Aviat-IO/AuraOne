import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/daily_context_synthesizer.dart';
import 'package:mobile_app/services/ai/cloud_gemini_adapter.dart';
import 'package:mobile_app/services/ai_feature_extractor.dart';
import 'package:mobile_app/services/calendar_service.dart';
import 'package:mobile_app/database/location_database.dart';

void main() {
  group('Journal Prompt Quality Tests', () {
    late CloudGeminiAdapter adapter;

    setUp(() {
      adapter = CloudGeminiAdapter();
    });

    test('Task 5.4: Sparse data day context', () async {
      final sparseContext = _createSparseContext();
      
      expect(sparseContext.photoContexts.length, lessThan(3));
      expect(sparseContext.calendarEvents.length, lessThan(2));
      expect(sparseContext.locationSummary.significantPlaces.length, lessThan(3));
      
      expect(sparseContext.overallConfidence, lessThan(0.5));
    });

    test('Task 5.5: Data-rich day context', () async {
      final richContext = _createRichContext();
      
      expect(richContext.photoContexts.length, greaterThan(5));
      expect(richContext.calendarEvents.length, greaterThan(2));
      expect(richContext.locationSummary.significantPlaces.length, greaterThan(3));
      expect(richContext.timelineEvents.length, greaterThan(8));
      
      expect(richContext.overallConfidence, greaterThan(0.6));
    });

    test('Task 5.6: Imperial measurements for US locale', () {
      final context = _createContextWithDistance(kilometers: 10.0);
      
      expect(context.locationSummary.totalKilometers, equals(10.0));
      
      final miles = context.locationSummary.totalKilometers * 0.621371;
      expect(miles, closeTo(6.2, 0.1));
    });

    test('Task 5.6: Metric measurements for non-US locale', () {
      final context = _createContextWithDistance(kilometers: 5.5);
      
      expect(context.locationSummary.totalKilometers, equals(5.5));
      expect(context.locationSummary.formattedDistance, equals('5.5km'));
    });

    test('Task 5.1: Context with person detections formatted correctly', () {
      final context = _createContextWithPeople(peopleCount: 3);
      
      expect(context.socialSummary.totalPeopleDetected, equals(3));
      expect(context.socialSummary.socialContexts.isNotEmpty, isTrue);
    });

    test('Task 5.1: Context with activities formatted correctly', () {
      final context = _createContextWithActivities();
      
      expect(context.activitySummary.primaryActivities.isNotEmpty, isTrue);
      expect(context.calendarEvents.isNotEmpty, isTrue);
    });

    test('Task 5.3: Quality metric - no robotic phrases', () {
      final narrativeExamples = [
        'Started the morning with a long walk through the park.',
        'Met up with a friend for coffee downtown.',
        'Spent the afternoon working from home on the quarterly report.',
      ];
      
      final roboticPhrases = [
        'photographed',
        'captured',
        'you can see',
        'visible in',
        'from where I was standing',
        'shadow on the pavement',
      ];
      
      for (final example in narrativeExamples) {
        for (final phrase in roboticPhrases) {
          expect(
            example.toLowerCase().contains(phrase),
            isFalse,
            reason: 'Good narrative should not contain "$phrase"',
          );
        }
      }
    });

    test('Task 5.3: Quality metric - proper grammar and complete sentences', () {
      final goodExample = 'Started the morning with a long walk through the park. '
          'The fall colors were particularly vibrant today.';
      
      expect(goodExample.endsWith('.'), isTrue);
      expect(goodExample.contains(RegExp(r'[A-Z]')), isTrue);
      
      final sentenceCount = '.'.allMatches(goodExample).length;
      expect(sentenceCount, greaterThan(1));
    });

    test('Task 5.3: Quality metric - no photo-technical details', () {
      final badPhrases = [
        'camera angle',
        'lighting conditions',
        'image composition',
        'photo shows',
        'reflection',
        'background clutter',
      ];
      
      final goodNarrative = 'Visited Liberty Park in the afternoon. '
          'Spent time on the swings with family members.';
      
      for (final phrase in badPhrases) {
        expect(
          goodNarrative.toLowerCase().contains(phrase),
          isFalse,
          reason: 'Should not contain technical detail: "$phrase"',
        );
      }
    });
  });
}

DailyContext _createSparseContext() {
  return DailyContext(
    date: DateTime(2024, 1, 15),
    photoContexts: [
      PhotoContext(
        timestamp: DateTime(2024, 1, 15, 10, 0),
        objectLabels: ['table'],
        sceneLabels: ['indoor'],
        detectedObjects: ['table'],
        faceCount: 0,
        confidenceScore: 0.7,
        activityDescription: 'indoor scene',
        socialContext: SocialContext(
          isSelfie: false,
          isGroupPhoto: false,
          hasPeople: false,
        ),
      ),
    ],
    calendarEvents: [],
    locationPoints: [],
    activities: [],
    movementData: [],
    geofenceEvents: [],
    locationNotes: [],
    timelineEvents: [],
    environmentSummary: EnvironmentSummary(
      dominantEnvironments: ['indoor'],
      environmentCounts: {'indoor': 1},
      weatherConditions: [],
      timeOfDayAnalysis: TimeOfDayAnalysis(
        morningPhotos: 1,
        afternoonPhotos: 0,
        eveningPhotos: 0,
        mostActiveTime: 'morning',
        activityByTimeOfDay: {'morning': 1},
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
      detectedObjects: ['table'],
      environments: ['indoor'],
      hadPhysicalActivity: false,
      hadCreativeActivity: false,
      hadWorkActivity: false,
    ),
    locationSummary: LocationSummary(
      significantPlaces: ['Home'],
      totalDistance: 100.0,
      timeMoving: Duration(minutes: 5),
      timeStationary: Duration(hours: 8),
      movementModes: ['still'],
      placeTimeSpent: {'Home': Duration(hours: 8)},
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
    overallConfidence: 0.3,
    metadata: {},
  );
}

DailyContext _createRichContext() {
  return DailyContext(
    date: DateTime(2024, 1, 15),
    photoContexts: List.generate(
      8,
      (i) => PhotoContext(
        timestamp: DateTime(2024, 1, 15, 9 + i),
        objectLabels: ['person', 'outdoor', 'building'],
        sceneLabels: ['outdoor', 'urban'],
        detectedObjects: ['person', 'building'],
        faceCount: 2,
        confidenceScore: 0.85,
        activityDescription: 'outdoor activity',
        socialContext: SocialContext(
          isSelfie: false,
          isGroupPhoto: true,
          hasPeople: true,
        ),
      ),
    ),
    calendarEvents: [
      CalendarEventData(
        id: '1',
        title: 'Team Meeting',
        startDate: DateTime(2024, 1, 15, 10, 0),
        endDate: DateTime(2024, 1, 15, 11, 0),
        location: 'Conference Room A',
        attendees: ['alice@example.com', 'bob@example.com'],
      ),
      CalendarEventData(
        id: '2',
        title: 'Lunch with Friends',
        startDate: DateTime(2024, 1, 15, 12, 30),
        endDate: DateTime(2024, 1, 15, 13, 30),
        location: 'Downtown Cafe',
        attendees: ['friend@example.com'],
      ),
      CalendarEventData(
        id: '3',
        title: 'Gym Workout',
        startDate: DateTime(2024, 1, 15, 18, 0),
        endDate: DateTime(2024, 1, 15, 19, 0),
        location: 'Fitness Center',
      ),
    ],
    locationPoints: [],
    activities: [],
    movementData: [],
    geofenceEvents: [],
    locationNotes: [],
    timelineEvents: List.generate(
      10,
      (i) => NarrativeEvent(
        type: NarrativeEventType.calendar,
        timestamp: DateTime(2024, 1, 15, 9 + i),
        meetingTitle: 'Event $i',
        placeName: 'Location $i',
      ),
    ),
    environmentSummary: EnvironmentSummary(
      dominantEnvironments: ['outdoor', 'urban', 'indoor'],
      environmentCounts: {'outdoor': 5, 'urban': 3, 'indoor': 2},
      weatherConditions: ['sunny'],
      timeOfDayAnalysis: TimeOfDayAnalysis(
        morningPhotos: 3,
        afternoonPhotos: 4,
        eveningPhotos: 1,
        mostActiveTime: 'afternoon',
        activityByTimeOfDay: {'morning': 3, 'afternoon': 4, 'evening': 1},
      ),
    ),
    socialSummary: SocialSummary(
      totalPeopleDetected: 16,
      averageGroupSize: 2.0,
      socialContexts: ['small_group', 'meeting_small'],
      socialActivityCounts: {'small_group': 5, 'meeting_small': 2},
      hadSignificantSocialTime: true,
    ),
    activitySummary: ActivitySummary(
      primaryActivities: ['meeting', 'dining', 'exercise'],
      activityDurations: {
        'meeting': Duration(hours: 1),
        'dining': Duration(hours: 1),
        'exercise': Duration(hours: 1),
      },
      detectedObjects: ['person', 'building', 'outdoor'],
      environments: ['outdoor', 'urban', 'indoor'],
      hadPhysicalActivity: true,
      hadCreativeActivity: false,
      hadWorkActivity: true,
    ),
    locationSummary: LocationSummary(
      significantPlaces: ['Office', 'Downtown Cafe', 'Fitness Center', 'Park'],
      totalDistance: 8500.0,
      timeMoving: Duration(hours: 2),
      timeStationary: Duration(hours: 6),
      movementModes: ['walking', 'driving'],
      placeTimeSpent: {
        'Office': Duration(hours: 4),
        'Downtown Cafe': Duration(hours: 1),
        'Fitness Center': Duration(hours: 1),
      },
    ),
    proximitySummary: ProximitySummary(
      nearbyDevicesDetected: 3,
      frequentProximityLocations: ['Office', 'Cafe'],
      locationDwellTimes: {
        'Office': Duration(hours: 4),
        'Cafe': Duration(hours: 1),
      },
      hasProximityInteractions: true,
      geofenceTransitions: ['enter Office', 'exit Office', 'enter Cafe'],
    ),
    writtenContentSummary: WrittenContentSummary(
      locationNoteContent: ['Great meeting today', 'Excellent coffee'],
      significantThemes: ['work', 'social'],
      totalWrittenEntries: 2,
      hasSignificantContent: true,
      emotionalTones: {'positive': 2},
      keyTopics: ['meeting', 'coffee', 'workout'],
    ),
    overallConfidence: 0.85,
    metadata: {
      'photo_count': 8,
      'calendar_events_count': 3,
      'location_points_count': 50,
    },
  );
}

DailyContext _createContextWithDistance({required double kilometers}) {
  final sparseContext = _createSparseContext();
  return DailyContext(
    date: sparseContext.date,
    photoContexts: sparseContext.photoContexts,
    calendarEvents: sparseContext.calendarEvents,
    locationPoints: sparseContext.locationPoints,
    activities: sparseContext.activities,
    movementData: sparseContext.movementData,
    geofenceEvents: sparseContext.geofenceEvents,
    locationNotes: sparseContext.locationNotes,
    timelineEvents: sparseContext.timelineEvents,
    environmentSummary: sparseContext.environmentSummary,
    socialSummary: sparseContext.socialSummary,
    activitySummary: sparseContext.activitySummary,
    locationSummary: LocationSummary(
      significantPlaces: ['Park', 'Home'],
      totalDistance: kilometers * 1000,
      timeMoving: Duration(hours: 2),
      timeStationary: Duration(hours: 6),
      movementModes: ['walking'],
      placeTimeSpent: {'Park': Duration(hours: 1), 'Home': Duration(hours: 7)},
    ),
    proximitySummary: sparseContext.proximitySummary,
    writtenContentSummary: sparseContext.writtenContentSummary,
    overallConfidence: sparseContext.overallConfidence,
    metadata: sparseContext.metadata,
  );
}

DailyContext _createContextWithPeople({required int peopleCount}) {
  final sparseContext = _createSparseContext();
  return DailyContext(
    date: sparseContext.date,
    photoContexts: [
      PhotoContext(
        timestamp: DateTime(2024, 1, 15, 14, 0),
        objectLabels: ['person', 'outdoor'],
        sceneLabels: ['outdoor', 'park'],
        detectedObjects: ['person'],
        faceCount: peopleCount,
        confidenceScore: 0.9,
        activityDescription: 'outdoor social activity',
        socialContext: SocialContext(
          isSelfie: false,
          isGroupPhoto: true,
          hasPeople: true,
        ),
      ),
    ],
    calendarEvents: sparseContext.calendarEvents,
    locationPoints: sparseContext.locationPoints,
    activities: sparseContext.activities,
    movementData: sparseContext.movementData,
    geofenceEvents: sparseContext.geofenceEvents,
    locationNotes: sparseContext.locationNotes,
    timelineEvents: sparseContext.timelineEvents,
    environmentSummary: sparseContext.environmentSummary,
    socialSummary: SocialSummary(
      totalPeopleDetected: peopleCount,
      averageGroupSize: peopleCount.toDouble(),
      socialContexts: ['small_group'],
      socialActivityCounts: {'small_group': 1},
      hadSignificantSocialTime: peopleCount > 2,
    ),
    activitySummary: sparseContext.activitySummary,
    locationSummary: sparseContext.locationSummary,
    proximitySummary: sparseContext.proximitySummary,
    writtenContentSummary: sparseContext.writtenContentSummary,
    overallConfidence: sparseContext.overallConfidence,
    metadata: sparseContext.metadata,
  );
}

DailyContext _createContextWithActivities() {
  final sparseContext = _createSparseContext();
  return DailyContext(
    date: sparseContext.date,
    photoContexts: sparseContext.photoContexts,
    calendarEvents: [
      CalendarEventData(
        id: '1',
        title: 'Morning Walk',
        startDate: DateTime(2024, 1, 15, 8, 0),
        endDate: DateTime(2024, 1, 15, 9, 0),
        location: 'Liberty Park',
      ),
      CalendarEventData(
        id: '2',
        title: 'Lunch Meeting',
        startDate: DateTime(2024, 1, 15, 12, 0),
        endDate: DateTime(2024, 1, 15, 13, 0),
        location: 'Downtown Restaurant',
        attendees: ['colleague@example.com'],
      ),
    ],
    locationPoints: sparseContext.locationPoints,
    activities: sparseContext.activities,
    movementData: sparseContext.movementData,
    geofenceEvents: sparseContext.geofenceEvents,
    locationNotes: sparseContext.locationNotes,
    timelineEvents: sparseContext.timelineEvents,
    environmentSummary: sparseContext.environmentSummary,
    socialSummary: sparseContext.socialSummary,
    activitySummary: ActivitySummary(
      primaryActivities: ['exercise', 'meeting', 'dining'],
      activityDurations: {
        'exercise': Duration(hours: 1),
        'meeting': Duration(hours: 1),
      },
      detectedObjects: ['outdoor', 'person'],
      environments: ['outdoor', 'indoor'],
      hadPhysicalActivity: true,
      hadCreativeActivity: false,
      hadWorkActivity: true,
    ),
    locationSummary: sparseContext.locationSummary,
    proximitySummary: sparseContext.proximitySummary,
    writtenContentSummary: sparseContext.writtenContentSummary,
    overallConfidence: 0.65,
    metadata: sparseContext.metadata,
  );
}
