import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/simple_location_service.dart';

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
}