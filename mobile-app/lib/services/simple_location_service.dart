import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../database/location_database.dart';
import '../providers/location_database_provider.dart';

// Provider for SimpleLocationService
final simpleLocationServiceProvider = Provider<SimpleLocationService>((ref) {
  final service = SimpleLocationService(ref);
  ref.onDispose(service.dispose);
  return service;
});

// Provider for current location
final currentLocationProvider = StateProvider<Position?>((ref) => null);

// Provider for tracking state
final isTrackingProvider = StateProvider<bool>((ref) => false);

// Provider for geofences
final geofencesProvider = StateProvider<List<GeofenceArea>>((ref) => []);

// Provider for location history
final locationHistoryProvider = StateProvider<List<LocationPoint>>((ref) => []);

class GeofenceArea {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String? notifyOnEntry;
  final String? notifyOnExit;
  final DateTime createdAt;
  bool isInside = false;

  GeofenceArea({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.notifyOnEntry,
    this.notifyOnExit,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'notifyOnEntry': notifyOnEntry,
    'notifyOnExit': notifyOnExit,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GeofenceArea.fromJson(Map<String, dynamic> json) => GeofenceArea(
    id: json['id'],
    name: json['name'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    radius: json['radius'],
    notifyOnEntry: json['notifyOnEntry'],
    notifyOnExit: json['notifyOnExit'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final double? accuracy;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
    this.accuracy,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'speed': speed,
    'heading': heading,
    'timestamp': timestamp.toIso8601String(),
    'accuracy': accuracy,
  };

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
    latitude: json['latitude'],
    longitude: json['longitude'],
    altitude: json['altitude'],
    speed: json['speed'],
    heading: json['heading'],
    timestamp: DateTime.parse(json['timestamp']),
    accuracy: json['accuracy'],
  );
}

class SimpleLocationService {
  final Ref ref;
  Timer? _dailyMaintenanceTimer;
  Future<void>? _initializeFuture;
  bool _isInitialized = false;
  bool _isDisposed = false;

  SimpleLocationService(this.ref);

  Future<void> initialize() async {
    if (_isDisposed) {
      return;
    }

    if (_isInitialized) {
      return;
    }

    final inFlight = _initializeFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final initialization = _initializeInternal();
    _initializeFuture = initialization;

    try {
      await initialization;
      _isInitialized = true;
    } finally {
      if (identical(_initializeFuture, initialization)) {
        _initializeFuture = null;
      }
    }
  }

  Future<void> _initializeInternal() async {
    debugPrint('SimpleLocationService initialized');

    await _loadGeofencesFromDatabase();
    if (_isDisposed) {
      return;
    }
    _scheduleDailyMaintenance();
  }

  void _scheduleDailyMaintenance() {
    _dailyMaintenanceTimer?.cancel();
    _dailyMaintenanceTimer = Timer.periodic(const Duration(hours: 24), (
      _,
    ) async {
      await _performDailyMaintenance();
    });
  }

  bool get hasActiveDailyMaintenanceTimer =>
      _dailyMaintenanceTimer?.isActive ?? false;

  void dispose() {
    _isDisposed = true;
    _dailyMaintenanceTimer?.cancel();
    _dailyMaintenanceTimer = null;
    _initializeFuture = null;
    _isInitialized = false;
  }

  // Load geofences from database
  Future<void> _loadGeofencesFromDatabase() async {
    final db = ref.read(locationDatabaseProvider);
    final dbGeofences = await (db.select(
      db.geofenceAreas,
    )..where((tbl) => tbl.isActive.equals(true))).get();
    final geofenceEvents = await db.select(db.geofenceEvents).get();

    final latestEventsByGeofence = <String, GeofenceEvent>{};
    for (final event in geofenceEvents) {
      final current = latestEventsByGeofence[event.geofenceId];
      if (current == null || event.timestamp.isAfter(current.timestamp)) {
        latestEventsByGeofence[event.geofenceId] = event;
      }
    }

    final geofences = dbGeofences.map((dbGeofence) {
      Map<String, dynamic>? metadata;
      if (dbGeofence.metadata != null) {
        metadata = jsonDecode(dbGeofence.metadata!);
      }

      final geofence = GeofenceArea(
        id: dbGeofence.id,
        name: dbGeofence.name,
        latitude: dbGeofence.latitude,
        longitude: dbGeofence.longitude,
        radius: dbGeofence.radius,
        notifyOnEntry: metadata?['notifyOnEntry'],
        notifyOnExit: metadata?['notifyOnExit'],
        createdAt: dbGeofence.createdAt,
      );
      geofence.isInside =
          latestEventsByGeofence[dbGeofence.id]?.eventType == 'enter';
      return geofence;
    }).toList();

    ref.read(geofencesProvider.notifier).state = geofences;
    debugPrint('Loaded ${geofences.length} geofences from database');
  }

  Future<void> reloadGeofencesFromDatabase() async {
    await _loadGeofencesFromDatabase();
  }

  // Perform daily maintenance tasks
  Future<void> _performDailyMaintenance() async {
    final db = ref.read(locationDatabaseProvider);
    final cleanupService = ref.read(locationDataCleanupProvider);

    // Generate summary for yesterday
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    await db.generateDailySummary(yesterday);

    // Clean up old data
    await cleanupService.performCleanup();

    debugPrint('Daily maintenance completed');
  }

  // Start tracking
  Future<bool> startTracking({
    Duration interval = const Duration(minutes: 1),
    double distanceFilter = 10,
  }) async {
    debugPrint(
      'SimpleLocationService no longer starts a continuous tracking stream. '
      'Use BackgroundLocationService for production location capture.',
    );
    ref.read(isTrackingProvider.notifier).state = false;
    return false;
  }

  // Stop tracking
  Future<void> stopTracking() async {
    ref.read(isTrackingProvider.notifier).state = false;
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Add a geofence
  Future<void> addGeofence(GeofenceArea geofence) async {
    final geofences = ref.read(geofencesProvider.notifier);
    geofences.update((state) => [...state, geofence]);

    // Store in database
    final db = ref.read(locationDatabaseProvider);
    await db.insertGeofence(
      GeofenceAreasCompanion(
        id: drift.Value(geofence.id),
        name: drift.Value(geofence.name),
        latitude: drift.Value(geofence.latitude),
        longitude: drift.Value(geofence.longitude),
        radius: drift.Value(geofence.radius),
        metadata: drift.Value(
          jsonEncode({
            'notifyOnEntry': geofence.notifyOnEntry,
            'notifyOnExit': geofence.notifyOnExit,
          }),
        ),
      ),
    );

    // Check if we're currently inside this geofence
    final currentPosition = ref.read(currentLocationProvider);
    if (currentPosition != null) {
      final distance = _calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        geofence.latitude,
        geofence.longitude,
      );
      geofence.isInside = distance <= geofence.radius;
    }
  }

  // Remove a geofence
  Future<void> removeGeofence(String id) async {
    final geofences = ref.read(geofencesProvider.notifier);
    geofences.update((state) => state.where((g) => g.id != id).toList());

    // Deactivate in database so historical events/notes remain valid.
    final db = ref.read(locationDatabaseProvider);
    await db.deactivateGeofence(id);
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      ref.read(currentLocationProvider.notifier).state = position;
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // Check and request location permissions
  Future<bool> checkLocationPermission() async {
    debugPrint('Checking location permissions...');

    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      // Try to open location settings
      try {
        await Geolocator.openLocationSettings();
        // Re-check after user potentially enables it
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('Location services still disabled after prompt');
          return false;
        }
      } catch (e) {
        debugPrint('Could not open location settings: $e');
        return false;
      }
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('Current location permission: $permission');

    // Request permission if denied
    if (permission == LocationPermission.denied) {
      debugPrint('Requesting location permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('Permission after request: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied by user');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever, opening app settings...');
      // Permissions are denied forever, prompt user to open settings
      try {
        await Geolocator.openAppSettings();
        // Give user time to change settings and return
        // Note: We can't detect if they actually changed it without re-checking later
        return false;
      } catch (e) {
        debugPrint('Could not open app settings: $e');
        return false;
      }
    }

    // For Android, we have whileInUse or always permission
    // Both are acceptable for basic tracking
    final hasPermission =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    debugPrint(
      'Location permission granted: $hasPermission (permission: $permission)',
    );
    return hasPermission;
  }

  // Private helper methods
  // Clear all location history
  Future<void> clearLocationHistory() async {
    ref.read(locationHistoryProvider.notifier).state = [];
    debugPrint('Location history cleared');
  }

  // Export location history as JSON
  String exportLocationHistory() {
    final history = ref.read(locationHistoryProvider);
    return jsonEncode(history.map((p) => p.toJson()).toList());
  }
}
