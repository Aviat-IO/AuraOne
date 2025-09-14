import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data_fusion/multi_modal_fusion_engine.dart';
import '../../providers/database_provider.dart';
import '../../models/collected_data.dart';

/// Daily pattern representation
class DailyPattern {
  final int hour;
  final ActivityType activity;
  final String? location;
  final double confidence;

  DailyPattern({
    required this.hour,
    required this.activity,
    this.location,
    required this.confidence,
  });
}

/// Personal daily narrative
class PersonalDailyNarrative {
  final String narrative;
  final List<String> emotionalInsights;
  final List<String> recommendations;
  final double wellnessScore;
  final Map<String, dynamic> activitySummary;
  final DateTime generatedAt;

  PersonalDailyNarrative({
    required this.narrative,
    required this.emotionalInsights,
    required this.recommendations,
    required this.wellnessScore,
    required this.activitySummary,
    required this.generatedAt,
  });
}

/// Personal Daily Context Engine
/// Generates natural language narratives from fused multi-modal data
/// with emotional insights and personalized recommendations
/// 100% ON-DEVICE PROCESSING - NO API CALLS
class PersonalContextEngine {
  final DatabaseService _databaseService;
  final MultiModalFusionEngine? _fusionEngine;

  // User patterns and preferences learned over time
  final Map<String, dynamic> _userPatterns = {};
  final Map<String, int> _activityFrequency = {};
  final Map<String, List<String>> _locationActivities = {};
  final List<DailyPattern> _dailyPatterns = [];

  // Emotional insights
  final Map<String, double> _emotionalTrends = {};
  DateTime? _lastAnalysisTime;

  PersonalContextEngine({
    required DatabaseService databaseService,
    MultiModalFusionEngine? fusionEngine,
  })  : _databaseService = databaseService,
        _fusionEngine = fusionEngine;

  /// Learn from historical user data
  Future<void> learnUserPatterns() async {
    try {
      // Get last 30 days of data
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final historicalData = await _databaseService.getDataByDateRange(
        startDate,
        endDate,
      );

      // Analyze activity patterns
      for (final data in historicalData) {
        if (data.type == 'fused_context' && data.data != null) {
          try {
            final fused = FusedDataPoint.fromJson(data.data!);

            // Track activity frequency
            final activityKey = fused.activity.toString();
            _activityFrequency[activityKey] =
                (_activityFrequency[activityKey] ?? 0) + 1;

            // Track location-activity associations
            if (fused.locationContext != null) {
              _locationActivities.putIfAbsent(
                fused.locationContext!,
                () => [],
              ).add(activityKey);
            }

            // Track time-based patterns
            final hour = fused.timestamp.hour;
            final pattern = DailyPattern(
              hour: hour,
              activity: fused.activity,
              location: fused.locationContext,
              confidence: fused.confidence,
            );
            _dailyPatterns.add(pattern);
          } catch (e) {
            debugPrint('Error parsing fused data: $e');
          }
        }
      }

      // Calculate emotional trends from photo analysis
      _calculateEmotionalTrends(historicalData);

      debugPrint('PersonalContextEngine: Learned patterns from ${historicalData.length} data points');
      debugPrint('Activity frequency: $_activityFrequency');
      debugPrint('Location patterns: ${_locationActivities.keys.length} locations');

    } catch (e) {
      debugPrint('PersonalContextEngine: Error learning patterns: $e');
    }
  }

