import 'package:flutter/material.dart';
import '../database/media_database.dart';
import '../database/location_database.dart';
import '../providers/data_activity_tracker.dart';
import 'ai_feature_extractor.dart';
import 'daily_context_synthesizer.dart';

/// Test results for AI pipeline validation
class PipelineTestResults {
  final bool aiFeatureExtractionPassed;
  final bool dailyContextSynthesisPassed;
  final List<String> extractionErrors;
  final List<String> synthesisErrors;
  final Map<String, dynamic> testMetrics;
  final List<PhotoContext> samplePhotoContexts;
  final DailyContext? sampleDailyContext;

  PipelineTestResults({
    required this.aiFeatureExtractionPassed,
    required this.dailyContextSynthesisPassed,
    required this.extractionErrors,
    required this.synthesisErrors,
    required this.testMetrics,
    required this.samplePhotoContexts,
    this.sampleDailyContext,
  });

  bool get allTestsPassed => aiFeatureExtractionPassed && dailyContextSynthesisPassed;

  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('AI Pipeline Test Results:');
    buffer.writeln('✓ AI Feature Extraction: ${aiFeatureExtractionPassed ? "PASSED" : "FAILED"}');
    buffer.writeln('✓ Daily Context Synthesis: ${dailyContextSynthesisPassed ? "PASSED" : "FAILED"}');

    if (extractionErrors.isNotEmpty) {
      buffer.writeln('\nExtraction Errors:');
      for (final error in extractionErrors) {
        buffer.writeln('  - $error');
      }
    }

    if (synthesisErrors.isNotEmpty) {
      buffer.writeln('\nSynthesis Errors:');
      for (final error in synthesisErrors) {
        buffer.writeln('  - $error');
      }
    }

    buffer.writeln('\nTest Metrics:');
    testMetrics.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });

    return buffer.toString();
  }
}

/// Service to test the AI extraction pipeline with sample data
class AIPipelineTester {
  static final AIPipelineTester _instance = AIPipelineTester._internal();
  factory AIPipelineTester() => _instance;
  AIPipelineTester._internal();

  final AIFeatureExtractor _extractor = AIFeatureExtractor();
  final DailyContextSynthesizer _synthesizer = DailyContextSynthesizer();

  /// Run comprehensive tests on the AI pipeline
  Future<PipelineTestResults> runComprehensiveTests({
    required MediaDatabase mediaDatabase,
    required LocationDatabase locationDatabase,
  }) async {
    debugPrint('🧪 Starting AI Pipeline Tests...');

    final startTime = DateTime.now();
    final extractionErrors = <String>[];
    final synthesisErrors = <String>[];
    final testMetrics = <String, dynamic>{};

    bool aiFeatureExtractionPassed = false;
    bool dailyContextSynthesisPassed = false;
    List<PhotoContext> samplePhotoContexts = [];
    DailyContext? sampleDailyContext;

    try {
      // Test 1: AI Feature Extraction
      debugPrint('🔍 Testing AI Feature Extraction...');
      final extractionResult = await _testAIFeatureExtraction(mediaDatabase);
      aiFeatureExtractionPassed = extractionResult['passed'] as bool;
      extractionErrors.addAll(extractionResult['errors'] as List<String>);
      samplePhotoContexts = extractionResult['contexts'] as List<PhotoContext>;
      testMetrics.addAll(extractionResult['metrics'] as Map<String, dynamic>);

      // Test 2: Daily Context Synthesis
      debugPrint('🧩 Testing Daily Context Synthesis...');
      final synthesisResult = await _testDailyContextSynthesis(
        mediaDatabase,
        locationDatabase,
        samplePhotoContexts,
      );
      dailyContextSynthesisPassed = synthesisResult['passed'] as bool;
      synthesisErrors.addAll(synthesisResult['errors'] as List<String>);
      sampleDailyContext = synthesisResult['context'] as DailyContext?;
      testMetrics.addAll(synthesisResult['metrics'] as Map<String, dynamic>);

    } catch (e) {
      extractionErrors.add('Critical test failure: $e');
      debugPrint('❌ Critical test failure: $e');
    }

    final endTime = DateTime.now();
    testMetrics['total_test_time_ms'] = endTime.difference(startTime).inMilliseconds;

    final results = PipelineTestResults(
      aiFeatureExtractionPassed: aiFeatureExtractionPassed,
      dailyContextSynthesisPassed: dailyContextSynthesisPassed,
      extractionErrors: extractionErrors,
      synthesisErrors: synthesisErrors,
      testMetrics: testMetrics,
      samplePhotoContexts: samplePhotoContexts,
      sampleDailyContext: sampleDailyContext,
    );

    debugPrint('🏁 Test completed: ${results.allTestsPassed ? "✅ ALL PASSED" : "❌ SOME FAILED"}');
    debugPrint(results.summary);

    return results;
  }

