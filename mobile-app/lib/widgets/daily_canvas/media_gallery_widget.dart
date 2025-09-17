import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:io';
import '../../providers/media_database_provider.dart';
import '../../providers/media_thumbnail_provider.dart' show CachedThumbnailWidget;

// Provider for media items from device storage
// Using autoDispose to clean up when not needed
final mediaItemsProvider = FutureProvider.family.autoDispose<List<MediaItem>, ({DateTime date, bool includeDeleted})>((ref, params) async {
  final mediaDb = ref.watch(mediaDatabaseProvider);

  // Calculate date range for the selected day
  final startOfDay = DateTime(params.date.year, params.date.month, params.date.day, 0, 0, 0);
  final endOfDay = DateTime(params.date.year, params.date.month, params.date.day, 23, 59, 59);

  try {
    // Query media items for the specific date range
    final mediaItems = await mediaDb.getMediaByDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
      processedOnly: false,  // Show both processed and unprocessed media
      includeDeleted: params.includeDeleted,
    );

    // Early return if no items found
    if (mediaItems.isEmpty) {
      return [];
    }

    // Convert database media items to UI MediaItem objects
    // Process items in parallel for better performance
    final List<MediaItem> result = [];

    // Process items more efficiently
    for (final item in mediaItems) {
      // Determine media type based on MIME type
      MediaType type = MediaType.photo;
      if (item.mimeType.startsWith('video/')) {
        type = MediaType.video;
      } else if (item.mimeType.startsWith('audio/')) {
        type = MediaType.audio;
      }

      // Create file URLs from file paths
      String? fileUrl;
      String? thumbnailUrl;

      // Optimize file existence check - avoid sync I/O in loop
      if (item.filePath != null) {
        fileUrl = item.filePath!; // Use direct path for local files
        thumbnailUrl = item.filePath!; // Use same path for thumbnails
        // File existence will be checked during image loading
      }

      if (fileUrl != null) {
        result.add(MediaItem(
          id: item.id,
          type: type,
          url: fileUrl,
          thumbnailUrl: thumbnailUrl ?? fileUrl,
          timestamp: item.createdDate,
          caption: '', // No captions in media database
          duration: item.duration != null ? Duration(seconds: item.duration!) : null,
          isDeleted: item.isDeleted,
        ));
      }
    }

    // Sort by timestamp, newest first
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return result;
  } catch (e) {
    debugPrint('Error loading media items for date ${params.date}: $e');
    return [];
  }
});

// Provider for loading state
final mediaLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for gallery view mode
final galleryViewModeProvider = StateProvider<GalleryViewMode>((ref) => GalleryViewMode.grid);

enum MediaType { photo, video, audio }
enum GalleryViewMode { grid, carousel }

class MediaItem {
  final String id;
  final MediaType type;
  final String url;
  final String thumbnailUrl;
  final DateTime timestamp;
  final String? caption;
  final Duration? duration;
  final bool isDeleted;

  MediaItem({
    required this.id,
    required this.type,
    required this.url,
    required this.thumbnailUrl,
    required this.timestamp,
    this.caption,
    this.duration,
    this.isDeleted = false,
  });
}

class MediaGalleryWidget extends ConsumerWidget {
  final DateTime date;
  final bool enableSelection;

  const MediaGalleryWidget({
    super.key,
    required this.date,
    this.enableSelection = false,
  });

