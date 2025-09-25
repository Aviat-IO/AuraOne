import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/simple_location_service.dart';
import '../services/persistent_location_service.dart';

class LocationSettingsCard extends ConsumerWidget {
  const LocationSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isTracking = ref.watch(isTrackingProvider);
    final locationService = ref.read(simpleLocationServiceProvider);
    final currentLocation = ref.watch(currentLocationProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: isTracking ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location Tracking',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isTracking ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isTracking ? Colors.green : Colors.grey).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isTracking ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isTracking ? 'Tracking Active' : 'Tracking Disabled',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isTracking ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (currentLocation != null && isTracking) ...[
                    Icon(
                      Icons.my_location,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Platform-specific info
            if (Platform.isAndroid) ...[
              _buildPlatformInfo(
                context,
                Icons.android,
                'Android',
                isTracking
                  ? '• Location service active\n• Background location permitted\n• Battery optimization may affect tracking'
                  : '• Requires location permission\n• May need battery optimization disabled',
              ),
            ] else if (Platform.isIOS) ...[
              _buildPlatformInfo(
                context,
                Icons.apple,
                'iOS',
                isTracking
                  ? '• Background location active\n• Using location updates\n• Blue status bar indicator when tracking'
                  : '• Requires "Always Allow" permission\n• Background App Refresh must be enabled',
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isTracking
                      ? null
                      : () async {
                          final success = await locationService.startTracking();
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to start tracking. Check permissions.'),
                              ),
                            );
                          }
                        },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Tracking'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !isTracking
                      ? null
                      : () async {
                          await locationService.stopTracking();
                        },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Tracking'),
                  ),
                ),
              ],
            ),

            // Battery optimization guidance (Android only)
            if (Platform.isAndroid) ...[
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.battery_saver, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Improve Background Tracking',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For reliable location tracking when the app is closed:',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _showBatteryOptimizationDialog(context),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('View Setup Instructions'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  }

  Widget _buildPlatformInfo(
    BuildContext context,
    IconData icon,
    String platform,
    String info,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              '$platform Settings',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          info,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  void _showBatteryOptimizationDialog(BuildContext context) {
    final persistentLocationService = PersistentLocationService();
    final guidance = persistentLocationService.getBatteryOptimizationGuidance();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_saver, color: Colors.orange),
            SizedBox(width: 8),
            Text('Battery Optimization Setup'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To ensure continuous location tracking when the app is closed, you need to disable battery optimization for Aura One.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Step-by-Step Instructions:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Open your device Settings\n'
                      '2. Go to "Apps" or "Application Manager"\n'
                      '3. Find and tap "Aura One"\n'
                      '4. Tap "Battery" or "Battery usage"\n'
                      '5. Select "Don\'t optimize" or "Allow background activity"\n\n'
                      'Alternative path:\n'
                      '• Settings → Battery → Battery optimization\n'
                      '• Find Aura One → Don\'t optimize',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Why This Helps:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Prevents Android from killing the location service\n'
                      '• Ensures tracking continues when app is closed\n'
                      '• Required for automatic journaling to work properly\n'
                      '• Captures locations every 2 minutes (instead of missing hours)',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Note: This will slightly increase battery usage but is necessary for continuous tracking.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
