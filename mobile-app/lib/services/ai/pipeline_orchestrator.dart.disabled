import 'dart:async';
import '../../utils/logger.dart';
import '../../database/location_database.dart';
import '../../database/media_database.dart';
import 'model_download_manager.dart';
import 'tflite_manager.dart';
import 'multimodal_fusion.dart';
import 'multimodal_fusion_processor.dart';
import 'narrative_generation.dart';
import 'spatiotemporal_processor.dart';
import 'visual_context_processor.dart';

/// Daily summary result from the AI pipeline
class DailySummary {
  final String narrative;
  final String briefSummary;
  final List<TimelineEvent> events;
  final Map<String, dynamic> metadata;
  final DateTime generatedAt;
  final double confidence;

  DailySummary({
    required this.narrative,
    required this.briefSummary,
    required this.events,
    required this.metadata,
    required this.generatedAt,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'narrative': narrative,
    'briefSummary': briefSummary,
    'events': events.map((e) => e.toJson()).toList(),
    'metadata': metadata,
    'generatedAt': generatedAt.toIso8601String(),
    'confidence': confidence,
  };
}

/// Timeline event representing a structured activity
class TimelineEvent {
  final DateTime startTime;
  final DateTime endTime;
  final String type; // 'stay' or 'journey'
  final String activity;
  final String? location;
  final String? description;
  final List<String>? imageCaptions;
  final Map<String, dynamic>? attributes;

  TimelineEvent({
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.activity,
    this.location,
    this.description,
    this.imageCaptions,
    this.attributes,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'type': type,
    'activity': activity,
    'location': location,
    'description': description,
    'imageCaptions': imageCaptions,
    'attributes': attributes,
  };
}

/// Pipeline state for tracking progress
enum PipelineState {
  idle,
  checkingModels,
  downloadingModels,
  processingSpatiotemporal,
  processingVisual,
  fusingData,
  generatingNarrative,
  completed,
  failed,
}

/// Pipeline progress information
class PipelineProgress {
  final PipelineState state;
  final double progress; // 0.0 to 1.0
  final String message;
  final String? currentStage;

  PipelineProgress({
    required this.state,
    required this.progress,
    required this.message,
    this.currentStage,
  });
}

/// AI Pipeline Orchestrator - Coordinates the 4-stage pipeline
class PipelineOrchestrator {
  static final _logger = AppLogger('PipelineOrchestrator');
  static final _instance = PipelineOrchestrator._internal();

  factory PipelineOrchestrator() => _instance;
  PipelineOrchestrator._internal();

  // Core managers
  final ModelDownloadManager _downloadManager = ModelDownloadManager();
  final TFLiteManager _tfliteManager = TFLiteManager();

  // Processing modules (Stage 1-4)
  final SpatiotemporalProcessor _spatiotemporalProcessor = SpatiotemporalProcessor();
  final VisualContextProcessor _visualProcessor = VisualContextProcessor();
  final MultiModalFusionService _fusionService = MultiModalFusionService();
  final NarrativeGenerationService _narrativeService = NarrativeGenerationService();

  // State management
  bool _isInitialized = false;
  bool _isProcessing = false;
  final StreamController<PipelineProgress> _progressController =
      StreamController<PipelineProgress>.broadcast();

  // Required models
  static const List<String> _requiredModels = [
    'har_cnn_lstm',     // For activity recognition
    'lightcap',         // For image captioning
    'gemma_3_nano',     // For narrative generation
  ];

  /// Get progress stream
  Stream<PipelineProgress> get progressStream => _progressController.stream;

  /// Initialize the pipeline orchestrator
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.info('Pipeline orchestrator already initialized');
      return;
    }

    try {
      _logger.info('Initializing AI Pipeline Orchestrator');

      _updateProgress(
        PipelineState.checkingModels,
        0.1,
        'Initializing pipeline components...',
      );

      // Initialize core managers
      await _downloadManager.initialize();
      await _tfliteManager.initialize();

      // Check model availability
      await _checkAndDownloadModels();

      // Initialize processing modules
      await _initializeProcessingModules();

      _isInitialized = true;
      _logger.info('Pipeline orchestrator initialized successfully');

      _updateProgress(
        PipelineState.idle,
        1.0,
        'Pipeline ready',
      );
    } catch (e, stack) {
      _logger.error('Failed to initialize pipeline', error: e, stackTrace: stack);
      _updateProgress(
        PipelineState.failed,
        0.0,
        'Initialization failed: $e',
      );
      throw Exception('Failed to initialize pipeline: $e');
    }
  }

