import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../database/location_database.dart' as loc_db;
import '../../database/media_database.dart';
import 'narrative_generation.dart';
import 'multimodal_fusion.dart';
import 'activity_recognition.dart';

/// Simplified AI Service for generating daily summaries
class SimpleAIService {
  static final _instance = SimpleAIService._internal();
  factory SimpleAIService() => _instance;
  SimpleAIService._internal();

  bool _isInitialized = false;
  loc_db.LocationDatabase? _locationDb;
  MediaDatabase? _mediaDb;

  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize({
    loc_db.LocationDatabase? locationDb,
    MediaDatabase? mediaDb,
  }) async {
    _locationDb = locationDb;
    _mediaDb = mediaDb;
    _isInitialized = true;
    debugPrint('Simple AI Service initialized');
  }

  /// Generate a daily summary
  Future<SimpleDailySummary> generateDailySummary({
    required DateTime date,
    NarrativeStyle style = NarrativeStyle.casual,
  }) async {
    debugPrint('Generating daily summary for ${date.toIso8601String()}');

    // Get data from databases
    final locationData = await _getLocationData(date);
    final mediaData = await _getMediaData(date);

    // Generate narrative based on available data
    String narrative;
    String summary;
    List<SimpleEvent> events = [];

    if (locationData.isEmpty && mediaData.isEmpty) {
      // No data available
      narrative = "No activity data recorded for this day.";
      summary = "No data available";
    } else {
      // Build a simple narrative
      final buffer = StringBuffer();

      // Opening
      buffer.writeln(_generateOpening(date, locationData.length, mediaData.length));

      // Location summary
      if (locationData.isNotEmpty) {
        buffer.writeln(_generateLocationSummary(locationData));

        // Create simple events from location clusters
        events = _createEventsFromLocations(locationData);
      }

      // Media summary
      if (mediaData.isNotEmpty) {
        buffer.writeln(_generateMediaSummary(mediaData));
      }

      // Closing
      buffer.writeln(_generateClosing(locationData.length, mediaData.length));

      narrative = buffer.toString().trim();
      summary = _generateBriefSummary(locationData.length, mediaData.length);
    }

    return SimpleDailySummary(
      date: date,
      narrative: narrative,
      summary: summary,
      events: events,
      style: style,
      confidence: 0.7,
      dataPoints: {
        'locations': locationData.length,
        'photos': mediaData.length,
      },
    );
  }

