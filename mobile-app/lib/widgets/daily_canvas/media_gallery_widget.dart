import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/colors.dart';

// Provider for media items
final mediaItemsProvider = StateProvider.family<List<MediaItem>, DateTime>((ref, date) {
  // TODO: Replace with actual media from storage
  return [
    MediaItem(
      id: '1',
      type: MediaType.photo,
      url: 'https://picsum.photos/400/300?random=1',
      thumbnailUrl: 'https://picsum.photos/200/150?random=1',
      timestamp: DateTime(date.year, date.month, date.day, 8, 30),
      caption: 'Morning coffee',
    ),
    MediaItem(
      id: '2',
      type: MediaType.photo,
      url: 'https://picsum.photos/400/300?random=2',
      thumbnailUrl: 'https://picsum.photos/200/150?random=2',
      timestamp: DateTime(date.year, date.month, date.day, 12, 0),
      caption: 'Lunch view',
    ),
    MediaItem(
      id: '3',
      type: MediaType.photo,
      url: 'https://picsum.photos/400/300?random=3',
      thumbnailUrl: 'https://picsum.photos/200/150?random=3',
      timestamp: DateTime(date.year, date.month, date.day, 15, 30),
      caption: 'Afternoon walk',
    ),
    MediaItem(
      id: '4',
      type: MediaType.video,
      url: 'https://example.com/video.mp4',
      thumbnailUrl: 'https://picsum.photos/200/150?random=4',
      timestamp: DateTime(date.year, date.month, date.day, 18, 0),
      caption: 'Sunset timelapse',
      duration: const Duration(seconds: 30),
    ),
    MediaItem(
      id: '5',
      type: MediaType.photo,
      url: 'https://picsum.photos/400/300?random=5',
      thumbnailUrl: 'https://picsum.photos/200/150?random=5',
      timestamp: DateTime(date.year, date.month, date.day, 20, 0),
      caption: 'Dinner with friends',
    ),
    MediaItem(
      id: '6',
      type: MediaType.photo,
      url: 'https://picsum.photos/400/300?random=6',
      thumbnailUrl: 'https://picsum.photos/200/150?random=6',
      timestamp: DateTime(date.year, date.month, date.day, 21, 30),
      caption: 'Evening reading',
    ),
  ];
});

// Provider for loading state
final mediaLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for gallery view mode
final galleryViewModeProvider = StateProvider<GalleryViewMode>((ref) => GalleryViewMode.grid);

enum MediaType { photo, video, audio }
enum GalleryViewMode { grid, list, carousel }

class MediaItem {
  final String id;
  final MediaType type;
  final String url;
  final String thumbnailUrl;
  final DateTime timestamp;
  final String? caption;
  final Duration? duration;

  MediaItem({
    required this.id,
    required this.type,
    required this.url,
    required this.thumbnailUrl,
    required this.timestamp,
    this.caption,
    this.duration,
  });
}

class MediaGalleryWidget extends ConsumerWidget {
  final DateTime date;

  const MediaGalleryWidget({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final mediaItems = ref.watch(mediaItemsProvider(date));
    final isLoading = ref.watch(mediaLoadingProvider);
    final viewMode = ref.watch(galleryViewModeProvider);
    
    return Skeletonizer(
      enabled: isLoading,
      child: Column(
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
                      icon: Icons.view_list,
                      mode: GalleryViewMode.list,
                      currentMode: viewMode,
                      onTap: () => ref.read(galleryViewModeProvider.notifier).state = GalleryViewMode.list,
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
                ? _buildEmptyState(theme)
                : _buildGalleryContent(
                    mediaItems: mediaItems,
                    viewMode: viewMode,
                    theme: theme,
                    isLight: isLight,
                    context: context,
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No media for this day',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Photos and videos will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Add media
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Media'),
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
  }) {
    switch (viewMode) {
      case GalleryViewMode.grid:
        return _buildGridView(mediaItems, theme, isLight, context);
      case GalleryViewMode.list:
        return _buildListView(mediaItems, theme, isLight, context);
      case GalleryViewMode.carousel:
        return _buildCarouselView(mediaItems, theme, isLight, context);
    }
  }
  
  Widget _buildGridView(
    List<MediaItem> mediaItems,
    ThemeData theme,
    bool isLight,
    BuildContext context,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final item = mediaItems[index];
        return _buildMediaThumbnail(
          item: item,
          onTap: () => _openImageViewer(context, mediaItems, index),
          theme: theme,
          isLight: isLight,
        );
      },
    );
  }
  
  Widget _buildListView(
    List<MediaItem> mediaItems,
    ThemeData theme,
    bool isLight,
    BuildContext context,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final item = mediaItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMediaListItem(
            item: item,
            onTap: () => _openImageViewer(context, mediaItems, index),
            theme: theme,
            isLight: isLight,
          ),
        );
      },
    );
  }
  
  Widget _buildCarouselView(
    List<MediaItem> mediaItems,
    ThemeData theme,
    bool isLight,
    BuildContext context,
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
  }) {
    return GestureDetector(
      onTap: onTap,
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
              CachedNetworkImage(
                imageUrl: item.thumbnailUrl,
                fit: BoxFit.cover,
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
                  ),
                ),
              ),
              if (item.type == MediaType.video)
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
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMediaListItem({
    required MediaItem item,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isLight,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
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
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
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
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.caption != null)
                      Text(
                        item.caption!,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (item.type == MediaType.video && item.duration != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(item.duration!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
  }) {
    return GestureDetector(
      onTap: onTap,
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
              CachedNetworkImage(
                imageUrl: item.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 48,
                  ),
                ),
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
    final imageProviders = mediaItems
        .where((item) => item.type == MediaType.photo)
        .map((item) => CachedNetworkImageProvider(item.url))
        .toList();
    
    if (imageProviders.isNotEmpty) {
      final imageProvider = MultiImageProvider(imageProviders);
      showImageViewerPager(
        context,
        imageProvider,
        onPageChanged: (page) {},
        onViewerDismissed: (page) {},
        backgroundColor: Colors.black.withValues(alpha: 0.9),
      );
    }
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}