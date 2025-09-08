import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../widgets/common/time_utils.dart';

// Sample location entry for UI development
class LocationEntry {
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? placeName;
  final String? address;
  final Duration? durationAtLocation;
  
  LocationEntry({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.placeName,
    this.address,
    this.durationAtLocation,
  });
}

// Mock data provider for development
final locationHistoryProvider = StateProvider<List<LocationEntry>>((ref) {
  // Generate sample data for UI development
  final now = DateTime.now();
  return List.generate(50, (index) {
    final timestamp = now.subtract(Duration(hours: index * 2));
    return LocationEntry(
      id: 'loc_$index',
      timestamp: timestamp,
      latitude: 37.7749 + (index % 10) * 0.01,
      longitude: -122.4194 + (index % 8) * 0.01,
      accuracy: 5.0 + (index % 3) * 10,
      placeName: index % 5 == 0 ? ['Home', 'Work', 'Coffee Shop', 'Park', 'Library'][index % 5] : null,
      address: '${100 + index} Sample St, San Francisco, CA',
      durationAtLocation: index % 4 == 0 ? Duration(minutes: 20 + index % 60) : null,
    );
  });
});

final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);
final selectedLocationIdsProvider = StateProvider<Set<String>>((ref) => {});

class LocationHistoryScreen extends HookConsumerWidget {
  const LocationHistoryScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tabController = useTabController(initialLength: 2);
    final locationEntries = ref.watch(locationHistoryProvider);
    final selectedDateRange = ref.watch(selectedDateRangeProvider);
    final selectedIds = ref.watch(selectedLocationIdsProvider);
    
