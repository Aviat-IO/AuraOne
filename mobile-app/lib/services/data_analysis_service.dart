import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:health/health.dart';
import 'package:photo_manager/photo_manager.dart';
import '../database/location_database.dart';
import '../database/media_database.dart';
import '../providers/location_database_provider.dart';
import '../providers/media_database_provider.dart';
import '../providers/service_providers.dart';
import 'calendar_service.dart';
import 'health_service.dart';
import 'photo_service.dart';
import 'ai_service.dart';
import '../utils/logger.dart';

/// Provider for the DataAnalysisService
final dataAnalysisServiceProvider = Provider<DataAnalysisService>((ref) {
  final locationDb = ref.watch(locationDatabaseProvider);
  final mediaDb = ref.watch(mediaDatabaseProvider);
  final calendarService = ref.watch(calendarServiceProvider);
  final healthService = ref.watch(healthServiceProvider);
  final photoService = ref.watch(photoServiceProvider);
  final aiService = ref.watch(aiServiceProvider);
  
  return DataAnalysisService(
    locationDb: locationDb,
    mediaDb: mediaDb,
    calendarService: calendarService,
    healthService: healthService,
    photoService: photoService,
    aiService: aiService,
  );
});

/// Service for analyzing and aggregating sensor data for AI summary generation
class DataAnalysisService {
  static final _logger = AppLogger('DataAnalysisService');
  
  final LocationDatabase locationDb;
  final MediaDatabase mediaDb;
  final CalendarService calendarService;
  final HealthService healthService;
  final PhotoService photoService;
  final AIService aiService;
  
  DataAnalysisService({
    required this.locationDb,
    required this.mediaDb,
    required this.calendarService,
    required this.healthService,
    required this.photoService,
    required this.aiService,
  });
  
  /// Generate a daily summary for the given date
  Future<String?> generateDailySummary({DateTime? date}) async {
    try {
      date ??= DateTime.now();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      _logger.info('Generating daily summary for ${startOfDay.toIso8601String()}');
      
      // Aggregate all data sources
      final context = await _aggregateDataForSummary(startOfDay, endOfDay);
      
      // Check if we have enough data to generate a summary
      if (!_hasMinimalData(context)) {
        _logger.info('Insufficient data for summary generation');
        return null;
      }
      
      // Generate summary using AI service
      final journalEntry = await aiService.generateJournalEntry(
        date: date,
        customContext: context,
      );
      
      return journalEntry.content;
    } catch (e, stack) {
      _logger.error('Failed to generate daily summary', error: e, stackTrace: stack);
      return null;
    }
  }
  
  /// Aggregate data from all sources for the given time period
  Future<Map<String, dynamic>> _aggregateDataForSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final context = <String, dynamic>{};
    
