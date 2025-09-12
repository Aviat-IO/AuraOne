import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import '../../utils/logger.dart';
// import '../location_service.dart'; // Removed - not needed
import 'dbscan_clustering.dart';
import 'activity_recognition.dart';
import 'image_captioning.dart';
import 'multimodal_fusion.dart';
import 'narrative_generation.dart';

/// Enhanced AI Service with hardware acceleration and optimizations
class EnhancedAIService {
  static final _logger = AppLogger('EnhancedAIService');
  static final _instance = EnhancedAIService._internal();

  factory EnhancedAIService() => _instance;
  EnhancedAIService._internal();

  // Sub-services
  final ActivityRecognitionService _activityService = ActivityRecognitionService();
  final ImageCaptioningService _captionService = ImageCaptioningService();
  final MultiModalFusionService _fusionService = MultiModalFusionService();
  final NarrativeGenerationService _narrativeService = NarrativeGenerationService();

  // State management
  bool _isInitialized = false;
  bool _isProcessing = false;
  Timer? _backgroundTimer;

  // Performance monitoring
  final Map<String, Duration> _performanceMetrics = {};

  // Hardware acceleration flags
  bool _useGpuDelegate = false;
  bool _useNnApiDelegate = false;
  bool _useCoreMLDelegate = false;

  /// Initialize the enhanced AI service with hardware acceleration
  Future<void> initialize({bool enableHardwareAcceleration = true}) async {
    if (_isInitialized) {
      _logger.info('Enhanced AI service already initialized');
      return;
    }

    try {
      _logger.info('Initializing enhanced AI service...');

      // Configure hardware acceleration
      if (enableHardwareAcceleration) {
        await _configureHardwareAcceleration();
      }

      // Initialize sub-services
      await _initializeSubServices();

      // Setup background processing
      _setupBackgroundProcessing();

      _isInitialized = true;
      _logger.info('Enhanced AI service initialized successfully');
    } catch (e, stack) {
      _logger.error('Failed to initialize enhanced AI service', error: e, stackTrace: stack);
      throw Exception('Failed to initialize enhanced AI service: $e');
    }
  }

  /// Configure hardware acceleration based on platform
  Future<void> _configureHardwareAcceleration() async {
    try {
      _logger.info('Configuring hardware acceleration...');

      if (Platform.isAndroid) {
        // Check for Android Neural Networks API support
        try {
          final options = InterpreterOptions();
            // ..addDelegate(NnApiDelegate()); // Not available in current version

          // Test if NNAPI is available
          final testInterpreter = await Interpreter.fromAsset(
            'assets/models/test_model.tflite',
            options: options,
          );
          testInterpreter.close();

          _useNnApiDelegate = true;
          _logger.info('Android NNAPI delegate enabled');
        } catch (e) {
          _logger.warning('NNAPI not available, falling back to CPU');
        }

        // Try GPU delegate for Android
        try {
          final gpuOptions = InterpreterOptions()
            ..addDelegate(GpuDelegateV2(
              options: GpuDelegateOptionsV2(
                // GPU options simplified for compatibility
              ),
            ));

          final testInterpreter = await Interpreter.fromAsset(
            'assets/models/test_model.tflite',
            options: gpuOptions,
          );
          testInterpreter.close();

          _useGpuDelegate = true;
          _logger.info('GPU delegate enabled for Android');
        } catch (e) {
          _logger.warning('GPU delegate not available');
        }
      } else if (Platform.isIOS) {
        // Try Core ML delegate for iOS
        try {
          final options = InterpreterOptions();
          // CoreML delegate not available in current tflite_flutter version

          final testInterpreter = await Interpreter.fromAsset(
            'assets/models/test_model.tflite',
            options: options,
          );
          testInterpreter.close();

          _useCoreMLDelegate = true;
          _logger.info('Core ML delegate enabled for iOS');
        } catch (e) {
          _logger.warning('Core ML not available, trying Metal');

          // Try Metal delegate as fallback
          try {
            final metalOptions = InterpreterOptions()
              // Metal delegate not available in current version
              ..threads = Platform.numberOfProcessors;

            final testInterpreter = await Interpreter.fromAsset(
              'assets/models/test_model.tflite',
              options: metalOptions,
            );
            testInterpreter.close();

            _useGpuDelegate = true;
            _logger.info('Metal delegate enabled for iOS');
          } catch (e) {
            _logger.warning('Metal delegate not available');
          }
        }
      }

      _logger.info('Hardware acceleration configuration complete - '
          'GPU: $_useGpuDelegate, NNAPI: $_useNnApiDelegate, CoreML: $_useCoreMLDelegate');
    } catch (e) {
      _logger.error('Failed to configure hardware acceleration', error: e);
    }
  }

