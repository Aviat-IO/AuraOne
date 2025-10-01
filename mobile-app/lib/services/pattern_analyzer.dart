import 'package:flutter/material.dart';
import '../database/journal_database.dart';
import '../database/media_database.dart';
import '../database/location_database.dart';
import '../widgets/daily_canvas/enhanced_summary_widget.dart';
import '../models/pattern_analysis_models.dart';

/// Analyzes long-term patterns across multiple days/weeks/months
/// for insights into behavioral trends, mood patterns, and seasonal changes
class PatternAnalyzer {
  final JournalDatabase _journalDatabase;
  final MediaDatabase _mediaDatabase;
  final LocationDatabase _locationDatabase;

  PatternAnalyzer({
    required JournalDatabase journalDatabase,
    required MediaDatabase mediaDatabase,
    required LocationDatabase locationDatabase,
  })  : _journalDatabase = journalDatabase,
        _mediaDatabase = mediaDatabase,
        _locationDatabase = locationDatabase;

  /// Analyzes activity patterns over a specified time period
  Future<ActivityPatternAnalysis> analyzeActivityPatterns({
    required DateTime startDate,
    required DateTime endDate,
    ActivityPatternType type = ActivityPatternType.weekly,
  }) async {
    final activitiesByDate = await _getActivitiesInRange(startDate, endDate);
    final summaries = await _getEnhancedSummariesInRange(startDate, endDate);

    if (activitiesByDate.isEmpty) {
      return ActivityPatternAnalysis.empty(type);
    }

    final patterns = <String, ActivityPattern>{};
    final dayOfWeekData = <int, List<double>>{};
    final categoryFrequency = <String, int>{};
    final timeDistribution = <String, Map<int, int>>{};
    final dayDistribution = <String, Map<int, int>>{};

    for (final entry in activitiesByDate.entries) {
      final date = entry.key;
      final activities = entry.value;
      final dayOfWeek = date.weekday;

      // Analyze day-of-week patterns
      dayOfWeekData.putIfAbsent(dayOfWeek, () => []).add(activities.length.toDouble());

      // Analyze activity categories
      for (final activity in activities) {
        final category = _categorizeActivity(activity);

        // Track frequency
        categoryFrequency[category] = (categoryFrequency[category] ?? 0) + 1;

        // Track time-of-day distribution
        final hour = activity.timestamp.hour;
        final hourBucket = (hour / 3).floor() * 3; // 3-hour buckets
        timeDistribution.putIfAbsent(category, () => {});
        timeDistribution[category]![hourBucket] =
            (timeDistribution[category]![hourBucket] ?? 0) + 1;

        // Track day-of-week distribution
        dayDistribution.putIfAbsent(category, () => {});
        dayDistribution[category]![dayOfWeek] =
            (dayDistribution[category]![dayOfWeek] ?? 0) + 1;
      }
    }

    // Create final patterns
    for (final category in categoryFrequency.keys) {
      final timeMap = <int, int>{};
      final dayMap = <int, int>{};

      // Convert to int maps
      for (final entry in timeDistribution[category]?.entries ?? <MapEntry<int, int>>[]) {
        timeMap[entry.key] = entry.value;
      }

      for (final entry in dayDistribution[category]?.entries ?? <MapEntry<int, int>>[]) {
        dayMap[entry.key] = entry.value;
      }

      patterns[category] = ActivityPattern(
        category: category,
        frequency: categoryFrequency[category]!,
        averageIntensity: 1.0, // Default intensity
        timeDistribution: timeMap,
        dayDistribution: dayMap,
      );
    }

    // Calculate weekly patterns
    final weeklyPatterns = _calculateWeeklyPatterns(dayOfWeekData);

    // Identify trends
    final trends = _identifyActivityTrends(summaries);

    return ActivityPatternAnalysis(
      type: type,
      period: DateRange(startDate, endDate),
      patterns: patterns,
      weeklyPatterns: weeklyPatterns,
      trends: trends,
      confidence: _calculatePatternConfidence(summaries.length),
      insights: _generateActivityInsights(patterns, weeklyPatterns, trends),
    );
  }

