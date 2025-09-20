import 'package:flutter/material.dart';
import '../database/media_database.dart';
import 'ai_feature_extractor.dart';
import 'daily_context_synthesizer.dart';
import 'ai_journal_generator.dart';

/// Confidence levels for AI analysis quality
enum ConfidenceLevel {
  excellent(0.8, 'Excellent', Colors.green),
  good(0.6, 'Good', Colors.lightGreen),
  moderate(0.4, 'Moderate', Colors.orange),
  limited(0.2, 'Limited', Colors.deepOrange),
  minimal(0.0, 'Minimal', Colors.red);

  const ConfidenceLevel(this.threshold, this.label, this.color);

  final double threshold;
  final String label;
  final Color color;

  static ConfidenceLevel fromScore(double score) {
    for (final level in values) {
      if (score >= level.threshold) {
        return level;
      }
    }
    return minimal;
  }
}

/// Detailed confidence analysis for different AI components
class ConfidenceAnalysis {
  final double overallScore;
  final ConfidenceLevel overallLevel;
  final PhotoAnalysisConfidence photoAnalysis;
  final ContextSynthesisConfidence contextSynthesis;
  final NarrativeGenerationConfidence narrativeGeneration;
  final List<String> qualityIndicators;
  final List<String> improvementSuggestions;
  final bool shouldShowWarning;
  final String qualityDescription;

  ConfidenceAnalysis({
    required this.overallScore,
    required this.overallLevel,
    required this.photoAnalysis,
    required this.contextSynthesis,
    required this.narrativeGeneration,
    required this.qualityIndicators,
    required this.improvementSuggestions,
    required this.shouldShowWarning,
    required this.qualityDescription,
  });
}

/// Photo analysis confidence breakdown
class PhotoAnalysisConfidence {
  final double score;
  final ConfidenceLevel level;
  final int photosAnalyzed;
  final int photosWithHighConfidence;
  final double averageFeatureDetectionScore;
  final Map<String, double> featureConfidenceScores;
  final List<String> reliableFeatures;
  final List<String> uncertainFeatures;

  PhotoAnalysisConfidence({
    required this.score,
    required this.level,
    required this.photosAnalyzed,
    required this.photosWithHighConfidence,
    required this.averageFeatureDetectionScore,
    required this.featureConfidenceScores,
    required this.reliableFeatures,
    required this.uncertainFeatures,
  });
}

/// Context synthesis confidence breakdown
class ContextSynthesisConfidence {
  final double score;
  final ConfidenceLevel level;
  final int dataSourcesAvailable;
  final Map<String, double> dataSourceReliability;
  final double temporalCoverage;
  final double spatialCoverage;
  final List<String> strongDataPoints;
  final List<String> weakDataPoints;

  ContextSynthesisConfidence({
    required this.score,
    required this.level,
    required this.dataSourcesAvailable,
    required this.dataSourceReliability,
    required this.temporalCoverage,
    required this.spatialCoverage,
    required this.strongDataPoints,
    required this.weakDataPoints,
  });
}

/// Narrative generation confidence breakdown
class NarrativeGenerationConfidence {
  final double score;
  final ConfidenceLevel level;
  final double templateMatchQuality;
  final double contextRichness;
  final double narrativeCoherence;
  final List<String> supportedClaims;
  final List<String> inferredClaims;

  NarrativeGenerationConfidence({
    required this.score,
    required this.level,
    required this.templateMatchQuality,
    required this.contextRichness,
    required this.narrativeCoherence,
    required this.supportedClaims,
    required this.inferredClaims,
  });
}

/// Fallback strategy for when AI analysis fails or has low confidence
class FallbackStrategy {
  final String type;
  final String description;
  final String content;
  final double confidence;
  final Map<String, dynamic> metadata;

  FallbackStrategy({
    required this.type,
    required this.description,
    required this.content,
    required this.confidence,
    required this.metadata,
  });
}

