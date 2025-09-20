import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pattern_analyzer.dart';
import '../services/journal_service.dart';
import '../models/pattern_analysis_models.dart';
import 'location_database_provider.dart';
import 'media_database_provider.dart';

/// Provider for the PatternAnalyzer service
final patternAnalyzerProvider = Provider<PatternAnalyzer>((ref) {
  final journalDatabase = ref.watch(journalDatabaseProvider);
  final mediaDatabase = ref.watch(mediaDatabaseProvider);
  final locationDatabase = ref.watch(locationDatabaseProvider);

  return PatternAnalyzer(
    journalDatabase: journalDatabase,
    mediaDatabase: mediaDatabase,
    locationDatabase: locationDatabase,
  );
});

/// Provider for weekly activity pattern analysis
final weeklyActivityPatternsProvider = FutureProvider.family<ActivityPatternAnalysis, DateTime>((ref, weekStart) async {
  final analyzer = ref.watch(patternAnalyzerProvider);
  final weekEnd = weekStart.add(const Duration(days: 7));

  return analyzer.analyzeActivityPatterns(
    startDate: weekStart,
    endDate: weekEnd,
    type: ActivityPatternType.weekly,
  );
});

/// Provider for monthly activity pattern analysis
final monthlyActivityPatternsProvider = FutureProvider.family<ActivityPatternAnalysis, DateTime>((ref, monthStart) async {
  final analyzer = ref.watch(patternAnalyzerProvider);
  final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

  return analyzer.analyzeActivityPatterns(
    startDate: monthStart,
    endDate: monthEnd,
    type: ActivityPatternType.monthly,
  );
});

/// Provider for monthly mood trend analysis
final monthlyMoodTrendsProvider = FutureProvider.family<MoodTrendAnalysis, DateTime>((ref, monthStart) async {
  final analyzer = ref.watch(patternAnalyzerProvider);
  final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

  return analyzer.analyzeMoodTrends(
    startDate: monthStart,
    endDate: monthEnd,
    type: MoodTrendType.monthly,
  );
});

/// Provider for quarterly mood trend analysis
final quarterlyMoodTrendsProvider = FutureProvider.family<MoodTrendAnalysis, DateTime>((ref, quarterStart) async {
  final analyzer = ref.watch(patternAnalyzerProvider);
  final quarterEnd = quarterStart.add(const Duration(days: 90));

  return analyzer.analyzeMoodTrends(
    startDate: quarterStart,
    endDate: quarterEnd,
    type: MoodTrendType.quarterly,
  );
});

/// Provider for monthly social pattern analysis
final monthlySocialPatternsProvider = FutureProvider.family<SocialPatternAnalysis, DateTime>((ref, monthStart) async {
  final analyzer = ref.watch(patternAnalyzerProvider);
  final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

  return analyzer.analyzeSocialPatterns(
    startDate: monthStart,
    endDate: monthEnd,
  );
});

/// Provider for monthly location pattern analysis
final monthlyLocationPatternsProvider = FutureProvider.family<LocationPatternAnalysis, DateTime>((ref, monthStart) async {
  final analyzer = ref.watch(patternAnalyzerProvider);
  final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

  return analyzer.analyzeLocationPatterns(
    startDate: monthStart,
    endDate: monthEnd,
  );
});

/// Provider for custom date range activity analysis
final customActivityPatternsProvider = FutureProvider.family<ActivityPatternAnalysis, PatternAnalysisRequest>((ref, request) async {
  final analyzer = ref.watch(patternAnalyzerProvider);

  return analyzer.analyzeActivityPatterns(
    startDate: request.startDate,
    endDate: request.endDate,
    type: request.activityPatternType,
  );
});

/// Provider for custom date range mood analysis
final customMoodTrendsProvider = FutureProvider.family<MoodTrendAnalysis, PatternAnalysisRequest>((ref, request) async {
  final analyzer = ref.watch(patternAnalyzerProvider);

  return analyzer.analyzeMoodTrends(
    startDate: request.startDate,
    endDate: request.endDate,
    type: request.moodTrendType,
  );
});

