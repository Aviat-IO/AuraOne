import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../../services/background_location_service.dart';

class DataViewerScreen extends HookConsumerWidget {
  const DataViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locationService = ref.watch(backgroundLocationServiceProvider);

    // Location event states
    final currentLocation = useState<bg.Location?>(null);
    final recentLocations = useState<List<bg.Location>>([]);
    final trackingStats = useState<Map<String, dynamic>>({});
    final isTracking = useState<bool>(false);

    // Load tracking state and stats
    useEffect(() {
      void loadTrackingState() async {
        final tracking = await locationService.isTrackingEnabled();
        isTracking.value = tracking;

        final stats = await locationService.getTrackingStats();
        trackingStats.value = stats;
      }

      loadTrackingState();

      // Refresh stats periodically
      final timer = Timer.periodic(const Duration(seconds: 5), (_) {
        loadTrackingState();
      });

      return () => timer.cancel();
    }, []);

    // Listen to location events
    useEffect(() {
      void locationCallback(bg.Location location) {
        currentLocation.value = location;

        // Add to recent locations (keep last 20)
        final locations = [...recentLocations.value, location];
        if (locations.length > 20) {
          locations.removeAt(0);
        }
        recentLocations.value = locations;
      }

      // Add listener
      bg.BackgroundGeolocation.onLocation(locationCallback);

      // Cleanup - remove listener by replacing with empty callback
      return () {
        bg.BackgroundGeolocation.onLocation((location) {});
      };
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking Debug'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isTracking.value ? Icons.pause : Icons.play_arrow),
            onPressed: () async {
              if (isTracking.value) {
                await locationService.stopTracking();
              } else {
                await locationService.startTracking();
              }
              isTracking.value = await locationService.isTrackingEnabled();
            },
            tooltip: isTracking.value ? 'Stop Tracking' : 'Start Tracking',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tracking Status Card
              _buildDataCard(
                title: 'Tracking Status',
                icon: isTracking.value ? Icons.location_on : Icons.location_off,
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow('Status', isTracking.value ? 'Active' : 'Stopped'),
                    _buildDataRow('State', trackingStats.value['isMoving']?.toString() ?? 'N/A'),
                    _buildDataRow('Tracking Mode', trackingStats.value['trackingMode']?.toString() ?? 'N/A'),
                    _buildDataRow('Distance Filter', '${trackingStats.value['distanceFilter'] ?? 'N/A'} m'),
                    _buildDataRow('Desired Accuracy', '${trackingStats.value['desiredAccuracy'] ?? 'N/A'} m'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Current Location Card
              if (currentLocation.value != null)
                _buildDataCard(
                  title: 'Current Location',
                  icon: Icons.my_location,
                  theme: theme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataRow(
                        'Latitude',
                        currentLocation.value!.coords.latitude.toStringAsFixed(6),
                      ),
                      _buildDataRow(
                        'Longitude',
                        currentLocation.value!.coords.longitude.toStringAsFixed(6),
                      ),
                      _buildDataRow(
                        'Accuracy',
                        '${currentLocation.value!.coords.accuracy.toStringAsFixed(1)} m',
                      ),
                      _buildDataRow(
                        'Altitude',
                        '${currentLocation.value!.coords.altitude.toStringAsFixed(1)} m',
                      ),
                      _buildDataRow(
                        'Speed',
                        '${(currentLocation.value!.coords.speed * 3.6).toStringAsFixed(1)} km/h',
                      ),
                      _buildDataRow(
                        'Heading',
                        '${currentLocation.value!.coords.heading.toStringAsFixed(0)}°',
                      ),
                      _buildDataRow(
                        'Timestamp',
                        currentLocation.value!.timestamp,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Activity Detection Card
              if (currentLocation.value != null)
                _buildDataCard(
                  title: 'Activity Detection',
                  icon: Icons.directions_walk,
                  theme: theme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataRow(
                        'Activity Type',
                        currentLocation.value!.activity.type,
                      ),
                      _buildDataRow(
                        'Confidence',
                        '${currentLocation.value!.activity.confidence}%',
                      ),
                      _buildDataRow(
                        'Is Moving',
                        currentLocation.value!.isMoving ? 'Yes' : 'No',
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Recent Locations List
              _buildDataCard(
                title: 'Recent Locations (${recentLocations.value.length})',
                icon: Icons.list,
                theme: theme,
                child: recentLocations.value.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No locations recorded yet'),
                      )
                    : Column(
                        children: recentLocations.value.reversed.take(10).map((loc) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                loc.isMoving ? Icons.directions_walk : Icons.location_on,
                                color: loc.isMoving ? Colors.green : Colors.blue,
                              ),
                              title: Text(
                                '${loc.coords.latitude.toStringAsFixed(4)}, ${loc.coords.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              subtitle: Text(
                                '${loc.activity.type} (${loc.activity.confidence}%) - ${loc.timestamp}',
                                style: const TextStyle(fontSize: 10),
                              ),
                              trailing: Text(
                                '±${loc.coords.accuracy.toStringAsFixed(0)}m',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),

              // Debug Actions
              _buildDataCard(
                title: 'Debug Actions',
                icon: Icons.bug_report,
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final location = await locationService.getCurrentLocation();
                        if (location != null) {
                          currentLocation.value = location;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Current location retrieved')),
                          );
                        }
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('Get Current Location'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await locationService.changePace(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pace set to MOVING')),
                        );
                      },
                      icon: const Icon(Icons.directions_run),
                      label: const Text('Simulate Moving'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await locationService.changePace(false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pace set to STATIONARY')),
                        );
                      },
                      icon: const Icon(Icons.stop),
                      label: const Text('Simulate Stationary'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCard({
    required String title,
    required IconData icon,
    required ThemeData theme,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
