import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'optimization_manager.dart';
import 'privacy_manager.dart';
import 'spatiotemporal_processor.dart';
import 'visual_context_processor.dart';
import 'multimodal_fusion_processor.dart';
import 'summary_generator.dart';

// AI Service Configuration
class AIServiceConfig {
  final bool enableHardwareAcceleration;
  final bool enableDifferentialPrivacy;
  final double privacyEpsilon;
  final int maxMemoryMB;
  final BatteryOptimizationLevel batteryOptimization;
  final int inferenceThreads;

  const AIServiceConfig({
    this.enableHardwareAcceleration = true,
    this.enableDifferentialPrivacy = false,
    this.privacyEpsilon = 1.0,
    this.inferenceThreads = 2,
    this.maxMemoryMB = 512,
    this.batteryOptimization = BatteryOptimizationLevel.adaptive,
  });
}

enum BatteryOptimizationLevel {
  full,      // 100-80% battery
  medium,    // 80-50% battery
  minimal,   // <50% battery
  adaptive,  // Auto-adjust based on battery level
}

// Base class for pipeline stages
abstract class PipelineStage {
  Future<void> initialize();
  Future<void> dispose();
  bool get isInitialized;
}

// Main AI Service orchestrating the 4-stage pipeline
class AIService {
  final AIServiceConfig config;
  final SpatiotemporalProcessor spatiotemporalProcessor;
  final VisualContextProcessor visualContextProcessor;
  final MultimodalFusionProcessor multimodalFusionProcessor;
  final SummaryGenerator summaryGenerator;
  
  // Optimization and privacy managers
  late final OptimizationManager _optimizationManager;
  late final PrivacyManager _privacyManager;

  bool _isInitialized = false;
  Isolate? _inferenceIsolate;

  AIService({
    required this.config,
    required this.spatiotemporalProcessor,
    required this.visualContextProcessor,
    required this.multimodalFusionProcessor,
    required this.summaryGenerator,
  });

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize optimization and privacy managers
    _optimizationManager = OptimizationManager.instance;
    _privacyManager = PrivacyManager.instance;
    
    await _optimizationManager.initialize();
    
    // Configure privacy based on config
    _privacyManager.configure(
      privacyEpsilon: config.privacyEpsilon,
      enableDifferentialPrivacy: config.enableDifferentialPrivacy,
    );
    
    // Permissions are handled at app level

    // Initialize all pipeline stages with optimization support
    await spatiotemporalProcessor.initialize();
    await visualContextProcessor.initialize();
    await multimodalFusionProcessor.initialize();
    await summaryGenerator.initialize();

    // Set up inference isolate for background processing
    await _setupInferenceIsolate();

    _isInitialized = true;
    debugPrint('AIService initialized with optimizations');
  }

  Future<void> _setupInferenceIsolate() async {
    // Create isolate for running AI inference without blocking UI
    final receivePort = ReceivePort();
    _inferenceIsolate = await Isolate.spawn(
      _inferenceIsolateEntryPoint,
      receivePort.sendPort,
    );
  }

  static void _inferenceIsolateEntryPoint(SendPort sendPort) {
    // Isolate entry point for background AI processing
    // Receives inference requests and sends back results
  }

  Future<DailySummary> generateDailySummary(DateTime date) async {
    if (!_isInitialized) {
      throw StateError('AIService not initialized');
    }
    
    // Check battery and memory conditions
    final quality = _optimizationManager.getRecommendedQuality();
    debugPrint('Processing with quality level: $quality');
    
    if (_optimizationManager.isUnderMemoryPressure) {
      debugPrint('WARNING: Memory pressure detected - using minimal processing');
    }

    try {
      // Stage 1: Spatiotemporal Analysis with privacy
      final spatiotemporalData = await spatiotemporalProcessor.process(date);
      
      // Privacy features can be implemented here if needed

      // Stage 2: Visual Context Extraction
      final visualContextData = await visualContextProcessor.process(
        date,
        spatiotemporalData.events,
      );

      // Create a compatible VisualContext object for the fusion processor
      // This is a temporary adapter until we unify the types
      final visualContext = _createVisualContextAdapter(visualContextData);

      // Stage 3&4: Multimodal Fusion and Narrative Generation
      final fusedData = await multimodalFusionProcessor.process([
        spatiotemporalData,
        visualContext,
      ]);

      final summary = await summaryGenerator.process(fusedData);

      return summary as DailySummary;
    } catch (e) {
      // Progressive fallback strategy
      return _generateFallbackSummary(date, e);
    }
  }

  // Adapter to convert VisualContextData to the format expected by fusion processor
  dynamic _createVisualContextAdapter(dynamic visualContextData) {
    // Create an anonymous object with the properties expected by the fusion processor
    return _VisualContextAdapter(
      descriptions: <String>[],
      objects: <String>[],
      scenes: <String>[],
      totalPhotoCount: (visualContextData as VisualContextData?)?.photoCount ?? 0,
    );
  }

  Future<DailySummary> _generateFallbackSummary(DateTime date, dynamic error) async {
    // Implement progressive degradation:
    // 1. Try reduced model complexity
    // 2. Try template-based generation
    // 3. Fall back to simple activity logging

    debugPrint('AI generation failed, using fallback: $error');

    return DailySummary(
      date: date,
      content: 'Summary generation temporarily unavailable.',
      generationType: GenerationType.fallback,
    );
  }

  Future<void> dispose() async {
    _inferenceIsolate?.kill(priority: Isolate.immediate);
    spatiotemporalProcessor.dispose();
    visualContextProcessor.dispose();
    multimodalFusionProcessor.dispose();
    summaryGenerator.dispose();
    _isInitialized = false;
  }
}