    final filteredEntries = selectedDateRange != null
        ? locationEntries.where((entry) {
            return entry.timestamp.isAfter(selectedDateRange.start) &&
                   entry.timestamp.isBefore(selectedDateRange.end.add(const Duration(days: 1)));
          }).toList()
        : locationEntries;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (selectedIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showDeleteSelectedDialog(context, ref),
              tooltip: 'Delete Selected (${selectedIds.length})',
            ),
          ],
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Filters'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _showExportDialog(context, filteredEntries);
                  break;
                case 'clear_filters':
                  ref.read(selectedDateRangeProvider.notifier).state = null;
                  ref.read(selectedLocationIdsProvider.notifier).state = {};
                  break;
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
            Tab(icon: Icon(Icons.map), text: 'Map View'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter controls
            _buildFilterControls(context, ref, theme, filteredEntries.length),
            
            // Tab views
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _buildTimelineView(context, ref, theme, filteredEntries),
                  _buildMapView(context, theme, filteredEntries),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterControls(BuildContext context, WidgetRef ref, ThemeData theme, int totalEntries) {
    final selectedDateRange = ref.watch(selectedDateRangeProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDateRange(context, ref),
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    selectedDateRange != null
                      ? '${_formatDate(selectedDateRange.start)} - ${_formatDate(selectedDateRange.end)}'
                      : 'Select Date Range',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (selectedDateRange != null)
                IconButton(
                  onPressed: () {
                    ref.read(selectedDateRangeProvider.notifier).state = null;
                  },
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear filter',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                '$totalEntries location entries found',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimelineView(BuildContext context, WidgetRef ref, ThemeData theme, List<LocationEntry> entries) {
    final selectedIds = ref.watch(selectedLocationIdsProvider);
    
    if (entries.isEmpty) {
      return _buildEmptyState(context, theme, 'No location data found for the selected period.');
    }
    
    // Group entries by date
    final groupedEntries = <String, List<LocationEntry>>{};
    for (final entry in entries) {
      final dateKey = _formatDate(entry.timestamp);
      groupedEntries.putIfAbsent(dateKey, () => []).add(entry);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedEntries.length,
      itemBuilder: (context, index) {
        final dateKey = groupedEntries.keys.elementAt(index);
        final dayEntries = groupedEntries[dateKey]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateWithWeekday(DateTime.parse('${dateKey}T00:00:00')),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dayEntries.length} locations',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Location entries
              ...dayEntries.map((entry) => _buildLocationEntryTile(context, ref, theme, entry, selectedIds)),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildLocationEntryTile(
    BuildContext context, 
    WidgetRef ref, 
    ThemeData theme, 
    LocationEntry entry,
    Set<String> selectedIds,
  ) {
    final isSelected = selectedIds.contains(entry.id);
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1) : null,
        border: Border(
          left: BorderSide(
            color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              entry.placeName != null ? Icons.place : Icons.location_on,
              color: isSelected 
                ? theme.colorScheme.primary
                : entry.placeName != null 
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            Text(
              TimeUtils.formatTime(entry.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.placeName ?? 'Location',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: entry.placeName != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (entry.address != null) ...[
                    Text(
                      entry.address!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.gps_fixed,
              size: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Text(
              '±${entry.accuracy.toInt()}m',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            if (entry.durationAtLocation != null) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.schedule,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(entry.durationAtLocation!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                final currentSelection = ref.read(selectedLocationIdsProvider);
                if (value == true) {
                  ref.read(selectedLocationIdsProvider.notifier).state = 
                    {...currentSelection, entry.id};
                } else {
                  ref.read(selectedLocationIdsProvider.notifier).state = 
                    currentSelection.where((id) => id != entry.id).toSet();
                }
              },
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view_details',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'view_on_map',
                  child: Row(
                    children: [
                      Icon(Icons.map),
                      SizedBox(width: 8),
                      Text('View on Map'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view_details':
                    _showLocationDetails(context, entry);
                    break;
                  case 'view_on_map':
                    _viewLocationOnMap(context, entry);
                    break;
                  case 'delete':
                    _deleteLocationEntry(context, ref, entry);
                    break;
                }
              },
            ),
          ],
        ),
        onTap: () {
          _showLocationDetails(context, entry);
        },
      ),
    );
  }
  
  Widget _buildMapView(BuildContext context, ThemeData theme, List<LocationEntry> entries) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Map View Coming Soon',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Interactive map visualization of your location history will be available in a future update.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: entries.isNotEmpty ? () {
                  _showLocationsSummary(context, entries);
                } : null,
                icon: const Icon(Icons.summarize),
                label: const Text('View Summary'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'No Location Data',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  String _formatDateWithWeekday(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
  
  // Action methods
  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: ref.read(selectedDateRangeProvider),
    );
    
    if (picked != null) {
      ref.read(selectedDateRangeProvider.notifier).state = picked;
    }
  }
  
  void _showLocationDetails(BuildContext context, LocationEntry entry) {
    showDialog(
      context: context,
      builder: (context) => LocationDetailsDialog(entry: entry),
    );
  }
  
  void _viewLocationOnMap(BuildContext context, LocationEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map view coming soon in a future update'),
      ),
    );
  }
  
  void _deleteLocationEntry(BuildContext context, WidgetRef ref, LocationEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location Entry'),
        content: Text(
          'Are you sure you want to delete the location entry from ${TimeUtils.formatDateTime(entry.timestamp)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeleteEntry(context, ref, entry);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _performDeleteEntry(BuildContext context, WidgetRef ref, LocationEntry entry) {
    final currentEntries = ref.read(locationHistoryProvider);
    final updatedEntries = currentEntries.where((e) => e.id != entry.id).toList();
    ref.read(locationHistoryProvider.notifier).state = updatedEntries;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Location entry deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(locationHistoryProvider.notifier).state = currentEntries;
          },
        ),
      ),
    );
  }
  
  void _showDeleteSelectedDialog(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.read(selectedLocationIdsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Entries'),
        content: Text(
          'Are you sure you want to delete ${selectedIds.length} selected location entries? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeleteSelected(context, ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
  
  void _performDeleteSelected(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.read(selectedLocationIdsProvider);
    final currentEntries = ref.read(locationHistoryProvider);
    final updatedEntries = currentEntries.where((e) => !selectedIds.contains(e.id)).toList();
    
    ref.read(locationHistoryProvider.notifier).state = updatedEntries;
    ref.read(selectedLocationIdsProvider.notifier).state = {};
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedIds.length} location entries deleted'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _showExportDialog(BuildContext context, List<LocationEntry> entries) {
    showDialog(
      context: context,
      builder: (context) => LocationHistoryExportDialog(entries: entries),
    );
  }
  
  void _showLocationsSummary(BuildContext context, List<LocationEntry> entries) {
    final totalLocations = entries.length;
    final namedLocations = entries.where((e) => e.placeName != null).length;
    final averageAccuracy = entries.map((e) => e.accuracy).reduce((a, b) => a + b) / entries.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location History Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total locations: $totalLocations'),
            Text('Named places: $namedLocations'),
            Text('Average accuracy: ±${averageAccuracy.toInt()}m'),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Date range: ${TimeUtils.formatDate(entries.last.timestamp)} - ${TimeUtils.formatDate(entries.first.timestamp)}'),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Location details dialog
class LocationDetailsDialog extends StatelessWidget {
  final LocationEntry entry;
  
  const LocationDetailsDialog({super.key, required this.entry});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(entry.placeName ?? 'Location Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(theme, 'Time', TimeUtils.formatDateTime(entry.timestamp)),
            _buildDetailRow(theme, 'Coordinates', '${entry.latitude.toStringAsFixed(6)}, ${entry.longitude.toStringAsFixed(6)}'),
            _buildDetailRow(theme, 'Accuracy', '±${entry.accuracy.toInt()} meters'),
            if (entry.address != null)
              _buildDetailRow(theme, 'Address', entry.address!),
            if (entry.durationAtLocation != null)
              _buildDetailRow(theme, 'Duration', _formatDuration(entry.durationAtLocation!)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            // Copy coordinates to clipboard or show on external map
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location details copied')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

// Export dialog for location history
class LocationHistoryExportDialog extends StatefulWidget {
  final List<LocationEntry> entries;
  
  const LocationHistoryExportDialog({super.key, required this.entries});
  
  @override
  State<LocationHistoryExportDialog> createState() => _LocationHistoryExportDialogState();
}

class _LocationHistoryExportDialogState extends State<LocationHistoryExportDialog> {
  String _selectedFormat = 'JSON';
  bool _includeAddress = true;
  bool _includeAccuracy = true;
  bool _includeDuration = true;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Location History'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exporting ${widget.entries.length} location entries'),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedFormat,
              decoration: const InputDecoration(
                labelText: 'Export Format',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'JSON', child: Text('JSON')),
                DropdownMenuItem(value: 'CSV', child: Text('CSV')),
                DropdownMenuItem(value: 'GPX', child: Text('GPX (GPS Exchange)')),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedFormat = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            const Text('Include in export:'),
            CheckboxListTile(
              title: const Text('Address information'),
              value: _includeAddress,
              onChanged: (bool? value) {
                setState(() {
                  _includeAddress = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('GPS accuracy data'),
              value: _includeAccuracy,
              onChanged: (bool? value) {
                setState(() {
                  _includeAccuracy = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Duration at location'),
              value: _includeDuration,
              onChanged: (bool? value) {
                setState(() {
                  _includeDuration = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => _performExport(),
          icon: const Icon(Icons.download),
          label: const Text('Export'),
        ),
      ],
    );
  }
  
  Future<void> _performExport() async {
    Navigator.of(context).pop();
    
    // Show progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Exporting location data...'),
          ],
        ),
      ),
    );
    
    // Simulate export process
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.entries.length} entries exported to Downloads ($_selectedFormat)'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Open file manager or show file location
            },
          ),
        ),
      );
    }
  }
}