  /// Calculate emotional trends from historical data
  void _calculateEmotionalTrends(List<CollectedData> data) {
    final Map<String, List<double>> emotionScores = {};

    for (final item in data) {
      if (item.type == 'fused_context' && item.data != null) {
        try {
          final fused = FusedDataPoint.fromJson(item.data!);

          // Analyze photo emotions (faces detected)
          for (final photo in fused.photos) {
            if (photo.faceCount > 0) {
              // More faces often indicate social activity (positive)
              emotionScores.putIfAbsent('social', () => [])
                  .add(photo.faceCount.toDouble() / 5.0);
            }

            // Outdoor photos often correlate with positive mood
            if (photo.labels.any((l) =>
                l.toLowerCase().contains('outdoor') ||
                l.toLowerCase().contains('nature') ||
                l.toLowerCase().contains('park'))) {
              emotionScores.putIfAbsent('outdoor', () => []).add(1.0);
            }
          }

          // Activity-based emotions
          switch (fused.activity) {
            case ActivityType.running:
            case ActivityType.cycling:
              emotionScores.putIfAbsent('active', () => []).add(1.0);
              break;
            case ActivityType.stationary:
              if (fused.locationContext == 'Home') {
                emotionScores.putIfAbsent('restful', () => []).add(0.8);
              }
              break;
            default:
              break;
          }
        } catch (e) {
          debugPrint('Error calculating emotions: $e');
        }
      }
    }

    // Calculate averages
    emotionScores.forEach((key, scores) {
      if (scores.isNotEmpty) {
        _emotionalTrends[key] =
            scores.reduce((a, b) => a + b) / scores.length;
      }
    });
  }

  /// Generate personalized daily narrative
  Future<PersonalDailyNarrative> generateNarrative({
    DateTime? date,
    bool includeRecommendations = true,
  }) async {
    date ??= DateTime.now();

    // Learn patterns if not done recently
    if (_lastAnalysisTime == null ||
        DateTime.now().difference(_lastAnalysisTime!).inDays > 1) {
      await learnUserPatterns();
      _lastAnalysisTime = DateTime.now();
    }

    // Get today's fused data
    final todayData = await _getTodaysFusedData(date);

    // Generate base narrative
    String narrative = await _generateBaseNarrative(todayData);

    // Add emotional insights
    final emotions = _generateEmotionalInsights(todayData);

    // Add personalized recommendations
    final recommendations = includeRecommendations
        ? _generateRecommendations(todayData)
        : <String>[];

    // Enhance narrative with on-device processing
    narrative = _enhanceNarrativeOnDevice(
      narrative,
      emotions,
      recommendations,
      todayData,
    );

    return PersonalDailyNarrative(
      narrative: narrative,
      emotionalInsights: emotions,
      recommendations: recommendations,
      activitySummary: _summarizeActivities(todayData),
      wellnessScore: _calculateWellnessScore(todayData),
      generatedAt: DateTime.now(),
    );
  }

  /// Get today's fused data points
  Future<List<FusedDataPoint>> _getTodaysFusedData(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final data = await _databaseService.getDataByDateRange(
      startOfDay,
      endOfDay,
    );

    final fusedPoints = <FusedDataPoint>[];
    for (final item in data) {
      if (item.type == 'fused_context' && item.data != null) {
        try {
          fusedPoints.add(FusedDataPoint.fromJson(item.data!));
        } catch (e) {
          debugPrint('Error parsing fused point: $e');
        }
      }
    }

    // Sort by timestamp
    fusedPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return fusedPoints;
  }

  /// Generate base narrative from fused data
  Future<String> _generateBaseNarrative(List<FusedDataPoint> data) async {
    if (data.isEmpty) {
      return "Today was a quiet day with minimal tracked activity. "
             "Consider enabling location and photo permissions for richer insights.";
    }

    final StringBuffer narrative = StringBuffer();
    narrative.writeln("Your Personal Day Story:\n");

    // Group by time periods
    final morning = data.where((d) => d.timestamp.hour < 12).toList();
    final afternoon = data.where((d) =>
        d.timestamp.hour >= 12 && d.timestamp.hour < 17).toList();
    final evening = data.where((d) => d.timestamp.hour >= 17).toList();

    // Morning narrative
    if (morning.isNotEmpty) {
      narrative.writeln(_generatePeriodNarrative("Morning", morning));
    }

    // Afternoon narrative
    if (afternoon.isNotEmpty) {
      narrative.writeln(_generatePeriodNarrative("Afternoon", afternoon));
    }

    // Evening narrative
    if (evening.isNotEmpty) {
      narrative.writeln(_generatePeriodNarrative("Evening", evening));
    }

    // Add personal touches based on patterns
    if (_activityFrequency.isNotEmpty) {
      final topActivity = _activityFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      narrative.writeln("\n📊 Pattern Insight: ${_getActivityName(topActivity.key)} "
          "continues to be your most frequent activity this month.");
    }

    return narrative.toString();
  }

