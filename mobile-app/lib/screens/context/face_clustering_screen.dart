import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/colors.dart';
import '../../widgets/page_header.dart';
import '../../widgets/context/person_label_dialog.dart';

// Placeholder provider - will be replaced with actual face detection integration
final unlabeledFaceClustersProvider = FutureProvider.autoDispose<List<FaceCluster>>((ref) async {
  // TODO: Integrate with ML Kit face detection
  // For now, return empty list
  return [];
});

class FaceCluster {
  final String id;
  final List<String> photoIds;
  final DateTime firstSeen;
  final int photoCount;

  FaceCluster({
    required this.id,
    required this.photoIds,
    required this.firstSeen,
    required this.photoCount,
  });
}

class FaceClusteringScreen extends HookConsumerWidget {
  const FaceClusteringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final clustersAsync = ref.watch(unlabeledFaceClustersProvider);

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
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: PageHeader(
                        icon: Icons.face,
                        title: 'Label People',
                        subtitle: 'Identify people in your photos',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: clustersAsync.when(
                  data: (clusters) {
                    if (clusters.isEmpty) {
                      return _buildEmptyState(context, theme, isLight);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(unlabeledFaceClustersProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: clusters.length,
                        itemBuilder: (context, index) {
                          final cluster = clusters[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildClusterCard(
                              context,
                              theme,
                              isLight,
                              cluster,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading faces',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClusterCard(
    BuildContext context,
    ThemeData theme,
    bool isLight,
    FaceCluster cluster,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Face preview grid (3x4)
          _buildFaceGrid(cluster),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cluster.photoCount} photos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'First seen: ${_formatDate(cluster.firstSeen)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          FilledButton.icon(
            onPressed: () => _labelCluster(context, cluster),
            icon: const Icon(Icons.label, size: 18),
            label: const Text('Label This Person'),
            style: FilledButton.styleFrom(
              backgroundColor: isLight
                  ? AuraColors.lightPrimary
                  : AuraColors.darkPrimary,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceGrid(FaceCluster cluster) {
    final displayCount = cluster.photoCount.clamp(1, 12);
    
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: displayCount,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: Center(
              child: Icon(
                Icons.face,
                color: Colors.grey.shade400,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isLight) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLight
                    ? AuraColors.lightPrimaryContainer
                    : AuraColors.darkPrimaryContainer,
              ),
              child: Icon(
                Icons.face,
                size: 64,
                color: isLight
                    ? AuraColors.lightOnPrimaryContainer
                    : AuraColors.darkOnPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No unlabeled faces found',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We haven\'t detected any unlabeled faces in your recent photos.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  void _labelCluster(BuildContext context, FaceCluster cluster) {
    showDialog(
      context: context,
      builder: (context) => PersonLabelDialog(
        photoId: cluster.photoIds.isNotEmpty ? cluster.photoIds.first : null,
        faceIndex: 0,
      ),
    ).then((person) {
      if (person != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${person.name} labeled in ${cluster.photoCount} photos'),
            backgroundColor: AuraColors.lightPrimary,
          ),
        );
        Navigator.of(context).pop();
      }
    });
  }
}
