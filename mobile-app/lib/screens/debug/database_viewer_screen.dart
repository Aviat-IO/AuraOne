import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/location_database.dart';
import '../../providers/location_database_provider.dart';

class DatabaseViewerScreen extends HookConsumerWidget {
  const DatabaseViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tabController = useTabController(initialLength: 3);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Viewer'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Movement'),
            Tab(text: 'Location'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _MovementDataTab(),
          _LocationDataTab(),
          _SummaryDataTab(),
        ],
      ),
    );
  }
}

class _MovementDataTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final database = ref.watch(locationDatabaseProvider);
    final movementData = useState<List<MovementDataData>>([]);
    final isLoading = useState(true);
    final dateRange = useState<DateTimeRange?>(null);
    
    // Load movement data
    useEffect(() {
      void loadData() async {
        isLoading.value = true;
        try {
          final query = database.select(database.movementData);
          
          if (dateRange.value != null) {
            query.where((tbl) => tbl.timestamp.isBetweenValues(
              dateRange.value!.start,
              dateRange.value!.end,
            ));
          }
          
          query.orderBy([(tbl) => drift.OrderingTerm.desc(tbl.timestamp)]);
          query.limit(100);
          
          final data = await query.get();
          movementData.value = data;
        } catch (e) {
          debugPrint('Error loading movement data: $e');
        } finally {
          isLoading.value = false;
        }
      }
      
      loadData();
      return null;
    }, [dateRange.value]);
    
    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Date filter
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                      initialDateRange: dateRange.value,
                    );
                    if (picked != null) {
                      dateRange.value = picked;
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    dateRange.value != null
                      ? '${DateFormat('MMM d').format(dateRange.value!.start)} - ${DateFormat('MMM d').format(dateRange.value!.end)}'
                      : 'Select Date Range',
                  ),
                ),
              ),
              if (dateRange.value != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => dateRange.value = null,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear filter',
                ),
              ],
            ],
          ),
        ),
        
        // Data list
        Expanded(
          child: movementData.value.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No movement data found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: movementData.value.length,
                itemBuilder: (context, index) {
                  final item = movementData.value[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStateColor(item.state, theme),
                        child: Icon(
                          _getStateIcon(item.state),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        DateFormat('MMM d, yyyy HH:mm:ss').format(item.timestamp),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('State: ${item.state}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Average Magnitude', item.averageMagnitude.toStringAsFixed(3)),
                              _buildDetailRow('Sample Count', item.sampleCount.toString()),
                              const Divider(),
                              Text(
                                'Activity Distribution',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPercentageBar('Still', item.stillPercentage, Colors.blue),
                              _buildPercentageBar('Walking', item.walkingPercentage, Colors.green),
                              _buildPercentageBar('Running', item.runningPercentage, Colors.orange),
                              _buildPercentageBar('Driving', item.drivingPercentage, Colors.purple),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
        
        // Summary footer
        if (movementData.value.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Records: ${movementData.value.length}',
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton.icon(
                  onPressed: () async {
                    // Export functionality temporarily disabled

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Export functionality temporarily disabled'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export'),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPercentageBar(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStateColor(String state, ThemeData theme) {
    return switch (state) {
      'MovementState.still' => Colors.blue,
      'MovementState.walking' => Colors.green,
      'MovementState.running' => Colors.orange,
      'MovementState.driving' => Colors.purple,
      _ => theme.colorScheme.onSurface.withValues(alpha: 0.5),
    };
  }
  
  IconData _getStateIcon(String state) {
    return switch (state) {
      'MovementState.still' => Icons.person,
      'MovementState.walking' => Icons.directions_walk,
      'MovementState.running' => Icons.directions_run,
      'MovementState.driving' => Icons.directions_car,
      _ => Icons.help_outline,
    };
  }
}

class _LocationDataTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final database = ref.watch(locationDatabaseProvider);
    final locationData = useState<List<LocationPoint>>([]);
    final isLoading = useState(true);
    final limit = useState(50);
    
    // Load location data
    useEffect(() {
      void loadData() async {
        isLoading.value = true;
        try {
          final query = database.select(database.locationPoints)
            ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.timestamp)])
            ..limit(limit.value);
          
          final data = await query.get();
          locationData.value = data;
        } catch (e) {
          debugPrint('Error loading location data: $e');
        } finally {
          isLoading.value = false;
        }
      }
      
      loadData();
      return null;
    }, [limit.value]);
    
    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Load more controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Show last '),
              DropdownButton<int>(
                value: limit.value,
                items: const [
                  DropdownMenuItem(value: 25, child: Text('25')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                  DropdownMenuItem(value: 100, child: Text('100')),
                  DropdownMenuItem(value: 200, child: Text('200')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    limit.value = value;
                  }
                },
              ),
              const Text(' points'),
            ],
          ),
        ),
        
        // Data list
        Expanded(
          child: locationData.value.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No location data found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: locationData.value.length,
                itemBuilder: (context, index) {
                  final item = locationData.value[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isSignificant 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          item.isSignificant ? Icons.star : Icons.location_on,
                          color: item.isSignificant 
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        DateFormat('MMM d, yyyy HH:mm:ss').format(item.timestamp),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}'),
                          if (item.accuracy != null)
                            Text('Accuracy: ${item.accuracy!.toStringAsFixed(1)}m'),
                          if (item.activityType != null)
                            Text('Activity: ${item.activityType}'),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Location Details'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp)),
                                _buildDetailRow('Latitude', item.latitude.toStringAsFixed(8)),
                                _buildDetailRow('Longitude', item.longitude.toStringAsFixed(8)),
                                if (item.accuracy != null)
                                  _buildDetailRow('Accuracy', '${item.accuracy!.toStringAsFixed(2)} meters'),
                                if (item.altitude != null)
                                  _buildDetailRow('Altitude', '${item.altitude!.toStringAsFixed(2)} meters'),
                                if (item.speed != null)
                                  _buildDetailRow('Speed', '${(item.speed! * 3.6).toStringAsFixed(2)} km/h'),
                                if (item.heading != null)
                                  _buildDetailRow('Heading', '${item.heading!.toStringAsFixed(0)}°'),
                                if (item.activityType != null)
                                  _buildDetailRow('Activity', item.activityType!),
                                _buildDetailRow('Significant', item.isSignificant ? 'Yes' : 'No'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        ),
        
        // Summary footer
        if (locationData.value.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Text(
              'Showing ${locationData.value.length} most recent location points',
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _SummaryDataTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryData = useState<Map<String, dynamic>>({});
    final isLoading = useState(true);
    final database = ref.watch(locationDatabaseProvider);
    final locationSummaries = useState<List<LocationSummary>>([]);
    
    // Load summary data
    useEffect(() {
      void loadData() async {
        isLoading.value = true;
        try {
          // Movement summary temporarily disabled
          summaryData.value = {};

          // Get location summaries
          final query = database.select(database.locationSummaries)
            ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.date)])
            ..limit(7);
          
          final locData = await query.get();
          locationSummaries.value = locData;
        } catch (e) {
          debugPrint('Error loading summary data: $e');
        } finally {
          isLoading.value = false;
        }
      }
      
      loadData();
      return null;
    }, []);
    
    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movement Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Movement Summary (Last 24h)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    'Total Samples',
                    summaryData.value['totalSamples']?.toString() ?? '0',
                  ),
                  _buildSummaryRow(
                    'Average Activity',
                    summaryData.value['averageActivity'] != null
                      ? summaryData.value['averageActivity'].toStringAsFixed(3)
                      : 'N/A',
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'Still Time',
                    summaryData.value['stillTime'] != null
                      ? '${(summaryData.value['stillTime'] * 100).toStringAsFixed(1)}%'
                      : 'N/A',
                  ),
                  _buildSummaryRow(
                    'Active Time',
                    summaryData.value['activeTime'] != null
                      ? '${(summaryData.value['activeTime'] * 100).toStringAsFixed(1)}%'
                      : 'N/A',
                  ),
                  _buildSummaryRow(
                    'Walking Time',
                    summaryData.value['walkingTime'] != null
                      ? '${(summaryData.value['walkingTime'] * 100).toStringAsFixed(1)}%'
                      : 'N/A',
                  ),
                  _buildSummaryRow(
                    'Running Time',
                    summaryData.value['runningTime'] != null
                      ? '${(summaryData.value['runningTime'] * 100).toStringAsFixed(1)}%'
                      : 'N/A',
                  ),
                  _buildSummaryRow(
                    'Driving Time',
                    summaryData.value['drivingTime'] != null
                      ? '${(summaryData.value['drivingTime'] * 100).toStringAsFixed(1)}%'
                      : 'N/A',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Location Summaries
          if (locationSummaries.value.isNotEmpty) ...[
            Text(
              'Daily Location Summaries',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...locationSummaries.value.map((summary) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.calendar_today,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    DateFormat('EEEE, MMM d, yyyy').format(summary.date),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Points: ${summary.totalPoints}'),
                      Text('Distance: ${(summary.totalDistance / 1000).toStringAsFixed(2)} km'),
                      Text('Places visited: ${summary.placesVisited}'),
                      if (summary.activeMinutes != null)
                        Text('Active: ${summary.activeMinutes} minutes'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            }),
          ],
          
          // Database Stats Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Database Statistics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<int>(
                    future: database.select(database.movementData).get().then((data) => data.length),
                    builder: (context, snapshot) {
                      return _buildSummaryRow(
                        'Movement Records',
                        snapshot.data?.toString() ?? 'Loading...',
                      );
                    },
                  ),
                  FutureBuilder<int>(
                    future: database.select(database.locationPoints).get().then((data) => data.length),
                    builder: (context, snapshot) {
                      return _buildSummaryRow(
                        'Location Points',
                        snapshot.data?.toString() ?? 'Loading...',
                      );
                    },
                  ),
                  FutureBuilder<int>(
                    future: database.select(database.geofenceAreas).get().then((data) => data.length),
                    builder: (context, snapshot) {
                      return _buildSummaryRow(
                        'Geofence Areas',
                        snapshot.data?.toString() ?? 'Loading...',
                      );
                    },
                  ),
                  FutureBuilder<int>(
                    future: database.select(database.locationNotes).get().then((data) => data.length),
                    builder: (context, snapshot) {
                      return _buildSummaryRow(
                        'Location Notes',
                        snapshot.data?.toString() ?? 'Loading...',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}