  /// Generate narrative for a time period
  String _generatePeriodNarrative(String period, List<FusedDataPoint> data) {
    final StringBuffer narrative = StringBuffer();
    narrative.write("**$period:** ");

    // Group by location
    final locationGroups = <String, List<FusedDataPoint>>{};
    for (final point in data) {
      final location = point.locationContext ?? 'Unknown';
      locationGroups.putIfAbsent(location, () => []).add(point);
    }

    final descriptions = <String>[];
    locationGroups.forEach((location, points) {
      // Get dominant activity
      final activities = <ActivityType, int>{};
      for (final point in points) {
        activities[point.activity] = (activities[point.activity] ?? 0) + 1;
      }

      final dominantActivity = activities.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // Count photos
      final totalPhotos = points.fold<int>(
        0,
        (sum, p) => sum + p.photos.length,
      );

      // Build description
      String desc = "At $location, you were mostly ${_getActivityName(dominantActivity.toString())}";

      if (totalPhotos > 0) {
        // Get photo context
        final photoLabels = <String>{};
        final faceCount = points.fold<int>(
          0,
          (sum, p) => sum + p.photos.fold<int>(
            0,
            (s, photo) => s + photo.faceCount,
          ),
        );

        for (final point in points) {
          for (final photo in point.photos) {
            photoLabels.addAll(photo.labels);
          }
        }

        desc += " and captured $totalPhotos photo${totalPhotos > 1 ? 's' : ''}";

        if (faceCount > 0) {
          desc += " with $faceCount ${faceCount == 1 ? 'person' : 'people'}";
        }

        if (photoLabels.isNotEmpty) {
          final topLabels = photoLabels.take(3).join(', ');
          desc += " featuring $topLabels";
        }
      }

      descriptions.add(desc);
    });

    narrative.writeln(descriptions.join('. ') + '.');
    return narrative.toString();
  }

  /// Generate emotional insights
  List<String> _generateEmotionalInsights(List<FusedDataPoint> data) {
    final insights = <String>[];

    // Analyze social interaction
    final socialScore = data.fold<int>(
      0,
      (sum, p) => sum + p.photos.fold<int>(
        0,
        (s, photo) => s + photo.faceCount,
      ),
    );

    if (socialScore > 10) {
      insights.add("🤝 High social engagement today - great for emotional wellbeing!");
    } else if (socialScore > 0) {
      insights.add("👥 Some social interaction detected - human connection is valuable.");
    }

    // Analyze physical activity
    final activeMinutes = data.where((p) =>
        p.activity == ActivityType.walking ||
        p.activity == ActivityType.running ||
        p.activity == ActivityType.cycling
    ).length * 30 / 60; // Each data point represents ~30 seconds

    if (activeMinutes > 30) {
      insights.add("💪 Excellent physical activity - ${activeMinutes.round()} active minutes!");
    } else if (activeMinutes > 10) {
      insights.add("🚶 Good movement today - every step counts for your health.");
    }

    // Analyze variety of locations
    final uniqueLocations = data
        .map((p) => p.locationContext)
        .where((l) => l != null)
        .toSet()
        .length;

    if (uniqueLocations > 3) {
      insights.add("🗺️ Diverse day with ${uniqueLocations} different locations - variety enriches life!");
    }

    // Add trend-based insights
    if (_emotionalTrends.isNotEmpty) {
      final topEmotion = _emotionalTrends.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      if (topEmotion.value > 0.7) {
        insights.add("📈 Trending ${topEmotion.key} - ${_getEmotionMessage(topEmotion.key)}");
      }
    }

    return insights;
  }

