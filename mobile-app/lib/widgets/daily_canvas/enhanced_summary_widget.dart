import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../database/journal_database.dart';
import '../../database/media_database.dart';
import '../../database/location_database.dart';
import '../../providers/data_activity_tracker.dart';
import '../../services/journal_service.dart';
import '../../services/daily_context_synthesizer.dart';
import '../../services/ai_journal_generator.dart' as ai_gen;
import '../../services/ai_confidence_manager.dart';
import 'timeline_widget.dart';

// Provider for enhanced AI-powered daily summary
final enhancedDailySummaryProvider = FutureProvider.family<EnhancedDailySummary, DateTime>((ref, date) async {
  try {
    // Get basic journal data
    final journalDb = ref.watch(journalDatabaseProvider);
    final activities = await journalDb.getActivitiesForDate(date);

    // Get journal entry
    final journalService = ref.watch(journalServiceProvider);
    final journalEntry = await journalService.getEntryForDate(date);

    // Get databases for AI analysis
    final mediaDatabase = MediaDatabase();
    final locationDatabase = LocationDatabase();

    // Get activities from tracker
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final dataActivities = ref.read(dataActivityTrackerProvider.notifier).getActivitiesInRange(startOfDay, endOfDay);

    // Synthesize daily context using AI pipeline
    final synthesizer = DailyContextSynthesizer();
    final dailyContext = await synthesizer.synthesizeDailyContext(
      date: date,
      mediaDatabase: mediaDatabase,
      locationDatabase: locationDatabase,
      activities: dataActivities,
      enabledCalendarIds: {}, // TODO: Get from calendar settings
    );

    // Generate AI journal entry
    final journalGenerator = ai_gen.AIJournalGenerator();
    final aiJournalEntry = await journalGenerator.generateJournalEntry(dailyContext);

    // Analyze confidence and apply fallbacks
    final confidenceManager = AIConfidenceManager();
    final confidenceAnalysis = await confidenceManager.analyzeConfidence(
      photoContexts: dailyContext.photoContexts,
      dailyContext: dailyContext,
      journalEntry: aiJournalEntry,
    );

    // Create enhanced journal entry with confidence scoring and fallbacks
    final enhancedJournalEntry = await confidenceManager.createEnhancedJournalEntry(
      dailyContext: dailyContext,
      originalEntry: aiJournalEntry,
      confidenceAnalysis: confidenceAnalysis,
    );

    return EnhancedDailySummary.fromContextAndActivities(
      activities,
      journalEntry,
      date,
      dailyContext,
      enhancedJournalEntry,
      confidenceAnalysis,
    );
  } catch (e) {
    debugPrint('Error creating enhanced daily summary: $e');

    // Fallback to basic summary
    final journalDb = ref.watch(journalDatabaseProvider);
    final activities = await journalDb.getActivitiesForDate(date);
    final journalService = ref.watch(journalServiceProvider);
    final journalEntry = await journalService.getEntryForDate(date);

    return EnhancedDailySummary.fallback(activities, journalEntry, date);
  }
});

class EnhancedDailySummary {
  final DateTime date;
  final int totalEvents;
  final Map<EventType, int> eventCounts;
  final Map<String, int> activityTypeCounts;
  final List<String> topLocations;
  final int photoCount;
  final int calendarEventCount;
  final int movementMinutes;
  final String? journalWordCount;
  final String? aiSummary;
  final TimeOfDay? firstActivity;
  final TimeOfDay? lastActivity;

  // Enhanced AI insights
  final String? aiNarrative;
  final List<String> aiInsights;
  final List<String> aiHighlights;
  final String aiMood;
  final List<String> aiTags;
  final double aiConfidence;
  final Map<String, dynamic> aiMetadata;
  final bool hasAIAnalysis;

  // Enhanced confidence analysis
  final ConfidenceAnalysis? confidenceAnalysis;
  final bool hasConfidenceAnalysis;
  final List<String> qualityIndicators;
  final List<String> improvementSuggestions;

  // Context analysis
  final int socialScore;
  final String environmentalContext;
  final String activityPattern;

  EnhancedDailySummary({
    required this.date,
    required this.totalEvents,
    required this.eventCounts,
    required this.activityTypeCounts,
    required this.topLocations,
    required this.photoCount,
    required this.calendarEventCount,
    required this.movementMinutes,
    this.journalWordCount,
    this.aiSummary,
    this.firstActivity,
    this.lastActivity,
    this.aiNarrative,
    this.aiInsights = const [],
    this.aiHighlights = const [],
    this.aiMood = 'neutral',
    this.aiTags = const [],
    this.aiConfidence = 0.0,
    this.aiMetadata = const {},
    this.hasAIAnalysis = false,
    this.confidenceAnalysis,
    this.hasConfidenceAnalysis = false,
    this.qualityIndicators = const [],
    this.improvementSuggestions = const [],
    this.socialScore = 0,
    this.environmentalContext = '',
    this.activityPattern = '',
  });

