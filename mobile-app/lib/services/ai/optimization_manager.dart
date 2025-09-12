import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'ai_service.dart';

/// Optimization Manager for AI Pipeline
/// Handles hardware acceleration, battery optimization, and performance monitoring
class OptimizationManager {
  static OptimizationManager? _instance;
  
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Device capabilities
  DeviceTier _deviceTier = DeviceTier.unknown;
  bool _hasNeuralEngine = false;
  bool _hasGPU = false;
  int _availableMemoryMB = 0;
  
  // Battery state
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  StreamSubscription<int>? _batteryLevelSubscription;
  
  // Performance metrics
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  
  // Memory pressure handling
  bool _isUnderMemoryPressure = false;
  Timer? _memoryMonitorTimer;
  
  OptimizationManager._();
  
  static OptimizationManager get instance {
    _instance ??= OptimizationManager._();
    return _instance!;
  }
  
  /// Initialize optimization manager
  Future<void> initialize() async {
    await _detectDeviceCapabilities();
    await _setupBatteryMonitoring();
    _startMemoryMonitoring();
    _performanceMonitor.startMonitoring();
    
    debugPrint('OptimizationManager initialized');
    debugPrint('Device Tier: $_deviceTier');
    debugPrint('Neural Engine: $_hasNeuralEngine');
    debugPrint('GPU Available: $_hasGPU');
    debugPrint('Available Memory: ${_availableMemoryMB}MB');
  }
  
  /// Detect device capabilities for optimal model configuration
  Future<void> _detectDeviceCapabilities() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        
        // Estimate device tier based on Android version and RAM
        final sdkInt = androidInfo.version.sdkInt;
        final totalMemory = androidInfo.systemFeatures.contains('android.software.leanback')
            ? 2048 : 4096; // Rough estimate
        
        if (sdkInt >= 31 && totalMemory >= 6144) {
          _deviceTier = DeviceTier.flagship;
          _hasNeuralEngine = androidInfo.systemFeatures.contains('android.hardware.neuralnetworks.api');
        } else if (sdkInt >= 29 && totalMemory >= 4096) {
          _deviceTier = DeviceTier.midRange;
        } else {
          _deviceTier = DeviceTier.budget;
        }
        
        _hasGPU = androidInfo.systemFeatures.contains('android.hardware.vulkan.compute');
        _availableMemoryMB = totalMemory;
        
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        
        // Detect device tier based on model
        final model = iosInfo.model ?? '';
        if (model.contains('iPhone 14') || model.contains('iPhone 15') ||
            model.contains('iPad Pro')) {
          _deviceTier = DeviceTier.flagship;
          _hasNeuralEngine = true; // A14+ Bionic chips
        } else if (model.contains('iPhone 12') || model.contains('iPhone 13')) {
          _deviceTier = DeviceTier.midRange;
          _hasNeuralEngine = true;
        } else {
          _deviceTier = DeviceTier.budget;
        }
        
