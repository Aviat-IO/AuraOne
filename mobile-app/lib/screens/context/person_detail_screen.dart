import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/context_database.dart';
import '../../services/context_manager_service.dart';
import '../../services/privacy_sanitizer.dart';
import '../../theme/colors.dart';
import '../../widgets/context/components/person_avatar.dart';
import '../../widgets/context/components/privacy_indicator.dart';
import '../../widgets/context/person_label_dialog.dart';

final personDetailProvider = FutureProvider.autoDispose.family<Person?, int>((ref, personId) async {
  final contextManager = ContextManagerService();
  return await contextManager.getPersonById(personId);
});

final personPhotosProvider = FutureProvider.autoDispose.family<List<PhotoPersonLink>, int>((ref, personId) async {
  final contextManager = ContextManagerService();
  return await contextManager.getPhotoPersonLinks(''); // TODO: Implement getPersonPhotoLinks
});

class PersonDetailScreen extends HookConsumerWidget {
  final int personId;

  const PersonDetailScreen({
    super.key,
    required this.personId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    final personAsync = ref.watch(personDetailProvider(personId));
    final photosAsync = ref.watch(personPhotosProvider(personId));

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
          child: personAsync.when(
            data: (person) {
              if (person == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 80,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Person not found',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: isLight
                        ? AuraColors.lightPrimary
                        : AuraColors.darkPrimary,
                    leading: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => _editPerson(context, person),
                        icon: const Icon(Icons.edit, color: Colors.white),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deletePerson(context, ref, person);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Person'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isLight
                                ? [AuraColors.lightPrimary, AuraColors.lightSecondary]
                                : [AuraColors.darkPrimary, AuraColors.darkSecondary],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            PersonAvatar(
                              name: person.name,
                              size: PersonAvatarSize.xlarge,
                              showBorder: true,
                              borderColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  person.name,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (person.relationship.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    person.relationship,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          _buildStatsCard(context, theme, isLight, person, photosAsync),
                          const SizedBox(height: 16),
                          
                          _buildPrivacyCard(context, theme, isLight, person),
                          const SizedBox(height: 24),
                          
                          Text(
                            'Recent Photos',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          photosAsync.when(
                            data: (photos) {
                              if (photos.isEmpty) {
                                return _buildEmptyPhotos(context, theme);
                              }
                              return _buildPhotoGrid(context, photos);
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) => _buildEmptyPhotos(context, theme),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    Person person,
    AsyncValue<List<PhotoPersonLink>> photosAsync,
  ) {
    final photoCount = photosAsync.maybeWhen(
      data: (photos) => photos.length,
      orElse: () => 0,
    );

    final now = DateTime.now();
    final firstSeenDiff = now.difference(person.firstSeen);
    final lastSeenDiff = now.difference(person.lastSeen);

    return Container(
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
        boxShadow: [
          BoxShadow(
            color: isLight
                ? AuraColors.lightPrimary.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistics',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            context,
            Icons.photo,
            '$photoCount photos',
            theme,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            Icons.schedule,
            'First seen: ${_formatDuration(firstSeenDiff)} ago',
            theme,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            Icons.access_time,
            'Last seen: ${_formatDuration(lastSeenDiff)} ago',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String text,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyCard(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    Person person,
  ) {
    final privacyLevel = PrivacyLevel.values[person.privacyLevel];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isLight ? AuraColors.lightPrimary : AuraColors.darkPrimary)
                .withValues(alpha: 0.1),
            (isLight ? AuraColors.lightSecondary : AuraColors.darkSecondary)
                .withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: (isLight ? AuraColors.lightPrimary : AuraColors.darkPrimary)
              .withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Privacy Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              PrivacyIndicator(
                level: privacyLevel,
                showLabel: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _editPerson(context, person),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Change Privacy Level'),
            style: FilledButton.styleFrom(
              backgroundColor: isLight
                  ? AuraColors.lightPrimary
                  : AuraColors.darkPrimary,
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotos(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No photos yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Photos with this person will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, List<PhotoPersonLink> photos) {
    final displayPhotos = photos.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: displayPhotos.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          child: Center(
            child: Icon(
              Icons.photo,
              color: Colors.grey.shade400,
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays == 0) {
      if (duration.inHours == 0) {
        return '${duration.inMinutes} minutes';
      }
      return '${duration.inHours} hours';
    } else if (duration.inDays == 1) {
      return '1 day';
    } else if (duration.inDays < 7) {
      return '${duration.inDays} days';
    } else if (duration.inDays < 30) {
      final weeks = (duration.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';
    } else {
      final months = (duration.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    }
  }

  void _editPerson(BuildContext context, Person person) {
    showDialog(
      context: context,
      builder: (context) => PersonLabelDialog(
        initialName: person.name,
        initialRelationship: person.relationship.isNotEmpty 
            ? person.relationship 
            : null,
        initialPrivacyLevel: PrivacyLevel.values[person.privacyLevel],
      ),
    );
  }

  void _deletePerson(BuildContext context, WidgetRef ref, Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person'),
        content: Text(
          'Are you sure you want to delete ${person.name}? This will remove all associations with photos.',
        ),
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
        
        if (context.mounted) {
          context.pop();
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
