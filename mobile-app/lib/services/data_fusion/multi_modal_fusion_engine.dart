import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../location_service.dart';
import '../database_service.dart';
import '../photo_service.dart';
import '../ai/advanced_photo_analyzer.dart';
import '../../models/collected_data.dart';

/// Represents a fused data point combining multiple modalities
class FusedDataPoint {
  final DateTime timestamp;
  final Position? location;
  final String? locationContext; // e.g., "Home", "Work", "Grocery Store"
  final ActivityType activity;
  final double confidence;
  final List<PhotoContext> photos;
  final Map<String, dynamic> metadata;

  FusedDataPoint({
    required this.timestamp,
    this.location,
    this.locationContext,
    required this.activity,
    required this.confidence,
    required this.photos,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'location': location != null ? {
      'latitude': location!.latitude,
      'longitude': location!.longitude,
      'altitude': location!.altitude,
      'speed': location!.speed,
    } : null,
    'locationContext': locationContext,
    'activity': activity.toString(),
    'confidence': confidence,
    'photos': photos.map((p) => p.toJson()).toList(),
    'metadata': metadata,
  };
}

/// Photo with analyzed context
class PhotoContext {
  final String photoPath;
  final DateTime timestamp;
  final List<String> objects;
  final List<String> labels;
  final int faceCount;
  final String? recognizedText;
  final String sceneDescription;
  final Map<String, dynamic> metadata;

  PhotoContext({
    required this.photoPath,
    required this.timestamp,
    required this.objects,
    required this.labels,
    required this.faceCount,
    this.recognizedText,
    required this.sceneDescription,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'photoPath': photoPath,
    'timestamp': timestamp.toIso8601String(),
    'objects': objects,
    'labels': labels,
    'faceCount': faceCount,
    'recognizedText': recognizedText,
    'sceneDescription': sceneDescription,
    'metadata': metadata,
  };
}

/// Activity types detected from movement patterns
enum ActivityType {
  stationary,
  walking,
  running,
  cycling,
  driving,
  transit,
  unknown
}

/// Multi-Modal Data Fusion Engine
/// Combines photo analysis, location data, and movement patterns
class MultiModalFusionEngine {
  final LocationService _locationService;
  final PhotoService _photoService;
  final DatabaseService _databaseService;
  final AdvancedPhotoAnalyzer _photoAnalyzer;

  // Sensor streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _locationSubscription;

  // Activity detection state
  final List<AccelerometerEvent> _recentAccelerometer = [];
  final List<GyroscopeEvent> _recentGyroscope = [];
  final List<Position> _recentPositions = [];

  ActivityType _currentActivity = ActivityType.unknown;
  double _activityConfidence = 0.0;

  // Fusion state
  final List<FusedDataPoint> _fusedDataBuffer = [];
  Timer? _fusionTimer;

  bool _isRunning = false;

  MultiModalFusionEngine({
    required LocationService locationService,
    required PhotoService photoService,
    required DatabaseService databaseService,
    required AdvancedPhotoAnalyzer photoAnalyzer,
  })  : _locationService = locationService,
        _photoService = photoService,
        _databaseService = databaseService,
        _photoAnalyzer = photoAnalyzer;

  /// Start the fusion engine
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    debugPrint('Starting Multi-Modal Fusion Engine');

    // Initialize photo analyzer if needed
    await _photoAnalyzer.initialize();

    // Start sensor subscriptions
    _startSensorMonitoring();

    // Start location monitoring
    _startLocationMonitoring();

    // Start fusion timer (process data every 30 seconds)
    _fusionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _processFusedData(),
    );
  }

  /// Stop the fusion engine
  void stop() {
    if (!_isRunning) return;
    _isRunning = false;

    debugPrint('Stopping Multi-Modal Fusion Engine');

    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
    _fusionTimer?.cancel();

    // Process any remaining data
    _processFusedData();
  }