    try {
      // 1. Location data
      final locations = await _getLocationData(startDate, endDate);
      context['locations'] = locations;
      
      // 2. Calendar events
      final events = await _getCalendarData(startDate, endDate);
      context['events'] = events;
      
      // 3. Photos and media
      final media = await _getMediaData(startDate, endDate);
      context['media'] = media;
      
      // 4. Health data
      final health = await _getHealthData(startDate, endDate);
      context['health'] = health;
      
      // 5. Calculate statistics
      final stats = _calculateDailyStats(locations, events, media, health);
      context['stats'] = stats;
      
      // 6. Identify patterns and highlights
      final patterns = _identifyPatterns(context);
      context['patterns'] = patterns;
      
      _logger.info('Aggregated data context: ${context.keys.join(', ')}');
      
      return context;
    } catch (e, stack) {
      _logger.error('Failed to aggregate data', error: e, stackTrace: stack);
      return context;
    }
  }
  
  /// Get location data for the time period
  Future<Map<String, dynamic>> _getLocationData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final locations = await locationDb.getLocationsBetween(startDate, endDate);
      
      // Group locations by significant places
      final places = <String, List<LocationPoint>>{};
      final movements = <Map<String, dynamic>>[];
      
      for (final location in locations) {
        // Simple place clustering (can be enhanced with geofencing)
        final placeKey = '${location.latitude.toStringAsFixed(3)},${location.longitude.toStringAsFixed(3)}';
        places.putIfAbsent(placeKey, () => []).add(location);
      }
      
      // Calculate distance traveled
      double totalDistance = 0;
      for (int i = 1; i < locations.length; i++) {
        totalDistance += _calculateDistance(
          locations[i-1].latitude,
          locations[i-1].longitude,
          locations[i].latitude,
          locations[i].longitude,
        );
      }
      
      return {
        'places_visited': places.length,
        'total_distance_km': (totalDistance / 1000).toStringAsFixed(1),
        'time_range': {
          'start': locations.isNotEmpty ? locations.first.timestamp.toIso8601String() : null,
          'end': locations.isNotEmpty ? locations.last.timestamp.toIso8601String() : null,
        },
        'significant_locations': places.entries
            .where((e) => e.value.length > 5) // Places where user spent time
            .map((e) => {
              'coordinates': e.key,
              'duration_minutes': _calculateDuration(e.value),
              'visits': e.value.length,
            })
            .toList(),
      };
    } catch (e) {
      _logger.warning('Failed to get location data: $e');
      return {};
    }
  }
  
  /// Get calendar data for the time period
  Future<Map<String, dynamic>> _getCalendarData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final events = await calendarService.getEventsInRange(startDate, endDate);
      
      return {
        'event_count': events.length,
        'events': events.map((e) => {
          'title': e.title,
          'start': e.startDate.toIso8601String(),
          'end': e.endDate?.toIso8601String(),
          'location': e.location,
          'all_day': e.isAllDay,
        }).toList(),
      };
    } catch (e) {
      _logger.warning('Failed to get calendar data: $e');
      return {'event_count': 0, 'events': []};
    }
  }
  
  /// Get media data for the time period
  Future<Map<String, dynamic>> _getMediaData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get recent photos (limited to 1 day range)
      final duration = endDate.difference(startDate);
      final photos = await photoService.getRecentPhotos(
        limit: 100,
      );
      
      // Filter photos to the specific date range
      final filteredPhotos = <AssetEntity>[];
      for (final photo in photos) {
        final photoDate = photo.createDateTime ?? DateTime.fromMillisecondsSinceEpoch(photo.createDateSecond! * 1000);
        if (photoDate.isAfter(startDate) && photoDate.isBefore(endDate)) {
          filteredPhotos.add(photo);
        }
      }
      
      // Get media from database
      final mediaItems = await mediaDb.getRecentMedia(
        duration: duration,
        limit: 100,
      );
      
      // Filter media to the specific date range
      final filteredMedia = mediaItems.where((item) =>
        item.createdDate.isAfter(startDate) && item.createdDate.isBefore(endDate)
      ).toList();
      
      return {
        'photo_count': filteredPhotos.length,
        'media_count': filteredMedia.length,
        'photos': filteredPhotos.take(10).map((p) => {
          'id': p.id,
          'created_date': p.createDateTime?.toIso8601String() ?? 
            DateTime.fromMillisecondsSinceEpoch(p.createDateSecond! * 1000).toIso8601String(),
          'has_location': p.latitude != null && p.longitude != null,
        }).toList(),
        'media_types': _categorizeMediaTypes(filteredMedia),
      };
    } catch (e) {
      _logger.warning('Failed to get media data: $e');
      return {'photo_count': 0, 'media_count': 0};
    }
  }
  
  /// Get health data for the time period
  Future<Map<String, dynamic>> _getHealthData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final healthData = await healthService.getHealthDataInRange(startDate, endDate);
      
      // Calculate health statistics
      int totalSteps = 0;
      double totalActiveEnergy = 0;
      
      for (final data in healthData) {
        if (data.type == HealthDataType.STEPS) {
          totalSteps += (data.value as num).toInt();
        } else if (data.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          totalActiveEnergy += (data.value as num).toDouble();
        }
      }
      
      return {
        'steps': totalSteps,
        'active_energy': totalActiveEnergy.toStringAsFixed(0),
        'data_points': healthData.length,
      };
    } catch (e) {
      _logger.warning('Failed to get health data: $e');
      return {'steps': 0, 'active_energy': '0', 'data_points': 0};
    }
  }
  
  /// Calculate daily statistics
  Map<String, dynamic> _calculateDailyStats(
    Map<String, dynamic> locations,
    Map<String, dynamic> events,
    Map<String, dynamic> media,
    Map<String, dynamic> health,
  ) {
    return {
      'activity_level': _calculateActivityLevel(locations, health),
      'social_interactions': events['event_count'] ?? 0,
      'creativity_score': media['photo_count'] ?? 0,
      'movement_score': _calculateMovementScore(locations),
    };
  }
  
  /// Identify patterns in the aggregated data
  Map<String, dynamic> _identifyPatterns(Map<String, dynamic> context) {
    final patterns = <String, dynamic>{};
    
    // Identify day type (busy, relaxed, productive, etc.)
    final events = context['events'] as Map<String, dynamic>?;
    final eventCount = events?['event_count'] ?? 0;
    
    if (eventCount > 5) {
      patterns['day_type'] = 'busy';
    } else if (eventCount > 2) {
      patterns['day_type'] = 'productive';
    } else {
      patterns['day_type'] = 'relaxed';
    }
    
    // Identify activity patterns
    final health = context['health'] as Map<String, dynamic>?;
    final steps = health?['steps'] ?? 0;
    
    if (steps > 10000) {
      patterns['activity_pattern'] = 'very_active';
    } else if (steps > 5000) {
      patterns['activity_pattern'] = 'active';
    } else {
      patterns['activity_pattern'] = 'sedentary';
    }
    
    // Identify significant moments
    final media = context['media'] as Map<String, dynamic>?;
    final photoCount = media?['photo_count'] ?? 0;
    
    if (photoCount > 20) {
      patterns['memory_capture'] = 'high';
    } else if (photoCount > 5) {
      patterns['memory_capture'] = 'moderate';
    } else {
      patterns['memory_capture'] = 'low';
    }
    
    return patterns;
  }
  
  /// Check if we have minimal data to generate a summary
  bool _hasMinimalData(Map<String, dynamic> context) {
    // Need at least some data from any source
    final locations = context['locations'] as Map<String, dynamic>?;
    final events = context['events'] as Map<String, dynamic>?;
    final media = context['media'] as Map<String, dynamic>?;
    final health = context['health'] as Map<String, dynamic>?;
    
    final hasLocationData = locations != null && locations['places_visited'] != null && locations['places_visited'] > 0;
    final hasEventData = events != null && events['event_count'] != null && events['event_count'] > 0;
    final hasMediaData = media != null && media['photo_count'] != null && media['photo_count'] > 0;
    final hasHealthData = health != null && health['steps'] != null && health['steps'] > 0;
    
    return hasLocationData || hasEventData || hasMediaData || hasHealthData;
  }
  
  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
  
  double _toRadians(double degree) => degree * 3.14159265359 / 180;
  
  /// Calculate duration spent at a location
  int _calculateDuration(List<LocationPoint> points) {
    if (points.isEmpty) return 0;
    
    final first = points.first.timestamp;
    final last = points.last.timestamp;
    return last.difference(first).inMinutes;
  }
  
  /// Calculate activity level based on movement and health data
  String _calculateActivityLevel(
    Map<String, dynamic> locations,
    Map<String, dynamic> health,
  ) {
    final distance = double.tryParse(locations['total_distance_km']?.toString() ?? '0') ?? 0;
    final steps = health['steps'] ?? 0;
    
    if (steps > 10000 || distance > 10) {
      return 'high';
    } else if (steps > 5000 || distance > 5) {
      return 'moderate';
    } else {
      return 'low';
    }
  }
  
  /// Calculate movement score
  int _calculateMovementScore(Map<String, dynamic> locations) {
    final placesVisited = locations['places_visited'] ?? 0;
    final distance = double.tryParse(locations['total_distance_km']?.toString() ?? '0') ?? 0;
    
    // Simple scoring: places visited * 10 + distance in km
    return (placesVisited * 10 + distance).toInt();
  }
  
  /// Categorize media types
  Map<String, int> _categorizeMediaTypes(List<MediaItem> items) {
    final types = <String, int>{};
    
    for (final item in items) {
      final type = item.mimeType.split('/').first; // Get type from mime type (e.g., 'image', 'video')
      types[type] = (types[type] ?? 0) + 1;
    }
    
    return types;
  }
}