import 'dart:io';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

/// Health data point wrapper
class HealthDataPoint {
  final HealthDataType type;
  final double value;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String? sourceName;
  final String? sourceId;
  final Map<String, dynamic>? metadata;

  HealthDataPoint({
    required this.type,
    required this.value,
    required this.dateFrom,
    required this.dateTo,
    this.sourceName,
    this.sourceId,
    this.metadata,
  });

  /// Convert from Health package data point
  factory HealthDataPoint.fromHealthPoint(HealthDataPoint point) {
    return HealthDataPoint(
      type: point.type,
      value: point.value,
      dateFrom: point.dateFrom,
      dateTo: point.dateTo,
      sourceName: point.sourceName,
      sourceId: point.sourceId,
    );
  }
}

/// Privacy settings for health data sync
class HealthPrivacySettings {
  final bool syncEnabled;
  final Set<HealthDataType> allowedTypes;
  final int historyDays;
  final bool aggregateOnly;
  final bool anonymizeSources;

  const HealthPrivacySettings({
    this.syncEnabled = false,
    this.allowedTypes = const {},
    this.historyDays = 30,
    this.aggregateOnly = false,
    this.anonymizeSources = false,
  });

  HealthPrivacySettings copyWith({
    bool? syncEnabled,
    Set<HealthDataType>? allowedTypes,
    int? historyDays,
    bool? aggregateOnly,
    bool? anonymizeSources,
  }) {
    return HealthPrivacySettings(
      syncEnabled: syncEnabled ?? this.syncEnabled,
      allowedTypes: allowedTypes ?? this.allowedTypes,
      historyDays: historyDays ?? this.historyDays,
      aggregateOnly: aggregateOnly ?? this.aggregateOnly,
      anonymizeSources: anonymizeSources ?? this.anonymizeSources,
    );
  }
}

/// Service for managing health and fitness data
class HealthService {
  static final _logger = AppLogger('HealthService');
  static final _instance = HealthService._internal();

  factory HealthService() => _instance;
  HealthService._internal();

  HealthPrivacySettings _privacySettings = const HealthPrivacySettings();

  /// Default health data types to request
  static const defaultHealthTypes = {
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WORKOUT,
    HealthDataType.MINDFULNESS,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
  };

  /// Get current privacy settings
  HealthPrivacySettings get privacySettings => _privacySettings;

  /// Update privacy settings
  void updatePrivacySettings(HealthPrivacySettings settings) {
    _privacySettings = settings;
    _logger.info('Health privacy settings updated: syncEnabled=${settings.syncEnabled}');
  }

  /// Configure Health package
  Future<void> configure() async {
    try {
      _logger.info('Configuring Health package');
      // Health().configure() no longer takes parameters in newer versions
    } catch (e, stack) {
      _logger.error('Failed to configure Health package',
                   error: e, stackTrace: stack);
    }
  }

  /// Request health permissions
  Future<bool> requestPermissions({Set<HealthDataType>? types}) async {
    try {
      _logger.info('Requesting health permissions');

      // Use provided types or default types
      final requestTypes = types ?? defaultHealthTypes;

      // Platform-specific permission handling
      if (Platform.isIOS) {
        // iOS uses HealthKit
        final authorized = await Health().requestAuthorization(
          requestTypes.toList(),
          permissions: requestTypes.map((t) => HealthDataAccess.READ).toList(),
        );

        if (authorized) {
          _logger.info('iOS HealthKit permissions granted');
          return true;
        } else {
          _logger.warning('iOS HealthKit permissions denied');
          return false;
        }
      } else if (Platform.isAndroid) {
        // Android uses Health Connect (Android 14+) or Google Fit

        // First check activity recognition permission for Google Fit
        final activityStatus = await Permission.activityRecognition.request();

        if (!activityStatus.isGranted) {
          _logger.warning('Android activity recognition permission denied');
          return false;
        }

        // Then request health data permissions
        final authorized = await Health().requestAuthorization(
          requestTypes.toList(),
          permissions: requestTypes.map((t) => HealthDataAccess.READ).toList(),
        );

        if (authorized) {
          _logger.info('Android Health permissions granted');
          return true;
        } else {
          _logger.warning('Android Health permissions denied');
          return false;
        }
      }

      return false;
    } catch (e, stack) {
      _logger.error('Failed to request health permissions',
                   error: e, stackTrace: stack);
      return false;
    }
  }

  /// Check if health permissions are granted
  Future<bool> hasPermissions({Set<HealthDataType>? types}) async {
    try {
      final checkTypes = types ?? defaultHealthTypes;

      // Check if we have permissions for all requested types
      final permissions = await Health().hasPermissions(
        checkTypes.toList(),
        permissions: checkTypes.map((t) => HealthDataAccess.READ).toList(),
      );

      return permissions ?? false;
    } catch (e) {
      _logger.error('Failed to check health permissions', error: e);
      return false;
    }
  }

  /// Get health data in a date range
  Future<List<HealthDataPoint>> getHealthDataInRange(
    DateTime start,
    DateTime end, {
    Set<HealthDataType>? types,
  }) async {
    return await getHealthData(
      types: types,
      startDate: start,
      endDate: end,
    );
  }

