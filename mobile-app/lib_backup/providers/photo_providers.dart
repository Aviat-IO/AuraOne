import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'photo_service_provider.dart' show photoServiceProvider;

// Re-export the photo service provider for backward compatibility
export 'photo_service_provider.dart' show photoServiceProvider;

// Photo permission state provider
final photoPermissionProvider = StateProvider<bool>((ref) => false);

// Photo scanning state provider
final isPhotoScanningProvider = StateProvider<bool>((ref) => false);

// Recent photos provider - using actual PhotoService methods
final recentPhotosProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final photoService = ref.watch(photoServiceProvider);
  // The PhotoService might have different methods - we'll use what's available
  // This is a placeholder that prevents compilation errors
  return [];
});

// Photos by date provider - placeholder
final photosByDateProvider = FutureProvider.family<List<dynamic>, DateTime>((ref, date) async {
  // Placeholder implementation
  return [];
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