/// Enhanced AI confidence management and fallback handling
class AIConfidenceManager {
  static final AIConfidenceManager _instance = AIConfidenceManager._internal();
  factory AIConfidenceManager() => _instance;
  AIConfidenceManager._internal();

  /// Analyze confidence across all AI pipeline components
  Future<ConfidenceAnalysis> analyzeConfidence({
    required List<PhotoContext> photoContexts,
    required DailyContext dailyContext,
    required JournalEntry? journalEntry,
  }) async {
    try {
      // Analyze photo analysis confidence
      final photoAnalysis = _analyzePhotoConfidence(photoContexts);

      // Analyze context synthesis confidence
      final contextSynthesis = _analyzeContextConfidence(dailyContext);

      // Analyze narrative generation confidence
      final narrativeGeneration = journalEntry != null
          ? _analyzeNarrativeConfidence(journalEntry, dailyContext)
          : _createDefaultNarrativeConfidence();

      // Calculate overall confidence
      final overallScore = _calculateOverallConfidence(
        photoAnalysis.score,
        contextSynthesis.score,
        narrativeGeneration.score,
      );

      final overallLevel = ConfidenceLevel.fromScore(overallScore);

      // Generate quality indicators and suggestions
      final qualityIndicators = _generateQualityIndicators(
        photoAnalysis, contextSynthesis, narrativeGeneration,
      );

      final improvementSuggestions = _generateImprovementSuggestions(
        photoAnalysis, contextSynthesis, narrativeGeneration,
      );

      final shouldShowWarning = overallScore < 0.4;
      final qualityDescription = _generateQualityDescription(overallLevel, overallScore);

      return ConfidenceAnalysis(
        overallScore: overallScore,
        overallLevel: overallLevel,
        photoAnalysis: photoAnalysis,
        contextSynthesis: contextSynthesis,
        narrativeGeneration: narrativeGeneration,
        qualityIndicators: qualityIndicators,
        improvementSuggestions: improvementSuggestions,
        shouldShowWarning: shouldShowWarning,
        qualityDescription: qualityDescription,
      );
    } catch (e) {
      debugPrint('Error analyzing confidence: $e');
      return _createMinimalConfidenceAnalysis();
    }
  }

  /// Generate appropriate fallback strategy based on confidence analysis
  Future<FallbackStrategy> generateFallbackStrategy({
    required ConfidenceAnalysis confidenceAnalysis,
    required DailyContext dailyContext,
  }) async {
    try {
      if (confidenceAnalysis.overallScore >= 0.6) {
        // High confidence - no fallback needed
        return FallbackStrategy(
          type: 'none',
          description: 'AI analysis confidence is sufficient',
          content: '',
          confidence: confidenceAnalysis.overallScore,
          metadata: {'reason': 'high_confidence'},
        );
      }

      if (confidenceAnalysis.overallScore >= 0.3) {
        // Moderate confidence - enhanced template-based fallback
        return _generateTemplateBasedFallback(dailyContext, confidenceAnalysis);
      }

      // Low confidence - statistical fallback
      return _generateStatisticalFallback(dailyContext, confidenceAnalysis);
    } catch (e) {
      debugPrint('Error generating fallback strategy: $e');
      return _generateEmergencyFallback(dailyContext);
    }
  }

