// Stub implementation for APK size optimization
// Original fusion providers temporarily disabled to reduce APK size

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stub Multi-Modal Fusion Engine
class MultiModalFusionEngine {
  Future<Map<String, dynamic>> analyzePeriod(
    DateTime start,
    DateTime end,
  ) async {
    return {
      'summary': 'Fusion analysis temporarily disabled for optimized build',
      'disabled': true,
    };
  }
}

// Stub Fusion Engine Controller
class FusionEngineController {
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<void> toggle() async {
    _isRunning = !_isRunning;
  }

  Future<void> start() async {
    _isRunning = true;
  }

  Future<void> stop() async {
    _isRunning = false;
  }
}

// Provider for fusion engine
final fusionEngineProvider = Provider<MultiModalFusionEngine>((ref) {
  return MultiModalFusionEngine();
});

// Provider for fusion engine running state
final fusionEngineRunningProvider = StateProvider<bool>((ref) {
  return false; // Disabled by default in optimized build
});

// Provider for fusion engine controller
final fusionEngineControllerProvider = Provider<FusionEngineController>((ref) {
  return FusionEngineController();
});