import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../database/context_database.dart';
import '../../services/context_manager_service.dart';
import '../../services/privacy_sanitizer.dart';
import '../../theme/colors.dart';
import '../../widgets/page_header.dart';
import '../../widgets/context/components/person_card.dart';
import '../../widgets/context/person_label_dialog.dart';
import 'person_detail_screen.dart';

final peopleListProvider = FutureProvider.autoDispose<List<Person>>((ref) async {
  final contextManager = ContextManagerService();
  return await contextManager.getAllPeople();
});

final photoCountProvider = FutureProvider.autoDispose.family<int, int>((ref, personId) async {
  // TODO: Add method to get photo count per person
  // Will query PhotoPersonLink table when implemented
  return 0; // Placeholder
});

class PeopleListScreen extends HookConsumerWidget {
  const PeopleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final selectedFilter = useState<String>('All');

    final peopleAsync = ref.watch(peopleListProvider);

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
                            icon: Icons.people,
                            title: 'People',
                            subtitle: 'Manage your contacts',
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showAddPersonDialog(context, ref),
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
                        hintText: 'Search people...',
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
                            selectedFilter,
                            isLight,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context,
                            'Family',
                            selectedFilter,
                            isLight,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context,
                            'Friends',
                            selectedFilter,
                            isLight,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context,
                            'Work',
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
                child: peopleAsync.when(
                  data: (people) {
                    final filteredPeople = _filterPeople(
                      people,
                      searchQuery.value,
                      selectedFilter.value,
                    );

                    if (filteredPeople.isEmpty) {
                      return _buildEmptyState(context, ref, theme, isLight);
                    }

                    final grouped = _groupPeople(filteredPeople);

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(peopleListProvider);
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
        onPressed: () => _showAddPersonDialog(context, ref),
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
    ValueNotifier<String> selectedFilter,
    bool isLight,
  ) {
    final isSelected = selectedFilter.value == label;
    
    return FilterChip(
      label: Text(label),
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
    List<Person> people,
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
        ...people.map((person) {
          final photoCountAsync = ref.watch(photoCountProvider(person.id));
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: photoCountAsync.when(
              data: (count) => PersonCard(
                person: person,
                photoCount: count,
                lastSeen: person.lastSeen,
                onTap: () => _showPersonDetails(context, person),
                onEdit: () => _editPerson(context, ref, person),
                onDelete: () => _deletePerson(context, ref, person),
              ),
              loading: () => PersonCard(
                person: person,
                photoCount: 0,
                lastSeen: person.lastSeen,
              ),
              error: (_, __) => PersonCard(
                person: person,
                photoCount: 0,
                lastSeen: person.lastSeen,
              ),
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
              Icons.people_outline,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No people added yet',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Label people in your photos to make your journal entries more personal',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddPersonDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Person'),
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

  List<Person> _filterPeople(List<Person> people, String query, String filter) {
    var filtered = people;

    if (query.isNotEmpty) {
      filtered = filtered.where((person) {
        return person.name.toLowerCase().contains(query.toLowerCase()) ||
            person.relationship.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    if (filter != 'All') {
      filtered = filtered.where((person) {
        final rel = person.relationship.toLowerCase();
        switch (filter) {
          case 'Family':
            return rel.contains('parent') ||
                rel.contains('mother') ||
                rel.contains('father') ||
                rel.contains('brother') ||
                rel.contains('sister') ||
                rel.contains('child') ||
                rel.contains('son') ||
                rel.contains('daughter') ||
                rel.contains('spouse') ||
                rel.contains('partner') ||
                rel.contains('grandparent') ||
                rel.contains('grandmother') ||
                rel.contains('grandfather') ||
                rel.contains('aunt') ||
                rel.contains('uncle') ||
                rel.contains('cousin') ||
                rel.contains('niece') ||
                rel.contains('nephew') ||
                rel.contains('grandchild') ||
                rel.contains('grandson') ||
                rel.contains('granddaughter');
          case 'Friends':
            return rel.contains('friend');
          case 'Work':
            return rel.contains('colleague') ||
                rel.contains('manager') ||
                rel.contains('boss') ||
                rel.contains('client') ||
                rel.contains('mentor');
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  Map<String, List<Person>> _groupPeople(List<Person> people) {
    final groups = <String, List<Person>>{
      'Family': [],
      'Friends': [],
      'Professional': [],
      'Other': [],
    };

    for (final person in people) {
      final rel = person.relationship.toLowerCase();
      
      if (rel.contains('parent') ||
          rel.contains('mother') ||
          rel.contains('father') ||
          rel.contains('brother') ||
          rel.contains('sister') ||
          rel.contains('child') ||
          rel.contains('son') ||
          rel.contains('daughter') ||
          rel.contains('spouse') ||
          rel.contains('partner') ||
          rel.contains('grandparent') ||
          rel.contains('grandmother') ||
          rel.contains('grandfather') ||
          rel.contains('aunt') ||
          rel.contains('uncle') ||
          rel.contains('cousin') ||
          rel.contains('niece') ||
          rel.contains('nephew') ||
          rel.contains('grandchild') ||
          rel.contains('grandson') ||
          rel.contains('granddaughter')) {
        groups['Family']!.add(person);
      } else if (rel.contains('friend')) {
        groups['Friends']!.add(person);
      } else if (rel.contains('colleague') ||
          rel.contains('manager') ||
          rel.contains('boss') ||
          rel.contains('client') ||
          rel.contains('mentor')) {
        groups['Professional']!.add(person);
      } else {
        groups['Other']!.add(person);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  void _showAddPersonDialog(BuildContext context, WidgetRef ref) async {
    final person = await showDialog(
      context: context,
      builder: (context) => const PersonLabelDialog(),
    );
    
    if (person != null && context.mounted) {
      ref.invalidate(peopleListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${person.name} added successfully'),
          backgroundColor: AuraColors.lightPrimary,
        ),
      );
    }
  }

  void _showPersonDetails(BuildContext context, Person person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersonDetailScreen(personId: person.id),
      ),
    );
  }

  void _editPerson(BuildContext context, WidgetRef ref, Person person) async {
    final updated = await showDialog(
      context: context,
      builder: (context) => PersonLabelDialog(
        initialName: person.name,
        initialRelationship: person.relationship.isNotEmpty 
            ? person.relationship 
            : null,
        initialPrivacyLevel: PrivacyLevel.values[person.privacyLevel],
      ),
    );
    
    if (updated != null && context.mounted) {
      ref.invalidate(peopleListProvider);
    }
  }

  void _deletePerson(BuildContext context, WidgetRef ref, Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person'),
        content: Text('Are you sure you want to delete ${person.name}?'),
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
        await contextManager.deletePerson(person.id);
        ref.invalidate(peopleListProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${person.name} deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting person: $e')),
          );
        }
      }
    }
  }
}