// Data models for the pipeline
class DailySummary {
  final DateTime date;
  final String content;
  final GenerationType generationType;
  final Map<String, dynamic>? metadata;

  DailySummary({
    required this.date,
    required this.content,
    required this.generationType,
    this.metadata,
  });
}

enum GenerationType {
  full,      // Full AI pipeline
  reduced,   // Reduced model complexity
  template,  // Template-based
  simple,    // Simple activity list
  fallback,  // Error fallback
}

// Model File Manager for downloading large models
class ModelFileManager {
  static const String gemmaModelUrl = 'https://example.com/gemma-3-nano.tflite'; // Placeholder
  static const int gemmaModelSizeMB = 2000; // ~2GB

  final String modelsDirectory;

  ModelFileManager(this.modelsDirectory);

  Future<bool> isGemmaModelDownloaded() async {
    final modelFile = File(path.join(modelsDirectory, 'gemma-3-nano.tflite'));
    return modelFile.existsSync();
  }

  Stream<double> downloadGemmaModel() async* {
    // Implement download with progress tracking
    // This is a placeholder - actual implementation would use dio or similar

    yield 0.0;

    // Simulate download progress
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 100));
      yield i / 100.0;
    }
  }

  Future<void> verifyModelIntegrity(String modelPath) async {
    // Verify downloaded model checksum/integrity
  }

  Future<String> getModelPath(String modelName) async {
    return path.join(modelsDirectory, modelName);
  }
}

// License Manager for Gemma Terms of Use
class GemmaLicenseManager {
  static const String gemmaTermsUrl = 'https://ai.google.dev/gemma/terms';

  Future<bool> hasAcceptedTerms() async {
    // Check if user has accepted Gemma Terms of Use
    // Store acceptance in secure storage
    return false;
  }

  Future<void> recordTermsAcceptance() async {
    // Record user's acceptance of terms
  }

  String getTermsText() {
    return '''
Gemma Terms of Use

By using Gemma models, you agree to:
1. Use restrictions as specified in the Gemma Terms of Use
2. Not claim rights on generated content
3. Include appropriate disclaimers in your app

Full terms: $gemmaTermsUrl
''';
  }
}

// Provider for AI Service
final aiServiceConfigProvider = Provider<AIServiceConfig>((ref) {
  return const AIServiceConfig(
    enableHardwareAcceleration: true,
    enableDifferentialPrivacy: false,
    batteryOptimization: BatteryOptimizationLevel.adaptive,
  );
});

final aiServiceProvider = Provider<AIService>((ref) {
  final config = ref.watch(aiServiceConfigProvider);

  return AIService(
    config: config,
    spatiotemporalProcessor: SpatiotemporalProcessor(config),
    visualContextProcessor: VisualContextProcessor(config),
    multimodalFusionProcessor: MultimodalFusionProcessor(config),
    summaryGenerator: SummaryGenerator(config),
  );
});

// Adapter class for VisualContext compatibility
class _VisualContextAdapter {
  final List<String> descriptions;
  final List<String> objects;
  final List<String> scenes;
  final int totalPhotoCount;

  _VisualContextAdapter({
    required this.descriptions,
    required this.objects,
    required this.scenes,
    required this.totalPhotoCount,
  });
}

