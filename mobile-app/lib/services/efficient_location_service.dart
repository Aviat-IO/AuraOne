import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/location_database.dart';
import '../providers/location_providers.dart';
import '../utils/logger.dart';

class EfficientLocationService {
  static final EfficientLocationService _instance = EfficientLocationService._internal();
  factory EfficientLocationService() => _instance;
  EfficientLocationService._internal();

  final LocationDatabase _storage = LocationDatabase();
  Timer? _batchSaveTimer;
  List<LocationPointsCompanion> _pendingLocations = [];

  static const int _batchSaveIntervalMinutes = 5;
  static const int _batchSizeThreshold = 10;

  /// Initialize the efficient background location service
  Future<bool> initialize() async {
    try {
      appLogger.info('Initializing efficient background location service...');

      // Configure event listeners
      bg.BackgroundGeolocation.onLocation(_onLocation, _onLocationError);
      bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
      bg.BackgroundGeolocation.onActivityChange(_onActivityChange);
      bg.BackgroundGeolocation.onProviderChange(_onProviderChange);
      bg.BackgroundGeolocation.onEnabledChange(_onEnabledChange);

      // Configure the plugin with battery-efficient settings
      await bg.BackgroundGeolocation.ready(bg.Config(
        // Identification
        reset: false,

        // Location Settings
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_MEDIUM, // Balance between accuracy and battery
        distanceFilter: 50.0, // Only track significant movement (50 meters)
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,

        // Activity Recognition
        stopTimeout: 5, // Stop tracking after 5 minutes of being stationary
        activityRecognitionInterval: 10000, // Check activity every 10 seconds
        minimumActivityRecognitionConfidence: 75,
        disableStopDetection: false,

        // Motion Settings
        isMoving: false,
        stopOnStationary: true,
        stationaryRadius: 25.0,
        disableMotionActivityUpdates: false,

        // Battery & Performance
        preventSuspend: false,
        heartbeatInterval: 60, // Heartbeat every minute while moving
        schedule: [], // Can add time-based scheduling if needed
        scheduleUseAlarmManager: false,

        // Android-specific Settings
        notification: bg.Notification(
          title: "Journey Insights",
          text: "Recording your day",
          color: "#4A90E2",
          priority: bg.Config.NOTIFICATION_PRIORITY_LOW, // Low priority, minimal intrusion
          sticky: false,
          channelName: "Journey Tracking",
          smallIcon: "mipmap/ic_launcher", // Use app icon
        ),
        foregroundService: true,
        notificationPriority: bg.Config.NOTIFICATION_PRIORITY_LOW,
        notificationChannelName: "Journey Tracking",
        notificationTitle: "Journey Insights",
        notificationText: "Recording your day",
        notificationColor: "#4A90E2",

        // Debugging (disable in production)
        debug: false,
        logLevel: bg.Config.LOG_LEVEL_ERROR,
        logMaxDays: 3,
      ));

      // Start batch save timer
      _startBatchSaveTimer();

      appLogger.info('Efficient background location service initialized successfully');
      return true;
    } catch (e) {
      appLogger.error('Failed to initialize efficient location service', error: e);
      return false;
    }
  }

  /// Start tracking location
  Future<bool> startTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackingEnabled = prefs.getBool('backgroundLocationTracking') ?? false;

      if (!trackingEnabled) {
        appLogger.info('Background location tracking is disabled by user preference');
        return false;
      }

      // Get current state
      bg.State state = await bg.BackgroundGeolocation.state;

      if (!state.enabled) {
        // Start the service
        await bg.BackgroundGeolocation.start();
        appLogger.info('Started efficient background location tracking');
      } else {
        appLogger.info('Background location tracking already active');
      }

