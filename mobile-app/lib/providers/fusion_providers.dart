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
  final Ref _ref;

  FusionEngineController(this._ref);

  bool get isRunning => _ref.read(fusionEngineRunningProvider);

  Future<void> toggle() async {
    final currentState = _ref.read(fusionEngineRunningProvider);
    _ref.read(fusionEngineRunningProvider.notifier).state = !currentState;
  }

  Future<void> start() async {
    _ref.read(fusionEngineRunningProvider.notifier).state = true;
  }

  Future<void> stop() async {
    _ref.read(fusionEngineRunningProvider.notifier).state = false;
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
  return FusionEngineController(ref);
});