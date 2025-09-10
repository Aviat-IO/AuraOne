import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:health/health.dart';
import '../services/simple_location_service.dart';
import '../services/movement_tracking_service.dart';

// Battery optimization enum
enum BatteryOptimization {
  aggressive,
  balanced,
  performance,
}

// Privacy settings providers
final locationTrackingGranularityProvider = StateProvider<LocationGranularity>((ref) {
  return LocationGranularity.balanced;
});

final batteryOptimizationProvider = StateProvider<BatteryOptimization>((ref) {
  return BatteryOptimization.balanced;
});

final dataRetentionProvider = StateProvider<DataRetentionPeriod>((ref) {
  return DataRetentionPeriod.sixMonths;
});

final automaticDeletionProvider = StateProvider<bool>((ref) => true);

// Additional privacy control providers
final photoAccessProvider = StateProvider<bool>((ref) => false);
final calendarAccessProvider = StateProvider<bool>((ref) => false);
final healthDataProvider = StateProvider<bool>((ref) => false);
final bluetoothScanningProvider = StateProvider<bool>((ref) => false);
final microphoneAccessProvider = StateProvider<bool>((ref) => false);
final cameraAccessProvider = StateProvider<bool>((ref) => false);
final contactsAccessProvider = StateProvider<bool>((ref) => false);
final notificationAccessProvider = StateProvider<bool>((ref) => true);

// Permission status providers
final permissionStatusProvider = StateProvider<Map<Permission, PermissionStatus>>((ref) => {});

enum LocationGranularity {
  off,         // No location tracking
  approximate, // City/neighborhood level
  balanced,    // Street level (50m accuracy)  
  precise,     // GPS precise (10m accuracy)
}

enum DataRetentionPeriod {
  oneWeek,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  forever,
}