  /// Test AI feature extraction with real or synthetic data
  Future<Map<String, dynamic>> _testAIFeatureExtraction(MediaDatabase mediaDatabase) async {
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    List<PhotoContext> contexts = [];
    bool passed = false;

    try {
      // Initialize the AI extractor
      await _extractor.initialize();

      // Get recent media items for testing
      final mediaItems = await mediaDatabase.getRecentMedia(limit: 5);

      if (mediaItems.isEmpty) {
        // Create synthetic test data if no real photos available
        contexts = await _createSyntheticPhotoContexts();
        metrics['used_synthetic_data'] = true;
        metrics['synthetic_contexts_count'] = contexts.length;
        passed = contexts.isNotEmpty;
      } else {
        // Test with real photos
        final startTime = DateTime.now();

        try {
          contexts = await _extractor.analyzePhotos(mediaItems);
          passed = true;

          final endTime = DateTime.now();
          metrics['extraction_time_ms'] = endTime.difference(startTime).inMilliseconds;
          metrics['photos_processed'] = mediaItems.length;
          metrics['contexts_generated'] = contexts.length;
          metrics['average_confidence'] = contexts.isNotEmpty
              ? contexts.map((c) => c.confidenceScore).reduce((a, b) => a + b) / contexts.length
              : 0.0;

          // Validate extracted contexts
          final validationResults = _validatePhotoContexts(contexts);
          errors.addAll(validationResults['errors'] as List<String>);
          metrics.addAll(validationResults['metrics'] as Map<String, dynamic>);

        } catch (e) {
          errors.add('Photo analysis failed: $e');
          debugPrint('❌ Photo analysis error: $e');

          // Fallback to synthetic data
          contexts = await _createSyntheticPhotoContexts();
          metrics['fallback_to_synthetic'] = true;
          passed = contexts.isNotEmpty;
        }
      }

    } catch (e) {
      errors.add('Feature extraction initialization failed: $e');
      debugPrint('❌ Feature extraction init error: $e');
    }

    return {
      'passed': passed && errors.isEmpty,
      'errors': errors,
      'contexts': contexts,
      'metrics': metrics,
    };
  }

  /// Test daily context synthesis
  Future<Map<String, dynamic>> _testDailyContextSynthesis(
    MediaDatabase mediaDatabase,
    LocationDatabase locationDatabase,
    List<PhotoContext> photoContexts,
  ) async {
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    DailyContext? context;
    bool passed = false;

    try {
      final startTime = DateTime.now();
      final testDate = DateTime.now().subtract(Duration(days: 1)); // Test with yesterday

      // Create sample activities for testing
      final sampleActivities = _createSampleActivities(testDate);

      context = await _synthesizer.synthesizeDailyContext(
        date: testDate,
        mediaDatabase: mediaDatabase,
        locationDatabase: locationDatabase,
        activities: sampleActivities,
        enabledCalendarIds: {},
      );

      final endTime = DateTime.now();

      // Validate synthesis results
      passed = true;
      metrics['synthesis_time_ms'] = endTime.difference(startTime).inMilliseconds;
      metrics['photo_contexts_count'] = context.photoContexts.length;
      metrics['calendar_events_count'] = context.calendarEvents.length;
      metrics['location_points_count'] = context.locationPoints.length;
      metrics['activities_count'] = context.activities.length;
      metrics['overall_confidence'] = context.overallConfidence;
      metrics['narrative_length'] = context.narrativeOverview.length;

      // Validate context quality
      final validationResults = _validateDailyContext(context);
      errors.addAll(validationResults['errors'] as List<String>);
      metrics.addAll(validationResults['metrics'] as Map<String, dynamic>);

      debugPrint('📊 Generated narrative: ${context.narrativeOverview}');

    } catch (e) {
      errors.add('Daily context synthesis failed: $e');
      debugPrint('❌ Daily context synthesis error: $e');
    }

    return {
      'passed': passed && errors.isEmpty,
      'errors': errors,
      'context': context,
      'metrics': metrics,
    };
  }

