import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/data_fusion/multi_modal_fusion_engine.dart';
import '../services/location_service.dart';
import '../services/photo_service.dart';
import '../services/database_service.dart';
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

/// Provider for fusion engine running state
final fusionEngineRunningProvider = StateProvider<bool>((ref) => false);

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
      _ref.read(fusionEngineRunningProvider.notifier).state = true;
    }
  }

  /// Stop the fusion engine
  void stop() {
    final engine = _ref.read(fusionEngineProvider);
    final isRunning = _ref.read(fusionEngineRunningProvider);

    if (isRunning) {
      engine.stop();
      _ref.read(fusionEngineRunningProvider.notifier).state = false;
    }
  }

  /// Toggle fusion engine state
  Future<void> toggle() async {
    final isRunning = _ref.read(fusionEngineRunningProvider);
    if (isRunning) {
      stop();
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