        _hasGPU = true; // All iOS devices have Metal
        _availableMemoryMB = 4096; // Conservative estimate
      }
    } catch (e) {
      debugPrint('Error detecting device capabilities: $e');
      _deviceTier = DeviceTier.budget; // Conservative fallback
    }
  }
  
  /// Set up battery monitoring for adaptive processing
  Future<void> _setupBatteryMonitoring() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _batteryState = await _battery.batteryState;
      
      _batteryLevelSubscription = _battery.onBatteryLevelChanged.listen((level) {
        _batteryLevel = level;
        debugPrint('Battery level: $level%');
      });
      
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
        _batteryState = state;
        debugPrint('Battery state: $state');
      });
    } catch (e) {
      debugPrint('Battery monitoring setup failed: $e');
    }
  }
  
  /// Start monitoring memory pressure
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkMemoryPressure();
    });
  }
  
  /// Check current memory pressure
  void _checkMemoryPressure() {
    // This is a simplified check - in production, use platform channels
    // to access native memory APIs
    final rss = ProcessInfo.currentRss;
    final maxRss = ProcessInfo.maxRss;
    
    if (maxRss > 0) {
      final memoryUsagePercent = (rss / maxRss) * 100;
      _isUnderMemoryPressure = memoryUsagePercent > 85;
      
      if (_isUnderMemoryPressure) {
        debugPrint('WARNING: High memory pressure detected (${memoryUsagePercent.toStringAsFixed(1)}%)');
      }
    }
  }
  
  /// Get optimal TFLite delegate based on device capabilities
  Delegate? getOptimalDelegate() {
    if (_deviceTier == DeviceTier.budget || _isUnderMemoryPressure) {
      return null; // Use CPU only
    }
    
    try {
      if (Platform.isAndroid) {
        if (_hasNeuralEngine) {
          // Use NNAPI for Neural Engine acceleration
          return NnApiDelegate();
        } else if (_hasGPU) {
          // Use GPU delegate
          return GpuDelegateV2(
            options: GpuDelegateOptionsV2(
              isPrecisionLossAllowed: true,
              inferencePreference: TfLiteGpuInferenceUsage.sustainedSpeed,
              inferencePriority1: TfLiteGpuInferencePriority.minLatency,
              inferencePriority2: TfLiteGpuInferencePriority.minMemoryUsage,
              inferencePriority3: TfLiteGpuInferencePriority.maxPrecision,
            ),
          );
        }
      } else if (Platform.isIOS) {
        if (_hasNeuralEngine) {
          // Use Core ML delegate for Neural Engine
          return CoreMlDelegate(
            options: CoreMlDelegateOptions(
              enabledDevices: CoreMlDelegateEnabledDevices.neuralEngine,
              coremlVersion: 3,
            ),
          );
        } else if (_hasGPU) {
          // Use Metal delegate
          return MetalDelegate(
            options: MetalDelegateOptions(
              isPrecisionLossAllowed: true,
              waitType: TFLMetalDelegateWaitType.passive,
              enableQuantization: true,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to create hardware delegate: $e');
    }
    
    return null; // Fallback to CPU
  }
  
  /// Get current battery optimization level
  BatteryOptimizationLevel getBatteryOptimizationLevel() {
    if (_batteryState == BatteryState.charging ||
        _batteryState == BatteryState.full) {
      return BatteryOptimizationLevel.full;
    }
    
    if (_batteryLevel >= 80) {
      return BatteryOptimizationLevel.full;
    } else if (_batteryLevel >= 50) {
      return BatteryOptimizationLevel.medium;
    } else {
      return BatteryOptimizationLevel.minimal;
    }
  }
  
  /// Get recommended processing quality based on current state
  ProcessingQuality getRecommendedQuality() {
    final batteryLevel = getBatteryOptimizationLevel();
    
    if (_isUnderMemoryPressure) {
      return ProcessingQuality.minimal;
    }
    
    if (_deviceTier == DeviceTier.budget) {
      return batteryLevel == BatteryOptimizationLevel.full
          ? ProcessingQuality.medium
          : ProcessingQuality.minimal;
    }
    
    if (_deviceTier == DeviceTier.midRange) {
      return switch (batteryLevel) {
        BatteryOptimizationLevel.full => ProcessingQuality.high,
        BatteryOptimizationLevel.medium => ProcessingQuality.medium,
        BatteryOptimizationLevel.minimal => ProcessingQuality.minimal,
        _ => ProcessingQuality.medium,
      };
    }
    
    // Flagship devices
    return switch (batteryLevel) {
      BatteryOptimizationLevel.full => ProcessingQuality.maximum,
      BatteryOptimizationLevel.medium => ProcessingQuality.high,
      BatteryOptimizationLevel.minimal => ProcessingQuality.medium,
      _ => ProcessingQuality.high,
    };
  }
  
  /// Request necessary permissions for AI features
  Future<PermissionStatus> requestPermissions() async {
    final permissions = <Permission>[
      Permission.location,
      Permission.locationAlways,
      Permission.activityRecognition,
      Permission.sensors,
      Permission.photos,
      Permission.camera,
    ];
    
    final statuses = await permissions.request();
    
    // Check if all critical permissions are granted
    final locationStatus = statuses[Permission.locationAlways] ?? 
                          statuses[Permission.location] ?? 
                          PermissionStatus.denied;
    
    if (locationStatus != PermissionStatus.granted) {
      debugPrint('Location permission not granted');
      return locationStatus;
    }
    
    final activityStatus = statuses[Permission.activityRecognition] ?? 
                          PermissionStatus.denied;
    
    if (activityStatus != PermissionStatus.granted) {
      debugPrint('Activity recognition permission not granted');
      return activityStatus;
    }
    
    return PermissionStatus.granted;
  }
  
  /// Get performance metrics
  PerformanceMetrics getPerformanceMetrics() {
    return _performanceMonitor.getMetrics();
  }
  
  /// Clean up resources
  void dispose() {
    _batteryLevelSubscription?.cancel();
    _batteryStateSubscription?.cancel();
    _memoryMonitorTimer?.cancel();
    _performanceMonitor.stopMonitoring();
  }
  
  DeviceTier get deviceTier => _deviceTier;
  bool get hasNeuralEngine => _hasNeuralEngine;
  bool get hasGPU => _hasGPU;
  bool get isUnderMemoryPressure => _isUnderMemoryPressure;
  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
}

/// Performance monitoring for AI pipeline
class PerformanceMonitor {
  final Map<String, List<int>> _inferenceTimesMs = {};
  final Map<String, int> _inferenceCount = {};
  final Map<String, int> _errorCount = {};
  
  DateTime? _sessionStartTime;
  int _totalInferences = 0;
  
  void startMonitoring() {
    _sessionStartTime = DateTime.now();
    debugPrint('Performance monitoring started');
  }
  
  void recordInference(String modelName, int durationMs) {
    _inferenceTimesMs.putIfAbsent(modelName, () => []).add(durationMs);
    _inferenceCount[modelName] = (_inferenceCount[modelName] ?? 0) + 1;
    _totalInferences++;
    
    // Keep only last 100 measurements per model
    if (_inferenceTimesMs[modelName]!.length > 100) {
      _inferenceTimesMs[modelName]!.removeAt(0);
    }
  }
  
  void recordError(String modelName) {
    _errorCount[modelName] = (_errorCount[modelName] ?? 0) + 1;
  }
  
  PerformanceMetrics getMetrics() {
    final metrics = <String, ModelMetrics>{};
    
    for (final modelName in _inferenceTimesMs.keys) {
      final times = _inferenceTimesMs[modelName] ?? [];
      if (times.isEmpty) continue;
      
      final sorted = List<int>.from(times)..sort();
      final avg = times.reduce((a, b) => a + b) / times.length;
      final p50 = sorted[sorted.length ~/ 2];
      final p95 = sorted[(sorted.length * 0.95).floor()];
      final p99 = sorted[(sorted.length * 0.99).floor()];
      
      metrics[modelName] = ModelMetrics(
        averageMs: avg,
        p50Ms: p50,
        p95Ms: p95,
        p99Ms: p99,
        totalInferences: _inferenceCount[modelName] ?? 0,
        errorCount: _errorCount[modelName] ?? 0,
      );
    }
    
    return PerformanceMetrics(
      sessionDuration: _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!)
          : Duration.zero,
      totalInferences: _totalInferences,
      modelMetrics: metrics,
    );
  }
  
  void stopMonitoring() {
    debugPrint('Performance monitoring stopped');
    final metrics = getMetrics();
    debugPrint('Total inferences: ${metrics.totalInferences}');
    debugPrint('Session duration: ${metrics.sessionDuration}');
  }
}

// Enums and data classes

enum DeviceTier {
  flagship,  // Latest high-end devices
  midRange,  // Mid-tier devices
  budget,    // Budget devices
  unknown,   // Unknown tier
}

enum ProcessingQuality {
  maximum,   // Full quality, all features
  high,      // High quality, most features
  medium,    // Balanced quality
  minimal,   // Minimal processing
}

class PerformanceMetrics {
  final Duration sessionDuration;
  final int totalInferences;
  final Map<String, ModelMetrics> modelMetrics;
  
  PerformanceMetrics({
    required this.sessionDuration,
    required this.totalInferences,
    required this.modelMetrics,
  });
}

class ModelMetrics {
  final double averageMs;
  final int p50Ms;
  final int p95Ms;
  final int p99Ms;
  final int totalInferences;
  final int errorCount;
  
  ModelMetrics({
    required this.averageMs,
    required this.p50Ms,
    required this.p95Ms,
    required this.p99Ms,
    required this.totalInferences,
    required this.errorCount,
  });
  
  double get errorRate => totalInferences > 0 
      ? errorCount / totalInferences 
      : 0.0;
}