  /// Check and download required models
  Future<void> _checkAndDownloadModels() async {
    _logger.info('Checking required models...');

    for (final modelId in _requiredModels) {
      final isDownloaded = await _downloadManager.isModelDownloaded(modelId);

      if (!isDownloaded) {
        _logger.info('Model $modelId not found, downloading...');

        _updateProgress(
          PipelineState.downloadingModels,
          0.2,
          'Downloading model: $modelId',
        );

        try {
          // Note: In production, this should handle user consent for large downloads
          await _downloadManager.downloadModel(modelId);
          _logger.info('Model $modelId downloaded successfully');
        } catch (e) {
          _logger.error('Failed to download model $modelId', error: e);
          // Continue without this model - will use fallback
        }
      } else {
        _logger.info('Model $modelId already available');
      }
    }
  }

  /// Initialize processing modules
  Future<void> _initializeProcessingModules() async {
    _logger.info('Initializing processing modules...');

    // Load models into TFLite manager
    for (final modelId in _requiredModels) {
      final modelPath = await _downloadManager.getModelPath(modelId);
      if (modelPath != null) {
        try {
          await _tfliteManager.loadModel(modelPath, modelId: modelId);
          _logger.info('Loaded model: $modelId');
        } catch (e) {
          _logger.warning('Failed to load model $modelId: $e');
        }
      }
    }

    // Initialize individual processors
    await _spatiotemporalProcessor.initialize();
    await _visualProcessor.initialize();
    await _fusionService.initialize();
    await _narrativeService.initialize();
  }