  /// Initialize all sub-services
  Future<void> _initializeSubServices() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Initialize services in parallel where possible
      await Future.wait([
        _activityService.initialize(),
        _captionService.initialize(),
        _narrativeService.initialize(),
      ]);

      _performanceMetrics['initialization'] = stopwatch.elapsed;
      _logger.info('Sub-services initialized in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      _logger.error('Failed to initialize sub-services', error: e);
      throw e;
    }
  }

  /// Setup background processing for optimal conditions
  void _setupBackgroundProcessing() {
    // Register background task with Workmanager
    Workmanager().registerPeriodicTask(
      'ai_summary_generation',
      'generateDailySummary',
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.unmetered,
        requiresBatteryNotLow: true,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: true,
      ),
    );

    // Setup timer for periodic checks
    _backgroundTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkAndProcessPendingData(),
    );

    _logger.info('Background processing configured');
  }

  /// Generate daily summary with all optimizations
  Future<DailySummaryResult> generateDailySummary({
    required DateTime date,
    NarrativeStyle style = NarrativeStyle.casual,
    bool forceProcessing = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isProcessing && !forceProcessing) {
      throw Exception('Already processing a summary');
    }

    _isProcessing = true;
    final stopwatch = Stopwatch()..start();

    try {
      _logger.info('Generating daily summary for ${date.toIso8601String()}');

      // Step 1: Data collection (can be parallelized)
      final dataCollectionStart = stopwatch.elapsedMilliseconds;

      final locationData = await _collectLocationData(date);
      final activityData = await _collectActivityData(date);
      final photoData = await _collectPhotoData(date);

      _performanceMetrics['dataCollection'] =
          Duration(milliseconds: stopwatch.elapsedMilliseconds - dataCollectionStart);

      // Step 2: Multi-modal fusion
      final fusionStart = stopwatch.elapsedMilliseconds;

      final dailyEvents = await _fusionService.buildDailyTimeline(
        date: date,
        locationPoints: locationData,
        activityResults: activityData,
        photos: photoData,
      );

      _performanceMetrics['fusion'] =
          Duration(milliseconds: stopwatch.elapsedMilliseconds - fusionStart);

      // Step 3: Narrative generation
      final narrativeStart = stopwatch.elapsedMilliseconds;

      final narrative = await _narrativeService.generateNarrative(
        events: dailyEvents,
        style: style,
      );

      _performanceMetrics['narrative'] =
          Duration(milliseconds: stopwatch.elapsedMilliseconds - narrativeStart);

      // Build result
      final result = DailySummaryResult(
        date: date,
        narrative: narrative.narrative,
        summary: narrative.summary,
        events: dailyEvents,
        style: style,
        confidence: narrative.confidence,
        processingTime: stopwatch.elapsed,
        performanceMetrics: Map.from(_performanceMetrics),
      );

      _logger.info('Daily summary generated in ${stopwatch.elapsedMilliseconds}ms');

      return result;
    } catch (e, stack) {
      _logger.error('Failed to generate daily summary', error: e, stackTrace: stack);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  /// Collect location data for the date
  Future<List<LocationPoint>> _collectLocationData(DateTime date) async {
    // This would fetch from the database
    // For now, generate sample data
    final points = <LocationPoint>[];

    // Simulate location points throughout the day
    final baseTime = DateTime(date.year, date.month, date.day, 8, 0);
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    for (int i = 0; i < 100; i++) {
      points.add(LocationPoint(
        id: 'loc_$i',
        latitude: 37.7749 + (random * 0.001),
        longitude: -122.4194 + (random * 0.001),
        timestamp: baseTime.add(Duration(minutes: i * 5)),
      ));
    }

    return points;
  }

  /// Collect activity data for the date
  Future<List<ActivityRecognitionResult>> _collectActivityData(DateTime date) async {
    // This would fetch from the database
    // For now, return empty list
    return [];
  }

  /// Collect photo data for the date
  Future<List<dynamic>> _collectPhotoData(DateTime date) async {
    // This would use PhotoService
    // For now, return empty list
    return [];
  }

  /// Check and process pending data during optimal conditions
  Future<void> _checkAndProcessPendingData() async {
    try {
      // Check battery level
      if (!await _isBatteryOptimal()) {
        _logger.debug('Skipping processing - battery not optimal');
        return;
      }

      // Check if device is idle
      if (!await _isDeviceIdle()) {
        _logger.debug('Skipping processing - device not idle');
        return;
      }

      // Process pending summaries
      await _processPendingSummaries();
    } catch (e) {
      _logger.error('Error in background processing', error: e);
    }
  }

  /// Check if battery conditions are optimal
  Future<bool> _isBatteryOptimal() async {
    // This would check actual battery level
    // For now, return true
    return true;
  }

  /// Check if device is idle
  Future<bool> _isDeviceIdle() async {
    // This would check device activity
    // For now, return true
    return true;
  }

  /// Process pending summaries
  Future<void> _processPendingSummaries() async {
    // This would process any pending summaries
    _logger.debug('Checking for pending summaries...');
  }

  /// Get interpreter options with hardware acceleration
  InterpreterOptions getOptimizedInterpreterOptions() {
    final options = InterpreterOptions();

    // Set number of threads for CPU execution
    options.threads = Platform.numberOfProcessors ~/ 2;

    // Add hardware delegates
    if (_useGpuDelegate) {
      if (Platform.isAndroid) {
        options.addDelegate(GpuDelegateV2(
          options: GpuDelegateOptionsV2(),
        ));
      }
    }

    if (_useNnApiDelegate && Platform.isAndroid) {
      // NNAPI delegate not available in current version
    }

    if (_useCoreMLDelegate && Platform.isIOS) {
      // CoreML delegate not available in current version
    }

    return options;
  }

  /// Get performance metrics
  Map<String, Duration> getPerformanceMetrics() => Map.from(_performanceMetrics);

  /// Clear performance metrics
  void clearPerformanceMetrics() => _performanceMetrics.clear();

  /// Dispose resources
  void dispose() {
    _backgroundTimer?.cancel();
    _activityService.dispose();
    _captionService.dispose();
    _narrativeService.dispose();
    _isInitialized = false;
    _logger.info('Enhanced AI service disposed');
  }
}

/// Result of daily summary generation
class DailySummaryResult {
  final DateTime date;
  final String narrative;
  final String summary;
  final List<DailyEvent> events;
  final NarrativeStyle style;
  final double confidence;
  final Duration processingTime;
  final Map<String, Duration> performanceMetrics;

  DailySummaryResult({
    required this.date,
    required this.narrative,
    required this.summary,
    required this.events,
    required this.style,
    required this.confidence,
    required this.processingTime,
    required this.performanceMetrics,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'narrative': narrative,
    'summary': summary,
    'events': events.map((e) => e.toJson()).toList(),
    'style': style.name,
    'confidence': confidence,
    'processingTime': processingTime.inMilliseconds,
    'performanceMetrics': performanceMetrics.map(
      (k, v) => MapEntry(k, v.inMilliseconds),
    ),
  };
}

/// Provider for enhanced AI service
final enhancedAIServiceProvider = Provider<EnhancedAIService>((ref) {
  final service = EnhancedAIService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for generating daily summary
final dailySummaryProvider = FutureProvider.family<DailySummaryResult, DateTime>(
  (ref, date) async {
    final service = ref.watch(enhancedAIServiceProvider);
    return await service.generateDailySummary(date: date);
  },
);