  factory EnhancedDailySummary.fromContextAndActivities(
    List<JournalActivity> activities,
    JournalEntry? journalEntry,
    DateTime date,
    DailyContext dailyContext,
    ai_gen.JournalEntry aiJournalEntry,
    ConfidenceAnalysis? confidenceAnalysis,
  ) {
    // Basic summary calculation (reuse from original)
    final eventCounts = <EventType, int>{};
    final activityTypeCounts = <String, int>{};
    final locations = <String>[];
    var photoCount = 0;
    var calendarEventCount = 0;
    var movementMinutes = 0;

    DateTime? firstTime;
    DateTime? lastTime;

    for (final activity in activities) {
      if (firstTime == null || activity.timestamp.isBefore(firstTime)) {
        firstTime = activity.timestamp;
      }
      if (lastTime == null || activity.timestamp.isAfter(lastTime)) {
        lastTime = activity.timestamp;
      }

      activityTypeCounts[activity.activityType] =
          (activityTypeCounts[activity.activityType] ?? 0) + 1;

      EventType eventType;
      switch (activity.activityType) {
        case 'location':
          eventType = EventType.routine;
          if (activity.metadata != null) {
            try {
              final metadata = jsonDecode(activity.metadata!);
              if (metadata['location'] != null) {
                locations.add(metadata['location']);
              }
            } catch (_) {}
          }
          break;
        case 'photo':
          eventType = EventType.leisure;
          photoCount++;
          break;
        case 'movement':
          eventType = EventType.exercise;
          if (activity.metadata != null) {
            try {
              final metadata = jsonDecode(activity.metadata!);
              if (metadata['duration'] != null) {
                final duration = metadata['duration'].toString();
                final minutes = _parseDurationMinutes(duration);
                movementMinutes += minutes;
              }
            } catch (_) {}
          }
          break;
        case 'calendar':
          eventType = EventType.work;
          calendarEventCount++;
          break;
        case 'manual':
          eventType = EventType.routine;
          break;
        default:
          eventType = EventType.routine;
      }

      eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;
    }

    final locationCounts = <String, int>{};
    for (final location in locations) {
      locationCounts[location] = (locationCounts[location] ?? 0) + 1;
    }
    final sortedLocations = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topLocations = sortedLocations.take(3).map((e) => e.key).toList();

    // Enhanced AI analysis
    final totalPeople = dailyContext.photoContexts.fold(0, (sum, photo) => sum + photo.faceCount);
    final environments = dailyContext.photoContexts
        .expand((photo) => photo.sceneLabels)
        .toSet()
        .join(', ');

    String activityPattern;
    if (dailyContext.photoContexts.length > 10) {
      activityPattern = 'Highly Active';
    } else if (dailyContext.photoContexts.length > 5) {
      activityPattern = 'Moderately Active';
    } else if (dailyContext.calendarEvents.length > 3) {
      activityPattern = 'Scheduled';
    } else {
      activityPattern = 'Relaxed';
    }

    return EnhancedDailySummary(
      date: date,
      totalEvents: activities.length,
      eventCounts: eventCounts,
      activityTypeCounts: activityTypeCounts,
      topLocations: topLocations,
      photoCount: photoCount,
      calendarEventCount: calendarEventCount,
      movementMinutes: movementMinutes,
      journalWordCount: journalEntry?.content.split(' ').length.toString(),
      aiSummary: journalEntry?.summary,
      firstActivity: firstTime != null ? TimeOfDay.fromDateTime(firstTime) : null,
      lastActivity: lastTime != null ? TimeOfDay.fromDateTime(lastTime) : null,

      // AI enhancements
      aiNarrative: aiJournalEntry.narrative,
      aiInsights: aiJournalEntry.insights,
      aiHighlights: aiJournalEntry.highlights,
      aiMood: aiJournalEntry.mood,
      aiTags: aiJournalEntry.tags,
      aiConfidence: aiJournalEntry.confidence,
      aiMetadata: aiJournalEntry.metadata,
      hasAIAnalysis: true,

      // Enhanced confidence analysis
      confidenceAnalysis: confidenceAnalysis,
      hasConfidenceAnalysis: confidenceAnalysis != null,
      qualityIndicators: confidenceAnalysis?.qualityIndicators ?? [],
      improvementSuggestions: confidenceAnalysis?.improvementSuggestions ?? [],

      socialScore: totalPeople,
      environmentalContext: environments.isEmpty ? 'Indoor spaces' : environments,
      activityPattern: activityPattern,
    );
  }