  /// Start monitoring device sensors
  void _startSensorMonitoring() {
    // Monitor accelerometer for movement detection
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        _recentAccelerometer.add(event);
        if (_recentAccelerometer.length > 100) {
          _recentAccelerometer.removeAt(0);
        }
        _updateActivityDetection();
      },
      onError: (error) {
        debugPrint('Accelerometer error: $error');
      },
    );

    // Monitor gyroscope for rotation detection
    _gyroscopeSubscription = gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        _recentGyroscope.add(event);
        if (_recentGyroscope.length > 100) {
          _recentGyroscope.removeAt(0);
        }
      },
      onError: (error) {
        debugPrint('Gyroscope error: $error');
      },
    );
  }

  /// Start monitoring location
  void _startLocationMonitoring() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _recentPositions.add(position);
        if (_recentPositions.length > 20) {
          _recentPositions.removeAt(0);
        }
        _updateActivityDetection();
      },
      onError: (error) {
        debugPrint('Location error: $error');
      },
    );
  }

  /// Update activity detection based on sensor and location data
  void _updateActivityDetection() {
    if (_recentAccelerometer.isEmpty) return;

    // Calculate acceleration magnitude
    double totalAcceleration = 0;
    for (final event in _recentAccelerometer) {
      final magnitude = _calculateMagnitude(event.x, event.y, event.z);
      totalAcceleration += magnitude;
    }
    final avgAcceleration = totalAcceleration / _recentAccelerometer.length;

    // Calculate speed from GPS if available
    double? speed;
    if (_recentPositions.isNotEmpty) {
      speed = _recentPositions.last.speed;
    }

    // Detect activity based on patterns
    final detected = _detectActivity(avgAcceleration, speed);
    _currentActivity = detected.$1;
    _activityConfidence = detected.$2;
  }

  /// Detect activity type from sensor data
  (ActivityType, double) _detectActivity(double avgAcceleration, double? speed) {
    // Speed-based detection (most reliable)
    if (speed != null && speed >= 0) {
      if (speed < 0.5) {
        return (ActivityType.stationary, 0.9);
      } else if (speed < 2.0) {
        return (ActivityType.walking, 0.8);
      } else if (speed < 4.5) {
        return (ActivityType.running, 0.85);
      } else if (speed < 8.0) {
        return (ActivityType.cycling, 0.7);
      } else if (speed < 30.0) {
        return (ActivityType.transit, 0.7);
      } else {
        return (ActivityType.driving, 0.8);
      }
    }

    // Acceleration-based detection (fallback)
    if (avgAcceleration < 10.5) {
      return (ActivityType.stationary, 0.7);
    } else if (avgAcceleration < 12.0) {
      return (ActivityType.walking, 0.6);
    } else if (avgAcceleration < 15.0) {
      return (ActivityType.running, 0.6);
    } else {
      return (ActivityType.transit, 0.5);
    }
  }

  /// Calculate magnitude of 3D vector
  double _calculateMagnitude(double x, double y, double z) {
    return (x * x + y * y + z * z).sqrt();
  }

  /// Process and fuse collected data
  Future<void> _processFusedData() async {
    if (!_isRunning) return;

    try {
      final now = DateTime.now();

      // Get current location
      final currentPosition = _recentPositions.isNotEmpty
        ? _recentPositions.last
        : null;

      // Get location context (reverse geocoding would go here)
      String? locationContext;
      if (currentPosition != null) {
        locationContext = await _getLocationContext(currentPosition);
      }

      // Get recent photos
      final recentPhotos = await _getRecentPhotos(now);

      // Analyze photos
      final photoContexts = await _analyzePhotos(recentPhotos);

      // Create fused data point
      final fusedPoint = FusedDataPoint(
        timestamp: now,
        location: currentPosition,
        locationContext: locationContext,
        activity: _currentActivity,
        confidence: _activityConfidence,
        photos: photoContexts,
        metadata: {
          'accelerometerSamples': _recentAccelerometer.length,
          'gyroscopeSamples': _recentGyroscope.length,
          'locationSamples': _recentPositions.length,
        },
      );

      // Add to buffer
      _fusedDataBuffer.add(fusedPoint);

      // Store in database if buffer is large enough
      if (_fusedDataBuffer.length >= 5) {
        await _storeFusedData();
      }

      debugPrint('Fused data point created: ${fusedPoint.activity} at ${fusedPoint.locationContext ?? "Unknown"}');
    } catch (e) {
      debugPrint('Error processing fused data: $e');
    }
  }

  /// Get location context from coordinates
  Future<String?> _getLocationContext(Position position) async {
    // This would normally use reverse geocoding or place detection
    // For now, return a simple classification based on common locations

    // Check if near saved locations (home, work, etc.)
    // This is a placeholder - would integrate with actual place detection

    // Simple time-based heuristic for demo
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 6) {
      return 'Home';
    } else if (hour >= 9 && hour < 17) {
      return 'Work';
    } else if (hour >= 17 && hour < 20) {
      return 'Commute';
    } else {
      return 'Out and About';
    }
  }

  /// Get recent photos from photo service
  Future<List<MediaItem>> _getRecentPhotos(DateTime since) async {
    final photos = _photoService.getAllMedia();
    final cutoff = since.subtract(const Duration(minutes: 30));

    return photos.where((photo) {
      if (photo.createdDate == null) return false;
      return photo.createdDate!.isAfter(cutoff);
    }).toList();
  }

  /// Analyze photos using ML Kit
  Future<List<PhotoContext>> _analyzePhotos(List<MediaItem> photos) async {
    final contexts = <PhotoContext>[];

    for (final photo in photos) {
      if (photo.filePath == null) continue;

      try {
        final analysis = await _photoAnalyzer.analyzePhoto(photo.filePath!);
        if (analysis != null) {
          contexts.add(PhotoContext(
            photoPath: photo.filePath!,
            timestamp: photo.createdDate ?? DateTime.now(),
            objects: analysis.objects
              .where((o) => o.labels.isNotEmpty)
              .map((o) => o.labels.first.text)
              .toList(),
            labels: analysis.labels,
            faceCount: analysis.faceCount,
            recognizedText: analysis.recognizedText,
            sceneDescription: analysis.sceneDescription,
            metadata: analysis.metadata,
          ));
        }
      } catch (e) {
        debugPrint('Error analyzing photo: $e');
      }
    }

    return contexts;
  }

  /// Store fused data in database
  Future<void> _storeFusedData() async {
    if (_fusedDataBuffer.isEmpty) return;

    try {
      // Store each fused point as collected data
      for (final point in _fusedDataBuffer) {
        final data = CollectedData(
          timestamp: point.timestamp,
          dataType: 'fused_context',
          value: point.toJson(),
        );
        await _databaseService.insertCollectedData(data);
      }

      debugPrint('Stored ${_fusedDataBuffer.length} fused data points');
      _fusedDataBuffer.clear();
    } catch (e) {
      debugPrint('Error storing fused data: $e');
    }
  }

  /// Get recent fused data for summary generation
  Future<List<FusedDataPoint>> getRecentFusedData({
    Duration lookback = const Duration(hours: 24),
  }) async {
    final since = DateTime.now().subtract(lookback);
    final data = await _databaseService.getCollectedDataByType(
      'fused_context',
      since: since,
    );

    return data.map((item) {
      final json = item.value as Map<String, dynamic>;
      return _fusedDataPointFromJson(json);
    }).toList();
  }

  /// Convert JSON to FusedDataPoint
  FusedDataPoint _fusedDataPointFromJson(Map<String, dynamic> json) {
    return FusedDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'] != null ? Position(
        latitude: json['location']['latitude'],
        longitude: json['location']['longitude'],
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: json['location']['altitude'] ?? 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: json['location']['speed'] ?? 0,
        speedAccuracy: 0,
      ) : null,
      locationContext: json['locationContext'],
      activity: ActivityType.values.firstWhere(
        (a) => a.toString() == json['activity'],
        orElse: () => ActivityType.unknown,
      ),
      confidence: json['confidence'],
      photos: (json['photos'] as List).map((p) => PhotoContext(
        photoPath: p['photoPath'],
        timestamp: DateTime.parse(p['timestamp']),
        objects: List<String>.from(p['objects']),
        labels: List<String>.from(p['labels']),
        faceCount: p['faceCount'],
        recognizedText: p['recognizedText'],
        sceneDescription: p['sceneDescription'],
        metadata: p['metadata'],
      )).toList(),
      metadata: json['metadata'],
    );
  }

  /// Generate narrative from fused data
  Future<String> generateNarrative({
    Duration lookback = const Duration(hours: 24),
  }) async {
    final fusedData = await getRecentFusedData(lookback: lookback);
    if (fusedData.isEmpty) {
      return 'No activity data available for this period.';
    }

    // Group data by location context and activity
    final narrative = StringBuffer();
    narrative.writeln('Your Day in Context:\n');

    // Morning activities
    final morning = fusedData.where((d) =>
      d.timestamp.hour >= 6 && d.timestamp.hour < 12
    ).toList();
    if (morning.isNotEmpty) {
      narrative.writeln(_generatePeriodNarrative('Morning', morning));
    }

    // Afternoon activities
    final afternoon = fusedData.where((d) =>
      d.timestamp.hour >= 12 && d.timestamp.hour < 18
    ).toList();
    if (afternoon.isNotEmpty) {
      narrative.writeln(_generatePeriodNarrative('Afternoon', afternoon));
    }

    // Evening activities
    final evening = fusedData.where((d) =>
      d.timestamp.hour >= 18 || d.timestamp.hour < 6
    ).toList();
    if (evening.isNotEmpty) {
      narrative.writeln(_generatePeriodNarrative('Evening', evening));
    }

    return narrative.toString();
  }

  /// Generate narrative for a time period
  String _generatePeriodNarrative(String period, List<FusedDataPoint> data) {
    final buffer = StringBuffer();
    buffer.writeln('**$period:**');

    // Group by location
    final locations = <String, List<FusedDataPoint>>{};
    for (final point in data) {
      final location = point.locationContext ?? 'Unknown';
      locations.putIfAbsent(location, () => []).add(point);
    }

    for (final entry in locations.entries) {
      final location = entry.key;
      final points = entry.value;

      // Get dominant activity
      final activities = <ActivityType, int>{};
      for (final point in points) {
        activities[point.activity] = (activities[point.activity] ?? 0) + 1;
      }
      final dominantActivity = activities.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

      // Count photos
      final totalPhotos = points.fold<int>(
        0, (sum, p) => sum + p.photos.length
      );

      // Generate description
      buffer.write('At $location, you were mostly ${_activityToString(dominantActivity)}');

      if (totalPhotos > 0) {
        buffer.write(' and captured $totalPhotos photo${totalPhotos > 1 ? 's' : ''}');

        // Add photo context
        final allObjects = <String>{};
        final allLabels = <String>{};
        int totalFaces = 0;

        for (final point in points) {
          for (final photo in point.photos) {
            allObjects.addAll(photo.objects);
            allLabels.addAll(photo.labels);
            totalFaces += photo.faceCount;
          }
        }

        if (totalFaces > 0) {
          buffer.write(' with $totalFaces ${totalFaces == 1 ? 'person' : 'people'}');
        }

        if (allObjects.isNotEmpty) {
          final topObjects = allObjects.take(3).join(', ');
          buffer.write(' featuring $topObjects');
        }
      }

      buffer.writeln('.');
    }

    return buffer.toString();
  }

  /// Convert activity type to readable string
  String _activityToString(ActivityType activity) {
    switch (activity) {
      case ActivityType.stationary:
        return 'stationary';
      case ActivityType.walking:
        return 'walking';
      case ActivityType.running:
        return 'running';
      case ActivityType.cycling:
        return 'cycling';
      case ActivityType.driving:
        return 'driving';
      case ActivityType.transit:
        return 'in transit';
      case ActivityType.unknown:
        return 'active';
    }
  }

  /// Dispose of resources
  void dispose() {
    stop();
  }
}