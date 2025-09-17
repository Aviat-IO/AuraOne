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
  return SimpleLocationService(ref);
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
  StreamSubscription<Position>? _positionStream;
  Timer? _geofenceCheckTimer;

  SimpleLocationService(this.ref);

  // Initialize location service
  Future<void> initialize() async {
    debugPrint('SimpleLocationService initialized');

    // Load existing geofences from database
    await _loadGeofencesFromDatabase();

    // Schedule daily cleanup and summary generation
    Timer.periodic(Duration(hours: 24), (_) async {
      await _performDailyMaintenance();
    });
  }

  // Load geofences from database
  Future<void> _loadGeofencesFromDatabase() async {
    final db = ref.read(locationDatabaseProvider);
    final dbGeofences = await db.select(db.geofenceAreas).get();

    final geofences = dbGeofences.map((dbGeofence) {
      Map<String, dynamic>? metadata;
      if (dbGeofence.metadata != null) {
        metadata = jsonDecode(dbGeofence.metadata!);
      }

      return GeofenceArea(
        id: dbGeofence.id,
        name: dbGeofence.name,
        latitude: dbGeofence.latitude,
        longitude: dbGeofence.longitude,
        radius: dbGeofence.radius,
        notifyOnEntry: metadata?['notifyOnEntry'],
        notifyOnExit: metadata?['notifyOnExit'],
        createdAt: dbGeofence.createdAt,
      );
    }).toList();

    ref.read(geofencesProvider.notifier).state = geofences;
    debugPrint('Loaded ${geofences.length} geofences from database');
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
    Duration interval = const Duration(seconds: 10),
    double distanceFilter = 10,
  }) async {
    // Check permissions first
    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      return false;
    }

    // Configure location settings
    late LocationSettings locationSettings;

    locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter.toInt(),
    );

    // Start position stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _handleLocationUpdate(position);
    });

    // Start geofence checking timer
    _startGeofenceChecking();

    ref.read(isTrackingProvider.notifier).state = true;
    return true;
  }

  // Stop tracking
  Future<void> stopTracking() async {
    _positionStream?.cancel();
    _geofenceCheckTimer?.cancel();
    ref.read(isTrackingProvider.notifier).state = false;
  }

  void _handleLocationUpdate(Position position) async {
    // Update current location
    ref.read(currentLocationProvider.notifier).state = position;

    // Add to history
    final point = LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp,
      accuracy: position.accuracy,
    );

    final history = ref.read(locationHistoryProvider.notifier);
    history.update((state) => [...state, point]);

    // Store in database
    final db = ref.read(locationDatabaseProvider);
    await db.insertLocationPoint(LocationPointsCompanion(
      latitude: drift.Value(position.latitude),
      longitude: drift.Value(position.longitude),
      altitude: drift.Value(position.altitude),
      speed: drift.Value(position.speed),
      heading: drift.Value(position.heading),
      timestamp: drift.Value(position.timestamp),
      accuracy: drift.Value(position.accuracy),
      isSignificant: const drift.Value(false),
    ));

    // Check geofences
    _checkGeofences(position);

    // Store location data
    _storeLocationData(point);
  }

  void _startGeofenceChecking() {
    // Check geofences every 30 seconds
    _geofenceCheckTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      final position = await getCurrentLocation();
      if (position != null) {
        _checkGeofences(position);
      }
    });
  }

  void _checkGeofences(Position position) async {
    final geofences = ref.read(geofencesProvider);
    final db = ref.read(locationDatabaseProvider);

    for (final geofence in geofences) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        geofence.latitude,
        geofence.longitude,
      );

      final wasInside = geofence.isInside;
      final isNowInside = distance <= geofence.radius;

      if (!wasInside && isNowInside) {
        // Entered geofence
        geofence.isInside = true;
        debugPrint('Entered geofence: ${geofence.name}');

        // Store event in database
        await db.insertGeofenceEvent(GeofenceEventsCompanion(
          geofenceId: drift.Value(geofence.id),
          eventType: const drift.Value('enter'),
          timestamp: drift.Value(DateTime.now()),
          latitude: drift.Value(position.latitude),
          longitude: drift.Value(position.longitude),
        ));

        if (geofence.notifyOnEntry != null) {
          _createGeofenceNote(geofence, 'entered');
        }
      } else if (wasInside && !isNowInside) {
        // Exited geofence
        geofence.isInside = false;
        debugPrint('Exited geofence: ${geofence.name}');

        // Store event in database
        await db.insertGeofenceEvent(GeofenceEventsCompanion(
          geofenceId: drift.Value(geofence.id),
          eventType: const drift.Value('exit'),
          timestamp: drift.Value(DateTime.now()),
          latitude: drift.Value(position.latitude),
          longitude: drift.Value(position.longitude),
        ));

        if (geofence.notifyOnExit != null) {
          _createGeofenceNote(geofence, 'exited');
        }
      }
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

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
    await db.insertGeofence(GeofenceAreasCompanion(
      id: drift.Value(geofence.id),
      name: drift.Value(geofence.name),
      latitude: drift.Value(geofence.latitude),
      longitude: drift.Value(geofence.longitude),
      radius: drift.Value(geofence.radius),
      metadata: drift.Value(jsonEncode({
        'notifyOnEntry': geofence.notifyOnEntry,
        'notifyOnExit': geofence.notifyOnExit,
      })),
    ));

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

    // Remove from database
    final db = ref.read(locationDatabaseProvider);
    await db.deleteGeofence(id);
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
    final hasPermission = permission == LocationPermission.whileInUse ||
                          permission == LocationPermission.always;

    debugPrint('Location permission granted: $hasPermission (permission: $permission)');
    return hasPermission;
  }

  // Private helper methods
  Future<void> _storeLocationData(LocationPoint point) async {
    try {
      // Store location data locally
      debugPrint('Location: ${point.latitude}, ${point.longitude}');
    } catch (e) {
      debugPrint('Error storing location: $e');
    }
  }

  Future<void> _createGeofenceNote(GeofenceArea geofence, String action) async {
    try {
      // Create note when authenticated
      debugPrint('Geofence ${action}: ${geofence.name}');
    } catch (e) {
      debugPrint('Error creating geofence note: $e');
    }
  }

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
