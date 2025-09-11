import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/colors.dart';

// Provider for map data
final mapDataProvider = StateProvider.family<MapData?, DateTime>((ref, date) {
  // TODO: Replace with actual location data from storage
  return MapData(
    locations: [
      LocationPoint(
        latitude: 37.7749,
        longitude: -122.4194,
        time: DateTime(date.year, date.month, date.day, 7, 30),
        name: 'Home',
        type: LocationType.home,
      ),
      LocationPoint(
        latitude: 37.7849,
        longitude: -122.4094,
        time: DateTime(date.year, date.month, date.day, 9, 0),
        name: 'Office',
        type: LocationType.work,
      ),
      LocationPoint(
        latitude: 37.7949,
        longitude: -122.3994,
        time: DateTime(date.year, date.month, date.day, 12, 30),
        name: 'Lunch Spot',
        type: LocationType.food,
      ),
    ],
    totalDistance: 5.2,
    totalTime: Duration(hours: 14, minutes: 30),
  );
});

// Provider for loading state
final mapLoadingProvider = StateProvider<bool>((ref) => false);

enum LocationType { home, work, food, shopping, exercise, social, other }

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime time;
  final String name;
  final LocationType type;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.time,
    required this.name,
    required this.type,
  });
}

class MapData {
  final List<LocationPoint> locations;
  final double totalDistance;
  final Duration totalTime;

  MapData({
    required this.locations,
    required this.totalDistance,
    required this.totalTime,
  });
}

class MapWidget extends ConsumerWidget {
  final DateTime date;

  const MapWidget({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final mapData = ref.watch(mapDataProvider(date));
    final isLoading = ref.watch(mapLoadingProvider);

    return Skeletonizer(
      enabled: isLoading,
      child: Column(
        children: [
          // Map placeholder (will be replaced with flutter_map)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Stack(
                children: [
                  // Map placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Map View',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Interactive map will be displayed here',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map controls
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        _buildMapControl(
                          icon: Icons.add,
                          onTap: () {
                            // TODO: Zoom in
                          },
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildMapControl(
                          icon: Icons.remove,
                          onTap: () {
                            // TODO: Zoom out
                          },
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildMapControl(
                          icon: Icons.my_location,
                          onTap: () {
                            // TODO: Center on current location
                          },
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location stats
          if (mapData != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isLight
                      ? AuraColors.lightCardGradient
                      : AuraColors.darkCardGradient,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    icon: Icons.place,
                    value: mapData.locations.length.toString(),
                    label: 'Places',
                    theme: theme,
                  ),
                  _buildStat(
                    icon: Icons.straighten,
                    value: '${mapData.totalDistance.toStringAsFixed(1)} km',
                    label: 'Distance',
                    theme: theme,
                  ),
                  _buildStat(
                    icon: Icons.timer,
                    value: '${mapData.totalTime.inHours}h ${mapData.totalTime.inMinutes % 60}m',
                    label: 'Active Time',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],

          // Location list
          if (mapData != null && mapData.locations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: mapData.locations.length,
                itemBuilder: (context, index) {
                  final location = mapData.locations[index];
                  return _buildLocationCard(
                    location: location,
                    theme: theme,
                    isLight: isLight,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
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

  Widget _buildLocationCard({
    required LocationPoint location,
    required ThemeData theme,
    required bool isLight,
  }) {
    final color = _getLocationColor(location.type, theme);

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Focus on location on map
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getLocationIcon(location.type),
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  location.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${location.time.hour.toString().padLeft(2, '0')}:${location.time.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getLocationIcon(LocationType type) {
    switch (type) {
      case LocationType.home:
        return Icons.home;
      case LocationType.work:
        return Icons.work;
      case LocationType.food:
        return Icons.restaurant;
      case LocationType.shopping:
        return Icons.shopping_bag;
      case LocationType.exercise:
        return Icons.fitness_center;
      case LocationType.social:
        return Icons.people;
      case LocationType.other:
        return Icons.place;
    }
  }

  Color _getLocationColor(LocationType type, ThemeData theme) {
    switch (type) {
      case LocationType.home:
        return theme.colorScheme.primary;
      case LocationType.work:
        return Colors.blue;
      case LocationType.food:
        return Colors.orange;
      case LocationType.shopping:
        return Colors.purple;
      case LocationType.exercise:
        return Colors.green;
      case LocationType.social:
        return Colors.pink;
      case LocationType.other:
        return Colors.grey;
    }
  }
}