  factory EnhancedDailySummary.fallback(
    List<JournalActivity> activities,
    JournalEntry? journalEntry,
    DateTime date,
  ) {
    // Basic summary without AI enhancements
    final eventCounts = <EventType, int>{};
    final activityTypeCounts = <String, int>{};
    var photoCount = 0;
    var calendarEventCount = 0;
    var movementMinutes = 0;

    DateTime? firstTime;
    DateTime? lastTime;

    for (final activity in activities) {
      if (firstTime == null || activity.timestamp.isBefore(firstTime)) {
        firstTime = activity.timestamp;
      }
      if (lastTime == null || activity.timestamp.isAfter(lastTime)) {
        lastTime = activity.timestamp;
      }

      activityTypeCounts[activity.activityType] =
          (activityTypeCounts[activity.activityType] ?? 0) + 1;

      EventType eventType;
      switch (activity.activityType) {
        case 'location':
          eventType = EventType.routine;
          break;
        case 'photo':
          eventType = EventType.leisure;
          photoCount++;
          break;
        case 'movement':
          eventType = EventType.exercise;
          break;
        case 'calendar':
          eventType = EventType.work;
          calendarEventCount++;
          break;
        default:
          eventType = EventType.routine;
      }

      eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;
    }

    return EnhancedDailySummary(
      date: date,
      totalEvents: activities.length,
      eventCounts: eventCounts,
      activityTypeCounts: activityTypeCounts,
      topLocations: [],
      photoCount: photoCount,
      calendarEventCount: calendarEventCount,
      movementMinutes: movementMinutes,
      journalWordCount: journalEntry?.content.split(' ').length.toString(),
      aiSummary: journalEntry?.summary,
      firstActivity: firstTime != null ? TimeOfDay.fromDateTime(firstTime) : null,
      lastActivity: lastTime != null ? TimeOfDay.fromDateTime(lastTime) : null,
      hasAIAnalysis: false,
      hasConfidenceAnalysis: false,
      environmentalContext: 'Data not available',
      activityPattern: 'Unknown',
    );
  }