  /// Analyzes mood trends over time
  Future<MoodTrendAnalysis> analyzeMoodTrends({
    required DateTime startDate,
    required DateTime endDate,
    MoodTrendType type = MoodTrendType.monthly,
  }) async {
    final summaries = await _getEnhancedSummariesInRange(startDate, endDate);

    if (summaries.isEmpty) {
      return MoodTrendAnalysis.empty(type);
    }

    final moodDataPoints = <MapEntry<DateTime, MoodDataPoint>>[];
    final moodCategories = <String, int>{};
    final moodTriggers = <String, int>{};

    for (final summary in summaries) {
      final mood = _extractMoodFromSummary(summary);
      if (mood != null) {
        moodDataPoints.add(MapEntry(summary.date, mood));

        // Count mood categories
        moodCategories[mood.category] = (moodCategories[mood.category] ?? 0) + 1;

        // Track potential mood triggers
        for (final trigger in mood.triggers) {
          moodTriggers[trigger] = (moodTriggers[trigger] ?? 0) + 1;
        }
      }
    }

    // Calculate mood trend
    final trendDirection = _calculateMoodTrend(moodDataPoints);

    // Identify seasonal patterns
    final seasonalPatterns = _identifySeasonalMoodPatterns(moodDataPoints);

    // Find correlations
    final correlations = _findMoodCorrelations(summaries);

    return MoodTrendAnalysis(
      trendDirection: trendDirection,
      averageMoodScore: _calculateAverageMoodScore(moodDataPoints),
      seasonalPatterns: seasonalPatterns,
      correlations: correlations,
      confidence: _calculatePatternConfidence(moodDataPoints.length),
      insights: _generateMoodInsights(moodDataPoints, trendDirection, correlations),
    );
  }