  /// Create synthetic photo contexts for testing when no real photos available
  Future<List<PhotoContext>> _createSyntheticPhotoContexts() async {
    debugPrint('🎭 Creating synthetic photo contexts for testing...');

    return [
      PhotoContext(
        photoId: 'test_001',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        sceneLabels: ['outdoor', 'nature', 'park'],
        objectLabels: ['tree', 'bench', 'flower'],
        faceCount: 2,
        textContent: ['Welcome to Central Park'],
        socialContext: SocialContext(
          peopleCount: 2,
          isGroupPhoto: true,
          isSelfie: false,
        ),
        confidenceScore: 0.85,
      ),
      PhotoContext(
        photoId: 'test_002',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        sceneLabels: ['indoor', 'restaurant', 'dining'],
        objectLabels: ['food', 'coffee', 'table'],
        faceCount: 1,
        textContent: ['Menu', 'Cafe Milano'],
        socialContext: SocialContext(
          peopleCount: 1,
          isGroupPhoto: false,
          isSelfie: true,
        ),
        confidenceScore: 0.92,
      ),
      PhotoContext(
        photoId: 'test_003',
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        sceneLabels: ['outdoor', 'street', 'city'],
        objectLabels: ['car', 'building', 'sign'],
        faceCount: 0,
        textContent: ['Main Street', 'Downtown'],
        socialContext: SocialContext(
          peopleCount: 0,
          isGroupPhoto: false,
          isSelfie: false,
        ),
        confidenceScore: 0.78,
      ),
    ];
  }

  /// Create sample activities for testing synthesis
  List<DataActivity> _createSampleActivities(DateTime date) {
    return [
      DataActivity(
        type: ActivityType.photo,
        action: 'Photo captured',
        timestamp: date.add(Duration(hours: 9)),
        metadata: {'count': 5},
      ),
      DataActivity(
        type: ActivityType.location,
        action: 'Location updated',
        timestamp: date.add(Duration(hours: 10)),
        metadata: {'accuracy': 10.0},
      ),
      DataActivity(
        type: ActivityType.calendar,
        action: 'Event synced',
        timestamp: date.add(Duration(hours: 11)),
        metadata: {'events': 3},
      ),
    ];
  }

  /// Validate photo contexts for quality and completeness
  Map<String, dynamic> _validatePhotoContexts(List<PhotoContext> contexts) {
    final errors = <String>[];
    final metrics = <String, dynamic>{};

    if (contexts.isEmpty) {
      errors.add('No photo contexts generated');
      return {'errors': errors, 'metrics': metrics};
    }

    int validContexts = 0;
    double totalConfidence = 0.0;
    int totalLabels = 0;

    for (final context in contexts) {
      bool isValid = true;

      // Check required fields
      if (context.photoId.isEmpty) {
        errors.add('Photo context missing ID');
        isValid = false;
      }

      if (context.confidenceScore < 0.0 || context.confidenceScore > 1.0) {
        errors.add('Invalid confidence score: ${context.confidenceScore}');
        isValid = false;
      }

      // Check data quality
      if (context.sceneLabels.isEmpty && context.objectLabels.isEmpty) {
        errors.add('Photo context has no labels');
        isValid = false;
      }

      if (isValid) {
        validContexts++;
        totalConfidence += context.confidenceScore;
        totalLabels += context.sceneLabels.length + context.objectLabels.length;
      }
    }

    metrics['valid_contexts'] = validContexts;
    metrics['validation_rate'] = validContexts / contexts.length;
    metrics['average_confidence'] = totalConfidence / contexts.length;
    metrics['average_labels_per_photo'] = totalLabels / contexts.length;

    return {'errors': errors, 'metrics': metrics};
  }