  /// Create enhanced journal entry with confidence information and fallbacks
  Future<JournalEntry> createEnhancedJournalEntry({
    required DailyContext dailyContext,
    required JournalEntry? originalEntry,
    required ConfidenceAnalysis confidenceAnalysis,
  }) async {
    try {
      if (originalEntry != null && confidenceAnalysis.overallScore >= 0.6) {
        // High confidence - enhance original entry with confidence metadata
        return JournalEntry(
          date: originalEntry.date,
          narrative: originalEntry.narrative,
          insights: originalEntry.insights,
          highlights: originalEntry.highlights,
          mood: originalEntry.mood,
          tags: originalEntry.tags,
          confidence: confidenceAnalysis.overallScore,
          metadata: {
            ...originalEntry.metadata,
            'confidence_analysis': {
              'overall_level': confidenceAnalysis.overallLevel.label,
              'photo_analysis_score': confidenceAnalysis.photoAnalysis.score,
              'context_synthesis_score': confidenceAnalysis.contextSynthesis.score,
              'narrative_generation_score': confidenceAnalysis.narrativeGeneration.score,
              'quality_indicators': confidenceAnalysis.qualityIndicators,
            },
          },
        );
      }

      // Generate fallback strategy
      final fallbackStrategy = await generateFallbackStrategy(
        confidenceAnalysis: confidenceAnalysis,
        dailyContext: dailyContext,
      );

      // Create journal entry with fallback content
      return _createFallbackJournalEntry(dailyContext, fallbackStrategy, confidenceAnalysis);
    } catch (e) {
      debugPrint('Error creating enhanced journal entry: $e');
      return _createEmergencyJournalEntry(dailyContext);
    }
  }

  /// Analyze photo analysis confidence
  PhotoAnalysisConfidence _analyzePhotoConfidence(List<PhotoContext> photoContexts) {
    if (photoContexts.isEmpty) {
      return PhotoAnalysisConfidence(
        score: 0.0,
        level: ConfidenceLevel.minimal,
        photosAnalyzed: 0,
        photosWithHighConfidence: 0,
        averageFeatureDetectionScore: 0.0,
        featureConfidenceScores: {},
        reliableFeatures: [],
        uncertainFeatures: ['No photos available for analysis'],
      );
    }

    final photosWithHighConfidence = photoContexts
        .where((photo) => photo.confidenceScore >= 0.7)
        .length;

    final averageConfidence = photoContexts
        .map((photo) => photo.confidenceScore)
        .reduce((a, b) => a + b) / photoContexts.length;

    // Analyze feature detection quality
    final featureConfidenceScores = <String, double>{};
    final reliableFeatures = <String>[];
    final uncertainFeatures = <String>[];

    // Scene detection confidence
    final sceneLabelsCount = photoContexts.fold(0, (sum, photo) => sum + photo.sceneLabels.length);
    final sceneConfidence = (sceneLabelsCount / photoContexts.length) / 5.0; // Normalize to 0-1
    featureConfidenceScores['scene_detection'] = sceneConfidence.clamp(0.0, 1.0);

    // Face detection confidence
    final facesDetectedCount = photoContexts.fold(0, (sum, photo) => sum + photo.faceCount);
    final faceConfidence = facesDetectedCount > 0 ? 0.8 : 0.2;
    featureConfidenceScores['face_detection'] = faceConfidence;

    // Object detection confidence
    final objectLabelsCount = photoContexts.fold(0, (sum, photo) => sum + photo.objectLabels.length);
    final objectConfidence = (objectLabelsCount / photoContexts.length) / 3.0; // Normalize to 0-1
    featureConfidenceScores['object_detection'] = objectConfidence.clamp(0.0, 1.0);

    // Text recognition confidence
    final textBlocksCount = photoContexts.fold(0, (sum, photo) => sum + photo.textContent.length);
    final textConfidence = textBlocksCount > 0 ? 0.7 : 0.1;
    featureConfidenceScores['text_recognition'] = textConfidence;

    // Categorize features
    featureConfidenceScores.forEach((feature, confidence) {
      if (confidence >= 0.6) {
        reliableFeatures.add(feature);
      } else {
        uncertainFeatures.add(feature);
      }
    });

    final overallScore = featureConfidenceScores.values.isNotEmpty
        ? featureConfidenceScores.values.reduce((a, b) => a + b) / featureConfidenceScores.length
        : 0.0;

    return PhotoAnalysisConfidence(
      score: overallScore,
      level: ConfidenceLevel.fromScore(overallScore),
      photosAnalyzed: photoContexts.length,
      photosWithHighConfidence: photosWithHighConfidence,
      averageFeatureDetectionScore: averageConfidence,
      featureConfidenceScores: featureConfidenceScores,
      reliableFeatures: reliableFeatures,
      uncertainFeatures: uncertainFeatures,
    );
  }

