import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../database/media_database.dart';
import 'calendar_service.dart';
import 'health_service.dart';
import 'ble_scanning_service.dart';
import 'photo_service.dart';

/// Data source types for attribution
enum DataSourceType {
  manual,           // User-entered data
  calendar,         // Calendar events
  health,           // Health and fitness data
  photos,           // Photo library
  bluetooth,        // BLE proximity detection
  location,         // Location services
  system,           // System-generated
}

/// Data source attribution
class DataAttribution {
  final String id;
  final DataSourceType sourceType;
  final String sourceName;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? originalId;
  final double confidence;

  DataAttribution({
    required this.id,
    required this.sourceType,
    required this.sourceName,
    required this.timestamp,
    this.metadata = const {},
    this.originalId,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceType': sourceType.name,
    'sourceName': sourceName,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
    'originalId': originalId,
    'confidence': confidence,
  };

  factory DataAttribution.fromJson(Map<String, dynamic> json) {
    return DataAttribution(
      id: json['id'] as String,
      sourceType: DataSourceType.values.firstWhere(
        (e) => e.name == json['sourceType'],
        orElse: () => DataSourceType.system,
      ),
      sourceName: json['sourceName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      originalId: json['originalId'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Aggregated data entry with source attribution
class AttributedDataEntry {
  final String id;
  final String title;
  final String? description;
  final DateTime timestamp;
  final List<DataAttribution> attributions;
  final Map<String, dynamic> data;
  final Set<String> tags;

  AttributedDataEntry({
    required this.id,
    required this.title,
    this.description,
    required this.timestamp,
    required this.attributions,
    required this.data,
    this.tags = const {},
  });

  /// Check if entry has a specific source type
  bool hasSource(DataSourceType type) {
    return attributions.any((attr) => attr.sourceType == type);
  }

  /// Get attributions for a specific source type
  List<DataAttribution> getAttributions(DataSourceType type) {
    return attributions.where((attr) => attr.sourceType == type).toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'attributions': attributions.map((a) => a.toJson()).toList(),
    'data': data,
    'tags': tags.toList(),
  };

  factory AttributedDataEntry.fromJson(Map<String, dynamic> json) {
    return AttributedDataEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      attributions: (json['attributions'] as List)
          .map((a) => DataAttribution.fromJson(a as Map<String, dynamic>))
          .toList(),
      data: json['data'] as Map<String, dynamic>? ?? {},
      tags: Set<String>.from(json['tags'] as List? ?? []),
    );
  }
}

/// Service for managing data attribution and source tracking
class DataAttributionService {
  static final _logger = AppLogger('DataAttributionService');
  static final _instance = DataAttributionService._internal();

  factory DataAttributionService() => _instance;
  DataAttributionService._internal();

  final CalendarService _calendarService = CalendarService();
  final HealthService _healthService = HealthService();
  final BleScanningService _bleService = BleScanningService();
  final PhotoService _photoService = PhotoService();

  /// Aggregate data from all sources for a time period
  Future<List<AttributedDataEntry>> aggregateDataForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    Set<DataSourceType>? includeSources,
  }) async {
    try {
      _logger.info('Aggregating data from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      final entries = <AttributedDataEntry>[];
      final sources = includeSources ?? DataSourceType.values.toSet();

      // Aggregate calendar events
      if (sources.contains(DataSourceType.calendar)) {
        final calendarEntries = await _aggregateCalendarData(startDate, endDate);
        entries.addAll(calendarEntries);
      }

      // Aggregate health data
      if (sources.contains(DataSourceType.health)) {
        final healthEntries = await _aggregateHealthData(startDate, endDate);
        entries.addAll(healthEntries);
      }

      // Aggregate photo data
      if (sources.contains(DataSourceType.photos)) {
        final photoEntries = await _aggregatePhotoData(startDate, endDate);
        entries.addAll(photoEntries);
      }

      // Aggregate BLE proximity data
      if (sources.contains(DataSourceType.bluetooth)) {
        final bleEntries = await _aggregateBleData(startDate, endDate);
        entries.addAll(bleEntries);
      }

      // Sort by timestamp
      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Merge related entries
      final mergedEntries = _mergeRelatedEntries(entries);

      _logger.info('Aggregated ${mergedEntries.length} entries from ${sources.length} sources');

      return mergedEntries;
    } catch (e, stack) {
      _logger.error('Failed to aggregate data', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Aggregate calendar data
  Future<List<AttributedDataEntry>> _aggregateCalendarData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final events = await _calendarService.getEvents(
        startDate: startDate,
        endDate: endDate,
      );

      return events.map((event) {
        final attribution = DataAttribution(
          id: 'cal_${event.id}',
          sourceType: DataSourceType.calendar,
          sourceName: 'Calendar: ${event.calendarId ?? 'Unknown'}',
          timestamp: event.startDate,
          metadata: {
            'calendarId': event.calendarId,
            'isAllDay': event.isAllDay,
            'hasAttendees': event.attendees.isNotEmpty,
          },
          originalId: event.id,
        );

        return AttributedDataEntry(
          id: 'entry_cal_${event.id}',
          title: event.title,
          description: event.description,
          timestamp: event.startDate,
          attributions: [attribution],
          data: {
            'location': event.location,
            'duration': event.endDate?.difference(event.startDate).inMinutes,
            'attendees': event.attendees,
            'url': event.url,
          },
          tags: _extractTagsFromText('${event.title} ${event.description ?? ''}'),
        );
      }).toList();
    } catch (e) {
      _logger.error('Failed to aggregate calendar data', error: e);
      return [];
    }
  }

  /// Aggregate health data
  Future<List<AttributedDataEntry>> _aggregateHealthData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final summary = await _healthService.getDailySummary(
        date: startDate,
      );

      if (summary.isEmpty) return [];

      final attribution = DataAttribution(
        id: 'health_${startDate.millisecondsSinceEpoch}',
        sourceType: DataSourceType.health,
        sourceName: 'Health Data',
        timestamp: startDate,
        metadata: {
          'hasSteps': summary['steps'] != null && summary['steps'] > 0,
          'hasWorkouts': (summary['workouts'] as List?)?.isNotEmpty ?? false,
        },
      );

      final entry = AttributedDataEntry(
        id: 'entry_health_${startDate.millisecondsSinceEpoch}',
        title: 'Daily Health Summary',
        description: _buildHealthSummaryDescription(summary),
        timestamp: startDate,
        attributions: [attribution],
        data: summary,
        tags: {'health', 'fitness', 'activity'},
      );

      return [entry];
    } catch (e) {
      _logger.error('Failed to aggregate health data', error: e);
      return [];
    }
  }

  /// Aggregate photo data
  Future<List<AttributedDataEntry>> _aggregatePhotoData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get photos from the time period
      // This would query the media database for photos in the date range

      final entries = <AttributedDataEntry>[];

      // TODO: Implement photo aggregation when media database is ready
      // For now, return empty list

      return entries;
    } catch (e) {
      _logger.error('Failed to aggregate photo data', error: e);
      return [];
    }
  }

