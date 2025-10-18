import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../database/context_database.dart';
import '../../services/context_manager_service.dart';
import '../../theme/colors.dart';
import '../../widgets/page_header.dart';
import '../../widgets/context/components/place_card.dart';

import '../../widgets/context/place_naming_dialog.dart';
import 'place_detail_screen.dart';

final placesListProvider = FutureProvider.autoDispose<List<Place>>((ref) async {
  final contextManager = ContextManagerService();
  return await contextManager.getAllPlaces();
});

class PlacesListScreen extends HookConsumerWidget {
  const PlacesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final selectedFilter = useState<String>('All');

    final placesAsync = ref.watch(placesListProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? [
                    AuraColors.lightSurface,
                    AuraColors.lightSurface.withValues(alpha: 0.95),
                    AuraColors.lightSurfaceContainerLow.withValues(alpha: 0.9),
                  ]
                : [
                    AuraColors.darkSurface,
                    AuraColors.darkSurface.withValues(alpha: 0.98),
                    AuraColors.darkSurfaceContainerLow.withValues(alpha: 0.95),
                  ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Expanded(
                          child: PageHeader(
                            icon: Icons.place,
                            title: 'Places',
                            subtitle: 'Manage your locations',
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showAddPlaceDialog(context, ref),
                          icon: Icon(
                            Icons.add,
                            color: isLight
                                ? AuraColors.lightPrimary
                                : AuraColors.darkPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: searchController,
                      onChanged: (value) => searchQuery.value = value,
                      decoration: InputDecoration(
                        hintText: 'Search places...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            context,
                            'All',
                            Icons.apps,
                            selectedFilter,
                            isLight,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context,
                            'Primary',
                            Icons.star,
                            selectedFilter,
                            isLight,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context,
                            'Frequent',
                            Icons.repeat,
                            selectedFilter,
                            isLight,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: placesAsync.when(
                  data: (places) {
                    final filteredPlaces = _filterPlaces(
                      places,
                      searchQuery.value,
                      selectedFilter.value,
                    );

                    if (filteredPlaces.isEmpty) {
                      return _buildEmptyState(context, ref, theme, isLight);
                    }

                    final grouped = _groupPlaces(filteredPlaces);

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(placesListProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final entry = grouped.entries.elementAt(index);
                          return _buildSection(
                            context,
                            ref,
                            theme,
                            entry.key,
                            entry.value,
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlaceDialog(context, ref),
        backgroundColor: isLight
            ? AuraColors.lightPrimary
            : AuraColors.darkPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    IconData icon,
    ValueNotifier<String> selectedFilter,
    bool isLight,
  ) {
    final isSelected = selectedFilter.value == label;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        selectedFilter.value = selected ? label : 'All';
      },
      selectedColor: isLight
          ? AuraColors.lightPrimary.withValues(alpha: 0.3)
          : AuraColors.darkPrimary.withValues(alpha: 0.3),
      checkmarkColor: isLight
          ? AuraColors.lightPrimary
          : AuraColors.darkPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? (isLight ? AuraColors.lightPrimary : AuraColors.darkPrimary)
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    String title,
    List<Place> places,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ...places.map((place) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PlaceCard(
              place: place,
              onTap: () => _showPlaceDetails(context, place),
              onEdit: () => _editPlace(context, ref, place),
              onDelete: () => _deletePlace(context, ref, place),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, ThemeData theme, bool isLight) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No places added yet',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Name places you visit frequently to make your journal entries more personal',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddPlaceDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Place'),
              style: FilledButton.styleFrom(
                backgroundColor: isLight
                    ? AuraColors.lightPrimary
                    : AuraColors.darkPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Place> _filterPlaces(List<Place> places, String query, String filter) {
    var filtered = places;

    if (query.isNotEmpty) {
      filtered = filtered.where((place) {
        return place.name.toLowerCase().contains(query.toLowerCase()) ||
            place.category.toLowerCase().contains(query.toLowerCase()) ||
            (place.neighborhood?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (place.city?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    }

    if (filter != 'All') {
      filtered = filtered.where((place) {
        switch (filter) {
          case 'Primary':
            return place.significanceLevel == 2;
          case 'Frequent':
            return place.significanceLevel == 1;
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  Map<String, List<Place>> _groupPlaces(List<Place> places) {
    final groups = <String, List<Place>>{
      'Primary Places': [],
      'Frequent Places': [],
      'Occasional Places': [],
    };

    for (final place in places) {
      switch (place.significanceLevel) {
        case 2:
          groups['Primary Places']!.add(place);
          break;
        case 1:
          groups['Frequent Places']!.add(place);
          break;
        default:
          groups['Occasional Places']!.add(place);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  void _showAddPlaceDialog(BuildContext context, WidgetRef ref) async {
    final place = await showDialog(
      context: context,
      builder: (context) => const PlaceNamingDialog(
        latitude: 40.7128, // Default to NYC (will be replaced with actual location)
        longitude: -74.0060,
        address: 'Current location', // Will be replaced with actual address
      ),
    );
    
    if (place != null && context.mounted) {
      ref.invalidate(placesListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${place.name} added successfully'),
          backgroundColor: AuraColors.lightPrimary,
        ),
      );
    }
  }

  void _showPlaceDetails(BuildContext context, Place place) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaceDetailScreen(placeId: place.id),
      ),
    );
  }

  void _editPlace(BuildContext context, WidgetRef ref, Place place) async {
    final updated = await showDialog(
      context: context,
      builder: (context) => PlaceNamingDialog(
        latitude: place.latitude,
        longitude: place.longitude,
        initialName: place.name,
        suggestedCategory: place.category,
      ),
    );
    
    if (updated != null && context.mounted) {
      ref.invalidate(placesListProvider);
    }
  }

  void _deletePlace(BuildContext context, WidgetRef ref, Place place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Place'),
        content: Text('Are you sure you want to delete ${place.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AuraColors.lightError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final contextManager = ContextManagerService();
        await contextManager.deletePlace(place.id);
        ref.invalidate(placesListProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${place.name} deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting place: $e')),
          );
        }
      }
    }
  }
}