  /// Analyze context synthesis confidence
  ContextSynthesisConfidence _analyzeContextConfidence(DailyContext dailyContext) {
    final dataSourceReliability = <String, double>{};
    final strongDataPoints = <String>[];
    final weakDataPoints = <String>[];

    // Evaluate photo data
    if (dailyContext.photoContexts.isNotEmpty) {
      final photoReliability = dailyContext.photoContexts
          .map((photo) => photo.confidenceScore)
          .reduce((a, b) => a + b) / dailyContext.photoContexts.length;
      dataSourceReliability['photos'] = photoReliability;
      if (photoReliability >= 0.6) {
        strongDataPoints.add('High-quality photo analysis');
      } else {
        weakDataPoints.add('Photo analysis quality could be improved');
      }
    } else {
      dataSourceReliability['photos'] = 0.0;
      weakDataPoints.add('No photos available for analysis');
    }

    // Evaluate calendar data
    if (dailyContext.calendarEvents.isNotEmpty) {
      dataSourceReliability['calendar'] = 0.9; // Calendar data is highly reliable
      strongDataPoints.add('${dailyContext.calendarEvents.length} calendar events');
    } else {
      dataSourceReliability['calendar'] = 0.0;
      weakDataPoints.add('No calendar events available');
    }

    // Evaluate location data
    if (dailyContext.locationPoints.isNotEmpty) {
      final locationReliability = (dailyContext.locationPoints.length / 100.0).clamp(0.0, 0.8);
      dataSourceReliability['location'] = locationReliability;
      if (locationReliability >= 0.5) {
        strongDataPoints.add('Rich location tracking data');
      } else {
        weakDataPoints.add('Limited location data available');
      }
    } else {
      dataSourceReliability['location'] = 0.0;
      weakDataPoints.add('No location data available');
    }

    // Evaluate activity data
    if (dailyContext.activities.isNotEmpty) {
      final activityReliability = (dailyContext.activities.length / 20.0).clamp(0.0, 0.7);
      dataSourceReliability['activities'] = activityReliability;
      if (activityReliability >= 0.4) {
        strongDataPoints.add('Detailed activity tracking');
      } else {
        weakDataPoints.add('Sparse activity data');
      }
    } else {
      dataSourceReliability['activities'] = 0.0;
      weakDataPoints.add('No activity data available');
    }

    // Calculate temporal and spatial coverage
    final temporalCoverage = _calculateTemporalCoverage(dailyContext);
    final spatialCoverage = _calculateSpatialCoverage(dailyContext);

    // Calculate overall context confidence
    final averageReliability = dataSourceReliability.values.isNotEmpty
        ? dataSourceReliability.values.reduce((a, b) => a + b) / dataSourceReliability.values.length
        : 0.0;

    final dataSourceCount = dataSourceReliability.values.where((v) => v > 0).length;
    final diversityBonus = (dataSourceCount / 4.0) * 0.2; // Bonus for data diversity

    final overallScore = (averageReliability + diversityBonus + temporalCoverage * 0.1 + spatialCoverage * 0.1)
        .clamp(0.0, 1.0);

    return ContextSynthesisConfidence(
      score: overallScore,
      level: ConfidenceLevel.fromScore(overallScore),
      dataSourcesAvailable: dataSourceCount,
      dataSourceReliability: dataSourceReliability,
      temporalCoverage: temporalCoverage,
      spatialCoverage: spatialCoverage,
      strongDataPoints: strongDataPoints,
      weakDataPoints: weakDataPoints,
    );
  }