      return true;
    } catch (e) {
      appLogger.error('Failed to start location tracking', error: e);
      return false;
    }
  }

  /// Stop tracking location
  Future<bool> stopTracking() async {
    try {
      await bg.BackgroundGeolocation.stop();
      await _savePendingLocations(); // Save any pending data
      _batchSaveTimer?.cancel();
      appLogger.info('Stopped background location tracking');
      return true;
    } catch (e) {
      appLogger.error('Failed to stop location tracking', error: e);
      return false;
    }
  }

  /// Handle location updates
  void _onLocation(bg.Location location) {
    appLogger.debug('Location update received: ${location.coords.latitude}, ${location.coords.longitude}');

    // Create LocationPointsCompanion from the bg.Location
    final locationPoint = LocationPointsCompanion.insert(
      latitude: location.coords.latitude,
      longitude: location.coords.longitude,
      accuracy: Value(location.coords.accuracy),
      altitude: Value(location.coords.altitude),
      speed: Value(location.coords.speed),
      heading: Value(location.coords.heading),
      timestamp: location.timestamp != null
          ? DateTime.parse(location.timestamp!)
          : DateTime.now(),
      activityType: Value(location.activity?.type ?? 'unknown'),
      isSignificant: Value(location.isMoving ?? false),
    );

    // Add to pending locations for batch save
    _pendingLocations.add(locationPoint);

    // Save immediately if we have enough locations
    if (_pendingLocations.length >= _batchSizeThreshold) {
      _savePendingLocations();
    }
  }

  /// Handle location errors
  void _onLocationError(bg.LocationError error) {
    appLogger.error('Location error: [${error.code}] ${error.message}');
  }

  /// Handle motion change events (stationary -> moving and vice versa)
  void _onMotionChange(bg.Location location) {
    final isMoving = location.isMoving ?? false;
    appLogger.info('Motion changed: ${isMoving ? "moving" : "stationary"}');

    if (!isMoving) {
      // User stopped moving, save any pending locations
      _savePendingLocations();
    }
  }

  /// Handle activity change events
  void _onActivityChange(bg.ActivityChangeEvent event) {
    appLogger.debug('Activity changed: ${event.activity} (${event.confidence}%)');
  }

  /// Handle provider change events
  void _onProviderChange(bg.ProviderChangeEvent event) {
    appLogger.info('Location provider changed: enabled=${event.enabled}, status=${event.status}');

    if (!event.enabled) {
      appLogger.warning('Location services disabled by user');
    }
  }

  /// Handle enabled change events
  void _onEnabledChange(bool enabled) {
    appLogger.info('Background geolocation enabled: $enabled');
  }

  /// Start the batch save timer
  void _startBatchSaveTimer() {
    _batchSaveTimer?.cancel();
    _batchSaveTimer = Timer.periodic(
      Duration(minutes: _batchSaveIntervalMinutes),
      (_) => _savePendingLocations(),
    );
  }

  /// Save pending locations to storage
  Future<void> _savePendingLocations() async {
    if (_pendingLocations.isEmpty) return;

    try {
      final locationsToSave = List<LocationPointsCompanion>.from(_pendingLocations);
      _pendingLocations.clear();

      for (final location in locationsToSave) {
        await _storage.insertLocationPoint(location);
      }

      appLogger.info('Saved ${locationsToSave.length} location(s) to storage');
    } catch (e) {
      appLogger.error('Failed to save pending locations', error: e);
      // Re-add locations to pending list to retry later
      _pendingLocations.addAll(_pendingLocations);
    }
  }

  /// Get the current location on-demand
  Future<LocationPointsCompanion?> getCurrentLocation() async {
    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 3,
        timeout: 30,
        maximumAge: 5000,
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      );

      return LocationPointsCompanion.insert(
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        accuracy: Value(location.coords.accuracy),
        altitude: Value(location.coords.altitude),
        speed: Value(location.coords.speed),
        heading: Value(location.coords.heading),
        timestamp: location.timestamp != null
            ? DateTime.parse(location.timestamp!)
            : DateTime.now(),
        activityType: Value(location.activity?.type ?? 'unknown'),
        isSignificant: Value(location.isMoving ?? false),
      );
    } catch (e) {
      appLogger.error('Failed to get current location', error: e);
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    _batchSaveTimer?.cancel();
    _savePendingLocations();
  }
}