  /// Aggregate BLE proximity data
  Future<List<AttributedDataEntry>> _aggregateBleData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final summary = _bleService.getProximitySummary();

      if (summary['totalDevices'] == 0) return [];

      final attribution = DataAttribution(
        id: 'ble_${DateTime.now().millisecondsSinceEpoch}',
        sourceType: DataSourceType.bluetooth,
        sourceName: 'Bluetooth Proximity',
        timestamp: DateTime.now(),
        metadata: summary,
      );

      final entry = AttributedDataEntry(
        id: 'entry_ble_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Nearby Devices',
        description: _buildBleSummaryDescription(summary),
        timestamp: DateTime.now(),
        attributions: [attribution],
        data: summary,
        tags: {'proximity', 'bluetooth', 'devices'},
      );

      return [entry];
    } catch (e) {
      _logger.error('Failed to aggregate BLE data', error: e);
      return [];
    }
  }

  /// Merge related entries based on time proximity and content
  List<AttributedDataEntry> _mergeRelatedEntries(List<AttributedDataEntry> entries) {
    if (entries.isEmpty) return entries;

    final merged = <AttributedDataEntry>[];
    AttributedDataEntry? current;

    for (final entry in entries) {
      if (current == null) {
        current = entry;
        continue;
      }

      // Check if entries are within 30 minutes and have overlapping tags
      final timeDiff = entry.timestamp.difference(current.timestamp).inMinutes.abs();
      final hasOverlappingTags = current.tags.intersection(entry.tags).isNotEmpty;

      if (timeDiff <= 30 && hasOverlappingTags) {
        // Merge entries
        current = AttributedDataEntry(
          id: current.id,
          title: current.title,
          description: '${current.description ?? ''}\n${entry.description ?? ''}'.trim(),
          timestamp: current.timestamp,
          attributions: [...current.attributions, ...entry.attributions],
          data: {...current.data, ...entry.data},
          tags: current.tags.union(entry.tags),
        );
      } else {
        merged.add(current);
        current = entry;
      }
    }

    if (current != null) {
      merged.add(current);
    }

    return merged;
  }

  /// Build health summary description
  String _buildHealthSummaryDescription(Map<String, dynamic> summary) {
    final parts = <String>[];

    if (summary['steps'] != null && summary['steps'] > 0) {
      parts.add('${summary['steps']} steps');
    }

    if (summary['distance'] != null && summary['distance'] > 0) {
      final km = (summary['distance'] / 1000).toStringAsFixed(1);
      parts.add('${km}km');
    }

    if (summary['calories'] != null && summary['calories'] > 0) {
      parts.add('${summary['calories'].toStringAsFixed(0)} calories');
    }

    final workouts = summary['workouts'] as List?;
    if (workouts != null && workouts.isNotEmpty) {
      parts.add('${workouts.length} workout(s)');
    }

    return parts.isEmpty ? 'No activity data' : parts.join(', ');
  }

  /// Build BLE summary description
  String _buildBleSummaryDescription(Map<String, dynamic> summary) {
    final totalDevices = summary['totalDevices'] ?? 0;
    final zones = summary['zones'] as Map<String, dynamic>? ?? {};

    if (totalDevices == 0) {
      return 'No devices detected';
    }

    final parts = <String>['$totalDevices device(s) nearby'];

    final immediate = zones['immediate'] ?? 0;
    final near = zones['near'] ?? 0;

    if (immediate > 0) {
      parts.add('$immediate very close');
    }
    if (near > 0) {
      parts.add('$near nearby');
    }

    return parts.join(', ');
  }

  /// Extract tags from text
  Set<String> _extractTagsFromText(String text) {
    final tags = <String>{};
    final words = text.toLowerCase().split(RegExp(r'\s+'));

    // Common activity keywords
    const activityKeywords = {
      'meeting', 'workout', 'exercise', 'lunch', 'dinner', 'breakfast',
      'travel', 'work', 'home', 'office', 'gym', 'run', 'walk',
      'call', 'appointment', 'event', 'task', 'reminder',
    };

    for (final word in words) {
      if (activityKeywords.contains(word)) {
        tags.add(word);
      }
    }

    return tags;
  }

  /// Get attribution summary for a time period
  Future<Map<String, dynamic>> getAttributionSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final entries = await aggregateDataForPeriod(
        startDate: startDate,
        endDate: endDate,
      );

      final summary = <String, dynamic>{
        'totalEntries': entries.length,
        'sourceCounts': {},
        'tagCounts': {},
        'timeDistribution': {},
      };

      // Count by source
      for (final sourceType in DataSourceType.values) {
        final count = entries.where((e) => e.hasSource(sourceType)).length;
        if (count > 0) {
          summary['sourceCounts'][sourceType.name] = count;
        }
      }

      // Count tags
      final tagCounts = <String, int>{};
      for (final entry in entries) {
        for (final tag in entry.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
      summary['tagCounts'] = tagCounts;

      // Time distribution (by hour of day)
      final hourCounts = <int, int>{};
      for (final entry in entries) {
        final hour = entry.timestamp.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
      summary['timeDistribution'] = hourCounts;

      return summary;
    } catch (e, stack) {
      _logger.error('Failed to get attribution summary', error: e, stackTrace: stack);
      return {};
    }
  }
}