  /// Generate personalized recommendations
  List<String> _generateRecommendations(List<FusedDataPoint> data) {
    final recommendations = <String>[];

    // Activity-based recommendations
    final todayActivities = data.map((p) => p.activity).toSet();

    if (!todayActivities.contains(ActivityType.walking) &&
        !todayActivities.contains(ActivityType.running)) {
      recommendations.add("🏃 Consider a short walk or jog tomorrow for physical wellness.");
    }

    // Social recommendations
    final socialInteraction = data.any((p) =>
        p.photos.any((photo) => photo.faceCount > 0));

    if (!socialInteraction) {
      recommendations.add("☕ Plan to meet a friend or family member - social connections boost happiness.");
    }

    // Location variety
    final locations = data
        .map((p) => p.locationContext)
        .where((l) => l != null)
        .toSet();

    if (locations.length <= 2) {
      recommendations.add("🌳 Explore a new place tomorrow - variety stimulates creativity.");
    }

    // Time-based recommendations
    final currentHour = DateTime.now().hour;
    if (currentHour >= 20 && currentHour <= 23) {
      recommendations.add("😴 Consider winding down for better sleep quality tonight.");
    }

    // Pattern-based recommendations
    if (_dailyPatterns.isNotEmpty) {
      final commonMorningActivity = _getMostCommonActivityForHour(7, 9);
      if (commonMorningActivity != null &&
          !todayActivities.contains(commonMorningActivity)) {
        recommendations.add("⏰ Tomorrow, try your usual morning ${_getActivityName(commonMorningActivity.toString())} routine.");
      }
    }

    return recommendations.take(3).toList(); // Limit to 3 recommendations
  }

  /// Enhance narrative with on-device processing
  String _enhanceNarrativeOnDevice(
    String baseNarrative,
    List<String> emotions,
    List<String> recommendations,
    List<FusedDataPoint> todayData,
  ) {
    final StringBuffer enhanced = StringBuffer();

    // Create a warm, personalized narrative using on-device templates
    enhanced.writeln(_generatePersonalizedGreeting(todayData));
    enhanced.writeln();

    // Add the base narrative with enhancements
    enhanced.writeln(baseNarrative);

    // Add emotional insights with warm language
    if (emotions.isNotEmpty) {
      enhanced.writeln("\n✨ Today's Insights:");
      for (final insight in emotions) {
        enhanced.writeln(insight);
      }
    }

    // Add recommendations with encouragement
    if (recommendations.isNotEmpty) {
      enhanced.writeln("\n💡 Gentle Suggestions for Tomorrow:");
      for (final rec in recommendations) {
        enhanced.writeln(rec);
      }
    }

    // Add closing encouragement
    enhanced.writeln();
    enhanced.writeln(_generateClosingEncouragement(todayData));

    return enhanced.toString();
  }

  /// Generate personalized greeting based on data
  String _generatePersonalizedGreeting(List<FusedDataPoint> data) {
    final wellnessScore = _calculateWellnessScore(data);

    if (wellnessScore >= 80) {
      return "🌟 What an incredible day you've had! Your wellness journey is truly inspiring.";
    } else if (wellnessScore >= 60) {
      return "☀️ You've had a wonderful day filled with meaningful moments.";
    } else if (wellnessScore >= 40) {
      return "🌱 Every step forward matters, and today you've made progress.";
    } else {
      return "🤗 Some days are quieter than others, and that's perfectly okay.";
    }
  }