/// Provider for custom date range social analysis
final customSocialPatternsProvider = FutureProvider.family<SocialPatternAnalysis, PatternAnalysisRequest>((ref, request) async {
  final analyzer = ref.watch(patternAnalyzerProvider);

  return analyzer.analyzeSocialPatterns(
    startDate: request.startDate,
    endDate: request.endDate,
  );
});

/// Provider for custom date range location analysis
final customLocationPatternsProvider = FutureProvider.family<LocationPatternAnalysis, PatternAnalysisRequest>((ref, request) async {
  final analyzer = ref.watch(patternAnalyzerProvider);

  return analyzer.analyzeLocationPatterns(
    startDate: request.startDate,
    endDate: request.endDate,
  );
});

/// Provider for comprehensive pattern insights (combines all analyses)
final comprehensivePatternInsightsProvider = FutureProvider.family<ComprehensivePatternInsights, DateTime>((ref, monthStart) async {
  final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

  // Run all analyses in parallel
  final results = await Future.wait([
    ref.read(monthlyActivityPatternsProvider(monthStart).future),
    ref.read(monthlyMoodTrendsProvider(monthStart).future),
    ref.read(monthlySocialPatternsProvider(monthStart).future),
    ref.read(monthlyLocationPatternsProvider(monthStart).future),
  ]);

  final activityAnalysis = results[0] as ActivityPatternAnalysis;
  final moodAnalysis = results[1] as MoodTrendAnalysis;
  final socialAnalysis = results[2] as SocialPatternAnalysis;
  final locationAnalysis = results[3] as LocationPatternAnalysis;

  return ComprehensivePatternInsights(
    period: DateRange(monthStart, monthEnd),
    activityPatterns: activityAnalysis,
    moodTrends: moodAnalysis,
    socialPatterns: socialAnalysis,
    locationPatterns: locationAnalysis,
    overallConfidence: _calculateOverallConfidence([
      activityAnalysis.confidence,
      moodAnalysis.confidence,
      socialAnalysis.confidence,
      locationAnalysis.confidence,
    ]),
    keyInsights: _generateKeyInsights(activityAnalysis, moodAnalysis, socialAnalysis, locationAnalysis),
    recommendations: _generateRecommendations(activityAnalysis, moodAnalysis, socialAnalysis, locationAnalysis),
  );
});

// Helper functions

double _calculateOverallConfidence(List<double> confidences) {
  if (confidences.isEmpty) return 0.0;
  return confidences.reduce((a, b) => a + b) / confidences.length;
}

List<String> _generateKeyInsights(
  ActivityPatternAnalysis activityAnalysis,
  MoodTrendAnalysis moodAnalysis,
  SocialPatternAnalysis socialAnalysis,
  LocationPatternAnalysis locationAnalysis,
) {
  final insights = <String>[];

  // Cross-domain insights
  if (activityAnalysis.confidence > 0.6 && moodAnalysis.confidence > 0.6) {
    // Correlate activity patterns with mood trends
    if (moodAnalysis.trendDirection == TrendDirection.improving) {
      final topActivity = activityAnalysis.patterns.isNotEmpty
          ? activityAnalysis.patterns.values.reduce((a, b) => a.frequency > b.frequency ? a : b)
          : null;
      if (topActivity != null) {
        insights.add('Your increasing ${topActivity.category.toLowerCase()} activities may be contributing to your improving mood');
      }
    }
  }

  if (socialAnalysis.confidence > 0.6 && moodAnalysis.confidence > 0.6) {
    // Correlate social patterns with mood
    if (socialAnalysis.averageSocialInteractions > 2 && moodAnalysis.averageMoodScore > 0.7) {
      insights.add('Your active social life appears to have a positive impact on your mood');
    } else if (socialAnalysis.averageSocialInteractions < 1 && moodAnalysis.averageMoodScore < 0.5) {
      insights.add('Consider increasing social interactions to potentially boost your mood');
    }
  }

  if (locationAnalysis.confidence > 0.6 && activityAnalysis.confidence > 0.6) {
    // Correlate location patterns with activities
    if (locationAnalysis.homeBaseAnalysis.explorationRadius > 15) {
      insights.add('Your exploratory nature aligns well with your diverse activity patterns');
    } else if (locationAnalysis.homeBaseAnalysis.homeTimePercentage > 0.8) {
      insights.add('You prefer home-based activities and familiar environments');
    }
  }

  return insights;
}

