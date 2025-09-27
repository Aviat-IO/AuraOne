import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import '../database/location_database.dart';
import '../utils/logger.dart';

/// Free background location service using geolocator + flutter_background_service
/// This replaces the paid flutter_background_geolocation package
class FreeLocationService {
  static final FreeLocationService _instance = FreeLocationService._internal();
  factory FreeLocationService() => _instance;
  FreeLocationService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();
  static const String _channelName = 'location_tracking_channel';
  static const int _serviceId = 888;

  // Configurable parameters
  static const int _locationIntervalSeconds = 120; // 2 minutes between updates
  static const double _distanceFilterMeters = 50.0; // Minimum distance change
  static const int _batchSizeThreshold = 10;

  /// Initialize the background location service
  Future<bool> initialize() async {
    try {
      appLogger.info('Initializing free background location service...');

      // Configure the background service
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onServiceStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: _channelName,
          initialNotificationTitle: 'Journey Insights',
          initialNotificationContent: 'Recording your day',
          foregroundServiceNotificationId: _serviceId,
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: _onServiceStart,
          onBackground: _onServiceStart,
        ),
      );

      appLogger.info('Free background location service initialized');
      return true;
    } catch (e) {
      appLogger.error('Failed to initialize free location service', error: e);
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

      // Check and request location permissions
      final permission = await _checkLocationPermission();
      if (!permission) {
        appLogger.warning('Location permission not granted');
        return false;
      }

      // Start the background service
      final success = await _service.startService();
      if (success) {
        appLogger.info('Started free background location tracking');
      }
      return success;
    } catch (e) {
      appLogger.error('Failed to start location tracking', error: e);
      return false;
    }
  }

  /// Stop tracking location
  Future<bool> stopTracking() async {
    try {
      final isRunning = await _service.isRunning();
      if (isRunning) {
        // Send stop signal to service
        _service.invoke('stop');
        appLogger.info('Stopped background location tracking');
      }
      return true;
    } catch (e) {
      appLogger.error('Failed to stop location tracking', error: e);
      return false;
    }
  }

  /// Check if the service is running
  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        appLogger.warning('Location services are disabled');
        return false;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          appLogger.warning('Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        appLogger.warning('Location permission permanently denied');
        return false;
      }

      // For Android 10+ we need background location permission
      if (Platform.isAndroid) {
        // Background permission is handled by ACCESS_BACKGROUND_LOCATION in manifest
        // The permission dialog will show when we request location permission
        appLogger.info('Location permissions granted (including background for Android)');
      }

      return true;
    } catch (e) {
      appLogger.error('Error checking location permission', error: e);
      return false;
    }
  }

  /// Background service entry point
  @pragma('vm:entry-point')
  static Future<bool> _onServiceStart(ServiceInstance service) async {
    // Initialize Flutter bindings
    DartPluginRegistrant.ensureInitialized();

    // Track location points for batch saving
    final List<Map<String, dynamic>> pendingLocations = [];
    Timer? batchSaveTimer;
    Position? lastPosition;

    // Setup location database
    final database = LocationDatabase();

    // Save pending locations batch
    Future<void> savePendingLocations() async {
      if (pendingLocations.isEmpty) return;

      try {
        final locationsToSave = List<Map<String, dynamic>>.from(pendingLocations);
        pendingLocations.clear();

        for (final locationData in locationsToSave) {
          final location = LocationPointsCompanion.insert(
            latitude: locationData['latitude'] as double,
            longitude: locationData['longitude'] as double,
            accuracy: Value(locationData['accuracy'] as double?),
            altitude: Value(locationData['altitude'] as double?),
            speed: Value(locationData['speed'] as double?),
            heading: Value(locationData['heading'] as double?),
            timestamp: DateTime.fromMillisecondsSinceEpoch(locationData['timestamp'] as int),
            activityType: Value(locationData['activityType'] as String? ?? 'unknown'),
            isSignificant: Value(locationData['isSignificant'] as bool? ?? false),
          );

          await database.insertLocationPoint(location);
        }

        debugPrint('[FreeLocationService] Saved ${locationsToSave.length} location(s) to storage');
      } catch (e) {
        debugPrint('[FreeLocationService] Failed to save locations: $e');
        // Re-add locations to retry later
        pendingLocations.addAll(pendingLocations);
      }
    }

    // Setup batch save timer (every 5 minutes)
    batchSaveTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await savePendingLocations();
    });

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();

      // Update notification with minimal info
      service.setForegroundNotificationInfo(
        title: 'Journey Insights',
        content: 'Recording your day',
      );

      // Listen for stop signal
      service.on('stop').listen((event) async {
        await savePendingLocations();
        batchSaveTimer?.cancel();
        await database.close();
        service.stopSelf();
      });
    }

    // Location tracking timer
    Timer.periodic(Duration(seconds: _locationIntervalSeconds), (timer) async {
      try {
        // Check if we should continue
        final prefs = await SharedPreferences.getInstance();
        final trackingEnabled = prefs.getBool('backgroundLocationTracking') ?? false;

        if (!trackingEnabled) {
          // Stop the service if tracking was disabled
          await savePendingLocations();
          batchSaveTimer?.cancel();
          await database.close();
          service.stopSelf();
          timer.cancel();
          return;
        }

        // Get current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Balance accuracy and battery
          timeLimit: const Duration(seconds: 30),
        );

        // Check if position changed significantly
        if (lastPosition != null) {
          final distance = Geolocator.distanceBetween(
            lastPosition!.latitude,
            lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          // Skip if distance is less than threshold
          if (distance < _distanceFilterMeters) {
            debugPrint('[FreeLocationService] Skipping - moved only ${distance.toStringAsFixed(1)}m');
            return;
          }
        }

        lastPosition = position;

        // Create location data
        final locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'speed': position.speed,
          'heading': position.heading,
          'timestamp': position.timestamp?.millisecondsSinceEpoch ??
                       DateTime.now().millisecondsSinceEpoch,
          'activityType': position.speed != null && position.speed! > 1.0
                          ? 'moving' : 'stationary',
          'isSignificant': true, // All saved points are significant in this implementation
        };

        // Add to pending batch
        pendingLocations.add(locationData);

        debugPrint('[FreeLocationService] Location update: '
                   '${position.latitude.toStringAsFixed(6)}, '
                   '${position.longitude.toStringAsFixed(6)} '
                   '(${pendingLocations.length} pending)');

        // Save immediately if we have enough locations
        if (pendingLocations.length >= _batchSizeThreshold) {
          await savePendingLocations();
        }

        // Update service data for any listeners
        service.invoke('update', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': position.timestamp?.toIso8601String(),
          'pendingCount': pendingLocations.length,
        });

      } catch (e) {
        debugPrint('[FreeLocationService] Error getting location: $e');
      }
    });

    return true; // Service started successfully
  }

  /// Get the current location on-demand
  Future<LocationPointsCompanion?> getCurrentLocation() async {
    try {
      final permission = await _checkLocationPermission();
      if (!permission) {
        appLogger.warning('Cannot get location - permission denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      return LocationPointsCompanion.insert(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: Value(position.accuracy),
        altitude: Value(position.altitude),
        speed: Value(position.speed),
        heading: Value(position.heading),
        timestamp: position.timestamp ?? DateTime.now(),
        activityType: Value(position.speed != null && position.speed! > 1.0
                           ? 'moving' : 'stationary'),
        isSignificant: Value(true),
      );
    } catch (e) {
      appLogger.error('Failed to get current location', error: e);
      return null;
    }
  }
}