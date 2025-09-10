import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../widgets/page_header.dart';
import '../services/data_attribution_service.dart';
import '../providers/location_database_provider.dart';
import '../services/photo_service.dart';
import '../services/calendar_service.dart';
import '../services/health_service.dart';
import '../services/ble_scanning_service.dart';
import '../providers/service_providers.dart';

class PrivacyDashboardScreen extends HookConsumerWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scrollController = useScrollController();
    
    // Get data from various services
    final dataAttributionService = ref.watch(dataAttributionServiceProvider);
    final locationDb = ref.watch(locationDatabaseProvider);
    final photoService = ref.watch(photoServiceProvider);
    final calendarService = ref.watch(calendarServiceProvider);
    final healthService = ref.watch(healthServiceProvider);
    final bleService = ref.watch(bleServiceProvider);
    
    // Calculate statistics
    final stats = useState<Map<String, dynamic>>({});
    
    useEffect(() {
      Future<void> calculateStats() async {
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        
        // Get location count
        int locationCount = 0;
        try {
          final locations = await locationDb.getLocationsBetween(weekAgo, now);
          locationCount = locations.length;
        } catch (e) {
          // Handle error
        }
        
        // Get photo count
        int photoCount = 0;
        try {
          final photos = await photoService.getRecentPhotos(limit: 1000);
          photoCount = photos.length;
        } catch (e) {
          // Handle error
        }
        
        // Get calendar event count
        int calendarCount = 0;
        try {
          final events = await calendarService.getEventsInRange(weekAgo, now);
          calendarCount = events.length;
        } catch (e) {
          // Handle error
        }
        
        // Get health data count
        int healthCount = 0;
        try {
          final healthData = await healthService.getHealthDataInRange(weekAgo, now);
          healthCount = healthData.length;
        } catch (e) {
          // Handle error
        }
        
        // Get BLE device count
        int bleCount = 0;
        try {
          final devices = bleService.getRecentDevices();
          bleCount = devices.length;
        } catch (e) {
          // Handle error
        }
        
        stats.value = {
          'location': locationCount,
          'photos': photoCount,
          'calendar': calendarCount,
          'health': healthCount,
          'bluetooth': bleCount,
          'total': locationCount + photoCount + calendarCount + healthCount + bleCount,
        };
      }
      
      calculateStats();
      return null;
    }, []);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.95),
              theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PageHeader(
                    icon: Icons.shield,
                    title: 'Privacy Dashboard',
                    subtitle: 'Your data at a glance',
                    trailing: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => context.push('/privacy'),
                    ),
                  ),
                ),
              ),
              
              // Dashboard Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Overview Card
                    _buildOverviewCard(context, theme, stats.value),
                    const SizedBox(height: 16),
                    
                    // Data Collection Chart
                    _buildDataCollectionChart(context, theme, stats.value),
                    const SizedBox(height: 16),
                    
                    // Storage Status
                    _buildStorageStatusCard(context, theme, stats.value),
                    const SizedBox(height: 16),
                    
                    // Data Sources Breakdown
                    _buildDataSourcesBreakdown(context, theme, stats.value),
                    const SizedBox(height: 16),
                    
                    // Recent Activities
                    _buildRecentActivities(context, theme),
                    const SizedBox(height: 16),
                    
                    // Data Retention Settings
                    _buildDataRetentionCard(context, theme),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, ThemeData theme, Map<String, dynamic> stats) {
    final total = stats['total'] ?? 0;
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shield,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Collection Overview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last 7 days',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Total data points
            Center(
              child: Column(
                children: [
                  Text(
                    total.toString(),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Total Data Points',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat(
                  theme,
                  Icons.location_on,
                  stats['location']?.toString() ?? '0',
                  'Locations',
                ),
                _buildQuickStat(
                  theme,
                  Icons.photo,
                  stats['photos']?.toString() ?? '0',
                  'Photos',
                ),
                _buildQuickStat(
                  theme,
                  Icons.calendar_today,
                  stats['calendar']?.toString() ?? '0',
                  'Events',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(ThemeData theme, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDataCollectionChart(BuildContext context, ThemeData theme, Map<String, dynamic> stats) {
    // Generate sample data for the last 7 days
    final spots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), (20 + (i * 10) % 50).toDouble()));
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Collection Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 80,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            theme.colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageStatusCard(BuildContext context, ThemeData theme, Map<String, dynamic> stats) {
    final total = stats['total'] ?? 0;
    final storageUsedMB = (total * 0.001).toStringAsFixed(2); // Rough estimate
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Local Storage Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Storage bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0.35, // Example: 35% used
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$storageUsedMB MB used',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '35% of 100 MB',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Storage breakdown
            Column(
              children: [
                _buildStorageItem(theme, 'Location History', '12.5 MB', 0.25, Colors.blue),
                const SizedBox(height: 8),
                _buildStorageItem(theme, 'Photo Metadata', '8.3 MB', 0.17, Colors.green),
                const SizedBox(height: 8),
                _buildStorageItem(theme, 'Calendar Data', '5.2 MB', 0.10, Colors.orange),
                const SizedBox(height: 8),
                _buildStorageItem(theme, 'Health Records', '6.8 MB', 0.14, Colors.red),
                const SizedBox(height: 8),
                _buildStorageItem(theme, 'Other', '2.2 MB', 0.04, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageItem(ThemeData theme, String label, String size, double progress, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          size,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDataSourcesBreakdown(BuildContext context, ThemeData theme, Map<String, dynamic> stats) {
    final total = (stats['total'] ?? 1).toDouble();
    final location = (stats['location'] ?? 0).toDouble();
    final photos = (stats['photos'] ?? 0).toDouble();
    final calendar = (stats['calendar'] ?? 0).toDouble();
    final health = (stats['health'] ?? 0).toDouble();
    final bluetooth = (stats['bluetooth'] ?? 0).toDouble();

    final dataMap = <String, double>{
      'Location': location,
      'Photos': photos,
      'Calendar': calendar,
      'Health': health,
      'Bluetooth': bluetooth,
    };

    final colorList = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
    ];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Sources Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Pie chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: dataMap.entries.map((entry) {
                    final index = dataMap.keys.toList().indexOf(entry.key);
                    final percentage = (entry.value / total * 100).toStringAsFixed(1);
                    
                    return PieChartSectionData(
                      color: colorList[index],
                      value: entry.value,
                      title: '$percentage%',
                      radius: 80,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: dataMap.entries.map((entry) {
                final index = dataMap.keys.toList().indexOf(entry.key);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorList[index],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key} (${entry.value.toInt()})',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context, ThemeData theme) {
    final activities = [
      {'type': 'location', 'action': 'Location recorded', 'time': '2 minutes ago'},
      {'type': 'photo', 'action': 'Photo metadata analyzed', 'time': '15 minutes ago'},
      {'type': 'calendar', 'action': 'Calendar synced', 'time': '1 hour ago'},
      {'type': 'health', 'action': 'Health data updated', 'time': '2 hours ago'},
      {'type': 'bluetooth', 'action': 'Bluetooth device detected', 'time': '3 hours ago'},
    ];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full activity log
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...activities.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconForType(activity['type']!),
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['action']!,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          activity['time']!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRetentionCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Data Retention Policy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildRetentionItem(theme, 'Location History', '30 days'),
            const SizedBox(height: 12),
            _buildRetentionItem(theme, 'Photo Metadata', 'Until manually deleted'),
            const SizedBox(height: 12),
            _buildRetentionItem(theme, 'Calendar Events', '90 days'),
            const SizedBox(height: 12),
            _buildRetentionItem(theme, 'Health Records', '1 year'),
            const SizedBox(height: 12),
            _buildRetentionItem(theme, 'Bluetooth Contacts', '14 days'),
            
            const SizedBox(height: 20),
            
            FilledButton.tonal(
              onPressed: () => context.push('/privacy'),
              child: const Text('Manage Retention Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionItem(ThemeData theme, String dataType, String retention) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dataType,
          style: theme.textTheme.bodyMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            retention,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'location':
        return Icons.location_on;
      case 'photo':
        return Icons.photo;
      case 'calendar':
        return Icons.calendar_today;
      case 'health':
        return Icons.favorite;
      case 'bluetooth':
        return Icons.bluetooth;
      default:
        return Icons.data_usage;
    }
  }
}