  /// Analyze narrative generation confidence
  NarrativeGenerationConfidence _analyzeNarrativeConfidence(
    JournalEntry journalEntry,
    DailyContext dailyContext,
  ) {
    // Analyze template match quality
    final templateMatchQuality = _analyzeTemplateMatch(journalEntry, dailyContext);

    // Analyze context richness
    final contextRichness = _analyzeContextRichness(dailyContext);

    // Analyze narrative coherence
    final narrativeCoherence = _analyzeNarrativeCoherence(journalEntry);

    // Identify supported vs inferred claims
    final supportedClaims = <String>[];
    final inferredClaims = <String>[];

    if (dailyContext.photoContexts.isNotEmpty) {
      supportedClaims.add('Photo-based observations');
    }
    if (dailyContext.calendarEvents.isNotEmpty) {
      supportedClaims.add('Calendar event details');
    }
    if (dailyContext.locationPoints.isNotEmpty) {
      supportedClaims.add('Location-based insights');
    }

    if (journalEntry.mood != 'neutral') {
      inferredClaims.add('Mood assessment');
    }
    if (journalEntry.insights.isNotEmpty) {
      inferredClaims.add('Behavioral insights');
    }

    final overallScore = (templateMatchQuality + contextRichness + narrativeCoherence) / 3.0;

    return NarrativeGenerationConfidence(
      score: overallScore,
      level: ConfidenceLevel.fromScore(overallScore),
      templateMatchQuality: templateMatchQuality,
      contextRichness: contextRichness,
      narrativeCoherence: narrativeCoherence,
      supportedClaims: supportedClaims,
      inferredClaims: inferredClaims,
    );
  }

  /// Helper methods for confidence analysis

  double _calculateOverallConfidence(double photo, double context, double narrative) {
    // Weighted average with emphasis on data quality
    return (photo * 0.4 + context * 0.4 + narrative * 0.2).clamp(0.0, 1.0);
  }

