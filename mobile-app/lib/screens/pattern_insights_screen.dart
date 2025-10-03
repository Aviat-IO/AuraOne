import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/pattern_analysis_provider.dart';
import '../widgets/pattern_analysis/weekly_summary_widget.dart';
import '../widgets/pattern_analysis/monthly_summary_widget.dart';
import '../models/pattern_analysis_models.dart' as models;
import '../utils/time_utils.dart';

class PatternInsightsScreen extends HookConsumerWidget {
  const PatternInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tabController = useTabController(initialLength: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Insights'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_view_week),
              text: 'Weekly',
            ),
            Tab(
              icon: Icon(Icons.calendar_month),
              text: 'Monthly',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _WeeklyInsightsTab(),
          _MonthlyInsightsTab(),
        ],
      ),
    );
  }
}

class _WeeklyInsightsTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pageController = usePageController();
    final currentWeekIndex = useState(0);

    // Calculate weeks to show (current week and 3 weeks back)
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final weeks = List.generate(4, (index) {
      return currentWeekStart.subtract(Duration(days: index * 7));
    });

    return Column(
      children: [
        // Week navigation
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: currentWeekIndex.value < weeks.length - 1
                    ? () {
                        currentWeekIndex.value++;
                        pageController.animateToPage(
                          currentWeekIndex.value,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _getWeekLabel(weeks[currentWeekIndex.value]),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: currentWeekIndex.value > 0
                    ? () {
                        currentWeekIndex.value--;
                        pageController.animateToPage(
                          currentWeekIndex.value,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        // Week content
        Expanded(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: (index) {
              currentWeekIndex.value = index;
            },
            itemCount: weeks.length,
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    WeeklySummaryWidget(
                      weekStart: weeks[index],
                      onTapInsights: () => _showWeeklyDetails(
                        context,
                        ref,
                        weeks[index],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _WeeklyDetailsWidget(weekStart: weeks[index]),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getWeekLabel(DateTime weekStart) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));

    if (weekStart.isAtSameMomentAs(currentWeekStart)) {
      return 'This Week';
    } else if (weekStart.isAtSameMomentAs(currentWeekStart.subtract(const Duration(days: 7)))) {
      return 'Last Week';
    } else {
      final weekEnd = weekStart.add(const Duration(days: 6));
      return '${TimeUtils.formatDate(weekStart)} - ${TimeUtils.formatDate(weekEnd)}';
    }
  }

  void _showWeeklyDetails(BuildContext context, WidgetRef ref, DateTime weekStart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _WeeklyDetailSheet(
          weekStart: weekStart,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _MonthlyInsightsTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pageController = usePageController();
    final currentMonthIndex = useState(0);

    // Calculate months to show (current month and 2 months back)
    final now = DateTime.now();
    final months = List.generate(3, (index) {
      final targetMonth = now.month - index;
      final targetYear = targetMonth <= 0 ? now.year - 1 : now.year;
      final adjustedMonth = targetMonth <= 0 ? 12 + targetMonth : targetMonth;
      return DateTime(targetYear, adjustedMonth, 1);
    });

    return Column(
      children: [
        // Month navigation
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: currentMonthIndex.value < months.length - 1
                    ? () {
                        currentMonthIndex.value++;
                        pageController.animateToPage(
                          currentMonthIndex.value,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _getMonthLabel(months[currentMonthIndex.value]),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: currentMonthIndex.value > 0
                    ? () {
                        currentMonthIndex.value--;
                        pageController.animateToPage(
                          currentMonthIndex.value,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        // Month content
        Expanded(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: (index) {
              currentMonthIndex.value = index;
            },
            itemCount: months.length,
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: MonthlySummaryWidget(
                  monthStart: months[index],
                  onTapDetailed: () => _showMonthlyDetails(
                    context,
                    ref,
                    months[index],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getMonthLabel(DateTime monthStart) {
    final now = DateTime.now();
    if (monthStart.year == now.year && monthStart.month == now.month) {
      return 'This Month';
    } else if (monthStart.year == now.year && monthStart.month == now.month - 1) {
      return 'Last Month';
    } else {
      return TimeUtils.formatMonthYear(monthStart);
    }
  }

  void _showMonthlyDetails(BuildContext context, WidgetRef ref, DateTime monthStart) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _MonthlyDetailScreen(monthStart: monthStart),
      ),
    );
  }
}

class _WeeklyDetailsWidget extends HookConsumerWidget {
  final DateTime weekStart;

  const _WeeklyDetailsWidget({required this.weekStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activityPatternsAsync = ref.watch(weeklyActivityPatternsProvider(weekStart));

    return activityPatternsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (analysis) => analysis.patterns.isEmpty
          ? const SizedBox.shrink()
          : Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Breakdown',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...analysis.patterns.values.map((pattern) => _buildActivityPattern(theme, pattern)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActivityPattern(ThemeData theme, models.ActivityPattern pattern) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getCategoryColor(pattern.category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pattern.category,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '${pattern.frequency}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'physical':
        return Colors.green;
      case 'work':
        return Colors.blue;
      case 'social':
        return Colors.orange;
      case 'creative':
        return Colors.purple;
      case 'wellness':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _WeeklyDetailSheet extends ConsumerWidget {
  final DateTime weekStart;
  final ScrollController scrollController;

  const _WeeklyDetailSheet({
    required this.weekStart,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activityPatternsAsync = ref.watch(weeklyActivityPatternsProvider(weekStart));

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Weekly Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: activityPatternsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading details: $error'),
              ),
              data: (analysis) => ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDetailedInsights(theme, analysis),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInsights(ThemeData theme, models.ActivityPatternAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (analysis.insights.isNotEmpty) ...[
          Text(
            'Insights',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...analysis.insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $insight'),
              )),
          const SizedBox(height: 16),
        ],
        if (analysis.patterns.isNotEmpty) ...[
          Text(
            'Activity Patterns',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...analysis.patterns.values.map((pattern) => Card(
                child: ListTile(
                  leading: Icon(_getCategoryIcon(pattern.category)),
                  title: Text(pattern.category),
                  subtitle: Text('${pattern.frequency} activities'),
                  trailing: Text('${(pattern.averageIntensity * 100).round()}%'),
                ),
              )),
        ],
      ],
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
}

class _MonthlyDetailScreen extends ConsumerWidget {
  final DateTime monthStart;

  const _MonthlyDetailScreen({required this.monthStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final comprehensiveInsightsAsync = ref.watch(comprehensivePatternInsightsProvider(monthStart));

    return Scaffold(
      appBar: AppBar(
        title: Text(TimeUtils.formatMonthYear(monthStart)),
      ),
      body: comprehensiveInsightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading monthly details: $error'),
        ),
        data: (insights) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildComprehensiveDetails(theme, insights),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComprehensiveDetails(ThemeData theme, ComprehensivePatternInsights insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insights.keyInsights.isNotEmpty) ...[
          _buildSection(
            theme,
            'Key Insights',
            Icons.lightbulb,
            insights.keyInsights.map((insight) => Text('• $insight')).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (insights.recommendations.isNotEmpty) ...[
          _buildSection(
            theme,
            'Recommendations',
            Icons.recommend,
            insights.recommendations.map((rec) => Text('• $rec')).toList(),
          ),
          const SizedBox(height: 24),
        ],
        _buildSection(
          theme,
          'Activity Analysis',
          Icons.assessment,
          _buildActivityAnalysisWidgets(theme, insights.activityPatterns),
        ),
        const SizedBox(height: 24),
        _buildSection(
          theme,
          'Mood Trends',
          Icons.mood,
          _buildMoodAnalysisWidgets(theme, insights.moodTrends),
        ),
        const SizedBox(height: 24),
        _buildSection(
          theme,
          'Social Patterns',
          Icons.people,
          _buildSocialAnalysisWidgets(theme, insights.socialPatterns),
        ),
        const SizedBox(height: 24),
        _buildSection(
          theme,
          'Location Insights',
          Icons.location_on,
          _buildLocationAnalysisWidgets(theme, insights.locationPatterns),
        ),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  List<Widget> _buildActivityAnalysisWidgets(ThemeData theme, models.ActivityPatternAnalysis analysis) {
    if (analysis.patterns.isEmpty) {
      return [const Text('No activity patterns available')];
    }

    return analysis.patterns.values.map((pattern) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(pattern.category)),
          Text('${pattern.frequency} times'),
        ],
      ),
    )).toList();
  }

  List<Widget> _buildMoodAnalysisWidgets(ThemeData theme, models.MoodTrendAnalysis analysis) {
    return [
      Row(
        children: [
          const Text('Average Mood: '),
          Text(
            '${(analysis.averageMoodScore * 100).round()}%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Text('Trend: '),
          Text(
            analysis.trendDirection.toString().split('.').last,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSocialAnalysisWidgets(ThemeData theme, models.SocialPatternAnalysis analysis) {
    return [
      Row(
        children: [
          const Text('Avg Social Interactions: '),
          Text(
            analysis.averageSocialInteractions.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Text('Preferred Group Size: '),
          Text(
            analysis.preferences.preferredGroupSize.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildLocationAnalysisWidgets(ThemeData theme, models.LocationPatternAnalysis analysis) {
    return [
      Row(
        children: [
          const Text('Home Time: '),
          Text(
            '${(analysis.homeBaseAnalysis.homeTimePercentage * 100).round()}%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Text('Exploration Radius: '),
          Text(
            '${analysis.homeBaseAnalysis.explorationRadius.toStringAsFixed(1)} km',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ];
  }
}