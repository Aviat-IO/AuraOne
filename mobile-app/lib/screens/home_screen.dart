import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/simple_location_service.dart';
import '../widgets/location_settings_card.dart';
import '../widgets/photo_permission_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentLocation = ref.watch(currentLocationProvider);
    final isTracking = ref.watch(isTrackingProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura One'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip),
            onPressed: () => context.push('/privacy'),
            tooltip: 'Privacy Settings',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to general settings
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.self_improvement,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to Aura One',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your personal wellness journey starts here',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              // TODO: Navigate to journal entry
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('New Journal Entry'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Location Status Card
            const LocationSettingsCard(),
            const SizedBox(height: 16),
            
            // Photo Library Permission Card
            const PhotoPermissionCard(),
            const SizedBox(height: 16),
            
            // Current Location Card (if tracking)
            if (isTracking && currentLocation != null) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current Location',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLocationInfo(
                        'Coordinates',
                        '${currentLocation.latitude.toStringAsFixed(6)}, ${currentLocation.longitude.toStringAsFixed(6)}',
                        theme,
                      ),
                      const SizedBox(height: 8),
                      _buildLocationInfo(
                        'Accuracy',
                        '±${currentLocation.accuracy.toStringAsFixed(0)}m',
                        theme,
                      ),
                      const SizedBox(height: 8),
                      _buildLocationInfo(
                        'Altitude',
                        '${currentLocation.altitude.toStringAsFixed(0)}m',
                        theme,
                      ),
                      if (currentLocation.speed > 0) ...[
                        const SizedBox(height: 8),
                        _buildLocationInfo(
                          'Speed',
                          '${(currentLocation.speed * 3.6).toStringAsFixed(1)} km/h',
                          theme,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Quick Stats Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.insights,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Today\'s Activity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.edit_note,
                          value: '0',
                          label: 'Entries',
                          theme: theme,
                        ),
                        _buildStatItem(
                          icon: Icons.place,
                          value: '0',
                          label: 'Places',
                          theme: theme,
                        ),
                        _buildStatItem(
                          icon: Icons.timer,
                          value: '0h',
                          label: 'Active',
                          theme: theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Recent Entries Card (placeholder)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Recent Entries',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to all entries
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.note_add,
                            size: 48,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No journal entries yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start writing to capture your journey',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to new entry screen
        },
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }
  
  Widget _buildLocationInfo(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}