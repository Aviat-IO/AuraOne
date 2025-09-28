import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../database/location_database.dart';
import '../providers/location_database_provider.dart';
import '../utils/logger.dart';

/// Background task identifier
const String backgroundTaskId = "com.auraone.location_fetch";
const String workManagerTaskName = "locationTracking";

/// Workmanager callback - must be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // This runs every 15 minutes
    if (task == workManagerTaskName) {
      await _performLocationUpdate();
    }
    return Future.value(true);
  });
}

/// Perform the actual location update
Future<void> _performLocationUpdate() async {
  try {
    // Check if tracking is enabled
    final prefs = await SharedPreferences.getInstance();
    final trackingEnabled = prefs.getBool('backgroundLocationTracking') ?? false;

    if (!trackingEnabled) {
      appLogger.info("Background location tracking is disabled");
      return;
    }

    // Get current position with timeout
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ).timeout(
      Duration(seconds: 20),
      onTimeout: () async {
        // Fall back to last known position if timeout
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          return lastPosition;
        }
        throw TimeoutException('Failed to get location');
      },
    );

    appLogger.info("Background location received: ${position.latitude}, ${position.longitude}");

    // Initialize database
    final database = LocationDatabase();

    try {
      // Query for the last saved position
      final lastLocationQuery = database.select(database.locationPoints)
        ..orderBy([(t) => drift.OrderingTerm(
          expression: t.timestamp,
          mode: drift.OrderingMode.desc,
        )])
        ..limit(1);

      final lastLocations = await lastLocationQuery.get();

      // Apply intelligent filtering - only save if moved significantly
      bool isSignificantMove = true;

      if (lastLocations.isNotEmpty) {
        final lastLocation = lastLocations.first;
        double distance = Geolocator.distanceBetween(
          lastLocation.latitude,
          lastLocation.longitude,
          position.latitude,
          position.longitude,
        );

        // Only save if moved more than 50 meters
        if (distance < 50) {
          isSignificantMove = false;
          appLogger.info("Insignificant move (${distance.toStringAsFixed(1)}m). Skipping save.");
        }
      }

      if (isSignificantMove) {
        // Save the new position to the database
        final locationData = LocationPointsCompanion(
          latitude: drift.Value(position.latitude),
          longitude: drift.Value(position.longitude),
          altitude: drift.Value(position.altitude),
          speed: drift.Value(position.speed),
          heading: drift.Value(position.heading),
          timestamp: drift.Value(position.timestamp ?? DateTime.now()),
          accuracy: drift.Value(position.accuracy),
          activityType: drift.Value(
            position.speed != null && position.speed! > 1.0 ? 'moving' : 'stationary'
          ),
          isSignificant: const drift.Value(true),
        );

        await database.insertLocationPoint(locationData);
        appLogger.info("Significant move detected. Location saved to database.");

        // Store last update time
        await prefs.setInt('lastLocationUpdate', DateTime.now().millisecondsSinceEpoch);
      }
    } finally {
      // Always close the database connection
      await database.close();
    }
  } catch (e) {
    appLogger.error("Error getting location in background: $e");
  }
}

/// Provider for BackgroundLocationService
final backgroundLocationServiceProvider = Provider<BackgroundLocationService>((ref) {
  return BackgroundLocationService(ref);
});

/// Background location service using background_fetch for reliable periodic updates
class BackgroundLocationService {
  final Ref ref;

  BackgroundLocationService(this.ref);

  /// Initialize background location tracking
  Future<bool> initialize() async {
    try {
      appLogger.info('Initializing background location service...');

      // Initialize Workmanager for periodic tasks
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );

      // Register periodic task for location updates
      // This will run every 15 minutes (minimum for iOS background fetch)
      await Workmanager().registerPeriodicTask(
        backgroundTaskId,
        workManagerTaskName,
        frequency: Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: Duration(seconds: 10),
      );

      appLogger.info('Background location service initialized with 15-minute intervals');
      return true;
    } catch (e) {
      appLogger.error('Failed to initialize background location service', error: e);
      return false;
    }
  }

  /// Start background location tracking
  Future<bool> startTracking() async {
    try {
      // Check permissions first
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        appLogger.warning('Cannot start tracking - location permission denied');
        return false;
      }

      // Enable tracking preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('backgroundLocationTracking', true);

      appLogger.info('Background location tracking started successfully');

      // Perform initial location update
      await _performLocationUpdate();

      return true;
    } catch (e) {
      appLogger.error('Failed to start background location tracking', error: e);
      return false;
    }
  }

  /// Stop background location tracking
  Future<bool> stopTracking() async {
    try {
      // Disable tracking preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('backgroundLocationTracking', false);

      // Cancel the periodic task
      await Workmanager().cancelByUniqueName(backgroundTaskId);
      appLogger.info('Background location tracking stopped');

      return true;
    } catch (e) {
      appLogger.error('Failed to stop background location tracking', error: e);
      return false;
    }
  }

  /// Check if tracking is enabled
  Future<bool> isTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('backgroundLocationTracking') ?? false;
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
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        appLogger.warning('Location services are disabled');
        // Try to open location settings
        try {
          await Geolocator.openLocationSettings();
          // Re-check after user potentially enables it
          await Future.delayed(Duration(seconds: 2));
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            appLogger.warning('Location services still disabled after prompt');
            return false;
          }
        } catch (e) {
          appLogger.error('Could not open location settings: $e');
          return false;
        }
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      appLogger.info('Current location permission: $permission');

      // Request permission if denied
      if (permission == LocationPermission.denied) {
        appLogger.info('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        appLogger.info('Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          appLogger.warning('Location permission denied by user');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        appLogger.warning('Location permission denied forever, opening app settings...');
        // Permissions are denied forever, prompt user to open settings
        try {
          await Geolocator.openAppSettings();
          return false; // User needs to manually enable in settings
        } catch (e) {
          appLogger.error('Could not open app settings: $e');
          return false;
        }
      }

      // For background tracking, we need "always" permission on iOS
      // On Android, whileInUse is sufficient with background_fetch
      if (Platform.isIOS && permission == LocationPermission.whileInUse) {
        appLogger.info('iOS requires "Always Allow" for background tracking');
        // Guide user to upgrade permission
        await Geolocator.openAppSettings();
        return false;
      }

      final hasPermission = permission == LocationPermission.whileInUse ||
                           permission == LocationPermission.always;

      appLogger.info('Location permission granted: $hasPermission (permission: $permission)');
      return hasPermission;
    } catch (e) {
      appLogger.error('Error checking location permission', error: e);
      return false;
    }
  }

  /// Get current location on-demand
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      return position;
    } catch (e) {
      appLogger.error('Error getting current location: $e');
      return null;
    }
  }
}