  static int _parseDurationMinutes(String duration) {
    if (duration.contains('hour')) {
      final hours = double.tryParse(duration.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      return (hours * 60).round();
    } else if (duration.contains('min')) {
      return int.tryParse(duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return 0;
  }

  /// Get confidence level as text
  String get confidenceLevel {
    if (hasConfidenceAnalysis && confidenceAnalysis != null) {
      return confidenceAnalysis!.overallLevel.label;
    }
    // Fallback to simple confidence scoring
    if (aiConfidence > 0.8) return 'High';
    if (aiConfidence > 0.6) return 'Good';
    if (aiConfidence > 0.4) return 'Fair';
    return 'Low';
  }

  /// Get confidence color
  Color get confidenceColor {
    if (hasConfidenceAnalysis && confidenceAnalysis != null) {
      return confidenceAnalysis!.overallLevel.color;
    }
    // Fallback to simple confidence coloring
    if (aiConfidence > 0.8) return Colors.green;
    if (aiConfidence > 0.6) return Colors.blue;
    if (aiConfidence > 0.4) return Colors.orange;
    return Colors.red;
  }

  /// Get detailed confidence description
  String get confidenceDescription {
    if (hasConfidenceAnalysis && confidenceAnalysis != null) {
      return confidenceAnalysis!.qualityDescription;
    }
    return 'AI analysis quality: $confidenceLevel';
  }
}

class EnhancedSummaryWidget extends ConsumerWidget {
  final DateTime date;

  const EnhancedSummaryWidget({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(enhancedDailySummaryProvider(date));

    return summaryAsync.when(
      data: (summary) => _buildSummaryContent(context, theme, summary),
      loading: () => _buildLoadingSkeleton(theme),
      error: (error, stack) => _buildErrorState(theme, error),
    );
  }

  Widget _buildSummaryContent(BuildContext context, ThemeData theme, EnhancedDailySummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-Generated Narrative (if available)
          if (summary.hasAIAnalysis && summary.aiNarrative != null)
            _buildAINarrativeCard(theme, summary),

          if (summary.hasAIAnalysis && summary.aiNarrative != null)
            const SizedBox(height: 16),

          // Quick Stats Overview
          _buildQuickStatsCard(theme, summary),
          const SizedBox(height: 16),

          // AI Insights & Highlights (if available)
          if (summary.hasAIAnalysis) ...[
            _buildAIInsightsCard(theme, summary),
            const SizedBox(height: 16),
          ],

          // Activity Pattern & Mood
          if (summary.hasAIAnalysis) ...[
            _buildMoodAndPatternCard(theme, summary),
            const SizedBox(height: 16),
          ],

          // Traditional Activity Breakdown
          _buildActivityBreakdownCard(theme, summary),
          const SizedBox(height: 16),

          // Timeline Stats
          _buildTimelineStatsCard(context, theme, summary),
          const SizedBox(height: 16),

          // Pattern Insights Navigation
          _buildPatternInsightsCard(context, theme),

          // Basic AI Summary (fallback)
          if (!summary.hasAIAnalysis && summary.aiSummary != null && summary.aiSummary!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildBasicAISummaryCard(theme, summary),
          ],
        ],
      ),
    );
  }

  Widget _buildAINarrativeCard(ThemeData theme, EnhancedDailySummary summary) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Journal Entry',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: summary.confidenceColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${summary.confidenceLevel} Confidence',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: summary.confidenceColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (summary.hasConfidenceAnalysis && summary.confidenceAnalysis!.shouldShowWarning)
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              summary.aiNarrative!,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            if (summary.aiTags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.aiTags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard(ThemeData theme, EnhancedDailySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Daily Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Enhanced stats grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Events',
                    summary.totalEvents.toString(),
                    Icons.timeline,
                    theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Photos',
                    summary.photoCount.toString(),
                    Icons.photo_camera,
                    Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    summary.hasAIAnalysis ? 'Social' : 'Calendar',
                    summary.hasAIAnalysis
                        ? '${summary.socialScore} people'
                        : summary.calendarEventCount.toString(),
                    summary.hasAIAnalysis ? Icons.people : Icons.event,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Movement',
                    '${summary.movementMinutes}m',
                    Icons.directions_walk,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightsCard(ThemeData theme, EnhancedDailySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AI Insights & Highlights',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Insights
            if (summary.aiInsights.isNotEmpty) ...[
              Text(
                'Key Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              ...summary.aiInsights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],

            // Highlights
            if (summary.aiHighlights.isNotEmpty) ...[
              if (summary.aiInsights.isNotEmpty) const SizedBox(height: 20),
              Text(
                'Day Highlights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),
              ...summary.aiHighlights.take(3).map((highlight) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  highlight,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoodAndPatternCard(ThemeData theme, EnhancedDailySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Mood & Activity Pattern',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildMoodIndicator(theme, summary.aiMood),
                ),
                Expanded(
                  child: _buildPatternIndicator(theme, summary.activityPattern),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildEnvironmentContext(theme, summary.environmentalContext),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodIndicator(ThemeData theme, String mood) {
    Color moodColor;
    IconData moodIcon;

    switch (mood.toLowerCase()) {
      case 'energetic':
        moodColor = Colors.orange;
        moodIcon = Icons.bolt;
        break;
      case 'peaceful':
        moodColor = Colors.blue;
        moodIcon = Icons.spa;
        break;
      case 'accomplished':
        moodColor = Colors.green;
        moodIcon = Icons.check_circle;
        break;
      case 'reflective':
        moodColor = Colors.purple;
        moodIcon = Icons.self_improvement;
        break;
      case 'connected':
        moodColor = Colors.pink;
        moodIcon = Icons.favorite;
        break;
      default:
        moodColor = Colors.grey;
        moodIcon = Icons.sentiment_neutral;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: moodColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: moodColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(moodIcon, color: moodColor, size: 32),
          const SizedBox(height: 8),
          Text(
            mood.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: moodColor,
            ),
          ),
          Text(
            'Mood',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternIndicator(ThemeData theme, String pattern) {
    Color patternColor;
    IconData patternIcon;

    switch (pattern.toLowerCase()) {
      case 'highly active':
        patternColor = Colors.red;
        patternIcon = Icons.trending_up;
        break;
      case 'moderately active':
        patternColor = Colors.orange;
        patternIcon = Icons.timeline;
        break;
      case 'scheduled':
        patternColor = Colors.blue;
        patternIcon = Icons.schedule;
        break;
      case 'relaxed':
        patternColor = Colors.green;
        patternIcon = Icons.nature;
        break;
      default:
        patternColor = Colors.grey;
        patternIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: patternColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: patternColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(patternIcon, color: patternColor, size: 32),
          const SizedBox(height: 8),
          Text(
            pattern.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: patternColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Pattern',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentContext(ThemeData theme, String context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.place,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Environmental Context',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBreakdownCard(ThemeData theme, EnhancedDailySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Activity Breakdown',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (summary.eventCounts.isEmpty)
              Text(
                'No activities recorded for this day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            else
              ...summary.eventCounts.entries.map((entry) {
                final percentage = summary.totalEvents > 0
                    ? entry.value / summary.totalEvents
                    : 0.0;
                final color = _getEventTypeColor(entry.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getEventTypeDisplayName(entry.key),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${entry.value} (${(percentage * 100).round()}%)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearPercentIndicator(
                        lineHeight: 6,
                        percent: percentage,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        progressColor: color,
                        barRadius: const Radius.circular(3),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStatsCard(BuildContext context, ThemeData theme, EnhancedDailySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Timeline Stats',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (summary.firstActivity != null && summary.lastActivity != null) ...[
              _buildTimeRangeItem(
                theme,
                'Active Period',
                '${summary.firstActivity!.format(context)} - ${summary.lastActivity!.format(context)}',
                Icons.access_time,
              ),
              const SizedBox(height: 16),
            ],

            if (summary.topLocations.isNotEmpty) ...[
              _buildListItem(
                theme,
                'Top Locations',
                summary.topLocations.take(3).join(', '),
                Icons.location_on,
              ),
              const SizedBox(height: 16),
            ],

            if (summary.journalWordCount != null) ...[
              _buildListItem(
                theme,
                'Journal Words',
                summary.journalWordCount!,
                Icons.edit_note,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicAISummaryCard(ThemeData theme, EnhancedDailySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Basic AI Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              summary.aiSummary!,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeItem(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // AI Narrative skeleton
            Card(
              child: Container(
                height: 200,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),

            // Quick stats skeleton
            Card(
              child: Container(
                height: 150,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),

            // Insights skeleton
            Card(
              child: Container(
                height: 180,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),

            // Pattern skeleton
            Card(
              child: Container(
                height: 120,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),

            // Confidence skeleton
            Card(
              child: Container(
                height: 140,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading enhanced summary',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.routine:
        return Colors.blue;
      case EventType.work:
        return Colors.orange;
      case EventType.movement:
        return Colors.green;
      case EventType.social:
        return Colors.purple;
      case EventType.exercise:
        return Colors.red;
      case EventType.leisure:
        return Colors.teal;
    }
  }

  // Unused: Future feature for confidence analysis display
  /* Widget _buildConfidenceAnalysisCard(ThemeData theme, EnhancedDailySummary summary) {
    final confidenceAnalysis = summary.confidenceAnalysis!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: confidenceAnalysis.overallLevel.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: confidenceAnalysis.overallLevel.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Analysis Quality',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        confidenceAnalysis.qualityDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: confidenceAnalysis.overallLevel.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: confidenceAnalysis.overallLevel.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${(confidenceAnalysis.overallScore * 100).round()}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: confidenceAnalysis.overallLevel.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quality indicators
            if (confidenceAnalysis.qualityIndicators.isNotEmpty) ...[
              Text(
                'Quality Indicators',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: confidenceAnalysis.qualityIndicators.map((indicator) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        indicator,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],

            // Improvement suggestions
            if (confidenceAnalysis.improvementSuggestions.isNotEmpty) ...[
              if (confidenceAnalysis.qualityIndicators.isNotEmpty) const SizedBox(height: 16),
              Text(
                'Improvement Tips',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              ...confidenceAnalysis.improvementSuggestions.take(2).map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],

            // Component breakdown (warning if needed)
            if (confidenceAnalysis.shouldShowWarning) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Analysis quality is limited. Consider the improvement tips above for richer insights.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  } */

  Widget _buildPatternInsightsCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/pattern-insights'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: theme.colorScheme.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pattern Insights',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Discover weekly & monthly patterns',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: theme.colorScheme.outline,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_view_week,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Weekly',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: theme.colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monthly',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: theme.colorScheme.tertiary,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trends',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEventTypeDisplayName(EventType type) {
    switch (type) {
      case EventType.routine:
        return 'Routine';
      case EventType.work:
        return 'Work';
      case EventType.movement:
        return 'Movement';
      case EventType.social:
        return 'Social';
      case EventType.exercise:
        return 'Exercise';
      case EventType.leisure:
        return 'Leisure';
    }
  }
}