List<String> _generateRecommendations(
  ActivityPatternAnalysis activityAnalysis,
  MoodTrendAnalysis moodAnalysis,
  SocialPatternAnalysis socialAnalysis,
  LocationPatternAnalysis locationAnalysis,
) {
  final recommendations = <String>[];

  // Mood-based recommendations
  if (moodAnalysis.trendDirection == TrendDirection.declining) {
    recommendations.add('Consider incorporating more mood-boosting activities into your routine');

    if (socialAnalysis.averageSocialInteractions < 2) {
      recommendations.add('Try scheduling more social activities to potentially improve your mood');
    }

    if (activityAnalysis.patterns.values.any((p) => p.category == 'Physical' && p.frequency < 3)) {
      recommendations.add('Increasing physical activities might help improve your mood');
    }
  }

  // Activity balance recommendations
  final physicalActivity = activityAnalysis.patterns.values.firstWhere(
    (p) => p.category == 'Physical',
    orElse: () => const ActivityPattern(
      category: 'Physical',
      frequency: 0,
      averageIntensity: 0.0,
      timeDistribution: {},
      dayDistribution: {},
    ),
  );

  if (physicalActivity.frequency < 3) {
    recommendations.add('Consider adding more physical activities to your weekly routine');
  }

  // Social recommendations
  if (socialAnalysis.averageSocialInteractions < 1 && moodAnalysis.averageMoodScore < 0.6) {
    recommendations.add('Try joining group activities or scheduling regular social meetups');
  }

  // Location/exploration recommendations
  if (locationAnalysis.homeBaseAnalysis.explorationRadius < 5 &&
      activityAnalysis.patterns.values.any((p) => p.category == 'Creative' && p.frequency > 2)) {
    recommendations.add('Consider exploring new locations for your creative activities to add variety');
  }

  return recommendations;
}

// Data models for requests and comprehensive insights

class PatternAnalysisRequest {
  final DateTime startDate;
  final DateTime endDate;
  final ActivityPatternType activityPatternType;
  final MoodTrendType moodTrendType;

  const PatternAnalysisRequest({
    required this.startDate,
    required this.endDate,
    this.activityPatternType = ActivityPatternType.monthly,
    this.moodTrendType = MoodTrendType.monthly,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternAnalysisRequest &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          activityPatternType == other.activityPatternType &&
          moodTrendType == other.moodTrendType;

  @override
  int get hashCode =>
      startDate.hashCode ^
      endDate.hashCode ^
      activityPatternType.hashCode ^
      moodTrendType.hashCode;
}

class ComprehensivePatternInsights {
  final DateRange period;
  final ActivityPatternAnalysis activityPatterns;
  final MoodTrendAnalysis moodTrends;
  final SocialPatternAnalysis socialPatterns;
  final LocationPatternAnalysis locationPatterns;
  final double overallConfidence;
  final List<String> keyInsights;
  final List<String> recommendations;

  const ComprehensivePatternInsights({
    required this.period,
    required this.activityPatterns,
    required this.moodTrends,
    required this.socialPatterns,
    required this.locationPatterns,
    required this.overallConfidence,
    required this.keyInsights,
    required this.recommendations,
  });

  bool get hasValidData => overallConfidence > 0.3;

  ConfidenceLevel get confidenceLevel {
    if (overallConfidence >= 0.8) return ConfidenceLevel.excellent;
    if (overallConfidence >= 0.6) return ConfidenceLevel.good;
    if (overallConfidence >= 0.4) return ConfidenceLevel.moderate;
    if (overallConfidence >= 0.2) return ConfidenceLevel.limited;
    return ConfidenceLevel.minimal;
  }
}

// Import the ConfidenceLevel enum from the existing confidence manager
enum ConfidenceLevel {
  excellent,
  good,
  moderate,
  limited,
  minimal,
}