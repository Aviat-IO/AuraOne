import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_fusion/multi_modal_fusion_engine.dart';
import '../services/ai/advanced_photo_analyzer.dart';
import 'location_providers.dart';
import 'photo_providers.dart';
import 'database_provider.dart';

/// Provider for the photo analyzer
final photoAnalyzerProvider = Provider<AdvancedPhotoAnalyzer>((ref) {
  return AdvancedPhotoAnalyzer();
});

/// Provider for the multi-modal fusion engine
final fusionEngineProvider = Provider<MultiModalFusionEngine>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  final photoService = ref.watch(photoServiceProvider);
  final databaseService = ref.watch(databaseServiceProvider);
  final photoAnalyzer = ref.watch(photoAnalyzerProvider);

  return MultiModalFusionEngine(
    locationService: locationService,
    photoService: photoService,
    databaseService: databaseService,
    photoAnalyzer: photoAnalyzer,
  );
});

/// Provider for fusion engine running state with persistence
final fusionEngineRunningProvider = StateNotifierProvider<FusionEngineStateNotifier, bool>((ref) {
  return FusionEngineStateNotifier(ref);
});

class FusionEngineStateNotifier extends StateNotifier<bool> {
  final Ref _ref;

  FusionEngineStateNotifier(this._ref) : super(true) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('fusion_engine_enabled') ?? true;
    state = isEnabled;

    // Auto-start if enabled
    if (isEnabled) {
      final controller = _ref.read(fusionEngineControllerProvider);
      await controller.start();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fusion_engine_enabled', enabled);
  }
}

/// Provider to start/stop fusion engine based on settings
final fusionEngineControllerProvider = Provider<FusionEngineController>((ref) {
  return FusionEngineController(ref);
});

/// Controller for managing fusion engine lifecycle
class FusionEngineController {
  final Ref _ref;

  FusionEngineController(this._ref);

  /// Start the fusion engine
  Future<void> start() async {
    final engine = _ref.read(fusionEngineProvider);
    final isRunning = _ref.read(fusionEngineRunningProvider);

    if (!isRunning) {
      await engine.start();
      await _ref.read(fusionEngineRunningProvider.notifier).setEnabled(true);
    }
  }

  /// Stop the fusion engine
  Future<void> stop() async {
    final engine = _ref.read(fusionEngineProvider);
    final isRunning = _ref.read(fusionEngineRunningProvider);

    if (isRunning) {
      engine.stop();
      await _ref.read(fusionEngineRunningProvider.notifier).setEnabled(false);
    }
  }

  /// Toggle fusion engine state
  Future<void> toggle() async {
    final isRunning = _ref.read(fusionEngineRunningProvider);
    if (isRunning) {
      await stop();
    } else {
      await start();
    }
  }
}

/// Provider for recent fused data
final recentFusedDataProvider = FutureProvider.autoDispose<List<FusedDataPoint>>((ref) async {
  final engine = ref.watch(fusionEngineProvider);
  return engine.getRecentFusedData();
});

/// Provider for generating narrative from fused data
final fusedNarrativeProvider = FutureProvider.autoDispose<String>((ref) async {
  final engine = ref.watch(fusionEngineProvider);
  return engine.generateNarrative();
});