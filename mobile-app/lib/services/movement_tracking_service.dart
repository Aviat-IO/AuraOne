import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:drift/drift.dart' as drift;
import '../database/location_database.dart';
import '../providers/location_database_provider.dart';

// Movement state enum
enum MovementState {
  still,
  walking,
  running,
  driving,
  unknown,
}

// Movement data model
class MovementData {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double magnitude;
  final MovementState state;
  final double confidence;
  
  MovementData({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.state,
    required this.confidence,
  });
}

// Provider for movement tracking enabled state
final movementTrackingEnabledProvider = StateProvider<bool>((ref) {
  return true; // Enabled by default as per requirements
});

// Provider for current movement state
final currentMovementStateProvider = StateProvider<MovementState>((ref) {
  return MovementState.unknown;
});

// Provider for movement history
final movementHistoryProvider = StateProvider<List<MovementData>>((ref) {
  return [];
});

// Movement tracking service provider
final movementTrackingServiceProvider = Provider<MovementTrackingService>((ref) {
  final database = ref.watch(locationDatabaseProvider);
  return MovementTrackingService(ref, database);
});

class MovementTrackingService {
  final Ref _ref;
  final LocationDatabase _database;
  
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<UserAccelerometerEvent>? _userAccelerometerSubscription;
  
  final List<double> _recentMagnitudes = [];
  final int _windowSize = 50; // Sample window for analysis
  
  Timer? _analysisTimer;
  Timer? _persistenceTimer;
  
  // Movement detection thresholds (more sensitive)
  static const double _stillThreshold = 0.1;      // Very still
  static const double _walkingThreshold = 0.3;    // Walking threshold
  static const double _runningThreshold = 1.5;    // Running threshold  
  static const double _drivingThreshold = 3.0;    // Vehicle threshold
  
  // Gyroscope data for rotation detection
  final List<GyroscopeEvent> _recentGyroData = [];
  
  // Accelerometer data for movement patterns
  final List<AccelerometerEvent> _recentAccelData = [];
  
  MovementTrackingService(this._ref, this._database);
  
  // Initialize movement tracking
  Future<void> initialize() async {
    final enabled = _ref.read(movementTrackingEnabledProvider);
    if (enabled) {
      await startTracking();
    }
  }
  
  // Start tracking movement
  Future<void> startTracking() async {
    // Movement tracking starting...
    
    // Subscribe to gyroscope events
    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(
      _handleGyroscopeEvent,
      onError: (error) {
        // Gyroscope error: $error
      },
      cancelOnError: false,
    );
    
    // Subscribe to accelerometer events for additional movement detection
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(
      _handleAccelerometerEvent,
      onError: (error) {
        // Accelerometer error: $error
      },
      cancelOnError: false,
    );
    
    // Subscribe to user accelerometer (removes gravity)
    _userAccelerometerSubscription = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(
      _handleUserAccelerometerEvent,
      onError: (error) {
        // User accelerometer error: $error
      },
      cancelOnError: false,
    );
    
    // Start analysis timer
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _analyzeMovementPattern(),
    );
    