  /// Analyzes social interaction patterns
  Future<SocialPatternAnalysis> analyzeSocialPatterns({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final summaries = await _getEnhancedSummariesInRange(startDate, endDate);

    if (summaries.isEmpty) {
      return SocialPatternAnalysis.empty();
    }

    final socialData = <MapEntry<DateTime, SocialInteractionData>>[];
    final groupSizeDistribution = <int, int>{};
    final socialSettings = <String, int>{};

    for (final summary in summaries) {
      final socialInfo = _extractSocialData(summary);
      socialData.add(MapEntry(summary.date, socialInfo));

      // Track group size distribution
      groupSizeDistribution[socialInfo.averageGroupSize.round()] =
          (groupSizeDistribution[socialInfo.averageGroupSize.round()] ?? 0) + 1;

      // Track social settings
      for (final setting in socialInfo.commonSettings) {
        socialSettings[setting] = (socialSettings[setting] ?? 0) + 1;
      }
    }

    final socialTrends = _identifySocialTrends(socialData);
    final socialPreferences = _analyzeSocialPreferences(socialData);

    return SocialPatternAnalysis(
      averageSocialInteractions: _calculateAverageSocialInteractions(socialData),
      trends: socialTrends,
      preferences: socialPreferences,
      confidence: _calculatePatternConfidence(socialData.length),
      insights: _generateSocialInsights(socialData, socialTrends, socialPreferences),
    );
  }

  /// Analyzes location and movement patterns
  Future<LocationPatternAnalysis> analyzeLocationPatterns({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final summaries = await _getEnhancedSummariesInRange(startDate, endDate);

    if (summaries.isEmpty) {
      return LocationPatternAnalysis.empty();
    }

    final locationData = <MapEntry<DateTime, LocationInsights>>[];
    final frequentLocations = <String, int>{};
    final movementPatterns = <String, int>{};

    for (final summary in summaries) {
      final locationInfo = _extractLocationData(summary);
      locationData.add(MapEntry(summary.date, locationInfo));

      // Track frequent locations
      for (final location in locationInfo.visitedPlaces) {
        frequentLocations[location] = (frequentLocations[location] ?? 0) + 1;
      }

      // Track movement patterns
      movementPatterns[locationInfo.movementPattern] =
          (movementPatterns[locationInfo.movementPattern] ?? 0) + 1;
    }

    final locationTrends = _identifyLocationTrends(locationData);
    final homeBaseAnalysis = _analyzeHomeBase(locationData);

    return LocationPatternAnalysis(
      trends: locationTrends,
      homeBaseAnalysis: homeBaseAnalysis,
      confidence: _calculatePatternConfidence(locationData.length),
      insights: _generateLocationInsights(locationData, locationTrends, homeBaseAnalysis),
    );
  }

  // Helper methods

  Future<Map<DateTime, List<JournalActivity>>> _getActivitiesInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final activitiesByDate = <DateTime, List<JournalActivity>>{};

    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      try {
        // Get activities for the date
        final activities = await _journalDatabase.getActivitiesForDate(currentDate);
        if (activities.isNotEmpty) {
          activitiesByDate[currentDate] = activities;
        }
      } catch (e) {
        // Skip days with errors and continue
        debugPrint('Error getting activities for $currentDate: $e');
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return activitiesByDate;
  }

  Future<List<EnhancedDailySummary>> _getEnhancedSummariesInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final summaries = <EnhancedDailySummary>[];

    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      try {
        // Get activities for the date
        final activities = await _journalDatabase.getActivitiesForDate(currentDate);
        final journalEntry = await _journalDatabase.getJournalEntryForDate(currentDate);

        // Create a basic enhanced summary from available data
        final summary = EnhancedDailySummary.fallback(
          activities,
          journalEntry,
          currentDate,
        );
        summaries.add(summary);
      } catch (e) {
        // Skip days with errors and continue
        debugPrint('Error getting data for $currentDate: $e');
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return summaries;
  }

  String _categorizeActivity(JournalActivity activity) {
    final title = '${activity.activityType} ${activity.description}'.toLowerCase();

    if (title.contains('workout') || title.contains('exercise') || title.contains('gym')) {
      return 'Physical';
    } else if (title.contains('work') || title.contains('meeting') || title.contains('office')) {
      return 'Work';
    } else if (title.contains('social') || title.contains('friend') || title.contains('family')) {
      return 'Social';
    } else if (title.contains('creative') || title.contains('art') || title.contains('music')) {
      return 'Creative';
    } else if (title.contains('relax') || title.contains('rest') || title.contains('meditation')) {
      return 'Wellness';
    } else {
      return 'Other';
    }
  }

  WeeklyPattern _calculateWeeklyPatterns(Map<int, List<double>> dayOfWeekData) {
    final averages = <int, double>{};
    int mostActiveDay = 1;
    int leastActiveDay = 1;
    double maxAverage = 0.0;
    double minAverage = double.infinity;

    for (final entry in dayOfWeekData.entries) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      averages[entry.key] = average;

      if (average > maxAverage) {
        maxAverage = average;
        mostActiveDay = entry.key;
      }

      if (average < minAverage) {
        minAverage = average;
        leastActiveDay = entry.key;
      }
    }

    return WeeklyPattern(
      dayAverages: averages,
      mostActiveDay: mostActiveDay,
      leastActiveDay: leastActiveDay,
      weekendVsWeekdayRatio: _calculateWeekendRatio(averages),
    );
  }

  double _calculateWeekendRatio(Map<int, double> dayAverages) {
    final weekdayAverage = [1, 2, 3, 4, 5]
        .map((day) => dayAverages[day] ?? 0.0)
        .reduce((a, b) => a + b) / 5;

    final weekendAverage = [6, 7]
        .map((day) => dayAverages[day] ?? 0.0)
        .reduce((a, b) => a + b) / 2;

    return weekendAverage / (weekdayAverage == 0 ? 1 : weekdayAverage);
  }

  List<ActivityTrend> _identifyActivityTrends(List<EnhancedDailySummary> summaries) {
    // Implement trend analysis logic
    return [];
  }

  MoodDataPoint? _extractMoodFromSummary(EnhancedDailySummary summary) {
    // Extract mood information from AI-generated insights
    final insights = summary.aiInsights;
    if (insights.isEmpty) return null;

    // Combine all insights text for analysis
    final insightText = insights.toLowerCase();

    // Sentiment word lists with weights
    final positiveWords = {
      'happy': 0.8, 'excited': 0.9, 'great': 0.7, 'wonderful': 0.9, 'amazing': 0.9,
      'good': 0.6, 'excellent': 0.9, 'fantastic': 0.9, 'joy': 0.8, 'love': 0.8,
      'delightful': 0.8, 'pleasant': 0.7, 'satisfied': 0.7, 'accomplished': 0.8,
      'productive': 0.7, 'successful': 0.8, 'energetic': 0.7, 'grateful': 0.8,
    };

    final negativeWords = {
      'sad': 0.8, 'angry': 0.8, 'frustrated': 0.7, 'stressed': 0.7, 'anxious': 0.7,
      'worried': 0.6, 'upset': 0.7, 'difficult': 0.5, 'challenging': 0.5, 'hard': 0.4,
      'tired': 0.5, 'exhausted': 0.7, 'overwhelmed': 0.8, 'disappointed': 0.7,
      'lonely': 0.7, 'bad': 0.6, 'terrible': 0.9, 'awful': 0.9,
    };

    final neutralWords = {
      'normal': 0.5, 'routine': 0.5, 'typical': 0.5, 'regular': 0.5, 'average': 0.5,
    };

    // Calculate sentiment scores
    double positiveScore = 0.0;
    int positiveCount = 0;
    double negativeScore = 0.0;
    int negativeCount = 0;
    final List<String> triggers = [];

    // Analyze positive sentiment
    positiveWords.forEach((word, weight) {
      if (insightText.contains(word)) {
        positiveScore += weight;
        positiveCount++;
        triggers.add('+$word');
      }
    });

    // Analyze negative sentiment
    negativeWords.forEach((word, weight) {
      if (insightText.contains(word)) {
        negativeScore += weight;
        negativeCount++;
        triggers.add('-$word');
      }
    });

    // Check for neutral indicators
    bool hasNeutralIndicators = neutralWords.keys.any((word) => insightText.contains(word));

    // Calculate overall mood score (0.0 to 1.0)
    double finalScore = 0.5; // Default neutral
    String category = 'Neutral';
    double confidence = 0.5;

    if (positiveCount > 0 || negativeCount > 0) {
      // Calculate weighted score
      final totalWeight = positiveScore + negativeScore;
      if (totalWeight > 0) {
        finalScore = positiveScore / totalWeight;
      }

      // Determine category
      if (finalScore >= 0.7) {
        category = 'Positive';
        confidence = 0.7 + (finalScore - 0.7) * 0.3; // 0.7-1.0
      } else if (finalScore <= 0.3) {
        category = 'Negative';
        confidence = 0.7 + (0.3 - finalScore) * 0.3; // 0.7-1.0
      } else {
        category = 'Neutral';
        confidence = 0.6 - (finalScore - 0.5).abs() * 0.4; // 0.2-0.6
      }

      // Increase confidence based on number of sentiment indicators found
      final totalIndicators = positiveCount + negativeCount;
      confidence = (confidence + (totalIndicators * 0.05)).clamp(0.0, 1.0);
    } else if (hasNeutralIndicators) {
      confidence = 0.6;
    }

    // If very low confidence, return null (insufficient data)
    if (confidence < 0.3) return null;

    return MoodDataPoint(
      score: finalScore,
      category: category,
      triggers: triggers.take(5).toList(), // Limit to top 5 triggers
      confidence: confidence,
    );
  }

  TrendDirection _calculateMoodTrend(List<MapEntry<DateTime, MoodDataPoint>> moodData) {
    if (moodData.length < 2) return TrendDirection.stable;

    final scores = moodData.map((e) => e.value.score).toList();
    final firstHalf = scores.take(scores.length ~/ 2).toList();
    final secondHalf = scores.skip(scores.length ~/ 2).toList();

    final firstAverage = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAverage = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final difference = secondAverage - firstAverage;

    if (difference > 0.1) return TrendDirection.improving;
    if (difference < -0.1) return TrendDirection.declining;
    return TrendDirection.stable;
  }

  double _calculateAverageMoodScore(List<MapEntry<DateTime, MoodDataPoint>> moodData) {
    if (moodData.isEmpty) return 0.5;
    return moodData.map((e) => e.value.score).reduce((a, b) => a + b) / moodData.length;
  }

  Map<String, SeasonalPattern> _identifySeasonalMoodPatterns(
    List<MapEntry<DateTime, MoodDataPoint>> moodData,
  ) {
    // Group by season and analyze patterns
    return {};
  }

  List<MoodCorrelation> _findMoodCorrelations(List<EnhancedDailySummary> summaries) {
    // Analyze correlations between mood and activities, weather, etc.
    return [];
  }

  SocialInteractionData _extractSocialData(EnhancedDailySummary summary) {
    // Extract social interaction data from summary
    return SocialInteractionData(
      interactionCount: 0,
      averageGroupSize: 1,
      commonSettings: [],
      interactionQuality: 0.5,
    );
  }

  double _calculateAverageSocialInteractions(
    List<MapEntry<DateTime, SocialInteractionData>> socialData,
  ) {
    if (socialData.isEmpty) return 0.0;
    return socialData
        .map((e) => e.value.interactionCount.toDouble())
        .reduce((a, b) => a + b) / socialData.length;
  }

  List<SocialTrend> _identifySocialTrends(
    List<MapEntry<DateTime, SocialInteractionData>> socialData,
  ) {
    return [];
  }

  SocialPreferences _analyzeSocialPreferences(
    List<MapEntry<DateTime, SocialInteractionData>> socialData,
  ) {
    return SocialPreferences(
      preferredGroupSize: 2,
      preferredSettings: [],
      socialEnergyPattern: 'Moderate',
    );
  }

  LocationInsights _extractLocationData(EnhancedDailySummary summary) {
    return LocationInsights(
      visitedPlaces: [],
      movementPattern: 'Local',
      explorationScore: 0.5,
    );
  }

  List<LocationTrend> _identifyLocationTrends(
    List<MapEntry<DateTime, LocationInsights>> locationData,
  ) {
    return [];
  }

  HomeBaseAnalysis _analyzeHomeBase(
    List<MapEntry<DateTime, LocationInsights>> locationData,
  ) {
    return HomeBaseAnalysis(
      homeTimePercentage: 0.7,
      averageDistanceFromHome: 5.0,
      explorationRadius: 10.0,
    );
  }

  double _calculatePatternConfidence(int dataPoints) {
    if (dataPoints < 7) return 0.3; // Low confidence with less than a week
    if (dataPoints < 30) return 0.6; // Medium confidence with less than a month
    if (dataPoints < 90) return 0.8; // High confidence with 1-3 months
    return 0.9; // Very high confidence with 3+ months
  }

  List<String> _generateActivityInsights(
    Map<String, ActivityPattern> patterns,
    WeeklyPattern weeklyPatterns,
    List<ActivityTrend> trends,
  ) {
    final insights = <String>[];

    // Most common activity pattern
    final mostFrequent = patterns.values
        .reduce((a, b) => a.frequency > b.frequency ? a : b);
    insights.add('Your most frequent activity category is ${mostFrequent.category}');

    // Weekly pattern insights
    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    insights.add('You are most active on ${dayNames[weeklyPatterns.mostActiveDay]}');

    if (weeklyPatterns.weekendVsWeekdayRatio > 1.2) {
      insights.add('You tend to be more active on weekends');
    } else if (weeklyPatterns.weekendVsWeekdayRatio < 0.8) {
      insights.add('You tend to be more active on weekdays');
    }

    return insights;
  }

  List<String> _generateMoodInsights(
    List<MapEntry<DateTime, MoodDataPoint>> moodData,
    TrendDirection trendDirection,
    List<MoodCorrelation> correlations,
  ) {
    final insights = <String>[];

    switch (trendDirection) {
      case TrendDirection.improving:
        insights.add('Your mood has been trending upward recently');
        break;
      case TrendDirection.declining:
        insights.add('Your mood has been trending downward - consider self-care activities');
        break;
      case TrendDirection.stable:
        insights.add('Your mood has been relatively stable');
        break;
    }

    final averageScore = _calculateAverageMoodScore(moodData);
    if (averageScore > 0.7) {
      insights.add('You generally maintain a positive mood');
    } else if (averageScore < 0.4) {
      insights.add('You might benefit from focusing on mood-boosting activities');
    }

    return insights;
  }

  List<String> _generateSocialInsights(
    List<MapEntry<DateTime, SocialInteractionData>> socialData,
    List<SocialTrend> socialTrends,
    SocialPreferences socialPreferences,
  ) {
    final insights = <String>[];

    final averageInteractions = _calculateAverageSocialInteractions(socialData);
    if (averageInteractions > 3) {
      insights.add('You maintain an active social life');
    } else if (averageInteractions < 1) {
      insights.add('You prefer quieter, more solitary activities');
    }

    insights.add('Your preferred group size appears to be ${socialPreferences.preferredGroupSize}');

    return insights;
  }

  List<String> _generateLocationInsights(
    List<MapEntry<DateTime, LocationInsights>> locationData,
    List<LocationTrend> locationTrends,
    HomeBaseAnalysis homeBaseAnalysis,
  ) {
    final insights = <String>[];

    if (homeBaseAnalysis.homeTimePercentage > 0.8) {
      insights.add('You spend most of your time close to home');
    } else if (homeBaseAnalysis.homeTimePercentage < 0.5) {
      insights.add('You frequently explore areas away from home');
    }

    if (homeBaseAnalysis.explorationRadius > 20) {
      insights.add('You have a wide exploration radius and enjoy traveling');
    } else if (homeBaseAnalysis.explorationRadius < 5) {
      insights.add('You prefer to stay within familiar local areas');
    }

    return insights;
  }
}

// Data Models