  /// Generate daily summary from sensor and media data
  Future<DailySummary> generateDailySummary({
    required DateTime date,
    required LocationDatabase locationDb,
    required MediaDatabase mediaDb,
    NarrativeStyle style = NarrativeStyle.reflective,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isProcessing) {
      throw Exception('Pipeline is already processing');
    }

    _isProcessing = true;

    try {
      _logger.info('Starting daily summary generation for $date');

      // Stage 1: Spatiotemporal Analysis
      _updateProgress(
        PipelineState.processingSpatiotemporal,
        0.25,
        'Analyzing location and movement data...',
        'Stage 1: Spatiotemporal Analysis',
      );

      final spatiotemporalEvents = await _processSpatiotemporalData(
        date,
        locationDb,
      );

      // Stage 2: Visual Context Extraction
      _updateProgress(
        PipelineState.processingVisual,
        0.45,
        'Processing photos and visual context...',
        'Stage 2: Visual Context Extraction',
      );

      final visualContexts = await _processVisualData(
        date,
        mediaDb,
      );

      // Stage 3: Multi-modal Fusion
      _updateProgress(
        PipelineState.fusingData,
        0.65,
        'Combining data sources...',
        'Stage 3: Multi-modal Fusion',
      );

      final fusedEvents = await _fuseMultimodalData(
        spatiotemporalEvents,
        visualContexts,
      );

      // Stage 4: Narrative Generation
      _updateProgress(
        PipelineState.generatingNarrative,
        0.85,
        'Generating narrative summary...',
        'Stage 4: Narrative Generation',
      );

      final summary = await _generateNarrative(
        fusedEvents,
        style,
      );

      _updateProgress(
        PipelineState.completed,
        1.0,
        'Summary generated successfully',
      );

      _logger.info('Daily summary generation completed');
      return summary;

    } catch (e, stack) {
      _logger.error('Pipeline processing failed', error: e, stackTrace: stack);
      _updateProgress(
        PipelineState.failed,
        0.0,
        'Processing failed: $e',
      );
      throw Exception('Failed to generate daily summary: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Stage 1: Process spatiotemporal data
  Future<List<SpatiotemporalEvent>> _processSpatiotemporalData(
    DateTime date,
    LocationDatabase locationDb,
  ) async {
    try {
      // Get location data for the date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final locationEntries = await locationDb.getLocationsBetween(
        startOfDay,
        endOfDay,
      );

      if (locationEntries.isEmpty) {
        _logger.info('No location data available for $date');
        return [];
      }

      // Process with spatiotemporal processor
      final events = await _spatiotemporalProcessor.processLocationData(
        locationEntries,
      );

      _logger.info('Processed ${events.length} spatiotemporal events');
      return events;
    } catch (e) {
      _logger.error('Spatiotemporal processing failed', error: e);
      return [];
    }
  }

  /// Stage 2: Process visual data
  Future<List<VisualContext>> _processVisualData(
    DateTime date,
    MediaDatabase mediaDb,
  ) async {
    try {
      // Get photos for the date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final mediaEntries = await mediaDb.getMediaBetween(
        startOfDay,
        endOfDay,
      );

      if (mediaEntries.isEmpty) {
        _logger.info('No photos available for $date');
        return [];
      }

      // Process with visual context processor
      final contexts = await _visualProcessor.processImages(
        mediaEntries,
      );

      _logger.info('Processed ${contexts.length} visual contexts');
      return contexts;
    } catch (e) {
      _logger.error('Visual processing failed', error: e);
      return [];
    }
  }

  /// Stage 3: Fuse multimodal data
  Future<List<TimelineEvent>> _fuseMultimodalData(
    List<SpatiotemporalEvent> spatiotemporalEvents,
    List<VisualContext> visualContexts,
  ) async {
    try {
      // Convert to fusion input format
      final fusionInput = FusionInput(
        spatiotemporalEvents: spatiotemporalEvents,
        visualContexts: visualContexts,
        timestamp: DateTime.now(),
      );

      // Process with fusion service
      final fusionResult = await _fusionService.fuseMultimodalData(fusionInput);

      // Convert to timeline events
      final timelineEvents = _convertToTimelineEvents(fusionResult);

      _logger.info('Created ${timelineEvents.length} timeline events');
      return timelineEvents;
    } catch (e) {
      _logger.error('Multimodal fusion failed', error: e);
      // Fallback: Create basic events from spatiotemporal data
      return _createFallbackEvents(spatiotemporalEvents);
    }
  }

  /// Stage 4: Generate narrative
  Future<DailySummary> _generateNarrative(
    List<TimelineEvent> events,
    NarrativeStyle style,
  ) async {
    try {
      // Prepare context for narrative generation
      final context = {
        'events': events.map((e) => e.toJson()).toList(),
        'date': DateTime.now().toIso8601String(),
        'eventCount': events.length,
      };

      // Generate narrative with the service
      final narrativeResult = await _narrativeService.generateNarrative(
        context,
        style: style,
      );

      // Create daily summary
      return DailySummary(
        narrative: narrativeResult.narrative,
        briefSummary: narrativeResult.summary,
        events: events,
        metadata: narrativeResult.metadata,
        generatedAt: narrativeResult.generatedAt,
        confidence: narrativeResult.confidence,
      );
    } catch (e) {
      _logger.error('Narrative generation failed', error: e);
      // Fallback: Create basic summary
      return _createFallbackSummary(events);
    }
  }

  /// Convert fusion result to timeline events
  List<TimelineEvent> _convertToTimelineEvents(FusionResult fusionResult) {
    final events = <TimelineEvent>[];

    for (final enrichedEvent in fusionResult.enrichedEvents) {
      events.add(TimelineEvent(
        startTime: enrichedEvent['startTime'] as DateTime,
        endTime: enrichedEvent['endTime'] as DateTime,
        type: enrichedEvent['type'] as String,
        activity: enrichedEvent['activity'] as String,
        location: enrichedEvent['location'] as String?,
        description: enrichedEvent['description'] as String?,
        imageCaptions: enrichedEvent['imageCaptions'] as List<String>?,
        attributes: enrichedEvent['attributes'] as Map<String, dynamic>?,
      ));
    }

    return events;
  }

  /// Create fallback events when fusion fails
  List<TimelineEvent> _createFallbackEvents(
    List<SpatiotemporalEvent> spatiotemporalEvents,
  ) {
    return spatiotemporalEvents.map((event) {
      return TimelineEvent(
        startTime: event.startTime,
        endTime: event.endTime,
        type: event.type.name,
        activity: event.activity,
        location: event.location.name,
        description: null,
        imageCaptions: null,
        attributes: {
          'confidence': event.confidence,
        },
      );
    }).toList();
  }

  /// Create fallback summary when narrative generation fails
  DailySummary _createFallbackSummary(List<TimelineEvent> events) {
    final activities = events.map((e) => e.activity).toSet().join(', ');
    final locations = events
        .where((e) => e.location != null)
        .map((e) => e.location)
        .toSet()
        .join(', ');

    return DailySummary(
      narrative: 'Your day included: $activities. '
          'You visited: ${locations.isNotEmpty ? locations : "various places"}.',
      briefSummary: 'A day with ${events.length} activities',
      events: events,
      metadata: {'fallback': true},
      generatedAt: DateTime.now(),
      confidence: 0.5,
    );
  }

  /// Update progress
  void _updateProgress(
    PipelineState state,
    double progress,
    String message, [
    String? currentStage,
  ]) {
    _progressController.add(PipelineProgress(
      state: state,
      progress: progress,
      message: message,
      currentStage: currentStage,
    ));
  }

  /// Clean up resources
  void dispose() {
    _progressController.close();
    _tfliteManager.releaseAllModels();
  }
}