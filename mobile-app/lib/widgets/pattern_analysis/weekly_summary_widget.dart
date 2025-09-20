import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../providers/pattern_analysis_provider.dart';
import '../../services/pattern_analyzer.dart';
import '../../models/pattern_analysis_models.dart' as models;
import '../../utils/time_utils.dart';

class WeeklySummaryWidget extends HookConsumerWidget {
  final DateTime weekStart;
  final VoidCallback? onTapInsights;

  const WeeklySummaryWidget({
    super.key,
    required this.weekStart,
    this.onTapInsights,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final activityPatternsAsync = ref.watch(weeklyActivityPatternsProvider(weekStart));

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Summary',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${TimeUtils.formatDate(weekStart)} - ${TimeUtils.formatDate(weekEnd)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTapInsights != null)
                  IconButton(
                    onPressed: onTapInsights,
                    icon: const Icon(Icons.insights),
                    tooltip: 'View Detailed Insights',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            activityPatternsAsync.when(
              loading: () => _buildLoadingSkeleton(theme),
              error: (error, stack) => _buildErrorWidget(theme, error),
              data: (analysis) => _buildAnalysisContent(theme, analysis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Skeletonizer(
      child: Column(
        children: [
          _buildStatRow(
            'Total Activities',
            '25',
            theme,
            Icons.event,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Most Active Day',
            'Wednesday',
            theme,
            Icons.today,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Activity Category',
            'Physical',
            theme,
            Icons.fitness_center,
          ),
          const SizedBox(height: 16),
          _buildProgressIndicator(
            'Week Progress',
            0.7,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unable to load weekly summary',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent(ThemeData theme, models.ActivityPatternAnalysis analysis) {
    if (analysis.patterns.isEmpty) {
      return _buildEmptyState(theme);
    }

    final totalActivities = analysis.patterns.values.fold<int>(
      0,
      (sum, pattern) => sum + pattern.frequency,
    );

    final mostFrequentPattern = analysis.patterns.values.reduce(
      (a, b) => a.frequency > b.frequency ? a : b,
    );

    final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final mostActiveDay = dayNames[analysis.weeklyPatterns.mostActiveDay];

    return Column(
      children: [
        _buildStatRow(
          'Total Activities',
          totalActivities.toString(),
          theme,
          Icons.event,
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          'Most Active Day',
          mostActiveDay,
          theme,
          Icons.today,
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          'Top Category',
          mostFrequentPattern.category,
          theme,
          _getCategoryIcon(mostFrequentPattern.category),
        ),
        const SizedBox(height: 16),
        _buildWeekdayChart(theme, analysis.weeklyPatterns),
        const SizedBox(height: 16),
        _buildConfidenceIndicator(theme, analysis.confidence),
        if (analysis.insights.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInsightsSection(theme, analysis.insights),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No activities recorded this week',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging activities to see weekly patterns',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme, IconData icon) {
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
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayChart(ThemeData theme, models.WeeklyPattern weeklyPattern) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxValue = weeklyPattern.dayAverages.values.isNotEmpty
        ? weeklyPattern.dayAverages.values.reduce((a, b) => a > b ? a : b)
        : 1.0;

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
            'Daily Activity Distribution',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final dayIndex = index + 1;
              final value = weeklyPattern.dayAverages[dayIndex] ?? 0.0;
              final height = maxValue > 0 ? (value / maxValue) * 40 : 0.0;
              final isHighest = dayIndex == weeklyPattern.mostActiveDay;

              return Column(
                children: [
                  Container(
                    width: 24,
                    height: height.clamp(2.0, 40.0),
                    decoration: BoxDecoration(
                      color: isHighest
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNames[index],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isHighest
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: isHighest ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 8,
          percent: value.clamp(0.0, 1.0),
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          progressColor: theme.colorScheme.primary,
          barRadius: const Radius.circular(4),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator(ThemeData theme, double confidence) {
    final confidenceLevel = _getConfidenceLevel(confidence);
    final color = _getConfidenceColor(confidence, theme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            'Analysis Confidence: $confidenceLevel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '${(confidence * 100).round()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(ThemeData theme, List<String> insights) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Key Insights',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...insights.take(2).map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $insight',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              )),
        ],
      ),
    );
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

  Color _getConfidenceColor(double confidence, ThemeData theme) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.lightGreen;
    if (confidence >= 0.4) return Colors.orange;
    if (confidence >= 0.2) return Colors.deepOrange;
    return Colors.red;
  }
}