  Future<void> _toggleMediaSelection(MediaItem item, WidgetRef ref) async {
    try {
      final mediaDb = ref.read(mediaDatabaseProvider);

      if (item.isDeleted) {
        // Restore the item (include it)
        await mediaDb.restoreMediaItem(item.id);
      } else {
        // Soft delete the item (exclude it)
        await mediaDb.softDeleteMediaItem(item.id);
      }

      // Refresh the provider to update the UI
      ref.invalidate(mediaItemsProvider);
    } catch (e) {
      debugPrint('Error toggling media selection: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final mediaItemsAsync = ref.watch(mediaItemsProvider((date: date, includeDeleted: enableSelection)));
    final viewMode = ref.watch(galleryViewModeProvider);

    return mediaItemsAsync.when(
      data: (mediaItems) => Column(
        children: [
          // Gallery header with view mode selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${mediaItems.length} items',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Row(
                  children: [
                    _buildViewModeButton(
                      icon: Icons.grid_view,
                      mode: GalleryViewMode.grid,
                      currentMode: viewMode,
                      onTap: () => ref.read(galleryViewModeProvider.notifier).state = GalleryViewMode.grid,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildViewModeButton(
                      icon: Icons.view_carousel,
                      mode: GalleryViewMode.carousel,
                      currentMode: viewMode,
                      onTap: () => ref.read(galleryViewModeProvider.notifier).state = GalleryViewMode.carousel,
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Gallery content
          Expanded(
            child: mediaItems.isEmpty
                ? _buildEmptyState(theme, context, ref)
                : _buildGalleryContent(
                    mediaItems: mediaItems,
                    viewMode: viewMode,
                    theme: theme,
                    isLight: isLight,
                    context: context,
                    ref: ref,
                  ),
          ),
        ],
      ),
      loading: () => Skeletonizer(
        enabled: true,
        child: Column(
          children: [
            // Header skeleton
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Row(
                    children: List.generate(3, (index) => Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                ],
              ),
            ),
            // Grid skeleton
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading media',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No photos for this day',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Photos from your device will appear here\nwhen available for this date',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryContent({
    required List<MediaItem> mediaItems,
    required GalleryViewMode viewMode,
    required ThemeData theme,
    required bool isLight,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    switch (viewMode) {
      case GalleryViewMode.grid:
        return _buildGridView(mediaItems, theme, isLight, context, ref);
      case GalleryViewMode.carousel:
        return _buildCarouselView(mediaItems, theme, isLight, context, ref);
    }
  }

  Widget _buildGridView(
    List<MediaItem> mediaItems,
    ThemeData theme,
    bool isLight,
    BuildContext context,
    WidgetRef ref,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      cacheExtent: 500, // Cache items off-screen for smoother scrolling
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: mediaItems.length,
      addAutomaticKeepAlives: false, // Disable automatic keep alives
      addRepaintBoundaries: true, // Add repaint boundaries for performance
      itemBuilder: (context, index) {
        final item = mediaItems[index];
        return _buildMediaThumbnail(
          item: item,
          onTap: () => _openImageViewer(context, mediaItems, index),
          theme: theme,
          isLight: isLight,
          ref: ref,
        );
      },
    );
  }


  Widget _buildCarouselView(
    List<MediaItem> mediaItems,
    ThemeData theme,
    bool isLight,
    BuildContext context,
    WidgetRef ref,
  ) {
    return PageView.builder(
      padEnds: false,
      controller: PageController(viewportFraction: 0.85),
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final item = mediaItems[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: _buildMediaCarouselItem(
            item: item,
            onTap: () => _openImageViewer(context, mediaItems, index),
            theme: theme,
            isLight: isLight,
            ref: ref,
          ),
        );
      },
    );
  }

  Widget _buildMediaThumbnail({
    required MediaItem item,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isLight,
    required WidgetRef ref,
  }) {
    return GestureDetector(
      onTap: enableSelection
          ? () => _toggleMediaSelection(item, ref)
          : onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image with opacity based on selection state
              Opacity(
                opacity: enableSelection && item.isDeleted ? 0.5 : 1.0,
                child: _buildOptimizedThumbnail(
                  url: item.thumbnailUrl,
                  fit: BoxFit.cover,
                  theme: theme,
                ),
              ),

              // Excluded overlay
              if (enableSelection && item.isDeleted)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: Icon(
                      Icons.remove_circle,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ),

              // Video play button
              if (item.type == MediaType.video && (!enableSelection || !item.isDeleted))
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

              // Selection indicator
              if (enableSelection)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: item.isDeleted
                          ? Colors.red.withValues(alpha: 0.9)
                          : Colors.green.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      item.isDeleted ? Icons.remove : Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMediaCarouselItem({
    required MediaItem item,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isLight,
    required WidgetRef ref,
  }) {
    return GestureDetector(
      onTap: enableSelection
          ? () => _toggleMediaSelection(item, ref)
          : onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildOptimizedThumbnail(
                url: item.url,
                fit: BoxFit.cover,
                theme: theme,
              ),
              // Gradient overlay for caption
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.caption != null)
                        Text(
                          item.caption!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (item.type == MediaType.video)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required GalleryViewMode mode,
    required GalleryViewMode currentMode,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final isActive = mode == currentMode;

    return Material(
      color: isActive
          ? theme.colorScheme.primary.withValues(alpha: 0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, List<MediaItem> mediaItems, int initialIndex) {
    // Filter to only photo items and track their original indices
    final photoItems = <MediaItem>[];
    final photoIndices = <int>[];

    for (int i = 0; i < mediaItems.length; i++) {
      if (mediaItems[i].type == MediaType.photo) {
        photoItems.add(mediaItems[i]);
        photoIndices.add(i);
      }
    }

    if (photoItems.isEmpty) return;

    // Find the correct index in the filtered photo list
    int photoIndex = 0;
    for (int i = 0; i < photoIndices.length; i++) {
      if (photoIndices[i] == initialIndex) {
        photoIndex = i;
        break;
      }
    }

    final imageProviders = photoItems
        .map((item) => _getImageProvider(item.url))
        .toList();

    final imageProvider = MultiImageProvider(imageProviders, initialIndex: photoIndex);
    showImageViewerPager(
      context,
      imageProvider,
      onPageChanged: (page) {},
      onViewerDismissed: (page) {},
      backgroundColor: Colors.black.withValues(alpha: 0.9),
    );
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImageProvider(url);
    } else {
      return FileImage(File(url));
    }
  }



  Widget _buildOptimizedThumbnail({
    required String url,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    required ThemeData theme,
  }) {
    // Use our optimized thumbnail provider for local files
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return CachedThumbnailWidget(
        filePath: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            size: 24,
          ),
        ),
      );
    }

    // Handle network images with optimized settings
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: width != null ? (width * 2).toInt() : 400,
      memCacheHeight: height != null ? (height * 2).toInt() : 400,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          size: 24,
        ),
      ),
    );
  }
}