    // Start persistence timer
    _persistenceTimer?.cancel();
    _persistenceTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _persistMovementData(),
    );
    
    // Movement tracking started
  }
  
  // Stop tracking movement
  void stopTracking() {
    // Movement tracking stopping...
    
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _userAccelerometerSubscription?.cancel();
    _analysisTimer?.cancel();
    _persistenceTimer?.cancel();
    
    _gyroscopeSubscription = null;
    _accelerometerSubscription = null;
    _userAccelerometerSubscription = null;
    _analysisTimer = null;
    _persistenceTimer = null;
    
    _recentMagnitudes.clear();
    _recentGyroData.clear();
    _recentAccelData.clear();
    
    // Movement tracking stopped
  }
  
  // Handle gyroscope events
  void _handleGyroscopeEvent(GyroscopeEvent event) {
    // Calculate rotation magnitude
    final magnitude = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
    
    // Add to recent data
    _recentGyroData.add(event);
    if (_recentGyroData.length > _windowSize) {
      _recentGyroData.removeAt(0);
    }
    
    // Add magnitude to analysis window
    _recentMagnitudes.add(magnitude);
    if (_recentMagnitudes.length > _windowSize) {
      _recentMagnitudes.removeAt(0);
    }
  }
  
  // Handle accelerometer events
  void _handleAccelerometerEvent(AccelerometerEvent event) {
    _recentAccelData.add(event);
    if (_recentAccelData.length > _windowSize) {
      _recentAccelData.removeAt(0);
    }
  }
  
  // Handle user accelerometer events (gravity removed)
  void _handleUserAccelerometerEvent(UserAccelerometerEvent event) {
    // Calculate movement magnitude without gravity
    final magnitude = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
    
    // This gives us actual device movement
    if (_recentMagnitudes.length < _windowSize * 2) {
      _recentMagnitudes.add(magnitude);
    }
  }
  
  // Analyze movement patterns
  void _analyzeMovementPattern() {
    if (_recentMagnitudes.isEmpty) return;
    
    // Calculate average magnitude
    final avgMagnitude = _recentMagnitudes.reduce((a, b) => a + b) / _recentMagnitudes.length;
    
    // Calculate variance for pattern detection
    double variance = 0;
    for (final mag in _recentMagnitudes) {
      variance += pow(mag - avgMagnitude, 2);
    }
    variance = variance / _recentMagnitudes.length;
    
    // Determine movement state based on patterns
    final state = _determineMovementState(avgMagnitude, variance);
    final confidence = _calculateConfidence(avgMagnitude, variance, state);
    
    // Update current state
    _ref.read(currentMovementStateProvider.notifier).state = state;
    
    // Create movement data entry
    final movementData = MovementData(
      timestamp: DateTime.now(),
      x: _recentGyroData.isNotEmpty ? _recentGyroData.last.x : 0,
      y: _recentGyroData.isNotEmpty ? _recentGyroData.last.y : 0,
      z: _recentGyroData.isNotEmpty ? _recentGyroData.last.z : 0,
      magnitude: avgMagnitude,
      state: state,
      confidence: confidence,
    );
    
    // Add to history
    final history = _ref.read(movementHistoryProvider);
    final updatedHistory = [...history, movementData];
    
    // Keep only recent history (last hour)
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final recentHistory = updatedHistory.where((data) => data.timestamp.isAfter(cutoff)).toList();
    
    _ref.read(movementHistoryProvider.notifier).state = recentHistory;
    
    // State: $state, Confidence: ${confidence.toStringAsFixed(2)}
  }
  
  // Determine movement state from sensor data
  MovementState _determineMovementState(double avgMagnitude, double variance) {
    // Enhanced detection with both accelerometer and gyroscope data
    
    // Check for driving (consistent acceleration, low variance in pattern)
    if (avgMagnitude > _drivingThreshold) {
      // Additional check for vehicle movement patterns
      if (variance < 2.0 || (_recentAccelData.isNotEmpty && _hasVehiclePattern())) {
        return MovementState.driving;
      }
    }
    
    // Check for running (high magnitude with rhythmic pattern)
    if (avgMagnitude > _runningThreshold) {
      // Running has higher variance due to impact patterns
      if (variance > 0.5) {
        return MovementState.running;
      }
    }
    
    // Check for walking (moderate magnitude with regular pattern)
    if (avgMagnitude > _walkingThreshold) {
      // Walking has characteristic step patterns
      if (_hasWalkingPattern()) {
        return MovementState.walking;
      }
    }
    
    // Check for still (very low magnitude and variance)
    if (avgMagnitude <= _stillThreshold && variance < 0.05) {
      return MovementState.still;
    }
    
    // If between thresholds, make educated guess based on patterns
    if (avgMagnitude > _stillThreshold && avgMagnitude <= _walkingThreshold) {
      // Likely slow walking or shuffling
      return MovementState.walking;
    }
    
    return MovementState.unknown;
  }
  
  // Check for walking pattern in accelerometer data
  bool _hasWalkingPattern() {
    if (_recentAccelData.length < 10) return false;
    
    // Walking typically has regular peaks in acceleration
    double avgY = 0;
    for (final event in _recentAccelData) {
      avgY += event.y.abs();
    }
    avgY /= _recentAccelData.length;
    
    // Walking typically shows 0.5-2.0 m/s² variation in Y axis
    return avgY > 0.2 && avgY < 2.0;
  }
  
  // Check for vehicle movement pattern
  bool _hasVehiclePattern() {
    if (_recentAccelData.length < 10) return false;
    
    // Vehicle movement has smoother acceleration changes
    double totalChange = 0;
    for (int i = 1; i < _recentAccelData.length; i++) {
      final prev = _recentAccelData[i - 1];
      final curr = _recentAccelData[i];
      totalChange += (curr.x - prev.x).abs() + (curr.y - prev.y).abs() + (curr.z - prev.z).abs();
    }
    
    // Vehicle has smoother changes
    return totalChange / _recentAccelData.length < 0.5;
  }
  
  // Calculate confidence in movement detection
  double _calculateConfidence(double avgMagnitude, double variance, MovementState state) {
    double confidence = 0.5; // Base confidence
    
    // Factor in data availability
    if (_recentMagnitudes.length < _windowSize / 2) {
      confidence *= 0.7; // Lower confidence with less data
    }
    
    switch (state) {
      case MovementState.still:
        // Very high confidence when both magnitude and variance are very low
        if (avgMagnitude < _stillThreshold && variance < 0.05) {
          confidence = 0.95;
        } else {
          confidence = 1.0 - (avgMagnitude / (_stillThreshold * 2)).clamp(0.0, 1.0);
        }
        break;
        
      case MovementState.walking:
        // Check pattern matching and magnitude range
        if (_hasWalkingPattern()) {
          confidence = 0.85;
          // Boost confidence if in ideal walking range
          if (avgMagnitude > _walkingThreshold && avgMagnitude < _runningThreshold) {
            confidence = 0.9;
          }
        } else if (avgMagnitude > _walkingThreshold && avgMagnitude < _runningThreshold) {
          confidence = 0.7;
        }
        break;
        
      case MovementState.running:
        // Running has distinctive high magnitude and variance
        if (avgMagnitude > _runningThreshold && avgMagnitude < _drivingThreshold) {
          confidence = 0.8;
          if (variance > 0.5 && variance < 3.0) {
            confidence = 0.9;
          }
        }
        break;
        
      case MovementState.driving:
        // Vehicle movement has smooth patterns
        if (_hasVehiclePattern() && avgMagnitude > _drivingThreshold) {
          confidence = 0.95;
        } else if (avgMagnitude > _drivingThreshold) {
          confidence = 0.75;
        }
        break;
        
      case MovementState.unknown:
        // Low confidence when we can't determine state
        confidence = 0.2;
        break;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  // Persist movement data to database
  Future<void> _persistMovementData() async {
    final history = _ref.read(movementHistoryProvider);
    if (history.isEmpty) return;
    
    try {
      // Calculate summary statistics for the period
      final states = <MovementState, int>{};
      double totalMagnitude = 0;
      
      for (final data in history) {
        states[data.state] = (states[data.state] ?? 0) + 1;
        totalMagnitude += data.magnitude;
      }
      
      // Find dominant state
      MovementState dominantState = MovementState.unknown;
      int maxCount = 0;
      states.forEach((state, count) {
        if (count > maxCount) {
          maxCount = count;
          dominantState = state;
        }
      });
      
      final avgMagnitude = totalMagnitude / history.length;
      
      // Store in database
      await _database.into(_database.movementData).insert(
        MovementDataCompanion.insert(
          timestamp: DateTime.now(),
          state: dominantState.toString(),
          averageMagnitude: avgMagnitude,
          sampleCount: history.length,
          stillPercentage: (states[MovementState.still] ?? 0) / history.length,
          walkingPercentage: (states[MovementState.walking] ?? 0) / history.length,
          runningPercentage: (states[MovementState.running] ?? 0) / history.length,
          drivingPercentage: (states[MovementState.driving] ?? 0) / history.length,
        ),
      );
      
      // Persisted movement data to database
    } catch (e) {
      // Error persisting data: $e
    }
  }
  
  // Get movement summary for a time period
  Future<Map<String, dynamic>> getMovementSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 1));
    final end = endDate ?? DateTime.now();
    
    final query = _database.select(_database.movementData)
      ..where((tbl) => tbl.timestamp.isBetweenValues(start, end));
    
    final data = await query.get();
    
    if (data.isEmpty) {
      return {
        'totalSamples': 0,
        'averageActivity': 0.0,
        'stillTime': 0.0,
        'activeTime': 0.0,
        'dominantState': MovementState.unknown.toString(),
      };
    }
    
    // Calculate summary statistics
    double totalStill = 0;
    double totalWalking = 0;
    double totalRunning = 0;
    double totalDriving = 0;
    double totalMagnitude = 0;
    
    for (final entry in data) {
      totalStill += entry.stillPercentage;
      totalWalking += entry.walkingPercentage;
      totalRunning += entry.runningPercentage;
      totalDriving += entry.drivingPercentage;
      totalMagnitude += entry.averageMagnitude;
    }
    
    final count = data.length;
    
    return {
      'totalSamples': data.fold(0, (sum, e) => sum + e.sampleCount),
      'averageActivity': totalMagnitude / count,
      'stillTime': totalStill / count,
      'activeTime': (totalWalking + totalRunning + totalDriving) / count,
      'walkingTime': totalWalking / count,
      'runningTime': totalRunning / count,
      'drivingTime': totalDriving / count,
      'dominantState': _getDominantState(totalStill, totalWalking, totalRunning, totalDriving),
    };
  }
  
  String _getDominantState(double still, double walking, double running, double driving) {
    final max = [still, walking, running, driving].reduce((a, b) => a > b ? a : b);
    if (max == still) return MovementState.still.toString();
    if (max == walking) return MovementState.walking.toString();
    if (max == running) return MovementState.running.toString();
    if (max == driving) return MovementState.driving.toString();
    return MovementState.unknown.toString();
  }
  
  // Clear all movement data
  Future<void> clearMovementData() async {
    await _database.delete(_database.movementData).go();
    _ref.read(movementHistoryProvider.notifier).state = [];
    // Cleared all movement data
  }
  
  // Export movement data
  Future<Map<String, dynamic>> exportMovementData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();
    
    final query = _database.select(_database.movementData)
      ..where((tbl) => tbl.timestamp.isBetweenValues(start, end))
      ..orderBy([(tbl) => drift.OrderingTerm.asc(tbl.timestamp)]);
    
    final data = await query.get();
    
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
      'dataPoints': data.map((e) => {
        'timestamp': e.timestamp.toIso8601String(),
        'state': e.state,
        'averageMagnitude': e.averageMagnitude,
        'sampleCount': e.sampleCount,
        'stillPercentage': e.stillPercentage,
        'walkingPercentage': e.walkingPercentage,
        'runningPercentage': e.runningPercentage,
        'drivingPercentage': e.drivingPercentage,
      }).toList(),
    };
  }
}