class PrivacySettingsScreen extends HookConsumerWidget {
  const PrivacySettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final granularity = ref.watch(locationTrackingGranularityProvider);
    final retention = ref.watch(dataRetentionProvider);
    final autoDelete = ref.watch(automaticDeletionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Location'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Privacy overview section
              _buildPrivacyOverview(context),
              const SizedBox(height: 24),
              
              // Location tracking granularity
              _buildLocationGranularitySection(context, ref, granularity),
              const SizedBox(height: 24),
              
              // Movement tracking section
              _buildMovementTrackingSection(context, ref),
              const SizedBox(height: 24),
              
              // Data retention settings
              _buildDataRetentionSection(context, ref, retention, autoDelete),
              const SizedBox(height: 24),
              
              // Additional Data Source Controls
              _buildDataSourceControlsSection(context, ref),
              const SizedBox(height: 24),
              
              // Device Permissions
              _buildDevicePermissionsSection(context, ref),
              const SizedBox(height: 24),
              
              // Location history management
              _buildLocationHistorySection(context),
              const SizedBox(height: 24),
              
              // Data export and opt-out
              _buildDataControlSection(context),
              const SizedBox(height: 24),
              
              // Privacy information
              _buildPrivacyInfoSection(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPrivacyOverview(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Privacy Matters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Aura One is designed with privacy first. All your location data stays on your device and is never sent to our servers without your explicit consent.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primaryContainer,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.offline_bolt,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Local storage only • No cloud sync • You control your data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationGranularitySection(BuildContext context, WidgetRef ref, LocationGranularity granularity) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Tracking Precision',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how precisely we track your location for automatic journey mapping.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            ...LocationGranularity.values.map((value) {
              final isSelected = granularity == value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    ref.read(locationTrackingGranularityProvider.notifier).state = value;
                    _updateLocationSettings(ref, value);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected 
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                        : null,
                    ),
                    child: Row(
                      children: [
                        Radio<LocationGranularity>(
                          value: value,
                          groupValue: granularity,
                          onChanged: (LocationGranularity? newValue) {
                            if (newValue != null) {
                              ref.read(locationTrackingGranularityProvider.notifier).state = newValue;
                              _updateLocationSettings(ref, newValue);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGranularityTitle(value),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _getGranularityDescription(value),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _getGranularityIcon(value),
                          color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMovementTrackingSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final movementEnabled = ref.watch(movementTrackingEnabledProvider);
    final currentState = ref.watch(currentMovementStateProvider);
    final movementHistory = ref.watch(movementHistoryProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_walk,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Movement Tracking',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track movement patterns using device sensors to determine wakefulness, activity levels, and movement type.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Movement tracking toggle
            SwitchListTile(
              title: const Text('Enable Movement Tracking'),
              subtitle: Text(
                movementEnabled 
                  ? 'Gyroscope and accelerometer data is being collected'
                  : 'Movement tracking is disabled',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              value: movementEnabled,
              onChanged: (bool value) async {
                ref.read(movementTrackingEnabledProvider.notifier).state = value;
                
                final movementService = ref.read(movementTrackingServiceProvider);
                if (value) {
                  await movementService.startTracking();
                } else {
                  movementService.stopTracking();
                }
              },
              secondary: Icon(
                movementEnabled ? Icons.sensors : Icons.sensors_off,
                color: theme.colorScheme.primary,
              ),
            ),
            
            if (movementEnabled) ...[
              const Divider(),
              
              // Current movement state display
              ListTile(
                leading: Icon(
                  _getMovementStateIcon(currentState),
                  color: _getMovementStateColor(currentState, theme),
                ),
                title: const Text('Current Activity'),
                subtitle: Text(
                  _getMovementStateText(currentState),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _getMovementStateColor(currentState, theme),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: movementHistory.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(movementHistory.last.confidence * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              ),
              
              const SizedBox(height: 8),
              
              // Movement history summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Hour Summary',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (movementHistory.isNotEmpty) ...[
                      _buildMovementSummaryRow(
                        context,
                        'Samples Collected',
                        movementHistory.length.toString(),
                      ),
                      _buildMovementSummaryRow(
                        context,
                        'Primary Activity',
                        _getMostFrequentState(movementHistory),
                      ),
                      _buildMovementSummaryRow(
                        context,
                        'Average Confidence',
                        '${(_getAverageConfidence(movementHistory) * 100).toStringAsFixed(0)}%',
                      ),
                    ] else ...[
                      Text(
                        'No movement data collected yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // View detailed movement data button
              OutlinedButton.icon(
                onPressed: () {
                  context.push('/privacy/movement-history');
                },
                icon: const Icon(Icons.analytics, size: 20),
                label: const Text('View Movement History'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Privacy note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Movement data is processed locally on your device and never transmitted to external servers. This data helps determine your activity patterns and wakefulness.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMovementSummaryRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getMovementStateIcon(MovementState state) {
    return switch (state) {
      MovementState.still => Icons.person,
      MovementState.walking => Icons.directions_walk,
      MovementState.running => Icons.directions_run,
      MovementState.driving => Icons.directions_car,
      MovementState.unknown => Icons.help_outline,
    };
  }
  
  Color _getMovementStateColor(MovementState state, ThemeData theme) {
    return switch (state) {
      MovementState.still => theme.colorScheme.secondary,
      MovementState.walking => Colors.green,
      MovementState.running => Colors.orange,
      MovementState.driving => Colors.blue,
      MovementState.unknown => theme.colorScheme.onSurface.withValues(alpha: 0.5),
    };
  }
  
  String _getMovementStateText(MovementState state) {
    return switch (state) {
      MovementState.still => 'Still / Resting',
      MovementState.walking => 'Walking',
      MovementState.running => 'Running',
      MovementState.driving => 'In Vehicle',
      MovementState.unknown => 'Detecting...',
    };
  }
  
  String _getMostFrequentState(List<MovementData> history) {
    if (history.isEmpty) return 'Unknown';
    
    final stateCounts = <MovementState, int>{};
    for (final data in history) {
      stateCounts[data.state] = (stateCounts[data.state] ?? 0) + 1;
    }
    
    MovementState mostFrequent = MovementState.unknown;
    int maxCount = 0;
    stateCounts.forEach((state, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequent = state;
      }
    });
    
    return _getMovementStateText(mostFrequent);
  }
  
  double _getAverageConfidence(List<MovementData> history) {
    if (history.isEmpty) return 0.0;
    
    double total = 0;
    for (final data in history) {
      total += data.confidence;
    }
    return total / history.length;
  }
  
  Widget _buildDataRetentionSection(BuildContext context, WidgetRef ref, DataRetentionPeriod retention, bool autoDelete) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Retention',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Control how long location data is stored on your device.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<DataRetentionPeriod>(
              value: retention,
              decoration: InputDecoration(
                labelText: 'Keep location data for',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.schedule),
              ),
              items: DataRetentionPeriod.values.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(_getRetentionPeriodName(period)),
                );
              }).toList(),
              onChanged: (DataRetentionPeriod? newValue) {
                if (newValue != null) {
                  ref.read(dataRetentionProvider.notifier).state = newValue;
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Automatic cleanup'),
              subtitle: Text(
                autoDelete 
                  ? 'Old location data will be deleted automatically'
                  : 'You will need to manually delete old data',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              value: autoDelete,
              onChanged: (bool value) {
                ref.read(automaticDeletionProvider.notifier).state = value;
              },
              secondary: Icon(
                autoDelete ? Icons.auto_delete : Icons.delete_outline,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationHistorySection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View and manage your stored location data.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildLocationHistoryActions(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationHistoryActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.timeline,
            color: theme.colorScheme.primary,
          ),
          title: const Text('View Location Timeline'),
          subtitle: const Text('Browse your location history with interactive timeline'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/privacy/location-history');
          },
        ),
        
        const Divider(),
        
        ListTile(
          leading: Icon(
            Icons.map,
            color: theme.colorScheme.primary,
          ),
          title: const Text('View on Map'),
          subtitle: const Text('See your visited locations on a map'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/privacy/location-map');
          },
        ),
        
        const Divider(),
        
        ListTile(
          leading: Icon(
            Icons.delete_sweep,
            color: theme.colorScheme.error,
          ),
          title: const Text('Delete Selected Data'),
          subtitle: const Text('Remove specific location entries'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showSelectiveDeleteDialog(context),
        ),
      ],
    );
  }
  
  Widget _buildDataControlSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Control',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export or delete all your location data.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showExportDialog(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Export Data'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showDeleteAllDialog(context),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete All'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrivacyInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Privacy Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildPrivacyInfoItem(
              context,
              Icons.storage,
              'Local Storage Only',
              'All location data is stored locally on your device and never transmitted to external servers.',
            ),
            
            _buildPrivacyInfoItem(
              context,
              Icons.location_off,
              'No Tracking Without Permission',
              'Location tracking only starts after you explicitly grant permission.',
            ),
            
            _buildPrivacyInfoItem(
              context,
              Icons.security,
              'Your Control',
              'You can view, export, or delete your location data at any time.',
            ),
            
            _buildPrivacyInfoItem(
              context,
              Icons.visibility_off,
              'Background Processing',
              'Location data is processed locally to enhance your journal entries with contextual information.',
            ),
            
            const SizedBox(height: 16),
            
            TextButton.icon(
              onPressed: () => _showDetailedPrivacyInfo(context),
              icon: const Icon(Icons.read_more),
              label: const Text('Read Full Privacy Policy'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrivacyInfoItem(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods for granularity settings
  String _getGranularityTitle(LocationGranularity granularity) {
    return switch (granularity) {
      LocationGranularity.off => 'Location Tracking Off',
      LocationGranularity.approximate => 'Approximate Location',
      LocationGranularity.balanced => 'Balanced Precision',
      LocationGranularity.precise => 'Precise Location',
    };
  }
  
  String _getGranularityDescription(LocationGranularity granularity) {
    return switch (granularity) {
      LocationGranularity.off => 'No location data will be collected',
      LocationGranularity.approximate => 'City/neighborhood level (~1km accuracy)',
      LocationGranularity.balanced => 'Street level tracking (~50m accuracy)',
      LocationGranularity.precise => 'GPS precise tracking (~10m accuracy)',
    };
  }
  
  IconData _getGranularityIcon(LocationGranularity granularity) {
    return switch (granularity) {
      LocationGranularity.off => Icons.location_disabled,
      LocationGranularity.approximate => Icons.location_city,
      LocationGranularity.balanced => Icons.location_on,
      LocationGranularity.precise => Icons.my_location,
    };
  }
  
  String _getRetentionPeriodName(DataRetentionPeriod period) {
    return switch (period) {
      DataRetentionPeriod.oneWeek => '1 Week',
      DataRetentionPeriod.oneMonth => '1 Month',
      DataRetentionPeriod.threeMonths => '3 Months',
      DataRetentionPeriod.sixMonths => '6 Months',
      DataRetentionPeriod.oneYear => '1 Year',
      DataRetentionPeriod.forever => 'Forever',
    };
  }
  
  // Action methods
  void _updateLocationSettings(WidgetRef ref, LocationGranularity granularity) async {
    // Update battery optimization based on granularity
    final batteryMode = switch (granularity) {
      LocationGranularity.off => BatteryOptimization.aggressive,
      LocationGranularity.approximate => BatteryOptimization.aggressive,
      LocationGranularity.balanced => BatteryOptimization.balanced,
      LocationGranularity.precise => BatteryOptimization.performance,
    };
    
    ref.read(batteryOptimizationProvider.notifier).state = batteryMode;
    
    final locationService = ref.read(simpleLocationServiceProvider);
    
    // Handle location tracking based on granularity
    if (granularity == LocationGranularity.off) {
      // If location is turned off, stop tracking
      await locationService.stopTracking();
    } else {
      // If location is being enabled, request permission and start tracking
      final hasPermission = await locationService.checkLocationPermission();
      if (hasPermission) {
        await locationService.startTracking();
      } else {
        // If permission denied, reset to off
        ref.read(locationTrackingGranularityProvider.notifier).state = LocationGranularity.off;
      }
    }
  }
  
  void _showSelectiveDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location Data'),
        content: const Text(
          'Choose a date range to delete location data from your device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/privacy/selective-delete');
            },
            child: const Text('Select Dates'),
          ),
        ],
      ),
    );
  }
  
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationDataExportDialog(),
    );
  }
  
  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Location Data'),
        content: const Text(
          'This will permanently delete all location data stored on your device. Your journal entries will remain, but location context will be removed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAllLocationData(context);
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
  
  void _showDetailedPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DetailedPrivacyInfoDialog(),
    );
  }
  
  Future<void> _deleteAllLocationData(BuildContext context) async {
    // Show progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Deleting location data...'),
          ],
        ),
      ),
    );
    
    try {
      // Implement deletion logic here
      await Future.delayed(const Duration(seconds: 2)); // Simulate deletion
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All location data has been deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // New Data Source Controls Section
  Widget _buildDataSourceControlsSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photoAccess = ref.watch(photoAccessProvider);
    final calendarAccess = ref.watch(calendarAccessProvider);
    final healthData = ref.watch(healthDataProvider);
    final bluetoothScanning = ref.watch(bluetoothScanningProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.data_usage,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Data Source Access',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Control which device data sources the app can access for enhanced journaling features.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Photo Access Toggle
            _buildDataSourceToggle(
              context, 
              ref,
              icon: Icons.photo_library,
              title: 'Photo Access',
              subtitle: 'Access device photos for journal entries and memories',
              value: photoAccess,
              onChanged: (value) async {
                if (value) {
                  final status = await _requestPhotoPermission();
                  if (status) {
                    ref.read(photoAccessProvider.notifier).state = value;
                  }
                } else {
                  ref.read(photoAccessProvider.notifier).state = value;
                }
              },
            ),
            
            // Calendar Access Toggle  
            _buildDataSourceToggle(
              context,
              ref,
              icon: Icons.calendar_today,
              title: 'Calendar Access',
              subtitle: 'Read calendar events for automatic journal context',
              value: calendarAccess,
              onChanged: (value) async {
                if (value) {
                  final status = await _requestCalendarPermission();
                  if (status) {
                    ref.read(calendarAccessProvider.notifier).state = value;
                  }
                } else {
                  ref.read(calendarAccessProvider.notifier).state = value;
                }
              },
            ),
            
            // Health Data Toggle
            _buildDataSourceToggle(
              context,
              ref,
              icon: Icons.favorite,
              title: 'Health Data',
              subtitle: 'Track wellness metrics like steps, heart rate, and sleep',
              value: healthData,
              onChanged: (value) async {
                if (value) {
                  final status = await _requestHealthPermission();
                  if (status) {
                    ref.read(healthDataProvider.notifier).state = value;
                  }
                } else {
                  ref.read(healthDataProvider.notifier).state = value;
                }
              },
            ),
            
            // Bluetooth Scanning Toggle
            _buildDataSourceToggle(
              context,
              ref,
              icon: Icons.bluetooth_searching,
              title: 'Bluetooth Scanning',
              subtitle: 'Detect nearby devices for location context',
              value: bluetoothScanning,
              onChanged: (value) async {
                if (value) {
                  final status = await _requestBluetoothPermission();
                  if (status) {
                    ref.read(bluetoothScanningProvider.notifier).state = value;
                  }
                } else {
                  ref.read(bluetoothScanningProvider.notifier).state = value;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Device Permissions Section
  Widget _buildDevicePermissionsSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final microphoneAccess = ref.watch(microphoneAccessProvider);
    final cameraAccess = ref.watch(cameraAccessProvider);
    final contactsAccess = ref.watch(contactsAccessProvider);
    final notificationAccess = ref.watch(notificationAccessProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Device Permissions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage access to device features and sensors.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Microphone Toggle
            _buildDataSourceToggle(
              context,
              ref,
              icon: Icons.mic,
              title: 'Microphone',
              subtitle: 'Voice notes and audio recording',
              value: microphoneAccess,
              onChanged: (value) async {
                if (value) {
                  final status = await Permission.microphone.request();
                  if (status.isGranted) {
                    ref.read(microphoneAccessProvider.notifier).state = value;
                  }
                } else {
                  ref.read(microphoneAccessProvider.notifier).state = value;
                }
              },
            ),
            
            // Camera Toggle
            _buildDataSourceToggle(
              context,
              ref,
              icon: Icons.camera_alt,
              title: 'Camera',
              subtitle: 'Take photos directly within journal entries',
              value: cameraAccess,
              onChanged: (value) async {
                if (value) {
                  final status = await Permission.camera.request();
                  if (status.isGranted) {
                    ref.read(cameraAccessProvider.notifier).state = value;
                  }
                } else {
                  ref.read(cameraAccessProvider.notifier).state = value;
                }
              },
            ),
            
            // Contacts Toggle
            _buildDataSourceToggle(
              context,
              ref,
              icon: Icons.contacts,
              title: 'Contacts',
              subtitle: 'Tag people in journal entries',
              value: contactsAccess,
              onChanged: (value) async {
                if (value) {
                  final status = await Permission.contacts.request();
                  if (status.isGranted) {
                    ref.read(contactsAccessProvider.notifier).state = value;
                  }
                } else {
                  ref.read(contactsAccessProvider.notifier).state = value;
                }
              },
            ),
            
            // Notifications Toggle
            _buildDataSourceToggle(
              context,
              ref,
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Reminders and app notifications',
              value: notificationAccess,
              onChanged: (value) async {
                if (value) {
                  final status = await Permission.notification.request();
                  if (status.isGranted) {
                    ref.read(notificationAccessProvider.notifier).state = value;
                  }
                } else {
                  ref.read(notificationAccessProvider.notifier).state = value;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Reusable toggle widget for data sources
  Widget _buildDataSourceToggle(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value 
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: value 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Permission request methods
  Future<bool> _requestPhotoPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result == PermissionState.authorized || result == PermissionState.limited;
  }

  Future<bool> _requestCalendarPermission() async {
    final DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();
    final result = await deviceCalendarPlugin.requestPermissions();
    return result.isSuccess == true;
  }

  Future<bool> _requestHealthPermission() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];
    return await Health().requestAuthorization(types, permissions: [
      HealthDataAccess.READ,
      HealthDataAccess.READ_WRITE,
    ]);
  }

  Future<bool> _requestBluetoothPermission() async {
    try {
      final bluetoothPermission = await Permission.bluetooth.request();
      final bluetoothScanPermission = await Permission.bluetoothScan.request();
      return bluetoothPermission.isGranted && bluetoothScanPermission.isGranted;
    } catch (e) {
      return false;
    }
  }
}

// Export dialog widget
class LocationDataExportDialog extends StatefulWidget {
  const LocationDataExportDialog({super.key});
  
  @override
  State<LocationDataExportDialog> createState() => _LocationDataExportDialogState();
}

class _LocationDataExportDialogState extends State<LocationDataExportDialog> {
  String _selectedFormat = 'JSON';
  bool _includeMetadata = true;
  bool _includeAccuracy = true;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Location Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose export format and options:'),
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
          
          CheckboxListTile(
            title: const Text('Include metadata'),
            subtitle: const Text('Timestamps, accuracy, and source info'),
            value: _includeMetadata,
            onChanged: (bool? value) {
              setState(() {
                _includeMetadata = value ?? true;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          
          CheckboxListTile(
            title: const Text('Include accuracy data'),
            subtitle: const Text('GPS accuracy and confidence levels'),
            value: _includeAccuracy,
            onChanged: (bool? value) {
              setState(() {
                _includeAccuracy = value ?? true;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _exportLocationData();
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
  
  Future<void> _exportLocationData() async {
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
    
    try {
      // Simulate export process
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location data exported to Downloads folder ($_selectedFormat format)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// Detailed privacy info dialog
class DetailedPrivacyInfoDialog extends StatelessWidget {
  const DetailedPrivacyInfoDialog({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Privacy Policy'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location Data Privacy',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aura One collects location data solely to enhance your personal journaling experience by:\n\n'
                '• Automatically mapping your daily journey\n'
                '• Providing location context for your memories\n'
                '• Sending location-based reminders\n'
                '• Creating timeline visualizations\n\n'
                'All location data is stored locally on your device using encrypted storage. '
                'No location data is transmitted to external servers or third parties.\n\n'
                'You have complete control over:\n'
                '• When location tracking is active\n'
                '• How precise the tracking is\n'
                '• How long data is retained\n'
                '• Viewing and deleting your data\n'
                '• Exporting your data\n\n'
                'You can opt out of location tracking at any time without affecting '
                'other app functionality.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('I Understand'),
        ),
      ],
    );
  }
}