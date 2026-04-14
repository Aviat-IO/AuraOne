import 'dart:async';
import 'dart:math' as math;
import 'package:drift/drift.dart' as drift;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/location_database.dart';
import '../providers/location_database_provider.dart';
import '../providers/location_tracking_runtime_provider.dart';
import 'simple_location_service.dart';
import '../utils/logger.dart';

/// Provider for BackgroundLocationService
final backgroundLocationServiceProvider = Provider<BackgroundLocationService>((
  ref,
) {
  final service = BackgroundLocationService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Background location service using flutter_background_geolocation for robust tracking
class BackgroundLocationService {
  final Ref ref;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _trackingAllowed = false;
  Future<bool>? _initializeFuture;
  Future<bool>? _trackingCommandFuture;
  bool? _desiredTrackingState;

  BackgroundLocationService(this.ref);

  /// Initialize background location tracking
  Future<bool> initialize() async {
    if (_isDisposed) {
      return false;
    }

    if (_isInitialized) {
      appLogger.info('Background location service already initialized');
      return true;
    }

    final inFlight = _initializeFuture;
    if (inFlight != null) {
      return await inFlight;
    }

    final initialization = _initializeInternal();
    _initializeFuture = initialization;

    try {
      final initialized = await initialization;
      if (initialized) {
        _isInitialized = true;
      }
      return initialized;
    } finally {
      if (identical(_initializeFuture, initialization)) {
        _initializeFuture = null;
      }
    }
  }

  Future<bool> _initializeInternal() async {
    try {
      appLogger.info('Initializing flutter_background_geolocation service...');

      // Configure the plugin
      final state = await bg.BackgroundGeolocation.ready(
        bg.Config(
          // License configuration - load from environment variable
          // Get your license from: https://www.transistorsoft.com/shop/products/flutter-background-geolocation
          //
          // SECURITY: Never commit license keys to git
          // Add your license key to .env file: BG_GEO_LICENSE=your_key_here
          //
          // For development/testing without a license, the plugin works but shows a notification
          authorization: _getLicenseKey() != null
              ? bg.Authorization(
                  strategy: bg.Authorization.STRATEGY_JWT,
                  accessToken: _getLicenseKey()!,
                )
              : null,

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
            title: "Aura One",
            text: "Tracking your location for journal context",
            sticky: false,
            priority: bg.Config.NOTIFICATION_PRIORITY_MIN, // Minimal visibility
            channelName: "Location Services", // Android 8+ channel name
          ),

          // Battery optimization
          preventSuspend: false,
          heartbeatInterval: 60, // Heartbeat every 60 seconds when stationary
        ),
      );

      if (_isDisposed) {
        return false;
      }

      // Configure event listeners only after ready succeeds so retries do not
      // stack duplicate subscriptions on failed initialization attempts.
      bg.BackgroundGeolocation.onLocation(_onLocation, _onLocationError);
      bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
      bg.BackgroundGeolocation.onProviderChange(_onProviderChange);

      _trackingAllowed = state.enabled;
      appLogger.info('Background location service initialized successfully');
      appLogger.info(
        'Initial state - enabled: ${state.enabled}, tracking: ${state.enabled}',
      );

      return true;
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to initialize background location service',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  void dispose() {
    _isDisposed = true;
    bg.BackgroundGeolocation.removeListener(_onLocation);
    bg.BackgroundGeolocation.removeListener(_onMotionChange);
    bg.BackgroundGeolocation.removeListener(_onProviderChange);
    _initializeFuture = null;
    _trackingCommandFuture = null;
    _isInitialized = false;
    _trackingAllowed = false;
  }

  /// Handle location updates
  Future<void> _onLocation(bg.Location location) async {
    try {
      appLogger.info(
        "Location received: ${location.coords.latitude}, ${location.coords.longitude}",
      );

      if (!_trackingAllowed) {
        appLogger.warning(
          "Background location tracking is not allowed yet, skipping save. Location data will not appear on map!",
        );
        return;
      }

      // Use the database from the provider to ensure proper stream notifications
      final database = ref.read(locationDatabaseProvider);
      appLogger.info("Database provider retrieved successfully");

      // Query for the last saved position to apply intelligent filtering
      final lastLocationQuery = database.select(database.locationPoints)
        ..orderBy([
          (t) => drift.OrderingTerm(
            expression: t.timestamp,
            mode: drift.OrderingMode.desc,
          ),
        ])
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
          appLogger.info(
            "Location too recent (${timeDiff.inSeconds}s). Skipping save.",
          );
        }
      }

      if (shouldSave) {
        // Use the activity type directly from flutter_background_geolocation
        // Plugin provides: still, stationary, on_foot, walking, running, in_vehicle, on_bicycle
        String activityType = location.activity.type;

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

        final insertedId = await database.insertLocationPoint(locationData);
        appLogger.info(
          "✓ Location saved to database with ID: $insertedId (lat: ${location.coords.latitude}, lng: ${location.coords.longitude})",
        );

        // Store last update time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'lastLocationUpdate',
          DateTime.now().millisecondsSinceEpoch,
        );

        await _evaluateGeofences(
          latitude: location.coords.latitude,
          longitude: location.coords.longitude,
          timestamp: DateTime.parse(location.timestamp),
        );
      }
    } catch (e, stackTrace) {
      appLogger.error(
        "Error handling location update",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle location errors
  void _onLocationError(bg.LocationError error) {
    appLogger.error("Location error: ${error.code} - ${error.message}");
  }

  /// Handle motion change events (moving <-> stationary)
  void _onMotionChange(bg.Location location) {
    appLogger.info(
      "Motion change detected: isMoving=${location.isMoving}, activity=${location.activity.type}",
    );
    // Location will be saved via _onLocation callback
  }

  /// Handle provider change events (location services enabled/disabled)
  void _onProviderChange(bg.ProviderChangeEvent event) {
    appLogger.info(
      "Provider change: enabled=${event.enabled}, status=${event.status}",
    );
    if (!event.enabled) {
      _trackingAllowed = false;
      appLogger.warning("Location services have been disabled");
    }

    Future.microtask(() async {
      final actualState = await isTrackingEnabled();
      ref.read(locationTrackingRuntimeStateProvider.notifier).state =
          actualState;
    });
  }

  /// Start background location tracking
  Future<bool> startTracking() async {
    return _requestTrackingState(true);
  }

  Future<bool> _startTrackingInternal() async {
    try {
      await ref.read(simpleLocationServiceProvider).initialize();

      final alreadyEnabled = await isTrackingEnabled();
      if (alreadyEnabled) {
        _trackingAllowed = true;
        ref.read(locationTrackingRuntimeStateProvider.notifier).state = true;
        appLogger.info('Background location tracking already running');
        return true;
      }

      // Initialize if not already done
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          appLogger.error('Cannot start tracking - initialization failed');
          return false;
        }
      }

      _trackingAllowed = true;

      // Start tracking
      final state = await bg.BackgroundGeolocation.start();
      appLogger.info('✓ Background location tracking started successfully');
      appLogger.info(
        'State after start - enabled: ${state.enabled}, tracking: ${state.enabled}',
      );

      ref.read(locationTrackingRuntimeStateProvider.notifier).state =
          state.enabled;

      return true;
    } catch (e, stackTrace) {
      _trackingAllowed = false;
      appLogger.error(
        'Failed to start background location tracking',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _evaluateGeofences({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    final geofences = ref.read(geofencesProvider);
    if (geofences.isEmpty) {
      return;
    }

    final database = ref.read(locationDatabaseProvider);
    for (final geofence in geofences) {
      final distance = _distanceMeters(
        latitude,
        longitude,
        geofence.latitude,
        geofence.longitude,
      );
      final wasInside = geofence.isInside;
      final isNowInside = distance <= geofence.radius;

      if (!wasInside && isNowInside) {
        geofence.isInside = true;
        await database.insertGeofenceEvent(
          GeofenceEventsCompanion.insert(
            geofenceId: geofence.id,
            eventType: 'enter',
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      } else if (wasInside && !isNowInside) {
        geofence.isInside = false;
        await database.insertGeofenceEvent(
          GeofenceEventsCompanion.insert(
            geofenceId: geofence.id,
            eventType: 'exit',
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      }
    }
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * (3.141592653589793 / 180.0);
    final dLon = (lon2 - lon1) * (3.141592653589793 / 180.0);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * 3.141592653589793 / 180.0) *
            math.cos(lat2 * 3.141592653589793 / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Stop background location tracking
  Future<bool> stopTracking() async {
    return _requestTrackingState(false);
  }

  Future<bool> _requestTrackingState(bool enabled) async {
    _desiredTrackingState = enabled;

    final inFlight = _trackingCommandFuture;
    if (inFlight != null) {
      await inFlight;
      if (_desiredTrackingState != enabled) {
        return _requestTrackingState(_desiredTrackingState!);
      }
      return (await isTrackingEnabled()) == enabled;
    }

    final command = enabled
        ? _startTrackingInternal()
        : _stopTrackingInternal();
    _trackingCommandFuture = command;

    try {
      await command;
    } finally {
      if (identical(_trackingCommandFuture, command)) {
        _trackingCommandFuture = null;
      }
    }

    if (_desiredTrackingState != enabled) {
      return _requestTrackingState(_desiredTrackingState!);
    }

    return (await isTrackingEnabled()) == enabled;
  }

  Future<bool> _stopTrackingInternal() async {
    try {
      _trackingAllowed = false;

      // Stop tracking
      final state = await bg.BackgroundGeolocation.stop();
      appLogger.info('Background location tracking stopped');
      appLogger.info('State after stop - enabled: ${state.enabled}');

      ref.read(locationTrackingRuntimeStateProvider.notifier).state =
          state.enabled;

      return true;
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to stop background location tracking',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check if tracking is enabled
  Future<bool> isTrackingEnabled() async {
    try {
      final state = await bg.BackgroundGeolocation.state;
      _trackingAllowed = state.enabled;
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
      appLogger.error(
        'Error checking location permission',
        error: e,
        stackTrace: stackTrace,
      );
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
      appLogger.error(
        'Error getting current location',
        error: e,
        stackTrace: stackTrace,
      );
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
      appLogger.error(
        'Error getting tracking stats',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Get license key from environment
  String? _getLicenseKey() {
    appLogger.info('Checking for BG_GEO_LICENSE...');
    appLogger.info('dotenv.isInitialized: ${dotenv.isInitialized}');

    // Try dotenv first (from .env file)
    if (dotenv.isInitialized &&
        dotenv.env['BG_GEO_LICENSE']?.isNotEmpty == true) {
      final key = dotenv.env['BG_GEO_LICENSE']!;
      appLogger.info('Found license key from .env (length: ${key.length})');
      return key;
    }

    // Fall back to compile-time environment variable (--dart-define)
    const envKey = String.fromEnvironment('BG_GEO_LICENSE');
    if (envKey.isNotEmpty) {
      appLogger.info(
        'Found license key from --dart-define (length: ${envKey.length})',
      );
      return envKey;
    }

    appLogger.warning('No license key found - will run in development mode');
    return null;
  }
}
