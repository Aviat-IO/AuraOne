/// Pattern analysis data models for long-term behavioral insights
library;

enum ActivityPatternType {
  weekly,
  monthly,
  quarterly,
}

enum MoodTrendType {
  monthly,
  quarterly,
  yearly,
}

enum TrendDirection {
  improving,
  declining,
  stable,
}

enum ConfidenceLevel {
  excellent,
  good,
  moderate,
  limited,
  minimal,
}

class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  Duration get duration => end.difference(start);
}

class ActivityPattern {
  final String category;
  final int frequency;
  final double averageIntensity;
  final Map<int, int> timeDistribution;
  final Map<int, int> dayDistribution;

  const ActivityPattern({
    required this.category,
    required this.frequency,
    required this.averageIntensity,
    required this.timeDistribution,
    required this.dayDistribution,
  });

  ActivityPattern copyWith({
    String? category,
    int? frequency,
    double? averageIntensity,
    Map<int, int>? timeDistribution,
    Map<int, int>? dayDistribution,
  }) {
    return ActivityPattern(
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      averageIntensity: averageIntensity ?? this.averageIntensity,
      timeDistribution: timeDistribution ?? this.timeDistribution,
      dayDistribution: dayDistribution ?? this.dayDistribution,
    );
  }
}

class WeeklyPattern {
  final Map<int, double> dayAverages;
  final int mostActiveDay;
  final int leastActiveDay;
  final double weekendVsWeekdayRatio;

  const WeeklyPattern({
    required this.dayAverages,
    required this.mostActiveDay,
    required this.leastActiveDay,
    required this.weekendVsWeekdayRatio,
  });
}

class ActivityTrend {
  final String category;
  final TrendDirection direction;
  final double magnitude;
  final List<DateTime> significantDates;

  const ActivityTrend({
    required this.category,
    required this.direction,
    required this.magnitude,
    required this.significantDates,
  });
}

class ActivityPatternAnalysis {
  final ActivityPatternType type;
  final DateRange period;
  final Map<String, ActivityPattern> patterns;
  final WeeklyPattern weeklyPatterns;
  final List<ActivityTrend> trends;
  final List<String> insights;
  final double confidence;

  const ActivityPatternAnalysis({
    required this.type,
    required this.period,
    required this.patterns,
    required this.weeklyPatterns,
    required this.trends,
    required this.insights,
    required this.confidence,
  });

  factory ActivityPatternAnalysis.empty(ActivityPatternType type) {
    final now = DateTime.now();
    return ActivityPatternAnalysis(
      type: type,
      period: DateRange(now, now),
      patterns: {},
      weeklyPatterns: WeeklyPattern(
        dayAverages: {},
        mostActiveDay: 1,
        leastActiveDay: 1,
        weekendVsWeekdayRatio: 1.0,
      ),
      trends: [],
      insights: ['Insufficient data for analysis'],
      confidence: 0.0,
    );
  }
}

class MoodDataPoint {
  final double score;
  final String category;
  final List<String> triggers;
  final double confidence;

  const MoodDataPoint({
    required this.score,
    required this.category,
    required this.triggers,
    required this.confidence,
  });
}

class SeasonalPattern {
  final Map<String, double> seasonalAverages;
  final String dominantSeason;
  final double seasonalVariability;

  const SeasonalPattern({
    required this.seasonalAverages,
    required this.dominantSeason,
    required this.seasonalVariability,
  });
}

class MoodCorrelation {
  final String factor;
  final double correlation;
  final double significance;
  final String description;

  const MoodCorrelation({
    required this.factor,
    required this.correlation,
    required this.significance,
    required this.description,
  });
}

class MoodTrendAnalysis {
  final TrendDirection trendDirection;
  final double averageMoodScore;
  final Map<String, SeasonalPattern> seasonalPatterns;
  final List<MoodCorrelation> correlations;
  final List<String> insights;
  final double confidence;

  const MoodTrendAnalysis({
    required this.trendDirection,
    required this.averageMoodScore,
    required this.seasonalPatterns,
    required this.correlations,
    required this.insights,
    required this.confidence,
  });

  factory MoodTrendAnalysis.empty(MoodTrendType type) {
    return MoodTrendAnalysis(
      trendDirection: TrendDirection.stable,
      averageMoodScore: 0.5,
      seasonalPatterns: {},
      correlations: [],
      insights: ['Insufficient data for mood analysis'],
      confidence: 0.0,
    );
  }
}

class SocialInteractionData {
  final int interactionCount;
  final double averageGroupSize;
  final List<String> commonSettings;
  final double interactionQuality;

  const SocialInteractionData({
    required this.interactionCount,
    required this.averageGroupSize,
    required this.commonSettings,
    required this.interactionQuality,
  });
}

class SocialTrend {
  final String type;
  final TrendDirection direction;
  final double magnitude;
  final List<DateTime> significantDates;

  const SocialTrend({
    required this.type,
    required this.direction,
    required this.magnitude,
    required this.significantDates,
  });
}

class SocialPreferences {
  final int preferredGroupSize;
  final List<String> preferredSettings;
  final String socialEnergyPattern;

  const SocialPreferences({
    required this.preferredGroupSize,
    required this.preferredSettings,
    required this.socialEnergyPattern,
  });
}

class SocialPatternAnalysis {
  final double averageSocialInteractions;
  final List<SocialTrend> trends;
  final SocialPreferences preferences;
  final List<String> insights;
  final double confidence;

  const SocialPatternAnalysis({
    required this.averageSocialInteractions,
    required this.trends,
    required this.preferences,
    required this.insights,
    required this.confidence,
  });

  factory SocialPatternAnalysis.empty() {
    return SocialPatternAnalysis(
      averageSocialInteractions: 0.0,
      trends: [],
      preferences: SocialPreferences(
        preferredGroupSize: 1,
        preferredSettings: [],
        socialEnergyPattern: 'Unknown',
      ),
      insights: ['Insufficient data for social analysis'],
      confidence: 0.0,
    );
  }
}

class LocationInsights {
  final List<String> visitedPlaces;
  final String movementPattern;
  final double explorationScore;

  const LocationInsights({
    required this.visitedPlaces,
    required this.movementPattern,
    required this.explorationScore,
  });
}

class LocationTrend {
  final String type;
  final TrendDirection direction;
  final double magnitude;
  final List<DateTime> significantDates;

  const LocationTrend({
    required this.type,
    required this.direction,
    required this.magnitude,
    required this.significantDates,
  });
}

class HomeBaseAnalysis {
  final double homeTimePercentage;
  final double averageDistanceFromHome;
  final double explorationRadius;

  const HomeBaseAnalysis({
    required this.homeTimePercentage,
    required this.averageDistanceFromHome,
    required this.explorationRadius,
  });
}

class LocationPatternAnalysis {
  final List<LocationTrend> trends;
  final HomeBaseAnalysis homeBaseAnalysis;
  final List<String> insights;
  final double confidence;

  const LocationPatternAnalysis({
    required this.trends,
    required this.homeBaseAnalysis,
    required this.insights,
    required this.confidence,
  });

  factory LocationPatternAnalysis.empty() {
    return LocationPatternAnalysis(
      trends: [],
      homeBaseAnalysis: HomeBaseAnalysis(
        homeTimePercentage: 0.0,
        averageDistanceFromHome: 0.0,
        explorationRadius: 0.0,
      ),
      insights: ['Insufficient data for location analysis'],
      confidence: 0.0,
    );
  }
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