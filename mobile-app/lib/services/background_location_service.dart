import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/location_database.dart';
import '../utils/logger.dart';

/// Provider for BackgroundLocationService
final backgroundLocationServiceProvider = Provider<BackgroundLocationService>((ref) {
  return BackgroundLocationService(ref);
});

/// Background location service using flutter_background_geolocation for robust tracking
class BackgroundLocationService {
  final Ref ref;
  bool _isInitialized = false;

  BackgroundLocationService(this.ref);

  /// Initialize background location tracking
  Future<bool> initialize() async {
    if (_isInitialized) {
      appLogger.info('Background location service already initialized');
      return true;
    }

    try {
      appLogger.info('Initializing flutter_background_geolocation service...');

      // Configure event listeners
      bg.BackgroundGeolocation.onLocation(_onLocation, _onLocationError);
      bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
      bg.BackgroundGeolocation.onProviderChange(_onProviderChange);

      // Configure the plugin
      final state = await bg.BackgroundGeolocation.ready(bg.Config(
        // Geolocation options
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 50.0, // Only track locations 50m apart
        stopTimeout: 5, // Stop tracking after 5 minutes of no motion

        // Activity recognition
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,

        // HTTP & persistence (disabled for now - we use local database)
        autoSync: false,
        maxDaysToPersist: 0, // Don't persist in plugin's database

        // Application config
        debug: false, // Set to true for development debugging
        logLevel: bg.Config.LOG_LEVEL_OFF,

        // Android specific
        foregroundService: true,
        notification: bg.Notification(
          title: "Aura One Location Tracking",
          text: "Tracking your location for journal context",
          sticky: false,
        ),

        // Battery optimization
        preventSuspend: false,
        heartbeatInterval: 60, // Heartbeat every 60 seconds when stationary
      ));

      _isInitialized = true;
      appLogger.info('Background location service initialized successfully');
      appLogger.info('Initial state - enabled: ${state.enabled}, tracking: ${state.enabled}');

      return true;
    } catch (e, stackTrace) {
      appLogger.error('Failed to initialize background location service', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Handle location updates
  Future<void> _onLocation(bg.Location location) async {
    try {
      appLogger.info("Location received: ${location.coords.latitude}, ${location.coords.longitude}");

      // Check if tracking is enabled
      final prefs = await SharedPreferences.getInstance();
      final trackingEnabled = prefs.getBool('backgroundLocationTracking') ?? false;

      if (!trackingEnabled) {
        appLogger.info("Background location tracking is disabled, skipping save");
        return;
      }

      // Initialize database
      final database = LocationDatabase();

      try {
        // Query for the last saved position to apply intelligent filtering
        final lastLocationQuery = database.select(database.locationPoints)
          ..orderBy([(t) => drift.OrderingTerm(
            expression: t.timestamp,
            mode: drift.OrderingMode.desc,
          )])
          ..limit(1);

        final lastLocations = await lastLocationQuery.get();

        // The plugin already filters by distanceFilter (50m), but we can add additional logic
        bool shouldSave = true;

        if (lastLocations.isNotEmpty) {
          final lastLocation = lastLocations.first;
          final timeDiff = DateTime.now().difference(lastLocation.timestamp);

          // Don't save if last location was less than 30 seconds ago (prevent bursts)
          if (timeDiff.inSeconds < 30) {
            shouldSave = false;
            appLogger.info("Location too recent (${timeDiff.inSeconds}s). Skipping save.");
          }
        }

        if (shouldSave) {
          // Determine activity type based on motion state
          String activityType = 'unknown';
          if (location.activity.type == 'still' || location.activity.type == 'stationary') {
            activityType = 'stationary';
          } else if (location.activity.type == 'on_foot' || location.activity.type == 'walking' || location.activity.type == 'running') {
            activityType = 'moving';
          } else if (location.activity.type == 'in_vehicle' || location.activity.type == 'on_bicycle') {
            activityType = 'moving';
          }

          // Save the new position to the database
          final locationData = LocationPointsCompanion(
            latitude: drift.Value(location.coords.latitude),
            longitude: drift.Value(location.coords.longitude),
            altitude: drift.Value(location.coords.altitude),
            speed: drift.Value(location.coords.speed),
            heading: drift.Value(location.coords.heading),
            timestamp: drift.Value(DateTime.parse(location.timestamp)),
            accuracy: drift.Value(location.coords.accuracy),
            activityType: drift.Value(activityType),
            isSignificant: drift.Value(location.isMoving),
          );

          await database.insertLocationPoint(locationData);
          appLogger.info("Location saved to database");

          // Store last update time
          await prefs.setInt('lastLocationUpdate', DateTime.now().millisecondsSinceEpoch);
        }
      } finally {
        // Always close the database connection
        await database.close();
      }
    } catch (e, stackTrace) {
      appLogger.error("Error handling location update", error: e, stackTrace: stackTrace);
    }
  }

  /// Handle location errors
  void _onLocationError(bg.LocationError error) {
    appLogger.error("Location error: ${error.code} - ${error.message}");
  }

  /// Handle motion change events (moving <-> stationary)
  void _onMotionChange(bg.Location location) {
    appLogger.info("Motion change detected: isMoving=${location.isMoving}, activity=${location.activity.type}");
    // Location will be saved via _onLocation callback
  }

  /// Handle provider change events (location services enabled/disabled)
  void _onProviderChange(bg.ProviderChangeEvent event) {
    appLogger.info("Provider change: enabled=${event.enabled}, status=${event.status}");
    if (!event.enabled) {
      appLogger.warning("Location services have been disabled");
    }
  }

  /// Start background location tracking
  Future<bool> startTracking() async {
    try {
      // Initialize if not already done
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          return false;
        }
      }

      // Enable tracking preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('backgroundLocationTracking', true);

      // Start tracking
      final state = await bg.BackgroundGeolocation.start();
      appLogger.info('Background location tracking started successfully');
      appLogger.info('State after start - enabled: ${state.enabled}, tracking: ${state.enabled}');

      return true;
    } catch (e, stackTrace) {
      appLogger.error('Failed to start background location tracking', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Stop background location tracking
  Future<bool> stopTracking() async {
    try {
      // Disable tracking preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('backgroundLocationTracking', false);

      // Stop tracking
      final state = await bg.BackgroundGeolocation.stop();
      appLogger.info('Background location tracking stopped');
      appLogger.info('State after stop - enabled: ${state.enabled}');

      return true;
    } catch (e, stackTrace) {
      appLogger.error('Failed to stop background location tracking', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if tracking is enabled
  Future<bool> isTrackingEnabled() async {
    try {
      final state = await bg.BackgroundGeolocation.state;
      return state.enabled;
    } catch (e) {
      appLogger.error('Error checking tracking status', error: e);
      return false;
    }
  }

  /// Get the last update time
  Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('lastLocationUpdate');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    try {
      final status = await bg.BackgroundGeolocation.requestPermission();
      appLogger.info('Location permission status: $status');

      // Status values:
      // 0 = AUTHORIZED_ALWAYS
      // 1 = AUTHORIZED_WHEN_IN_USE
      // 2 = DENIED
      // 3 = NOT_DETERMINED
      return status == bg.ProviderChangeEvent.AUTHORIZATION_STATUS_ALWAYS ||
             status == bg.ProviderChangeEvent.AUTHORIZATION_STATUS_WHEN_IN_USE;
    } catch (e, stackTrace) {
      appLogger.error('Error checking location permission', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get current location on-demand
  Future<bg.Location?> getCurrentLocation() async {
    try {
      // Initialize if not already done
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          return null;
        }
      }

      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 1,
        timeout: 30,
        maximumAge: 5000,
        desiredAccuracy: 50,
      );

      return location;
    } catch (e, stackTrace) {
      appLogger.error('Error getting current location', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Change pace (moving/stationary) manually
  Future<void> changePace(bool isMoving) async {
    try {
      await bg.BackgroundGeolocation.changePace(isMoving);
      appLogger.info('Pace changed to: ${isMoving ? "moving" : "stationary"}');
    } catch (e, stackTrace) {
      appLogger.error('Error changing pace', error: e, stackTrace: stackTrace);
    }
  }

  /// Get tracking statistics
  Future<Map<String, dynamic>> getTrackingStats() async {
    try {
      final state = await bg.BackgroundGeolocation.state;
      final lastUpdate = await getLastUpdateTime();

      return {
        'enabled': state.enabled,
        'isMoving': state.isMoving,
        'trackingMode': state.trackingMode,
        'lastUpdate': lastUpdate?.toIso8601String(),
        'distanceFilter': state.distanceFilter,
        'desiredAccuracy': state.desiredAccuracy,
      };
    } catch (e, stackTrace) {
      appLogger.error('Error getting tracking stats', error: e, stackTrace: stackTrace);
      return {};
    }
  }
}
