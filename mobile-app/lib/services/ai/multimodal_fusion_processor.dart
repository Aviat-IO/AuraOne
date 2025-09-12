import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path/path.dart' as path;
import 'ai_service.dart';
import 'spatiotemporal_processor.dart';
import 'visual_context_processor.dart';

/// Stage 3: Multimodal Fusion Processor
/// Combines spatiotemporal and visual context using Gemma 3 Nano
class MultimodalFusionProcessor extends PipelineStage {
  final AIServiceConfig config;
  final ModelFileManager modelFileManager;
  final GemmaLicenseManager licenseManager;
  
  FlutterGemma? _gemmaChat;
  bool _initialized = false;
  Isolate? _fusionIsolate;
  
  // Gemma 3 Nano configuration
  static const String modelFileName = 'gemma-3n-E2B-it-litert.task';
  static const int maxTokens = 4096;
  static const int maxImages = 3; // Gemma 3 Nano supports multimodal
  static const double temperature = 0.7;
  static const double topP = 0.95;
  static const int topK = 40;
  
  MultimodalFusionProcessor(
    this.config, {
    ModelFileManager? modelFileManager,
    GemmaLicenseManager? licenseManager,
  }) : modelFileManager = modelFileManager ?? ModelFileManager(
          Directory.systemTemp.path,
        ),
        licenseManager = licenseManager ?? GemmaLicenseManager();

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Check if user has accepted Gemma Terms of Use
      if (!await licenseManager.hasAcceptedTerms()) {
        debugPrint('Gemma Terms of Use not accepted - using fallback');
        _initialized = true;
        return;
      }
      
      // Check if model is downloaded
      final modelPath = await modelFileManager.getModelPath(modelFileName);
      if (!await File(modelPath).exists()) {
        debugPrint('Gemma model not found - download required');
        _initialized = true;
        return;
      }
      
      // Initialize Gemma with hardware acceleration if available
      _gemmaChat = FlutterGemma(
        maxTokens: maxTokens,
        temperature: temperature,
        topK: topK,
        topP: topP,
        randomSeed: DateTime.now().millisecondsSinceEpoch,
      );
      
      await _gemmaChat!.init(
        modelPath: modelPath,
        modelType: config.enableHardwareAcceleration 
          ? GemmaModelType.gpu 
          : GemmaModelType.cpu,
      );
      
      // Set up fusion isolate for heavy processing
      await _setupFusionIsolate();
      
