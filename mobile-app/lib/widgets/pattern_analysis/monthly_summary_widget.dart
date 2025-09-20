import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../providers/pattern_analysis_provider.dart';
import '../../services/pattern_analyzer.dart';
import '../../models/pattern_analysis_models.dart' as models;
import '../../utils/time_utils.dart';

class MonthlySummaryWidget extends HookConsumerWidget {
  final DateTime monthStart;
  final VoidCallback? onTapDetailed;

  const MonthlySummaryWidget({
    super.key,
    required this.monthStart,
    this.onTapDetailed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

    final comprehensiveInsightsAsync = ref.watch(comprehensivePatternInsightsProvider(monthStart));

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, monthStart, monthEnd),
            const SizedBox(height: 16),
            comprehensiveInsightsAsync.when(
              loading: () => _buildLoadingSkeleton(theme),
              error: (error, stack) => _buildErrorWidget(theme, error),
              data: (insights) => _buildComprehensiveInsights(theme, insights),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, DateTime monthStart, DateTime monthEnd) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.calendar_month,
            color: theme.colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Overview',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                TimeUtils.formatMonthYear(monthStart),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        if (onTapDetailed != null)
          FilledButton.icon(
            onPressed: onTapDetailed,
            icon: const Icon(Icons.analytics, size: 18),
            label: const Text('Details'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Skeletonizer(
      child: Column(
        children: [
          _buildOverviewCards(theme, isLoading: true),
          const SizedBox(height: 16),
          _buildTrendSection(theme, isLoading: true),
          const SizedBox(height: 16),
          _buildInsightsSection(theme, isLoading: true),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, Object error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load monthly summary',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprehensiveInsights(ThemeData theme, ComprehensivePatternInsights insights) {
    if (!insights.hasValidData) {
      return _buildEmptyState(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewCards(theme, insights: insights),
        const SizedBox(height: 16),
        _buildTrendSection(theme, insights: insights),
        const SizedBox(height: 16),
        _buildPatternBreakdown(theme, insights),
        const SizedBox(height: 16),
        _buildConfidenceIndicator(theme, insights.overallConfidence),
        if (insights.keyInsights.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInsightsSection(theme, insights: insights),
        ],
        if (insights.recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildRecommendationsSection(theme, insights.recommendations),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Not enough data yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep logging your activities to see comprehensive monthly insights',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(ThemeData theme, {ComprehensivePatternInsights? insights, bool isLoading = false}) {
    final activityCount = insights?.activityPatterns.patterns.values.fold<int>(0, (sum, p) => sum + p.frequency) ?? 0;
    final avgMoodScore = insights?.moodTrends.averageMoodScore ?? 0.5;
    final socialInteractions = insights?.socialPatterns.averageSocialInteractions ?? 0.0;
    final explorationScore = insights?.locationPatterns.homeBaseAnalysis.explorationRadius ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            theme,
            'Activities',
            activityCount.toString(),
            Icons.event,
            theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOverviewCard(
            theme,
            'Mood Score',
            '${(avgMoodScore * 100).round()}%',
            Icons.mood,
            _getMoodColor(avgMoodScore),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOverviewCard(
            theme,
            'Social',
            socialInteractions.toStringAsFixed(1),
            Icons.people,
            theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOverviewCard(
            theme,
            'Exploration',
            '${(explorationScore * 100).round()}%',
            Icons.explore,
            theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(ThemeData theme, {ComprehensivePatternInsights? insights, bool isLoading = false}) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTrendIndicator(theme, 'Mood', models.TrendDirection.stable)),
                const SizedBox(width: 16),
                Expanded(child: _buildTrendIndicator(theme, 'Activity', models.TrendDirection.stable)),
              ],
            ),
          ],
        ),
      );
    }

    if (insights == null) return const SizedBox.shrink();

    return Container(
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
                Icons.trending_up,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Trends',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTrendIndicator(
                  theme,
                  'Mood',
                  insights.moodTrends.trendDirection,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTrendIndicator(
                  theme,
                  'Social',
                  _calculateSocialTrend(insights.socialPatterns),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(ThemeData theme, String label, models.TrendDirection direction) {
    final (icon, color, text) = _getTrendInfo(direction, theme);

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: $text',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternBreakdown(ThemeData theme, ComprehensivePatternInsights insights) {
    final topActivityCategory = insights.activityPatterns.patterns.isNotEmpty
        ? insights.activityPatterns.patterns.values.reduce((a, b) => a.frequency > b.frequency ? a : b)
        : null;

    final preferredGroupSize = insights.socialPatterns.preferences.preferredGroupSize;
    final homeTimePercentage = insights.locationPatterns.homeBaseAnalysis.homeTimePercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pattern Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topActivityCategory != null)
            _buildPatternItem(
              theme,
              'Most Frequent Activity',
              topActivityCategory.category,
              '${topActivityCategory.frequency} times',
              _getCategoryIcon(topActivityCategory.category),
            ),
          const SizedBox(height: 12),
          _buildPatternItem(
            theme,
            'Preferred Group Size',
            preferredGroupSize.toString(),
            preferredGroupSize == 1 ? 'Solo activities' : 'Group activities',
            Icons.people,
          ),
          const SizedBox(height: 12),
          _buildPatternItem(
            theme,
            'Home Time',
            '${(homeTimePercentage * 100).round()}%',
            homeTimePercentage > 0.7 ? 'Homebody' : 'Explorer',
            Icons.home,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(ThemeData theme, String label, String value, String description, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator(ThemeData theme, double confidence) {
    final confidenceLevel = _getConfidenceLevel(confidence);
    final color = _getConfidenceColor(confidence);

    return LinearPercentIndicator(
      lineHeight: 8,
      percent: confidence.clamp(0.0, 1.0),
      backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
      progressColor: color,
      barRadius: const Radius.circular(4),
      trailing: Text(
        'Analysis Quality: $confidenceLevel',
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInsightsSection(ThemeData theme, {ComprehensivePatternInsights? insights, bool isLoading = false}) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '• Loading insights...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    if (insights?.keyInsights.isEmpty ?? true) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: theme.colorScheme.onSecondaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Key Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights!.keyInsights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSecondaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme, List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.recommend,
                color: theme.colorScheme.onTertiaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.take(3).map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Helper methods

  Color _getMoodColor(double moodScore) {
    if (moodScore >= 0.7) return Colors.green;
    if (moodScore >= 0.5) return Colors.orange;
    return Colors.red;
  }

  (IconData, Color, String) _getTrendInfo(models.TrendDirection direction, ThemeData theme) {
    switch (direction) {
      case models.TrendDirection.improving:
        return (Icons.trending_up, Colors.green, 'Improving');
      case models.TrendDirection.declining:
        return (Icons.trending_down, Colors.red, 'Declining');
      case models.TrendDirection.stable:
        return (Icons.trending_flat, theme.colorScheme.outline, 'Stable');
    }
  }

  models.TrendDirection _calculateSocialTrend(models.SocialPatternAnalysis socialAnalysis) {
    // Simple heuristic based on social interactions
    if (socialAnalysis.averageSocialInteractions > 3) {
      return models.TrendDirection.improving;
    } else if (socialAnalysis.averageSocialInteractions < 1) {
      return models.TrendDirection.declining;
    }
    return models.TrendDirection.stable;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'physical':
        return Icons.fitness_center;
      case 'work':
        return Icons.work;
      case 'social':
        return Icons.people;
      case 'creative':
        return Icons.palette;
      case 'wellness':
        return Icons.spa;
      default:
        return Icons.category;
    }
  }

  String _getConfidenceLevel(double confidence) {
    if (confidence >= 0.8) return 'Excellent';
    if (confidence >= 0.6) return 'Good';
    if (confidence >= 0.4) return 'Moderate';
    if (confidence >= 0.2) return 'Limited';
    return 'Minimal';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.lightGreen;
    if (confidence >= 0.4) return Colors.orange;
    if (confidence >= 0.2) return Colors.deepOrange;
    return Colors.red;
  }
}