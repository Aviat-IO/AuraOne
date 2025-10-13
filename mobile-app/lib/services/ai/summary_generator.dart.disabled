import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'ai_service.dart';
import 'multimodal_fusion_processor.dart';

/// Stage 4: Summary Generator
/// Generates human-readable narratives from fused multimodal data
class SummaryGenerator extends PipelineStage {
  final AIServiceConfig config;
  bool _isInitialized = false;
  Isolate? _generationIsolate;

  @override
  bool get isInitialized => _isInitialized;

  SummaryGenerator(this.config);

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize generation components
      debugPrint('Initializing Summary Generator with template-based generation');
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Summary Generator: $e');
      throw Exception('Failed to initialize Summary Generator: $e');
    }
  }

  @override
  Future<DailySummary> process(dynamic input) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (input is! FusionResult) {
      throw ArgumentError('SummaryGenerator requires FusionResult input');
    }

    final fusedData = input;

    // Generate summary using templates
    final narrative = await _generateNarrative(fusedData);
    final briefSummary = await _generateBriefSummary(fusedData);

    return DailySummary(
      narrative: narrative,
      briefSummary: briefSummary,
      keyHighlights: _extractKeyHighlights(fusedData),
      confidence: fusedData.confidence,
      processingTime: DateTime.now().difference(fusedData.timestamp),
      metadata: {
        'eventsCount': fusedData.events.length,
        'activitiesCount': fusedData.activities.length,
        'locationsCount': fusedData.locations.length,
        'photosCount': fusedData.totalPhotoCount,
        'generationMethod': 'template',
      },
    );
  }

  Future<String> _generateNarrative(FusionResult data) async {
    // Template-based narrative generation
    final buffer = StringBuffer();

    // Opening
    buffer.writeln(_generateOpening(data));

    // Main events
    for (final event in data.events) {
      buffer.writeln(_describeEvent(event));
    }

    // Activities summary
    if (data.activities.isNotEmpty) {
      buffer.writeln(_summarizeActivities(data.activities));
    }

    // Closing
    buffer.writeln(_generateClosing(data));

    return buffer.toString().trim();
  }

  Future<String> _generateBriefSummary(FusionResult data) async {
    final activities = data.activities.map((a) => a['type']).toSet().toList();
    final locationCount = data.locations.length;
    final photoCount = data.totalPhotoCount;

    return 'Today included ${activities.length} activities'
           '${locationCount > 0 ? " across $locationCount locations" : ""}'
           '${photoCount > 0 ? " with $photoCount photos captured" : ""}.';
  }

  List<String> _extractKeyHighlights(FusionResult data) {
    final highlights = <String>[];

    // Most significant events
    final significantEvents = data.events
        .where((e) => (e['significance'] as double? ?? 0) > 0.7)
        .take(3);

    for (final event in significantEvents) {
      highlights.add(_createHighlight(event));
    }

    // Activity highlights
    final uniqueActivities = data.activities
        .map((a) => a['type'] as String)
        .toSet()
        .toList();

    if (uniqueActivities.length > 2) {
      highlights.add('Active day with ${uniqueActivities.join(", ")}');
    }

    return highlights;
  }

  String _generateOpening(FusionResult data) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'morning' : hour < 18 ? 'afternoon' : 'evening';
    return 'Your $greeting started with ${data.events.isNotEmpty ? "several activities" : "a quiet period"}.';
  }

  String _describeEvent(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? 'activity';
    final location = event['location'] as String?;
    final duration = event['duration'] as Duration?;

    final description = StringBuffer();
    description.write('You spent ');

    if (duration != null) {
      description.write('${_formatDuration(duration)} ');
    }

    description.write(type);

    if (location != null) {
      description.write(' at $location');
    }

    description.write('.');

    return description.toString();
  }

  String _summarizeActivities(List<Map<String, dynamic>> activities) {
    final activityTypes = activities.map((a) => a['type']).toSet().toList();

    if (activityTypes.isEmpty) return '';

    if (activityTypes.length == 1) {
      return 'Your main activity today was ${activityTypes.first}.';
    }

    return 'You engaged in various activities including ${activityTypes.join(", ")}.';
  }

  String _generateClosing(FusionResult data) {
    final photoCount = data.totalPhotoCount;

    if (photoCount > 0) {
      return 'You captured $photoCount memorable moments throughout the day.';
    }

    return 'Another day of experiences and activities completed.';
  }

  String _createHighlight(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? 'Event';
    final location = event['location'] as String?;

    if (location != null) {
      return '$type at $location';
    }

    return type;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hour${hours > 1 ? "s" : ""} and $minutes minute${minutes != 1 ? "s" : ""}';
    }

    return '$minutes minute${minutes != 1 ? "s" : ""}';
  }

  @override
  Future<void> dispose() async {
    _generationIsolate?.kill(priority: Isolate.immediate);
    _isInitialized = false;
  }
}

/// Daily summary output
class DailySummary {
  final String narrative;
  final String briefSummary;
  final List<String> keyHighlights;
  final double confidence;
  final Duration processingTime;
  final Map<String, dynamic> metadata;

  DailySummary({
    required this.narrative,
    required this.briefSummary,
    required this.keyHighlights,
    required this.confidence,
    required this.processingTime,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'narrative': narrative,
    'briefSummary': briefSummary,
    'keyHighlights': keyHighlights,
    'confidence': confidence,
    'processingTime': processingTime.inMilliseconds,
    'metadata': metadata,
  };
}

/// Model file manager (placeholder)
class ModelFileManager {
  final String basePath;

  ModelFileManager(this.basePath);

  Future<String> getModelPath(String fileName) async {
    return path.join(basePath, fileName);
  }
}

/// License manager (placeholder)
class GemmaLicenseManager {
  Future<bool> hasAcceptedTerms() async {
    return false; // Always use template generation
  }
}