      _initialized = true;
      debugPrint('MultimodalFusionProcessor initialized with Gemma 3 Nano');
    } catch (e) {
      debugPrint('Failed to initialize Gemma: $e');
      debugPrint('Will use fallback fusion methods');
      _initialized = true;
    }
  }
  
  Future<void> _setupFusionIsolate() async {
    final receivePort = ReceivePort();
    _fusionIsolate = await Isolate.spawn(
      _fusionIsolateEntryPoint,
      receivePort.sendPort,
    );
  }
  
  static void _fusionIsolateEntryPoint(SendPort sendPort) {
    // Isolate for background fusion processing
    // Handles heavy data transformation without blocking UI
  }

  /// Fuse spatiotemporal and visual context into unified multimodal data
  Future<FusedMultimodalData> fuse(
    SpatiotemporalData spatiotemporalData,
    VisualContextData visualContext,
  ) async {
    if (!_initialized) {
      await initialize();
    }
    
    try {
      // Prepare structured events from spatiotemporal data
      final structuredEvents = _structureEvents(
        spatiotemporalData.events,
        spatiotemporalData.clusters,
      );
      
      // Select key images for multimodal input
      final keyImages = _selectKeyImages(
        visualContext.images,
        structuredEvents,
        maxImages: maxImages,
      );
      
      // Generate multimodal fusion with Gemma
      if (_gemmaChat != null) {
        return await _fuseWithGemma(
          structuredEvents,
          keyImages,
          visualContext.captions,
        );
      } else {
        // Fallback fusion without Gemma
        return _fuseWithoutGemma(
          structuredEvents,
          keyImages,
          visualContext.captions,
        );
      }
    } catch (e) {
      debugPrint('Fusion error: $e');
      return _createFallbackFusion(spatiotemporalData, visualContext);
    }
  }

  List<StructuredEvent> _structureEvents(
    List<SpatiotemporalEvent> events,
    List<EventCluster> clusters,
  ) {
    final structured = <StructuredEvent>[];
    
    for (final cluster in clusters) {
      final clusterEvents = events.where(
        (e) => cluster.eventIds.contains(e.id),
      ).toList();
      
      if (clusterEvents.isNotEmpty) {
        structured.add(StructuredEvent(
          startTime: cluster.startTime,
          endTime: cluster.endTime,
          location: cluster.primaryLocation,
          activity: cluster.dominantActivity,
          events: clusterEvents,
          importance: _calculateImportance(cluster, clusterEvents),
        ));
      }
    }
    
    // Sort by importance and time
    structured.sort((a, b) {
      final importanceCompare = b.importance.compareTo(a.importance);
      if (importanceCompare != 0) return importanceCompare;
      return a.startTime.compareTo(b.startTime);
    });
    
    return structured;
  }
  
  double _calculateImportance(
    EventCluster cluster,
    List<SpatiotemporalEvent> events,
  ) {
    double importance = 0.0;
    
    // Duration factor (longer events more important)
    final duration = cluster.endTime.difference(cluster.startTime).inMinutes;
    importance += (duration / 60.0).clamp(0.0, 1.0) * 0.3;
    
    // Activity significance
    final activityScore = _getActivitySignificance(cluster.dominantActivity);
    importance += activityScore * 0.3;
    
    // Location uniqueness
    if (cluster.primaryLocation.confidence > 0.8) {
      importance += 0.2;
    }
    
    // Event density
    importance += (events.length / 10.0).clamp(0.0, 1.0) * 0.2;
    
    return importance.clamp(0.0, 1.0);
  }
  
  double _getActivitySignificance(HumanActivity activity) {
    // Score activities by their narrative significance
    return switch (activity) {
      HumanActivity.running => 0.8,
      HumanActivity.walking => 0.4,
      HumanActivity.driving => 0.7,
      HumanActivity.working => 0.9,
      HumanActivity.exercising => 0.8,
      HumanActivity.socializing => 0.9,
      HumanActivity.shopping => 0.6,
      HumanActivity.eating => 0.7,
      HumanActivity.sleeping => 0.3,
      HumanActivity.stationary => 0.2,
      HumanActivity.unknown => 0.1,
    };
  }
  
  List<KeyImage> _selectKeyImages(
    List<ProcessedImage> images,
    List<StructuredEvent> events,
    {required int maxImages}
  ) {
    final keyImages = <KeyImage>[];
    
    // Sort images by relevance score
    final sortedImages = List<ProcessedImage>.from(images)
      ..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    // Select top images that align with important events
    for (final image in sortedImages.take(maxImages * 2)) {
      // Find corresponding event
      final correspondingEvent = events.firstWhere(
        (event) => image.timestamp.isAfter(event.startTime) &&
                   image.timestamp.isBefore(event.endTime),
        orElse: () => events.first,
      );
      
      keyImages.add(KeyImage(
        image: image,
        event: correspondingEvent,
        relevance: image.relevanceScore * correspondingEvent.importance,
      ));
    }
    
    // Sort by combined relevance and take top N
    keyImages.sort((a, b) => b.relevance.compareTo(a.relevance));
    return keyImages.take(maxImages).toList();
  }
  
  Future<FusedMultimodalData> _fuseWithGemma(
    List<StructuredEvent> events,
    List<KeyImage> keyImages,
    Map<String, String> captions,
  ) async {
    // Prepare multimodal prompt
    final prompt = _buildMultimodalPrompt(events, keyImages, captions);
    
    // Prepare image data for Gemma
    final imageBytes = <Uint8List>[];
    for (final keyImage in keyImages) {
      if (keyImage.image.imageData != null) {
        imageBytes.add(keyImage.image.imageData!);
      }
    }
    
    // Generate fusion with Gemma 3 Nano
    final response = await _gemmaChat!.generateResponseFromMultiModal(
      prompt: prompt,
      images: imageBytes,
    );
    
    return FusedMultimodalData(
      structuredEvents: events,
      keyImages: keyImages,
      narrativeContext: response.text ?? '',
      confidence: response.metadata?['confidence'] ?? 0.8,
      fusionMethod: 'gemma-3-nano-multimodal',
      timestamp: DateTime.now(),
    );
  }
  
  String _buildMultimodalPrompt(
    List<StructuredEvent> events,
    List<KeyImage> keyImages,
    Map<String, String> captions,
  ) {
    final promptBuilder = PromptTemplateManager();
    
    // Build context from events
    final eventContext = events.map((e) => 
      '${e.activity.name} at ${e.location.name} '
      'from ${e.startTime.hour}:${e.startTime.minute.toString().padLeft(2, '0')} '
      'to ${e.endTime.hour}:${e.endTime.minute.toString().padLeft(2, '0')}'
    ).join('\n');
    
    // Build image context
    final imageContext = keyImages.map((ki) =>
      'Image ${keyImages.indexOf(ki) + 1}: ${captions[ki.image.id] ?? "Visual moment"}'
    ).join('\n');
    
    return promptBuilder.buildFusionPrompt(
      eventContext: eventContext,
      imageContext: imageContext,
      dataRichness: _assessDataRichness(events, keyImages),
    );
  }
  
  DataRichness _assessDataRichness(
    List<StructuredEvent> events,
    List<KeyImage> keyImages,
  ) {
    final eventCount = events.length;
    final imageCount = keyImages.length;
    final avgImportance = events.isEmpty ? 0.0 :
      events.map((e) => e.importance).reduce((a, b) => a + b) / events.length;
    
    if (eventCount > 10 && imageCount >= 3 && avgImportance > 0.7) {
      return DataRichness.rich;
    } else if (eventCount > 5 || imageCount >= 2) {
      return DataRichness.moderate;
    } else {
      return DataRichness.sparse;
    }
  }
  
  FusedMultimodalData _fuseWithoutGemma(
    List<StructuredEvent> events,
    List<KeyImage> keyImages,
    Map<String, String> captions,
  ) {
    // Template-based fusion when Gemma is not available
    final narrativeBuilder = StringBuffer();
    
    narrativeBuilder.writeln('Daily Activity Summary:');
    narrativeBuilder.writeln();
    
    for (final event in events.take(5)) { // Top 5 events
      narrativeBuilder.writeln(
        '• ${event.activity.name} at ${event.location.name} '
        '(${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - '
        '${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')})'
      );
    }
    
    if (keyImages.isNotEmpty) {
      narrativeBuilder.writeln();
      narrativeBuilder.writeln('Key Moments Captured:');
      for (final keyImage in keyImages) {
        final caption = captions[keyImage.image.id];
        if (caption != null) {
          narrativeBuilder.writeln('• $caption');
        }
      }
    }
    
    return FusedMultimodalData(
      structuredEvents: events,
      keyImages: keyImages,
      narrativeContext: narrativeBuilder.toString(),
      confidence: 0.6,
      fusionMethod: 'template-based',
      timestamp: DateTime.now(),
    );
  }
  
  FusedMultimodalData _createFallbackFusion(
    SpatiotemporalData spatiotemporalData,
    VisualContextData visualContext,
  ) {
    return FusedMultimodalData(
      structuredEvents: [],
      keyImages: [],
      narrativeContext: 'Unable to generate fusion at this time.',
      confidence: 0.0,
      fusionMethod: 'fallback',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<void> dispose() async {
    _fusionIsolate?.kill(priority: Isolate.immediate);
    _gemmaChat?.dispose();
    _initialized = false;
  }

  @override
  bool get isInitialized => _initialized;
}

/// Manages adaptive prompt templates based on data richness
class PromptTemplateManager {
  String buildFusionPrompt({
    required String eventContext,
    required String imageContext,
    required DataRichness dataRichness,
  }) {
    return switch (dataRichness) {
      DataRichness.rich => _buildRichPrompt(eventContext, imageContext),
      DataRichness.moderate => _buildModeratePrompt(eventContext, imageContext),
      DataRichness.sparse => _buildSparsePrompt(eventContext, imageContext),
    };
  }
  
  String _buildRichPrompt(String eventContext, String imageContext) {
    return '''
Analyze this comprehensive daily activity data and create a rich, detailed narrative summary.

Activities and Locations:
$eventContext

Visual Context from Images:
$imageContext

Create a cohesive narrative that:
1. Highlights the most significant moments and transitions
2. Incorporates visual elements to enhance the story
3. Identifies patterns and meaningful connections
4. Provides insights about the day's flow and rhythm
5. Captures the emotional and experiential quality

Generate a narrative summary (3-4 paragraphs):''';
  }
  
  String _buildModeratePrompt(String eventContext, String imageContext) {
    return '''
Summarize this day's activities into a meaningful narrative.

Main Activities:
$eventContext

Key Moments:
$imageContext

Create a brief narrative that captures:
1. The main events and their significance
2. How the visual moments relate to activities
3. The overall arc of the day

Generate a summary (2-3 paragraphs):''';
  }
  
  String _buildSparsePrompt(String eventContext, String imageContext) {
    return '''
Create a simple summary of available information.

Recorded Activities:
$eventContext

${imageContext.isNotEmpty ? 'Visual Notes:\n$imageContext' : ''}

Provide a brief summary of what happened:''';
  }
}

// Data models for multimodal fusion

class FusedMultimodalData {
  final List<StructuredEvent> structuredEvents;
  final List<KeyImage> keyImages;
  final String narrativeContext;
  final double confidence;
  final String fusionMethod;
  final DateTime timestamp;
  
  FusedMultimodalData({
    required this.structuredEvents,
    required this.keyImages,
    required this.narrativeContext,
    required this.confidence,
    required this.fusionMethod,
    required this.timestamp,
  });
}

class StructuredEvent {
  final DateTime startTime;
  final DateTime endTime;
  final Location location;
  final HumanActivity activity;
  final List<SpatiotemporalEvent> events;
  final double importance;
  
  StructuredEvent({
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.activity,
    required this.events,
    required this.importance,
  });
}

class KeyImage {
  final ProcessedImage image;
  final StructuredEvent event;
  final double relevance;
  
  KeyImage({
    required this.image,
    required this.event,
    required this.relevance,
  });
}

enum DataRichness {
  rich,     // >10 events, >=3 images, high quality
  moderate, // 5-10 events, 1-2 images, medium quality
  sparse,   // <5 events, 0-1 images, low quality
}

// Gemma model types
enum GemmaModelType {
  cpu,
  gpu,
}
