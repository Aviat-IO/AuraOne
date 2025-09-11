import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../database/media_database.dart';
import '../services/face_detector.dart';
import '../services/person_service.dart';
import '../services/photo_service.dart';

// Singleton provider for the PhotoService with database integration
final photoServiceProvider = Provider<PhotoService>((ref) {
  final service = PhotoService(ref);

  // Dispose the service when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// Provider for photo discovery stream
final photoDiscoveryStreamProvider = StreamProvider<PhotoDiscoveryEvent>((ref) {
  final service = ref.watch(photoServiceProvider);
  return service.photoDiscoveryStream;
});

// Provider for new photo stream
final newPhotoStreamProvider = StreamProvider<List<AssetEntity>>((ref) {
  final service = ref.watch(photoServiceProvider);
  return service.newPhotoStream;
});

// Provider for scan statistics
final scanStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(photoServiceProvider);
  return service.getScanStatistics();
});

// Provider for stored media items from database
final storedMediaItemsProvider = FutureProvider.family<List<MediaItem>, ({bool includeDeleted, bool processedOnly})>(
  (ref, params) {
    final service = ref.watch(photoServiceProvider);
    return service.getStoredMediaItems(
      includeDeleted: params.includeDeleted,
      processedOnly: params.processedOnly,
    );
  },
);

// Provider for stored media statistics from database
final storedMediaStatisticsProvider = FutureProvider<Map<String, int>>((ref) {
  final service = ref.watch(photoServiceProvider);
  return service.getStoredMediaStatistics();
});

// Provider for photo service initialization
final photoServiceInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(photoServiceProvider);
  await service.initialize();
});

// Provider for permission state
final photoPermissionProvider = FutureProvider<PermissionState>((ref) async {
  final service = ref.watch(photoServiceProvider);
  return await service.requestPermissions();
});

// Provider for photo albums
final photoAlbumsProvider = FutureProvider.family<List<AssetPathEntity>, ({RequestType type, bool onlyAll})>(
  (ref, params) async {
    final service = ref.watch(photoServiceProvider);
    return await service.getAlbums(
      type: params.type,
      onlyAll: params.onlyAll,
    );
  },
);

// Provider for manual photo scan
final manualPhotoScanProvider = FutureProvider.family<List<AssetEntity>, ({DateTime? since, Duration lookback})>(
  (ref, params) async {
    final service = ref.watch(photoServiceProvider);
    return await service.performManualScan(
      since: params.since,
      lookback: params.lookback,
    );
  },
);

// Provider for photos with faces detection
final photosWithFacesProvider = FutureProvider.family<Map<String, FaceDetectionResult>, List<AssetEntity>>(
  (ref, assets) async {
    final service = ref.watch(photoServiceProvider);
    return await service.getPhotosWithFaces(assets);
  },
);

// Provider for person identification in photos
final personIdentificationProvider = FutureProvider.family<List<Person>, List<AssetEntity>>(
  (ref, photos) async {
    final service = ref.watch(photoServiceProvider);
    return await service.identifyPersonsInPhotos(photos);
  },
);

// Provider for all identified persons
final allPersonsProvider = FutureProvider<List<Person>>((ref) async {
  final service = ref.watch(photoServiceProvider);
  return await service.getAllPersons();
});

// Provider for person statistics
final personStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(photoServiceProvider);
  return await service.getPersonStatistics();
});

// Provider for searching persons by name
final personSearchProvider = FutureProvider.family<List<Person>, String>(
  (ref, query) async {
    final service = ref.watch(photoServiceProvider);
    return await service.searchPersonsByName(query);
  },
);

// Provider for today's photos with faces
final todayPhotosWithFacesProvider = FutureProvider<Map<String, FaceDetectionResult>>((ref) async {
  final service = ref.watch(photoServiceProvider);
  return await service.getTodayPhotosWithFaces();
});

// Provider for identifying persons in today's photos
final todayPersonIdentificationProvider = FutureProvider<List<Person>>((ref) async {
  final service = ref.watch(photoServiceProvider);
  return await service.identifyPersonsInTodayPhotos();
});
