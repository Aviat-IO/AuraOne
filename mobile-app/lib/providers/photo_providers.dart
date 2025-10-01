import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'media_database_provider.dart';
import '../database/media_database.dart';

// Export photo service provider for backward compatibility
export 'photo_service_provider.dart' show photoServiceProvider;

// Photo permission state provider
final photoPermissionProvider = StateProvider<bool>((ref) => false);

// Photo scanning state provider
final isPhotoScanningProvider = StateProvider<bool>((ref) => false);

// Recent photos provider - fetches recent media items from database
final recentPhotosProvider = FutureProvider.autoDispose<List<MediaItem>>((ref) async {
  final mediaDb = ref.watch(mediaDatabaseProvider);
  return await mediaDb.getRecentMedia(
    duration: const Duration(days: 30),
    limit: 100,
    includeDeleted: false,
  );
});

// Photos by date provider - fetches media for a specific date
final photosByDateProvider = FutureProvider.family<List<MediaItem>, DateTime>((ref, date) async {
  final mediaDb = ref.watch(mediaDatabaseProvider);
  // Get photos for the entire day (start to end of day)
  final dayStart = DateTime(date.year, date.month, date.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  return await mediaDb.getMediaByDateRange(
    startDate: dayStart,
    endDate: dayEnd,
    includeDeleted: false,
    processedOnly: true,
  );
});

// Photo album provider - placeholder
final photoAlbumsProvider = FutureProvider<List<PhotoAlbum>>((ref) async {
  // Placeholder implementation
  return [];
});

// Photo asset model
class PhotoAsset {
  final String id;
  final String? path;
  final DateTime? createDate;
  final DateTime? modifyDate;
  final double? latitude;
  final double? longitude;
  final int? width;
  final int? height;
  final String? mimeType;
  final int? fileSize;
  final Map<String, dynamic>? metadata;

  PhotoAsset({
    required this.id,
    this.path,
    this.createDate,
    this.modifyDate,
    this.latitude,
    this.longitude,
    this.width,
    this.height,
    this.mimeType,
    this.fileSize,
    this.metadata,
  });
}

// Photo album model
class PhotoAlbum {
  final String id;
  final String name;
  final int assetCount;
  final DateTime? startDate;
  final DateTime? endDate;

  PhotoAlbum({
    required this.id,
    required this.name,
    required this.assetCount,
    this.startDate,
    this.endDate,
  });
}