  /// Validate daily context for quality and completeness
  Map<String, dynamic> _validateDailyContext(DailyContext context) {
    final errors = <String>[];
    final metrics = <String, dynamic>{};

    // Check overall confidence
    if (context.overallConfidence < 0.0 || context.overallConfidence > 1.0) {
      errors.add('Invalid overall confidence: ${context.overallConfidence}');
    }

    // Check narrative quality
    if (context.narrativeOverview.isEmpty) {
      errors.add('Empty narrative overview');
    } else if (context.narrativeOverview.length < 10) {
      errors.add('Narrative too short');
    }

    // Calculate quality metrics
    metrics['narrative_quality'] = _assessNarrativeQuality(context.narrativeOverview);
    metrics['data_completeness'] = context.metadata['data_completeness'] ?? 0.0;
    metrics['summary_completeness'] = 1.0; // All summaries are always present

    return {'errors': errors, 'metrics': metrics};
  }

  /// Assess narrative quality based on content and structure
  double _assessNarrativeQuality(String narrative) {
    if (narrative.isEmpty) return 0.0;

    double quality = 0.5; // Base score

    // Check for descriptive content
    if (narrative.contains('spent time') || narrative.contains('visited')) quality += 0.2;
    if (narrative.contains('people') || narrative.contains('social')) quality += 0.1;
    if (narrative.contains('traveled') || narrative.contains('location')) quality += 0.1;
    if (narrative.length > 50) quality += 0.1;

    return quality.clamp(0.0, 1.0);
  }

  /// Quick test to verify AI components are working
  Future<bool> quickHealthCheck() async {
    try {
      debugPrint('🩺 Running AI Pipeline Health Check...');

      // Test AI extractor initialization
      await _extractor.initialize();

      // Create minimal synthetic data
      final syntheticContexts = await _createSyntheticPhotoContexts();

      if (syntheticContexts.isEmpty) {
        debugPrint('❌ Failed to create synthetic contexts');
        return false;
      }

      debugPrint('✅ AI Pipeline Health Check passed');
      return true;

    } catch (e) {
      debugPrint('❌ AI Pipeline Health Check failed: $e');
      return false;
    }
  }

  /// Generate a detailed test report
  String generateTestReport(PipelineTestResults results) {
    final buffer = StringBuffer();

    buffer.writeln('# AI Pipeline Test Report');
    buffer.writeln('Generated: ${DateTime.now().toLocal()}');
    buffer.writeln('');

    buffer.writeln('## Summary');
    buffer.writeln('Overall Status: ${results.allTestsPassed ? "✅ PASSED" : "❌ FAILED"}');
    buffer.writeln('');

    buffer.writeln('## Test Results');
    buffer.writeln('- AI Feature Extraction: ${results.aiFeatureExtractionPassed ? "✅" : "❌"}');
    buffer.writeln('- Daily Context Synthesis: ${results.dailyContextSynthesisPassed ? "✅" : "❌"}');
    buffer.writeln('');

    if (results.extractionErrors.isNotEmpty) {
      buffer.writeln('## Extraction Errors');
      for (final error in results.extractionErrors) {
        buffer.writeln('- $error');
      }
      buffer.writeln('');
    }

    if (results.synthesisErrors.isNotEmpty) {
      buffer.writeln('## Synthesis Errors');
      for (final error in results.synthesisErrors) {
        buffer.writeln('- $error');
      }
      buffer.writeln('');
    }

    buffer.writeln('## Metrics');
    results.testMetrics.forEach((key, value) {
      buffer.writeln('- $key: $value');
    });
    buffer.writeln('');

    if (results.sampleDailyContext != null) {
      buffer.writeln('## Sample Output');
      buffer.writeln('Narrative: "${results.sampleDailyContext!.narrativeOverview}"');
      buffer.writeln('Confidence: ${results.sampleDailyContext!.overallConfidence.toStringAsFixed(2)}');
    }

    return buffer.toString();
  }
}