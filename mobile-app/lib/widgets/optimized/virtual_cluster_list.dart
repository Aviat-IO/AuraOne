import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../services/ai/dbscan_clustering.dart';

/// Virtual scrolling list for clusters - only renders visible items
class VirtualClusterList extends HookConsumerWidget {
  final List<LocationCluster> clusters;
  final Function(LocationCluster)? onClusterTap;

  const VirtualClusterList({
    super.key,
    required this.clusters,
    this.onClusterTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use ListView.builder with item extent for optimal performance
    return ListView.builder(
      // Critical performance optimizations
      itemExtent: 80.0, // Fixed height enables better scrolling performance
      cacheExtent: 240.0, // Cache 3 items above and below
      addAutomaticKeepAlives: false, // Don't keep widgets alive
      addRepaintBoundaries: true, // Add repaint boundaries
      physics: const ClampingScrollPhysics(), // Smoother scrolling

      itemCount: clusters.length,
      itemBuilder: (context, index) {
        return _ClusterTile(
          cluster: clusters[index],
          onTap: onClusterTap,
        );
      },
    );
  }
}

/// Optimized cluster tile with minimal rebuilds
class _ClusterTile extends StatelessWidget {
  final LocationCluster cluster;
  final Function(LocationCluster)? onTap;

  const _ClusterTile({
    required this.cluster,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use const widgets where possible
    return InkWell(
      onTap: onTap != null ? () => onTap!(cluster) : null,
      child: Container(
        height: 80, // Fixed height for performance
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon with fixed size
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: theme.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time range
                  Text(
                    _formatTimeRange(cluster),
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Duration and point count
                  Text(
                    '${_formatDuration(cluster.duration)} • ${cluster.points.length} points',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRange(LocationCluster cluster) {
    final start = '${cluster.startTime.hour.toString().padLeft(2, '0')}:'
        '${cluster.startTime.minute.toString().padLeft(2, '0')}';
    final end = '${cluster.endTime.hour.toString().padLeft(2, '0')}:'
        '${cluster.endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}

/// Sliver version for custom scroll views
class SliverVirtualClusterList extends StatelessWidget {
  final List<LocationCluster> clusters;
  final Function(LocationCluster)? onClusterTap;

  const SliverVirtualClusterList({
    super.key,
    required this.clusters,
    this.onClusterTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList(
      itemExtent: 80.0,
      delegate: SliverChildBuilderDelegate(
        (context, index) => _ClusterTile(
          cluster: clusters[index],
          onTap: onClusterTap,
        ),
        childCount: clusters.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
      ),
    );
  }
}

/// Windowed list that only keeps a subset of items in memory
class WindowedClusterList extends HookConsumerWidget {
  final List<LocationCluster> clusters;
  final Function(LocationCluster)? onClusterTap;
  final int windowSize;

  const WindowedClusterList({
    super.key,
    required this.clusters,
    this.onClusterTap,
    this.windowSize = 50,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final visibleRange = useState<(int, int)>((0, windowSize));

    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) return;

        final position = scrollController.position;
        final itemHeight = 80.0;
        final firstVisible = (position.pixels / itemHeight).floor();
        final lastVisible = ((position.pixels + position.viewportDimension) / itemHeight).ceil();

        // Update visible range with buffer
        final start = (firstVisible - 10).clamp(0, clusters.length);
        final end = (lastVisible + 10).clamp(0, clusters.length);

        if (visibleRange.value != (start, end)) {
          visibleRange.value = (start, end);
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    final (start, end) = visibleRange.value;
    final visibleClusters = clusters.sublist(start, end);

    return Scrollbar(
      controller: scrollController,
      child: ListView.builder(
        controller: scrollController,
        itemExtent: 80.0,
        cacheExtent: 0, // We handle caching manually
        itemCount: clusters.length,
        itemBuilder: (context, index) {
          // Only build items in visible range
          if (index < start || index >= end) {
            return const SizedBox(height: 80);
          }

          final relativeIndex = index - start;
          if (relativeIndex >= 0 && relativeIndex < visibleClusters.length) {
            return _ClusterTile(
              cluster: visibleClusters[relativeIndex],
              onTap: onClusterTap,
            );
          }

          return const SizedBox(height: 80);
        },
      ),
    );
  }
}