  Future<List<loc_db.LocationPoint>> _getLocationData(DateTime date) async {
    if (_locationDb == null) return [];

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final points = await _locationDb!.getLocationPointsBetween(
        startOfDay,
        endOfDay,
      );

      return points;
    } catch (e) {
      debugPrint('Error getting location data: $e');
      return [];
    }
  }

  Future<List<dynamic>> _getMediaData(DateTime date) async {
    if (_mediaDb == null) return [];

    try {
      // Get media for the day
      final media = await _mediaDb!.getRecentMedia(
        duration: const Duration(days: 30), // Get recent media
        limit: 500,
      );

      // Filter to only this day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return media.where((m) {
        final createdDate = m.createdDate;
        return createdDate.isAfter(startOfDay) &&
               createdDate.isBefore(endOfDay);
      }).toList();
    } catch (e) {
      debugPrint('Error getting media data: $e');
      return [];
    }
  }

  String _generateOpening(DateTime date, int locationCount, int mediaCount) {
    final weekday = _getWeekdayName(date.weekday);

    if (locationCount > 0 && mediaCount > 0) {
      return "Your $weekday was filled with activity and memorable moments.";
    } else if (locationCount > 0) {
      return "You were active this $weekday, visiting several locations.";
    } else if (mediaCount > 0) {
      return "You captured some moments this $weekday.";
    } else {
      return "A quiet $weekday.";
    }
  }

  String _generateLocationSummary(List<loc_db.LocationPoint> locations) {
    // Group locations into clusters (simplified)
    final clusters = _clusterLocations(locations);

    if (clusters.isEmpty) {
      return "You stayed in one general area throughout the day.";
    } else if (clusters.length == 1) {
      return "You spent most of your day in one location.";
    } else {
      return "You visited ${clusters.length} different locations throughout the day.";
    }
  }

  String _generateMediaSummary(List<dynamic> media) {
    final photoCount = media.where((m) => m.mimeType?.startsWith('image/') ?? false).length;
    final videoCount = media.where((m) => m.mimeType?.startsWith('video/') ?? false).length;

    if (photoCount > 0 && videoCount > 0) {
      return "You captured $photoCount photos and $videoCount videos.";
    } else if (photoCount > 0) {
      return "You took $photoCount photo${photoCount > 1 ? 's' : ''}.";
    } else if (videoCount > 0) {
      return "You recorded $videoCount video${videoCount > 1 ? 's' : ''}.";
    } else {
      return "";
    }
  }

  String _generateClosing(int locationCount, int mediaCount) {
    final totalActivity = locationCount + mediaCount;

    if (totalActivity > 50) {
      return "It was a very active and eventful day!";
    } else if (totalActivity > 20) {
      return "A moderately active day with several memorable moments.";
    } else if (totalActivity > 0) {
      return "A calm day with a few activities.";
    } else {
      return "";
    }
  }

  String _generateBriefSummary(int locationCount, int mediaCount) {
    if (locationCount > 0 && mediaCount > 0) {
      return "Active day with $locationCount location points and $mediaCount media items";
    } else if (locationCount > 0) {
      return "$locationCount location points recorded";
    } else if (mediaCount > 0) {
      return "$mediaCount media items captured";
    } else {
      return "No activity recorded";
    }
  }

  List<SimpleEvent> _createEventsFromLocations(List<loc_db.LocationPoint> locations) {
    final clusters = _clusterLocations(locations);
    final events = <SimpleEvent>[];

    for (int i = 0; i < clusters.length && i < 5; i++) {
      final cluster = clusters[i];
      events.add(SimpleEvent(
        id: 'event_$i',
        startTime: cluster.first.timestamp,
        endTime: cluster.last.timestamp,
        type: EventType.stay,
        activities: [ActivityType.stationary],
        locationId: 'location_$i',
        metadata: {
          'pointCount': cluster.length,
          'latitude': cluster.first.latitude,
          'longitude': cluster.first.longitude,
        },
      ));
    }

    return events;
  }

  List<List<loc_db.LocationPoint>> _clusterLocations(List<loc_db.LocationPoint> locations) {
    if (locations.isEmpty) return [];

    // Simple time-based clustering
    final clusters = <List<loc_db.LocationPoint>>[];
    List<loc_db.LocationPoint> currentCluster = [];

    for (final point in locations) {
      if (currentCluster.isEmpty) {
        currentCluster.add(point);
      } else {
        final lastPoint = currentCluster.last;
        final timeDiff = point.timestamp.difference(lastPoint.timestamp);

        // If more than 30 minutes apart, start new cluster
        if (timeDiff.inMinutes > 30) {
          if (currentCluster.isNotEmpty) {
            clusters.add(List.from(currentCluster));
          }
          currentCluster = [point];
        } else {
          currentCluster.add(point);
        }
      }
    }

    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    return clusters;
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }

  void dispose() {
    _isInitialized = false;
    _locationDb = null;
    _mediaDb = null;
  }
}

/// Simple daily summary result
class SimpleDailySummary {
  final DateTime date;
  final String narrative;
  final String summary;
  final List<SimpleEvent> events;
  final NarrativeStyle style;
  final double confidence;
  final Map<String, dynamic> dataPoints;

  SimpleDailySummary({
    required this.date,
    required this.narrative,
    required this.summary,
    required this.events,
    required this.style,
    required this.confidence,
    required this.dataPoints,
  });
}

/// Simple event representation
class SimpleEvent {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final List<ActivityType> activities;
  final String? locationId;
  final Map<String, dynamic> metadata;

  SimpleEvent({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.activities,
    this.locationId,
    this.metadata = const {},
  });
}