  /// Generate closing encouragement
  String _generateClosingEncouragement(List<FusedDataPoint> data) {
    final hour = DateTime.now().hour;
    final wellnessScore = _calculateWellnessScore(data);

    if (hour >= 20) {
      return "Rest well tonight. Tomorrow brings new opportunities for growth and joy. 🌙";
    } else if (hour >= 16) {
      if (wellnessScore >= 60) {
        return "You're ending the day strong! Keep this positive momentum going. 💪";
      } else {
        return "There's still time today to add a small moment of joy. You've got this! ✨";
      }
    } else {
      return "Your day is unfolding beautifully. Keep embracing each moment. 🌈";
    }
  }

  /// Summarize activities for the day
  Map<String, dynamic> _summarizeActivities(List<FusedDataPoint> data) {
    final summary = <String, dynamic>{};

    // Count activities
    final activityCounts = <ActivityType, int>{};
    for (final point in data) {
      activityCounts[point.activity] =
          (activityCounts[point.activity] ?? 0) + 1;
    }

    // Convert to readable format
    activityCounts.forEach((activity, count) {
      final minutes = (count * 30 / 60).round(); // Each point ~30 seconds
      summary[_getActivityName(activity.toString())] = '$minutes minutes';
    });

    // Add photo summary
    final totalPhotos = data.fold<int>(
      0,
      (sum, p) => sum + p.photos.length,
    );
    summary['photos_captured'] = totalPhotos;

    // Add location summary
    final uniqueLocations = data
        .map((p) => p.locationContext)
        .where((l) => l != null)
        .toSet()
        .length;
    summary['locations_visited'] = uniqueLocations;

    return summary;
  }

  /// Calculate wellness score based on various factors
  double _calculateWellnessScore(List<FusedDataPoint> data) {
    double score = 50.0; // Base score

    // Physical activity bonus (up to +20)
    final activePoints = data.where((p) =>
        p.activity == ActivityType.walking ||
        p.activity == ActivityType.running ||
        p.activity == ActivityType.cycling
    ).length;
    score += min(20.0, activePoints * 2.0);

    // Social interaction bonus (up to +15)
    final socialScore = data.fold<int>(
      0,
      (sum, p) => sum + p.photos.fold<int>(
        0,
        (s, photo) => s + photo.faceCount,
      ),
    );
    score += min(15.0, socialScore * 1.5);

    // Location variety bonus (up to +10)
    final locations = data
        .map((p) => p.locationContext)
        .where((l) => l != null)
        .toSet()
        .length;
    score += min(10.0, locations * 3.0);

    // Photo memories bonus (up to +5)
    final photos = data.fold<int>(
      0,
      (sum, p) => sum + p.photos.length,
    );
    score += min(5.0, photos * 0.5);

    return min(100.0, score);
  }

  /// Get activity name from string
  String _getActivityName(String activity) {
    return activity
        .replaceAll('ActivityType.', '')
        .replaceAll('_', ' ')
        .toLowerCase();
  }

  /// Get emotion message
  String _getEmotionMessage(String emotion) {
    switch (emotion) {
      case 'social':
        return 'your social connections are enriching your life';
      case 'active':
        return 'your physical activity is boosting your energy';
      case 'outdoor':
        return 'time in nature is refreshing your mind';
      case 'restful':
        return 'you\'re finding good moments to recharge';
      default:
        return 'you\'re maintaining positive patterns';
    }
  }

  /// Get most common activity for hour range
  ActivityType? _getMostCommonActivityForHour(int startHour, int endHour) {
    final relevantPatterns = _dailyPatterns.where((p) =>
        p.hour >= startHour && p.hour <= endHour
    ).toList();

    if (relevantPatterns.isEmpty) return null;

    final activityCounts = <ActivityType, int>{};
    for (final pattern in relevantPatterns) {
      activityCounts[pattern.activity] =
          (activityCounts[pattern.activity] ?? 0) + 1;
    }

    return activityCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}