  double _calculateTemporalCoverage(DailyContext dailyContext) {
    final dayStart = DateTime(dailyContext.date.year, dailyContext.date.month, dailyContext.date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final allTimestamps = <DateTime>[
      ...dailyContext.photoContexts.map((p) => p.timestamp),
      ...dailyContext.calendarEvents.map((e) => e.startDate),
      ...dailyContext.activities.map((a) => a.timestamp),
    ];

    if (allTimestamps.isEmpty) return 0.0;

    // Calculate coverage across the day
    final sortedTimestamps = allTimestamps..sort();
    final timeSpan = sortedTimestamps.last.difference(sortedTimestamps.first);
    final daySpan = dayEnd.difference(dayStart);

    return (timeSpan.inMinutes / daySpan.inMinutes).clamp(0.0, 1.0);
  }

  double _calculateSpatialCoverage(DailyContext dailyContext) {
    if (dailyContext.locationPoints.isEmpty) return 0.0;

    // Simple heuristic: more location points = better spatial coverage
    return (dailyContext.locationPoints.length / 50.0).clamp(0.0, 1.0);
  }

  double _analyzeTemplateMatch(JournalEntry journalEntry, DailyContext dailyContext) {
    // Analyze how well the narrative matches the context data
    double score = 0.5; // Base score

    // Check if narrative length is appropriate for available data
    final dataRichness = dailyContext.photoContexts.length +
                        dailyContext.calendarEvents.length +
                        dailyContext.activities.length;

    if (dataRichness > 5 && journalEntry.narrative.length > 200) {
      score += 0.2;
    } else if (dataRichness <= 2 && journalEntry.narrative.length < 150) {
      score += 0.1;
    }

    // Check if insights match available data
    if (journalEntry.insights.isNotEmpty && dailyContext.photoContexts.isNotEmpty) {
      score += 0.2;
    }

    // Check if highlights are supported by data
    if (journalEntry.highlights.isNotEmpty &&
        (dailyContext.calendarEvents.isNotEmpty || dailyContext.photoContexts.isNotEmpty)) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  double _analyzeContextRichness(DailyContext dailyContext) {
    double richness = 0.0;

    // Photo context richness
    if (dailyContext.photoContexts.isNotEmpty) {
      richness += 0.3;
      if (dailyContext.photoContexts.any((p) => p.sceneLabels.isNotEmpty)) richness += 0.1;
      if (dailyContext.photoContexts.any((p) => p.faceCount > 0)) richness += 0.1;
    }

    // Calendar richness
    if (dailyContext.calendarEvents.isNotEmpty) {
      richness += 0.2;
      if (dailyContext.calendarEvents.any((e) => e.description?.isNotEmpty == true)) richness += 0.1;
    }

    // Location richness
    if (dailyContext.locationPoints.length > 10) {
      richness += 0.2;
    }

    return richness.clamp(0.0, 1.0);
  }

  double _analyzeNarrativeCoherence(JournalEntry journalEntry) {
    double coherence = 0.5; // Base score

    // Check narrative length appropriateness
    if (journalEntry.narrative.length >= 100 && journalEntry.narrative.length <= 800) {
      coherence += 0.2;
    }

    // Check for mood consistency
    if (journalEntry.mood != 'neutral' && journalEntry.narrative.isNotEmpty) {
      coherence += 0.1;
    }

    // Check for insights consistency
    if (journalEntry.insights.isNotEmpty) {
      coherence += 0.1;
    }

    // Check for highlights consistency
    if (journalEntry.highlights.isNotEmpty) {
      coherence += 0.1;
    }

    return coherence.clamp(0.0, 1.0);
  }

  /// Generate quality indicators
  List<String> _generateQualityIndicators(
    PhotoAnalysisConfidence photoAnalysis,
    ContextSynthesisConfidence contextSynthesis,
    NarrativeGenerationConfidence narrativeGeneration,
  ) {
    final indicators = <String>[];

    if (photoAnalysis.score >= 0.7) {
      indicators.add('High-quality photo analysis');
    }
    if (contextSynthesis.dataSourcesAvailable >= 3) {
      indicators.add('Rich data integration');
    }
    if (narrativeGeneration.score >= 0.7) {
      indicators.add('Coherent narrative generation');
    }
    if (contextSynthesis.temporalCoverage >= 0.5) {
      indicators.add('Good temporal coverage');
    }

    if (indicators.isEmpty) {
      indicators.add('Basic AI analysis completed');
    }

    return indicators;
  }

  /// Generate improvement suggestions
  List<String> _generateImprovementSuggestions(
    PhotoAnalysisConfidence photoAnalysis,
    ContextSynthesisConfidence contextSynthesis,
    NarrativeGenerationConfidence narrativeGeneration,
  ) {
    final suggestions = <String>[];

    if (photoAnalysis.photosAnalyzed == 0) {
      suggestions.add('Take photos throughout the day for richer context');
    } else if (photoAnalysis.score < 0.5) {
      suggestions.add('Take clearer photos with better lighting');
    }

    if (contextSynthesis.dataSourcesAvailable < 2) {
      suggestions.add('Enable location tracking and calendar sync');
    }

    if (contextSynthesis.temporalCoverage < 0.3) {
      suggestions.add('Capture moments throughout the day, not just in clusters');
    }

    if (narrativeGeneration.score < 0.5) {
      suggestions.add('Provide more varied daily activities for better insights');
    }

    return suggestions;
  }

  String _generateQualityDescription(ConfidenceLevel level, double score) {
    switch (level) {
      case ConfidenceLevel.excellent:
        return 'The AI analysis is highly reliable and comprehensive.';
      case ConfidenceLevel.good:
        return 'The AI analysis provides good insights with solid data support.';
      case ConfidenceLevel.moderate:
        return 'The AI analysis offers useful insights but could be enhanced with more data.';
      case ConfidenceLevel.limited:
        return 'The AI analysis is limited due to sparse data availability.';
      case ConfidenceLevel.minimal:
        return 'The AI analysis is minimal due to insufficient data.';
    }
  }

  /// Fallback strategy implementations

  Future<FallbackStrategy> _generateTemplateBasedFallback(
    DailyContext dailyContext,
    ConfidenceAnalysis confidenceAnalysis,
  ) async {
    final templates = _getTemplateBasedFallbacks();
    final bestTemplate = _selectBestTemplate(templates, dailyContext);

    return FallbackStrategy(
      type: 'template_based',
      description: 'Using structured template due to moderate AI confidence',
      content: bestTemplate,
      confidence: 0.6,
      metadata: {
        'original_confidence': confidenceAnalysis.overallScore,
        'fallback_reason': 'moderate_confidence',
        'data_sources': confidenceAnalysis.contextSynthesis.dataSourcesAvailable,
      },
    );
  }

  Future<FallbackStrategy> _generateStatisticalFallback(
    DailyContext dailyContext,
    ConfidenceAnalysis confidenceAnalysis,
  ) async {
    final content = _generateStatisticalSummary(dailyContext);

    return FallbackStrategy(
      type: 'statistical',
      description: 'Using data-driven summary due to low AI confidence',
      content: content,
      confidence: 0.4,
      metadata: {
        'original_confidence': confidenceAnalysis.overallScore,
        'fallback_reason': 'low_confidence',
        'data_points': _countDataPoints(dailyContext),
      },
    );
  }

  FallbackStrategy _generateEmergencyFallback(DailyContext dailyContext) {
    return FallbackStrategy(
      type: 'emergency',
      description: 'Basic fallback due to system error',
      content: 'Today was a day of simple moments. While detailed analysis was not available, '
               'the essence of the day was captured through ${_countDataPoints(dailyContext)} data points.',
      confidence: 0.2,
      metadata: {
        'fallback_reason': 'system_error',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Create default instances for error cases

  NarrativeGenerationConfidence _createDefaultNarrativeConfidence() {
    return NarrativeGenerationConfidence(
      score: 0.0,
      level: ConfidenceLevel.minimal,
      templateMatchQuality: 0.0,
      contextRichness: 0.0,
      narrativeCoherence: 0.0,
      supportedClaims: [],
      inferredClaims: [],
    );
  }

  ConfidenceAnalysis _createMinimalConfidenceAnalysis() {
    return ConfidenceAnalysis(
      overallScore: 0.1,
      overallLevel: ConfidenceLevel.minimal,
      photoAnalysis: PhotoAnalysisConfidence(
        score: 0.0,
        level: ConfidenceLevel.minimal,
        photosAnalyzed: 0,
        photosWithHighConfidence: 0,
        averageFeatureDetectionScore: 0.0,
        featureConfidenceScores: {},
        reliableFeatures: [],
        uncertainFeatures: ['System error occurred'],
      ),
      contextSynthesis: ContextSynthesisConfidence(
        score: 0.0,
        level: ConfidenceLevel.minimal,
        dataSourcesAvailable: 0,
        dataSourceReliability: {},
        temporalCoverage: 0.0,
        spatialCoverage: 0.0,
        strongDataPoints: [],
        weakDataPoints: ['System error occurred'],
      ),
      narrativeGeneration: _createDefaultNarrativeConfidence(),
      qualityIndicators: ['System recovery active'],
      improvementSuggestions: ['Please try again later'],
      shouldShowWarning: true,
      qualityDescription: 'System encountered an error during analysis.',
    );
  }

  JournalEntry _createFallbackJournalEntry(
    DailyContext dailyContext,
    FallbackStrategy fallbackStrategy,
    ConfidenceAnalysis confidenceAnalysis,
  ) {
    return JournalEntry(
      date: dailyContext.date,
      narrative: fallbackStrategy.content,
      insights: _generateFallbackInsights(dailyContext, confidenceAnalysis),
      highlights: _generateFallbackHighlights(dailyContext),
      mood: 'reflective',
      tags: ['ai_fallback', fallbackStrategy.type],
      confidence: fallbackStrategy.confidence,
      metadata: {
        'fallback_strategy': fallbackStrategy.type,
        'fallback_reason': fallbackStrategy.metadata['fallback_reason'] ?? 'unknown',
        'confidence_analysis': confidenceAnalysis.overallLevel.label,
        'generated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  JournalEntry _createEmergencyJournalEntry(DailyContext dailyContext) {
    return JournalEntry(
      date: dailyContext.date,
      narrative: 'Today contained moments that were experienced and remembered, '
                'even when detailed analysis was not available.',
      insights: ['Sometimes the most important experiences are felt rather than documented'],
      highlights: ['A day of personal presence'],
      mood: 'peaceful',
      tags: ['reflection', 'emergency_fallback'],
      confidence: 0.1,
      metadata: {
        'emergency_fallback': true,
        'generated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Helper methods for fallback content generation

  List<String> _getTemplateBasedFallbacks() {
    return [
      'Today unfolded with {activity_count} activities and {data_points} moments captured. '
      'The day held its own rhythm and significance.',
      'This day brought together {data_points} different experiences. '
      'Each moment contributed to the day\'s unique character.',
      'Today was marked by {activity_count} notable activities. '
      'The collected memories paint a picture of a meaningful day.',
    ];
  }

  String _selectBestTemplate(List<String> templates, DailyContext dailyContext) {
    final template = templates.first; // Simple selection for now
    final activityCount = dailyContext.activities.length + dailyContext.calendarEvents.length;
    final dataPoints = _countDataPoints(dailyContext);

    return template
        .replaceAll('{activity_count}', activityCount.toString())
        .replaceAll('{data_points}', dataPoints.toString());
  }

  String _generateStatisticalSummary(DailyContext dailyContext) {
    final photoCount = dailyContext.photoContexts.length;
    final eventCount = dailyContext.calendarEvents.length;
    final locationCount = dailyContext.locationPoints.length;
    final activityCount = dailyContext.activities.length;

    return 'Today\'s data summary: $photoCount photos captured, $eventCount calendar events, '
           '$locationCount location points tracked, and $activityCount activities recorded. '
           'While detailed AI analysis was limited, these data points reflect an active day.';
  }

  List<String> _generateFallbackInsights(DailyContext dailyContext, ConfidenceAnalysis confidenceAnalysis) {
    final insights = <String>[];

    if (dailyContext.photoContexts.isNotEmpty) {
      insights.add('${dailyContext.photoContexts.length} visual moments were captured');
    }

    if (dailyContext.calendarEvents.isNotEmpty) {
      insights.add('${dailyContext.calendarEvents.length} planned activities provided structure');
    }

    if (confidenceAnalysis.improvementSuggestions.isNotEmpty) {
      insights.add('Data quality can be improved for richer insights');
    }

    if (insights.isEmpty) {
      insights.add('Every day holds value, even in quiet moments');
    }

    return insights;
  }

  List<String> _generateFallbackHighlights(DailyContext dailyContext) {
    final highlights = <String>[];

    if (dailyContext.calendarEvents.isNotEmpty) {
      highlights.add(dailyContext.calendarEvents.first.title);
    }

    if (dailyContext.photoContexts.isNotEmpty) {
      highlights.add('${dailyContext.photoContexts.length} moments documented');
    }

    if (highlights.isEmpty) {
      highlights.add('A day of personal presence and awareness');
    }

    return highlights;
  }

  int _countDataPoints(DailyContext dailyContext) {
    return dailyContext.photoContexts.length +
           dailyContext.calendarEvents.length +
           dailyContext.locationPoints.length +
           dailyContext.activities.length;
  }
}