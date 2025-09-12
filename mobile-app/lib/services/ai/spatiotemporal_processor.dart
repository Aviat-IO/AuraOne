import 'dart:isolate';
import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'ai_service.dart';
import 'imu_data_collector.dart';

// Stage 1: Spatiotemporal Data Processing
class SpatiotemporalProcessor extends PipelineStage {
  final AIServiceConfig config;
  Interpreter? _harInterpreter;
  bool _initialized = false;
  
  // IMU data collector for real-time sensor data
  final IMUDataCollector _imuCollector = IMUDataCollector();
  StreamSubscription<List<IMUData>>? _imuStreamSubscription;
  final List<ActivityData> _recentActivities = [];

  // DBSCAN parameters
  static const double dbscanEps = 50.0; // 50 meters radius
  static const int dbscanMinPts = 5; // Minimum points for cluster
  static const double gridCellSize = 100.0; // 100m grid cells

  // HAR parameters
  static const int harWindowSize = 128; // 2.56 seconds at 50Hz
  static const double harSamplingRate = 50.0; // Hz
  static const int harOverlap = 64; // 50% overlap

  SpatiotemporalProcessor(this.config);

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Load HAR CNN-LSTM model
    await _loadHARModel();

    _initialized = true;
  }

  Future<void> _loadHARModel() async {
    try {
      // Load the quantized HAR model (~27KB as per AI-SPEC)
      final options = InterpreterOptions();

      if (config.enableHardwareAcceleration) {
        // Enable NNAPI for Android or Core ML for iOS
        if (Platform.isAndroid) {
          options.addDelegate(NnApiDelegate());
        } else if (Platform.isIOS) {
          // Core ML delegate would be added here
          // options.addDelegate(CoreMlDelegate());
        }
      }

      _harInterpreter = await Interpreter.fromAsset(
        'assets/models/preprocessing/har_model.tflite',
        options: options,
      );

      debugPrint('HAR model loaded successfully');
    } catch (e) {
      debugPrint('Failed to load HAR model: $e');
      // Continue without HAR - will use fallback
    }
  }

  Future<SpatiotemporalData> process(DateTime date) async {
    // Get GPS data for the day
    final gpsData = await _getGPSData(date);

    // Get IMU sensor data for the day
    final imuData = await _getIMUData(date);

    // Stage 1.1: Location Clustering with DBSCAN
    final locationClusters = await _performDBSCAN(gpsData);

    // Stage 1.2: Human Activity Recognition
    final activities = await _performHAR(imuData);

    // Correlate location and activity data
    final events = _correlateData(locationClusters, activities);

    return SpatiotemporalData(
      date: date,
      events: events,
      rawGPSCount: gpsData.length,
      clusterCount: locationClusters.where((c) => c.isStay).length,
    );
  }

  Future<List<GPSPoint>> _getGPSData(DateTime date) async {
    // Retrieve GPS data from storage/database
    // This would integrate with existing location tracking from Task 3
    return [];
  }

  Future<List<IMUData>> _getIMUData(DateTime date) async {
    // For historical data, retrieve from storage
    // For real-time, use _recentActivities
    if (_recentActivities.isNotEmpty) {
      // Convert recent activities back to IMU data for processing
      // This is a simplified approach - in production, you'd store raw IMU data
      return _recentActivities
          .where((a) => a.startTime.day == date.day && 
                       a.startTime.month == date.month &&
                       a.startTime.year == date.year)
          .expand((a) => _generateIMUDataFromActivity(a))
          .toList();
    }
    
    // Otherwise, retrieve from storage (if implemented)
    return [];
  }
  
  /// Generate synthetic IMU data from activity (for demo purposes)
  List<IMUData> _generateIMUDataFromActivity(ActivityData activity) {
    final samples = <IMUData>[];
    final duration = activity.endTime.difference(activity.startTime);
    final sampleCount = (duration.inMilliseconds / 20).round(); // 50Hz
    
    for (int i = 0; i < sampleCount && i < 128; i++) {
      samples.add(IMUData(
        accelX: 0.0,
        accelY: 9.8, // Gravity
        accelZ: 0.0,
        gyroX: 0.0,
        gyroY: 0.0,
        gyroZ: 0.0,
        timestamp: activity.startTime.add(Duration(milliseconds: i * 20)),
      ));
    }
    
    return samples;
  }

  Future<List<LocationCluster>> _performDBSCAN(List<GPSPoint> points) async {
    if (points.isEmpty) return [];

    // Grid-based optimization for O(n log n) complexity
    final grid = _createSpatialGrid(points);
    final clusters = <LocationCluster>[];
    final visited = Set<int>();
    final noise = Set<int>();
    int currentClusterId = 0;

    for (int i = 0; i < points.length; i++) {
      if (visited.contains(i)) continue;

      visited.add(i);
      final neighbors = _getNeighbors(points, i, grid);

      if (neighbors.length < dbscanMinPts) {
        noise.add(i);
      } else {
        currentClusterId++;
        final cluster = _expandCluster(
          points,
          i,
          neighbors,
          currentClusterId,
          visited,
          grid,
        );
        clusters.add(cluster);
      }
    }

    // Convert clusters to Stay/Journey events
    return _convertToEvents(clusters, noise, points);
  }

  Map<String, List<int>> _createSpatialGrid(List<GPSPoint> points) {
    final grid = <String, List<int>>{};

    for (int i = 0; i < points.length; i++) {
      final cellKey = _getCellKey(points[i]);
      grid.putIfAbsent(cellKey, () => []).add(i);
    }

    return grid;
  }

  String _getCellKey(GPSPoint point) {
    final x = (point.latitude / gridCellSize).floor();
    final y = (point.longitude / gridCellSize).floor();
    return '$x,$y';
  }

  List<int> _getNeighbors(
    List<GPSPoint> points,
    int pointIndex,
    Map<String, List<int>> grid,
  ) {
    final point = points[pointIndex];
    final neighbors = <int>[];

    // Check only relevant grid cells
    final cellKey = _getCellKey(point);
    final parts = cellKey.split(',');
    final x = int.parse(parts[0]);
    final y = int.parse(parts[1]);

    // Check 3x3 grid around the point
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final neighborKey = '${x + dx},${y + dy}';
        final cellPoints = grid[neighborKey] ?? [];

        for (final idx in cellPoints) {
          if (idx != pointIndex && _distance(point, points[idx]) <= dbscanEps) {
            neighbors.add(idx);
          }
        }
      }
    }

    return neighbors;
  }

  double _distance(GPSPoint p1, GPSPoint p2) {
    // Haversine distance formula for GPS coordinates
    const double earthRadius = 6371000; // meters
    final lat1Rad = p1.latitude * pi / 180;
    final lat2Rad = p2.latitude * pi / 180;
    final deltaLat = (p2.latitude - p1.latitude) * pi / 180;
    final deltaLon = (p2.longitude - p1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  LocationCluster _expandCluster(
    List<GPSPoint> points,
    int pointIndex,
    List<int> neighbors,
    int clusterId,
    Set<int> visited,
    Map<String, List<int>> grid,
  ) {
    final clusterPoints = [pointIndex];
    final seedSet = List<int>.from(neighbors);

    for (int i = 0; i < seedSet.length; i++) {
      final currentPoint = seedSet[i];

      if (!visited.contains(currentPoint)) {
        visited.add(currentPoint);
        final currentNeighbors = _getNeighbors(points, currentPoint, grid);

        if (currentNeighbors.length >= dbscanMinPts) {
          seedSet.addAll(currentNeighbors);
        }
      }

      clusterPoints.add(currentPoint);
    }

    // Calculate cluster center and time range
    return _createCluster(points, clusterPoints, clusterId);
  }

  LocationCluster _createCluster(
    List<GPSPoint> points,
    List<int> clusterIndices,
    int clusterId,
  ) {
    double sumLat = 0, sumLon = 0;
    DateTime? startTime, endTime;

    for (final idx in clusterIndices) {
      final point = points[idx];
      sumLat += point.latitude;
      sumLon += point.longitude;

      if (startTime == null || point.timestamp.isBefore(startTime)) {
        startTime = point.timestamp;
      }
      if (endTime == null || point.timestamp.isAfter(endTime)) {
        endTime = point.timestamp;
      }
    }

    return LocationCluster(
      id: clusterId,
      centerLatitude: sumLat / clusterIndices.length,
      centerLongitude: sumLon / clusterIndices.length,
      startTime: startTime!,
      endTime: endTime!,
      pointCount: clusterIndices.length,
      isStay: true,
    );
  }

  List<LocationCluster> _convertToEvents(
    List<LocationCluster> clusters,
    Set<int> noisePoints,
    List<GPSPoint> points,
  ) {
    final events = <LocationCluster>[];

    // Add stay clusters
    events.addAll(clusters);

    // Convert noise points to journey events
    if (noisePoints.isNotEmpty) {
      // Group consecutive noise points into journey segments
      final sortedNoise = noisePoints.toList()
        ..sort((a, b) => points[a].timestamp.compareTo(points[b].timestamp));

      // Create journey events from noise points
      // Implementation would group consecutive points into journey segments
    }

    return events;
  }

  Future<List<ActivityData>> _performHAR(List<IMUData> imuData) async {
    if (_harInterpreter == null || imuData.isEmpty) {
      return [];
    }

    final activities = <ActivityData>[];

    // Process IMU data in sliding windows
    for (int i = 0; i < imuData.length - harWindowSize; i += harOverlap) {
      final window = imuData.sublist(i, i + harWindowSize);
      final prediction = await _runHARInference(window);

      activities.add(ActivityData(
        startTime: window.first.timestamp,
        endTime: window.last.timestamp,
        activity: prediction.activity,
        confidence: prediction.confidence,
      ));
    }

    return activities;
  }

  Future<HARPrediction> _runHARInference(List<IMUData> window) async {
    // Prepare input tensor (128 samples x 6 channels: accel XYZ, gyro XYZ)
    final input = List.generate(
      harWindowSize,
      (i) => [
        window[i].accelX,
        window[i].accelY,
        window[i].accelZ,
        window[i].gyroX,
        window[i].gyroY,
        window[i].gyroZ,
      ],
    );

    // Run inference
    final output = List.filled(5, 0.0); // 5 activity classes
    _harInterpreter!.run(input, output);

    // Find predicted activity
    int maxIndex = 0;
    double maxConfidence = output[0];
    for (int i = 1; i < output.length; i++) {
      if (output[i] > maxConfidence) {
        maxConfidence = output[i];
        maxIndex = i;
      }
    }

    return HARPrediction(
      activity: _activityFromIndex(maxIndex),
      confidence: maxConfidence,
    );
  }

  PhysicalActivity _activityFromIndex(int index) {
    const activities = [
      PhysicalActivity.stationary,
      PhysicalActivity.walking,
      PhysicalActivity.running,
      PhysicalActivity.driving,
      PhysicalActivity.cycling,
    ];
    return activities[index];
  }

  List<SpatiotemporalEvent> _correlateData(
    List<LocationCluster> clusters,
    List<ActivityData> activities,
  ) {
    final events = <SpatiotemporalEvent>[];

    // Correlate location clusters with activities
    for (final cluster in clusters) {
      // Find activities that overlap with this cluster's time range
      final clusterActivities = activities.where((activity) {
        return activity.startTime.isAfter(cluster.startTime) &&
               activity.endTime.isBefore(cluster.endTime);
      }).toList();

      // Determine dominant activity
      final dominantActivity = _getDominantActivity(clusterActivities);

      events.add(SpatiotemporalEvent(
        type: cluster.isStay ? EventType.stay : EventType.journey,
        location: LatLng(cluster.centerLatitude, cluster.centerLongitude),
        startTime: cluster.startTime,
        endTime: cluster.endTime,
        activity: dominantActivity,
      ));
    }

    return events;
  }

  PhysicalActivity? _getDominantActivity(List<ActivityData> activities) {
    if (activities.isEmpty) return null;

    // Count occurrences of each activity
    final counts = <PhysicalActivity, int>{};
    for (final activity in activities) {
      counts[activity.activity] = (counts[activity.activity] ?? 0) + 1;
    }

    // Return most frequent activity
    return counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Start real-time Human Activity Recognition
  Future<void> startRealtimeHAR() async {
    if (!_initialized || _harInterpreter == null) {
      debugPrint('HAR not initialized, cannot start real-time collection');
      return;
    }
    
    // Check sensor availability
    final sensorsAvailable = await _imuCollector.checkSensorAvailability();
    if (!sensorsAvailable) {
      debugPrint('IMU sensors not available on this device');
      return;
    }
    
    // Start IMU data collection
    await _imuCollector.startCollection();
    
    // Subscribe to IMU data stream for real-time HAR
    _imuStreamSubscription = _imuCollector.imuDataStream.listen(
      (List<IMUData> window) async {
        // Run HAR inference on the window
        final prediction = await _runHARInference(window);
        
        // Store activity data
        final activity = ActivityData(
          startTime: window.first.timestamp,
          endTime: window.last.timestamp,
          activity: prediction.activity,
          confidence: prediction.confidence,
        );
        
        _recentActivities.add(activity);
        
        // Keep only recent activities (last hour)
        final cutoff = DateTime.now().subtract(const Duration(hours: 1));
        _recentActivities.removeWhere((a) => a.endTime.isBefore(cutoff));
        
        debugPrint('HAR: ${prediction.activity} (confidence: ${prediction.confidence.toStringAsFixed(2)})');
      },
    );
    
    debugPrint('Real-time HAR started');
  }
  
  /// Stop real-time Human Activity Recognition
  void stopRealtimeHAR() {
    _imuStreamSubscription?.cancel();
    _imuStreamSubscription = null;
    _imuCollector.stopCollection();
    debugPrint('Real-time HAR stopped');
  }
  
  /// Get recent activity data from real-time HAR
  List<ActivityData> getRecentActivities() {
    return List.from(_recentActivities);
  }

  @override
  Future<void> dispose() async {
    stopRealtimeHAR();
    _imuCollector.dispose();
    _harInterpreter?.close();
    _initialized = false;
  }

  @override
  bool get isInitialized => _initialized;
}

// Data models for spatiotemporal processing
class GPSPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  GPSPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

class IMUData {
  final double accelX, accelY, accelZ;
  final double gyroX, gyroY, gyroZ;
  final DateTime timestamp;

  IMUData({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.timestamp,
  });
}

class LocationCluster {
  final int id;
  final double centerLatitude;
  final double centerLongitude;
  final DateTime startTime;
  final DateTime endTime;
  final int pointCount;
  final bool isStay;

  LocationCluster({
    required this.id,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.startTime,
    required this.endTime,
    required this.pointCount,
    required this.isStay,
  });
}

class ActivityData {
  final DateTime startTime;
  final DateTime endTime;
  final PhysicalActivity activity;
  final double confidence;

  ActivityData({
    required this.startTime,
    required this.endTime,
    required this.activity,
    required this.confidence,
  });
}

class HARPrediction {
  final PhysicalActivity activity;
  final double confidence;

  HARPrediction({
    required this.activity,
    required this.confidence,
  });
}

enum PhysicalActivity {
  stationary,
  walking,
  running,
  driving,
  cycling,
}

class SpatiotemporalEvent {
  final EventType type;
  final LatLng location;
  final DateTime startTime;
  final DateTime endTime;
  final PhysicalActivity? activity;

  SpatiotemporalEvent({
    required this.type,
    required this.location,
    required this.startTime,
    required this.endTime,
    this.activity,
  });
}

enum EventType { stay, journey }

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}

class SpatiotemporalData {
  final DateTime date;
  final List<SpatiotemporalEvent> events;
  final int rawGPSCount;
  final int clusterCount;

  SpatiotemporalData({
    required this.date,
    required this.events,
    required this.rawGPSCount,
    required this.clusterCount,
  });
}