  /// Get health data for specified types
  Future<List<HealthDataPoint>> getHealthData({
    Set<HealthDataType>? types,
    DateTime? startDate,
    DateTime? endDate,
    bool applyPrivacyFilter = true,
  }) async {
    try {
      if (!_privacySettings.syncEnabled && applyPrivacyFilter) {
        _logger.info('Health sync is disabled');
        return [];
      }

      // Set date range based on privacy settings
      final now = DateTime.now();
      startDate ??= now.subtract(Duration(days: _privacySettings.historyDays));
      endDate ??= now;

      // Filter types based on privacy settings
      final requestTypes = applyPrivacyFilter
          ? (types ?? defaultHealthTypes).intersection(_privacySettings.allowedTypes)
          : (types ?? defaultHealthTypes);

      if (requestTypes.isEmpty && applyPrivacyFilter) {
        _logger.info('No allowed health data types');
        return [];
      }

      _logger.info('Fetching health data: ${requestTypes.length} types');

      // Request health data
      final healthData = await Health().getHealthDataFromTypes(
        types: requestTypes.toList(),
        startTime: startDate,
        endTime: endDate,
      );

      // Convert to our wrapper type
      final points = <HealthDataPoint>[];

      for (final point in healthData) {
        // Apply privacy transformations
        final sourceName = _privacySettings.anonymizeSources
            ? 'Health Source'
            : point.sourceName;

        // Convert value to double based on type
        double value = 0.0;
        if (point.value is num) {
          value = (point.value as num).toDouble();
        } else {
          value = double.tryParse(point.value.toString()) ?? 0.0;
        }
      

        points.add(HealthDataPoint(
          type: point.type,
          value: value,
          dateFrom: point.dateFrom,
          dateTo: point.dateTo,
          sourceName: sourceName,
          sourceId: point.sourceId,
        ));
      }

      _logger.info('Retrieved ${points.length} health data points');

      // Aggregate if requested
      if (_privacySettings.aggregateOnly && applyPrivacyFilter) {
        return _aggregateHealthData(points);
      }

      return points;
    } catch (e, stack) {
      _logger.error('Failed to get health data', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get daily summary of health data
  Future<Map<String, dynamic>> getDailySummary({
    DateTime? date,
    Set<HealthDataType>? types,
  }) async {
    try {
      date ??= DateTime.now();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final healthData = await getHealthData(
        types: types,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      final summary = <String, dynamic>{
        'date': date.toIso8601String(),
        'steps': 0,
        'distance': 0.0,
        'calories': 0.0,
        'activeMinutes': 0,
        'heartRate': <String, double>{},
        'sleep': <String, dynamic>{},
        'workouts': [],
      };

      // Process health data into summary
      for (final point in healthData) {
        switch (point.type) {
          case HealthDataType.STEPS:
            summary['steps'] = (summary['steps'] as int) + point.value.toInt();
            break;
          case HealthDataType.DISTANCE_WALKING_RUNNING:
            summary['distance'] = (summary['distance'] as double) + point.value;
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            summary['calories'] = (summary['calories'] as double) + point.value;
            break;
          case HealthDataType.HEART_RATE:
            final rates = summary['heartRate'] as Map<String, double>;
            if (rates.isEmpty || point.value < (rates['min'] ?? double.infinity)) {
              rates['min'] = point.value;
            }
            if (rates.isEmpty || point.value > (rates['max'] ?? 0)) {
              rates['max'] = point.value;
            }
            rates['avg'] = ((rates['avg'] ?? 0) + point.value) / 2;
            break;
          case HealthDataType.SLEEP_SESSION:
            final sleep = summary['sleep'] as Map<String, dynamic>;
            sleep['duration'] = ((sleep['duration'] ?? 0) as num) +
                point.dateTo.difference(point.dateFrom).inMinutes;
            break;
          case HealthDataType.WORKOUT:
            (summary['workouts'] as List).add({
              'type': point.metadata?['workoutType'] ?? 'Unknown',
              'duration': point.dateTo.difference(point.dateFrom).inMinutes,
              'calories': point.value,
            });
            break;
          default:
            break;
        }
      }

      _logger.info('Generated daily summary for $date');
      return summary;
    } catch (e, stack) {
      _logger.error('Failed to get daily summary', error: e, stackTrace: stack);
      return {};
    }
  }

  /// Write health data (for mindfulness/mental health tracking)
  Future<bool> writeHealthData({
    required HealthDataType type,
    required double value,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    try {
      endTime ??= startTime;

      _logger.info('Writing health data: $type = $value');

      final success = await Health().writeHealthData(
        value: value,
        type: type,
        startTime: startTime,
        endTime: endTime,
      );

      if (success) {
        _logger.info('Health data written successfully');
      } else {
        _logger.warning('Failed to write health data');
      }

      return success;
    } catch (e, stack) {
      _logger.error('Failed to write health data', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Aggregate health data for privacy
  List<HealthDataPoint> _aggregateHealthData(List<HealthDataPoint> points) {
    final aggregated = <HealthDataPoint>[];
    final typeGroups = <HealthDataType, List<HealthDataPoint>>{};

    // Group by type
    for (final point in points) {
      typeGroups.putIfAbsent(point.type, () => []).add(point);
    }

    // Aggregate each type
    for (final entry in typeGroups.entries) {
      final type = entry.key;
      final typePoints = entry.value;

      if (typePoints.isEmpty) continue;

      // Calculate aggregate values
      double totalValue = 0;
      DateTime earliestDate = typePoints.first.dateFrom;
      DateTime latestDate = typePoints.first.dateTo;

      for (final point in typePoints) {
        totalValue += point.value;
        if (point.dateFrom.isBefore(earliestDate)) {
          earliestDate = point.dateFrom;
        }
        if (point.dateTo.isAfter(latestDate)) {
          latestDate = point.dateTo;
        }
      }

      // Create aggregated point
      aggregated.add(HealthDataPoint(
        type: type,
        value: totalValue,
        dateFrom: earliestDate,
        dateTo: latestDate,
        sourceName: 'Aggregated',
      ));
    }

    return aggregated;
  }
}
