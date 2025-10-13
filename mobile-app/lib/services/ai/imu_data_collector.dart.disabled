// NOTE: This service is REDUNDANT with flutter_background_geolocation
// Activity detection is now provided by flutter_background_geolocation which includes:
// - activity.type: still/walking/running/in_vehicle/on_bicycle/on_foot
// - activity.confidence: confidence score for detected activity
// - isMoving: boolean indicating if device is moving
// - speed, heading, heading_accuracy: movement data
//
// Custom IMU data collection for HAR (Human Activity Recognition) is no longer needed.
// This file is kept for reference but is not used in production.

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'spatiotemporal_processor.dart';

/// Service for collecting IMU (Inertial Measurement Unit) data
/// from device accelerometer and gyroscope sensors
/// [DEPRECATED] Use flutter_background_geolocation activity data instead
class IMUDataCollector {
  // Sampling configuration
  static const Duration samplingInterval = Duration(milliseconds: 20); // 50Hz
  static const int bufferSize = 256; // Store recent samples for windowing
  
  // Stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // Data buffers
  final Queue<IMUData> _dataBuffer = Queue<IMUData>();
  
  // Latest sensor readings
  AccelerometerEvent? _lastAccelerometer;
  GyroscopeEvent? _lastGyroscope;
  
  // Collection state
  bool _isCollecting = false;
  Timer? _samplingTimer;
  
  // Stream controller for processed IMU data
  final _imuDataController = StreamController<List<IMUData>>.broadcast();
  Stream<List<IMUData>> get imuDataStream => _imuDataController.stream;
  
  /// Start collecting IMU data from device sensors
  Future<void> startCollection() async {
    if (_isCollecting) return;
    
    _isCollecting = true;
    _dataBuffer.clear();
    
    // Subscribe to accelerometer events
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen(
      (AccelerometerEvent event) {
        _lastAccelerometer = event;
      },
      onError: (error) {
        debugPrint('Accelerometer error: $error');
      },
      cancelOnError: false,
    );
    
    // Subscribe to gyroscope events
    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen(
      (GyroscopeEvent event) {
        _lastGyroscope = event;
      },
      onError: (error) {
        debugPrint('Gyroscope error: $error');
      },
      cancelOnError: false,
    );
    
    // Start sampling timer for consistent 50Hz sampling
    _samplingTimer = Timer.periodic(samplingInterval, (_) {
      _collectSample();
    });
    
    debugPrint('IMU data collection started at 50Hz');
  }
  
  /// Stop collecting IMU data
  void stopCollection() {
    _isCollecting = false;
    
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    
    _samplingTimer?.cancel();
    _samplingTimer = null;
    
    debugPrint('IMU data collection stopped');
  }
  
  /// Collect a single IMU sample from current sensor readings
  void _collectSample() {
    if (_lastAccelerometer == null || _lastGyroscope == null) {
      return; // Skip if we don't have both readings yet
    }
    
    final sample = IMUData(
      accelX: _lastAccelerometer!.x,
      accelY: _lastAccelerometer!.y,
      accelZ: _lastAccelerometer!.z,
      gyroX: _lastGyroscope!.x,
      gyroY: _lastGyroscope!.y,
      gyroZ: _lastGyroscope!.z,
      timestamp: DateTime.now(),
    );
    
    // Add to buffer
    _dataBuffer.add(sample);
    
    // Maintain buffer size
    while (_dataBuffer.length > bufferSize) {
      _dataBuffer.removeFirst();
    }
    
    // Emit window when we have enough samples (128 for HAR)
    if (_dataBuffer.length >= 128) {
      final window = _dataBuffer.toList().sublist(_dataBuffer.length - 128);
      _imuDataController.add(window);
    }
  }
  
  /// Get current buffer of IMU data
  List<IMUData> getCurrentBuffer() {
    return _dataBuffer.toList();
  }
  
  /// Get a sliding window of IMU data for HAR processing
  List<IMUData> getSlidingWindow({int windowSize = 128}) {
    if (_dataBuffer.length < windowSize) {
      return [];
    }
    
    return _dataBuffer.toList().sublist(_dataBuffer.length - windowSize);
  }
  
  /// Check if sensors are available on the device
  Future<bool> checkSensorAvailability() async {
    try {
      // Try to get one sample from each sensor
      final accelAvailable = await accelerometerEventStream()
          .first
          .timeout(const Duration(seconds: 2))
          .then((_) => true)
          .catchError((_) => false);
          
      final gyroAvailable = await gyroscopeEventStream()
          .first
          .timeout(const Duration(seconds: 2))
          .then((_) => true)
          .catchError((_) => false);
          
      return accelAvailable && gyroAvailable;
    } catch (e) {
      debugPrint('Error checking sensor availability: $e');
      return false;
    }
  }
  
  /// Dispose of resources
  void dispose() {
    stopCollection();
    _imuDataController.close();
  }
  
  bool get isCollecting => _isCollecting;
  int get bufferLength => _dataBuffer.length;
}

/// Extension to get proper sensor interval
extension on SensorInterval {
  static const SensorInterval fastestInterval = SensorInterval.fastestInterval;
}